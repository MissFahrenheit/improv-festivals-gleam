# Create your shipment

## First compile the front
``` bash
cd front && gleam run -m lustre/dev build
```

## Then create an erlang shipment
``` bash
cd ../back && gleam export erlang-shipment
```

# Run the command on your server
``` bash
SPREADSHEET_ID="" \
GOOGLE_DEVELOPER_KEY="" \
GOOGLE_API_URL="https://sheets.googleapis.com/v4/spreadsheets/" \
APP_URL="/" \
# this is where we cache the spreadsheets
RESOURCES_DIR="/path/to/resources" \
# this is the website output
OUTPUT_DIR="/path/to/output" \
# this is where we store our static assets
STATIC_DIR="path/to/erlang-shipment/back/priv/static" \
# optional: path to an HTML file with your analytics snippet (see below)
ANALYTICS_SNIPPET_FILE="" \
/path/to/erlang-shipment/entrypoint.sh run
```

# Analytics (optional)
The generated site has no analytics by default. To add your own (Plausible,
Umami, Google Analytics, …), save the snippet your provider gives you in an HTML
file and point `ANALYTICS_SNIPPET_FILE` at it. Its contents are inserted as-is
just before `</head>`. Leave the variable unset to build without analytics.
