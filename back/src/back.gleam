import argv
import back_types.{HTMLFileWriteError}
import cache
import envoy
import festivals_html
import gleam/io
import gleam/list
import gleam/result
import helpers
import lustre/element
import sheet_parser
import simplifile

pub fn main() -> Nil {
  let args = argv.load().arguments

  let app_url = result.unwrap(envoy.get("APP_URL"), "/")
  result.lazy_unwrap(
    simplifile.create_directory_all(helpers.get_output_dir()),
    fn() { Nil },
  )
  result.lazy_unwrap(
    simplifile.create_directory_all(helpers.get_resource_dir()),
    fn() { Nil },
  )
  helpers.copy_static_assets()

  let data_result = case list.contains(args, "--use-cache") {
    True -> cache.get_cached_data(helpers.get_sheet_info_filepath())
    False ->
      result.try(
        sheet_parser.fetch_spreadsheet_info(),
        cache.save_data_to_cache(_, helpers.get_sheet_info_filepath()),
      )
  }

  let res = {
    use json_sheets_data <- result.try(data_result)
    use sheets_titles <- result.try(sheet_parser.sheet_titles_decoder(
      json_sheets_data,
    ))

    let continents =
      sheets_titles
      |> list.map(sheet_parser.sheet_title_to_continent)

    list.flat_map(sheets_titles, fn(title) {
      case sheet_parser.sheet_to_festivals(title, args, continents) {
        Error(_) -> []
        Ok(sheet_festivals) -> sheet_festivals
      }
    })
    |> festivals_html.festival_to_html(continents, app_url)
    |> element.to_document_string
    |> simplifile.write(helpers.get_output_dir() <> "/index.html", _)
    |> result.replace_error(HTMLFileWriteError("Could not write HTML file"))
  }

  case res {
    Error(msg) -> {
      io.println_error(msg.msg)
      Nil
    }
    Ok(_) -> {
      io.println("Finished successfully")
      Nil
    }
  }
}
