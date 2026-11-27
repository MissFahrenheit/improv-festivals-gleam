# Improv festivals

A static site generator for a list of improv festivals. It reads the festivals
from a Google Sheet (one sheet tab per continent), finds an image for each
festival, and writes a single `index.html` plus its static assets. A small
Lustre app in the page handles switching between the continent tabs.

The code is three Gleam projects:

- `back/`: the generator (Erlang target). Runs once and exits.
- `front/`: the browser app (JavaScript target), bundled into
  `back/priv/static/front.js`.
- `shared/`: the types and HTML view both of them use.

## How to build a release

You need [Gleam](https://gleam.run) and Erlang/OTP 27 or newer.

1. Bundle the front end into `back/priv/static/`:

   ```bash
   cd front && gleam run -m lustre/dev build
   ```

2. Export the generator as an Erlang shipment:

   ```bash
   cd ../back && gleam export erlang-shipment
   ```

The release is now in `back/build/erlang-shipment/`.

## How to deploy to a VPS

The generator runs from cron every 10 minutes and writes the site into a
folder; a web server serves that folder. Nothing runs between updates.

1. Install Erlang/OTP 27 or newer on the VPS (Gleam isn't needed there), and
   [Caddy](https://caddyserver.com) to serve the site.

2. Copy the release over:

   ```bash
   rsync -az --delete back/build/erlang-shipment/ you@vps:/opt/improv-festivals/
   ```

3. On the VPS, create `/opt/improv-festivals/.env` with the
   [environment variables](#environment-variables), and make it readable only
   by you (`chmod 600`), since it holds the API key:

   ```bash
   export SPREADSHEET_ID="..."
   export GOOGLE_DEVELOPER_KEY="..."
   export GOOGLE_API_URL="https://sheets.googleapis.com/v4/spreadsheets/"
   export APP_URL="/"
   export RESOURCES_DIR="/var/lib/improv-festivals"
   export OUTPUT_DIR="/var/www/improv-festivals"
   export STATIC_DIR="/opt/improv-festivals/back/priv/static"
   # optional, see Analytics below
   export ANALYTICS_SNIPPET_FILE="/etc/improv-festivals/analytics.html"
   ```

4. Add the cron job with `crontab -e`:

   ```
   */10 * * * *  . /opt/improv-festivals/.env && flock -n /tmp/improv-festivals.lock /opt/improv-festivals/entrypoint.sh run >> /var/log/improv-festivals.log 2>&1
   ```

   `flock -n` skips a run while the previous one is still going. The first
   run is the slow one, because it fetches every festival's image.

5. Serve the output folder. In `/etc/caddy/Caddyfile`:

   ```
   festivals.example.com {
       root * /var/www/improv-festivals
       file_server
       encode gzip
   }
   ```

   Then `systemctl reload caddy`.

To check it worked, run the cron command once by hand and look for
`Finished successfully` in `/var/log/improv-festivals.log`, then open the
site.

To deploy a code change, build a new release and repeat step 2.

## Reference

### Environment variables

All are required except `ANALYTICS_SNIPPET_FILE`; the generator exits with
`Environment variable not found` if a required one is missing.

| Variable | What it is |
| --- | --- |
| `SPREADSHEET_ID` | ID of the Google Sheet, from its URL. |
| `GOOGLE_DEVELOPER_KEY` | Google API key with access to the Sheets API. |
| `GOOGLE_API_URL` | Sheets API base URL: `https://sheets.googleapis.com/v4/spreadsheets/` |
| `APP_URL` | Base URL the site is served from, for example `/`. |
| `RESOURCES_DIR` | Where the cache is kept: the sheet data (`improv_festivals-*.json`) and the festival images (`images.json`). Created if missing. |
| `OUTPUT_DIR` | Where the site is written: `index.html` and `static/`. Created if missing. |
| `STATIC_DIR` | The static assets to copy into `OUTPUT_DIR/static`: the release's `back/priv/static`. |
| `ANALYTICS_SNIPPET_FILE` | Optional. Path to an HTML file with an analytics snippet; see [Analytics](#analytics). Unset means no analytics. |

### Analytics

The generated site has no analytics by default. To add your own (Plausible,
Umami, Google Analytics, …), save the snippet your provider gives you in an
HTML file and point `ANALYTICS_SNIPPET_FILE` at it. Its contents are inserted
as-is just before `</head>`. If the variable is set but the file can't be
read, the run fails. Keep the file outside the release folder, since step 2 of
the deploy replaces that folder.

### Command-line flags

| Flag | Effect |
| --- | --- |
| `--use-cache` | Read the sheet data from `RESOURCES_DIR` instead of fetching it from Google. Useful for working on the HTML offline. |

Festival images are always cached in `RESOURCES_DIR/images.json`, and only
festivals missing from it are looked up. To fetch every image again, delete
that file.

### Exit status

| Status | Meaning |
| --- | --- |
| `0` | The site was written. Prints `Finished successfully`. |
| `1` | The run failed and the error was printed to stderr. The previous `index.html` is left as it was. |
