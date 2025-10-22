import back_types.{
  type GeneratorError, FetchGoogleSpreadsheetError, ParseJSONError,
}
import birl
import birl/duration
import cache
import envoy
import festival_builder
import gleam/dict
import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleam/uri
import glugify
import images
import types.{type Continent, type Festival, Continent, Festival}

type ColumnIndex {
  ColumnIndex(id: String, position: Int)
}

const sheet_file_src = "./resources/"

pub const info_filepath = "./resources/improv_festivals-info.json"

pub fn sheet_title_to_continent(title: String) -> Continent {
  Continent(id: glugify.slugify(title), label: title)
}

pub fn sheet_to_festivals(
  sheet_title: String,
  args: List(String),
  continents: List(Continent),
) -> Result(List(Festival), GeneratorError) {
  let assert Ok(google_developer_key) = envoy.get("GOOGLE_DEVELOPER_KEY")
  let assert Ok(spreadsheet_id) = envoy.get("SPREADSHEET_ID")
  let assert Ok(google_api_url) = envoy.get("GOOGLE_API_URL")
  let encoded_sheet_title = uri.percent_encode(sheet_title)
  let sheet_url =
    google_api_url
    <> spreadsheet_id
    <> "/values/"
    <> encoded_sheet_title
    <> "?key="
    <> google_developer_key

  let slugified_sheet_title = glugify.slugify(sheet_title)

  let filepath =
    sheet_file_src <> "improv_festivals-" <> slugified_sheet_title <> ".json"

  let data_result = case list.contains(args, "--use-cache") {
    True -> cache.get_cached_data(filepath)
    False ->
      result.try(fetch_spreadsheet_data(sheet_url), cache.save_data_to_cache(
        _,
        filepath,
      ))
  }
  use json_data <- result.try(data_result)

  use data_list <- result.try(sheet_values_decoder(json_data))

  let assert Ok(first_row) = list.first(data_list)
  let column_indexes = define_columns(first_row)
  let cached_images = images.get_cached_images()

  let images_and_festivals =
    list.drop(data_list, 1)
    |> list.map(fn(data_list_row) {
      data_to_key_value_list(data_list_row, column_indexes)
      |> dict.from_list()
    })
    |> list.filter(fn(dict_row) {
      case dict.get(dict_row, "mm") {
        Ok(mm) -> !string.is_empty(mm)
        Error(_) -> False
      }
    })
    |> list.map(festival_builder.map_data_list_to_festival(
      _,
      continents,
      slugified_sheet_title,
    ))
    |> list.filter(fn(festival) { festival.date != "" })
    |> list.fold(#(cached_images, []), fn(acc, festival) {
      let data =
        images.get_image_and_cache(acc.0, festival.webpage, festival.facebook)
      let festival = Festival(..festival, image: data.1)
      #(data.0, list.append(acc.1, [festival]))
    })

  let _ =
    images_and_festivals.0
    |> images.cached_images_to_json
    |> json.to_string
    |> cache.save_data_to_cache(images.image_file_src)

  images_and_festivals.1
  |> list.sort(festival_builder.sort_festivals_by_year_month)
  |> Ok
}

fn data_to_key_value_list(
  row: List(String),
  column_indexes: List(ColumnIndex),
) -> List(#(String, String)) {
  row
  |> list.index_fold([], fn(acc, field_value, index) {
    let res =
      list.find(column_indexes, fn(col_index) { col_index.position == index })
    case res {
      Error(_) -> acc
      Ok(field_col_index) ->
        list.append(acc, [#(field_col_index.id, field_value)])
    }
  })
}

fn fetch_spreadsheet_data(sheet_url) -> Result(String, GeneratorError) {
  let assert Ok(req) = request.to(sheet_url)

  case httpc.send(req) {
    Error(_) ->
      Error(FetchGoogleSpreadsheetError(
        "Error in fetching Google Spreadsheet data",
      ))
    Ok(resp) -> Ok(resp.body)
  }
}

pub fn fetch_spreadsheet_info() {
  let assert Ok(google_developer_key) = envoy.get("GOOGLE_DEVELOPER_KEY")
  let assert Ok(spreadsheet_id) = envoy.get("SPREADSHEET_ID")
  let assert Ok(google_api_url) = envoy.get("GOOGLE_API_URL")
  let spreadsheet_url =
    google_api_url <> spreadsheet_id <> "?key=" <> google_developer_key

  let assert Ok(req) = request.to(spreadsheet_url)

  case httpc.send(req) {
    Error(_) ->
      Error(FetchGoogleSpreadsheetError(
        "Error in fetching Google Spreadsheet data",
      ))
    Ok(resp) -> Ok(resp.body)
  }
}

pub fn sheet_titles_decoder(json_string: String) {
  let decoder = {
    use values <- decode.field(
      "sheets",
      decode.list(decode.at(["properties", "title"], decode.string)),
    )
    decode.success(values)
  }
  json.parse(from: json_string, using: decoder)
  |> result.replace_error(ParseJSONError("Error in parsing data from JSON file"))
}

fn sheet_values_decoder(
  json_string: String,
) -> Result(List(List(String)), GeneratorError) {
  let decoder = {
    use values <- decode.field(
      "values",
      decode.list(decode.list(decode.string)),
    )
    decode.success(values)
  }
  json.parse(from: json_string, using: decoder)
  |> result.replace_error(ParseJSONError("Error in parsing data from JSON file"))
}

fn allowed_column_names() -> List(String) {
  let now = birl.now()
  let current_year = birl.get_day(now).year
  let next_year = birl.get_day(birl.add(now, duration.years(1))).year
  [
    "festival-name",
    "city",
    "country",
    "language-s",
    "month",
    "mm",
    "webpage",
    "facebook",
    int.to_string(current_year),
    int.to_string(next_year),
  ]
}

fn define_columns(first_row: List(String)) -> List(ColumnIndex) {
  list.map(first_row, glugify.slugify)
  |> list.index_map(fn(name, index) { ColumnIndex(id: name, position: index) })
  |> list.filter(fn(column_index) {
    list.contains(allowed_column_names(), column_index.id)
  })
}
