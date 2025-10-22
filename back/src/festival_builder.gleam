import birl
import birl/duration
import gleam/dict
import gleam/int
import gleam/list
import gleam/order
import gleam/regexp
import gleam/result
import gleam/string
import gleam/uri
import types.{type Continent, type Festival, type YearCase, Festival}

pub fn sort_festivals_by_year_month(
  festival_a: Festival,
  festival_b: Festival,
) -> order.Order {
  string.compare(festival_a.year_month, festival_b.year_month)
}

pub fn map_data_list_to_festival(
  dict_row: dict.Dict(String, String),
  continents: List(Continent),
  continent_id: String,
) -> Festival {
  let assert Ok(continent) =
    list.find(continents, fn(continent) { continent.id == continent_id })
  let name = result.unwrap(dict.get(dict_row, "festival-name"), "")
  let city = result.unwrap(dict.get(dict_row, "city"), "")
  let country = result.unwrap(dict.get(dict_row, "country"), "")
  let languages = result.unwrap(dict.get(dict_row, "language-s"), "")
  let facebook = result.unwrap(dict.get(dict_row, "facebook"), "")
  let webpage = normalize_url(result.unwrap(dict.get(dict_row, "webpage"), ""))

  let festival =
    Festival(
      name:,
      city:,
      country:,
      languages:,
      date: "",
      continent:,
      facebook:,
      year_month: "",
      webpage:,
      image: "",
    )

  update_festival_dates(dict_row, festival)
}

fn update_festival_dates(
  dict_row: dict.Dict(String, String),
  festival: Festival,
) -> Festival {
  let now = birl.now()
  let current_year = birl.get_day(now).year
  let next_year = birl.get_day(birl.add(now, duration.years(1))).year

  let assert Ok(month) = dict.get(dict_row, "mm")
  let assert Ok(month_int) = int.parse(month)

  let current_year_date = extract_date_string_by_year(dict_row, current_year)
  let next_year_date = extract_date_string_by_year(dict_row, next_year)

  let festival_year_case =
    determine_year_case(month_int, current_year_date, next_year_date)

  Festival(
    ..festival,
    date: choose_date_string(
      current_year_date,
      next_year_date,
      festival_year_case,
    ),
    year_month: get_yearmonth(
      month_int,
      current_year,
      next_year,
      festival_year_case,
    ),
  )
}

pub fn get_yearmonth(
  month: Int,
  current_year: Int,
  next_year: Int,
  festival_year_case: YearCase,
) -> String {
  case festival_year_case {
    types.Empty -> ""
    types.ThisYear -> int.to_string(current_year) <> "-" <> int.to_string(month)
    types.NextYear -> int.to_string(next_year) <> "-" <> int.to_string(month)
  }
}

fn determine_year_case(
  month: Int,
  current_year_date: String,
  next_year_date: String,
) -> YearCase {
  let current_month = birl.get_day(birl.now()).month

  case current_year_date, next_year_date {
    "", "" -> types.Empty
    "", _ -> types.NextYear
    _, _ -> {
      case month >= current_month {
        True -> types.ThisYear
        False -> types.NextYear
      }
    }
  }
}

fn choose_date_string(
  current_year_date: String,
  next_year_date: String,
  year_case: YearCase,
) -> String {
  case year_case {
    types.Empty -> ""
    types.ThisYear -> current_year_date
    types.NextYear -> next_year_date
  }
}

fn extract_date_string_by_year(
  dict_row: dict.Dict(String, String),
  year: Int,
) -> String {
  let date_string =
    year
    |> int.to_string
    |> dict.get(dict_row, _)
    |> result.unwrap("")

  let assert Ok(regex) = regexp.from_string("\\d")

  case regexp.check(with: regex, content: date_string) {
    True -> date_string
    False -> ""
  }
}

fn normalize_url(webpage: String) -> String {
  let trimmed_webpage = string.trim(webpage)

  let assert Ok(regex) = regexp.from_string("^https?://")

  let url = case regexp.check(with: regex, content: trimmed_webpage) {
    True -> trimmed_webpage
    False -> {
      "https://" <> trimmed_webpage
    }
  }
  case uri.parse(url) {
    Ok(_) -> url
    Error(_) -> ""
  }
}
