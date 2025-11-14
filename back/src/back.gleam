import argv
import back_types.{
  type Config, type GeneratorError, Config, DirectoryCreationError,
  FailedToLoadConfig, HTMLFileWriteError, StaticAssetCopyError,
}
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

  let res = {
    use config <- result.try(load_env(args))
    use _ <- result.try(create_directories(config))
    use _ <- result.try(copy_static_assets(config))
    use json_sheets_data <- result.try(case config.use_cache {
      True -> cache.get_cached_data(helpers.get_sheet_info_filepath(config))
      False ->
        result.try(
          sheet_parser.fetch_spreadsheet_info(config),
          cache.save_data_to_cache(_, helpers.get_sheet_info_filepath(config)),
        )
    })
    use sheets_titles <- result.try(sheet_parser.sheet_titles_decoder(
      json_sheets_data,
    ))
    let continents =
      sheets_titles
      |> list.map(sheet_parser.sheet_title_to_continent)

    list.flat_map(sheets_titles, fn(title) {
      case sheet_parser.sheet_to_festivals(config, title, continents) {
        Error(_) -> []
        Ok(sheet_festivals) -> sheet_festivals
      }
    })
    |> festivals_html.festival_to_html(continents, config.app_url)
    |> element.to_document_string
    |> simplifile.write(config.output_dir <> "/index.html", _)
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

fn load_env(args: List(String)) -> Result(Config, GeneratorError) {
  {
    use app_url <- result.try(envoy.get("APP_URL"))
    use resources_dir <- result.try(envoy.get("RESOURCES_DIR"))
    use output_dir <- result.try(envoy.get("OUTPUT_DIR"))
    use static_dir <- result.try(envoy.get("STATIC_DIR"))
    use google_api_url <- result.try(envoy.get("GOOGLE_API_URL"))
    use google_developer_key <- result.try(envoy.get("GOOGLE_DEVELOPER_KEY"))
    use spreadsheet_id <- result.try(envoy.get("SPREADSHEET_ID"))
    Ok(Config(
      use_cache: list.contains(args, "--use-cache"),
      refresh_images: list.contains(args, "--refresh-images"),
      spreadsheet_id:,
      google_developer_key:,
      google_api_url:,
      app_url:,
      resources_dir:,
      output_dir:,
      static_dir:,
    ))
  }
  |> result.replace_error(FailedToLoadConfig("Environment variable not found"))
}

fn create_directories(config: Config) -> Result(Nil, GeneratorError) {
  {
    use _ <- result.try(simplifile.create_directory_all(config.output_dir))
    use _ <- result.try(simplifile.create_directory_all(config.resources_dir))
    Ok(Nil)
  }
  |> result.replace_error(DirectoryCreationError("Directory creation failed"))
}

fn copy_static_assets(config: Config) -> Result(Nil, GeneratorError) {
  let target_path = config.output_dir <> "/static"
  {
    use _ <- result.try(simplifile.copy_directory(
      config.static_dir,
      target_path,
    ))
    Ok(Nil)
  }
  |> result.replace_error(StaticAssetCopyError("Could not copy static assets"))
}
