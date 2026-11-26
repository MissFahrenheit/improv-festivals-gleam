import birl
import birl/duration
import gleam/dict
import gleam/int
import gleam/list
import gleam/option
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
  let name = string.trim(result.unwrap(dict.get(dict_row, "festival-name"), ""))
  let city = result.unwrap(dict.get(dict_row, "city"), "")
  let country = result.unwrap(dict.get(dict_row, "country"), "")
  let languages = result.unwrap(dict.get(dict_row, "language-s"), "")
  let facebook =
    normalize_url(result.unwrap(dict.get(dict_row, "facebook"), ""))
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

  // A row with a missing or non-numeric month gets no date and is dropped
  // later, instead of crashing the whole run.
  let month_int =
    dict.get(dict_row, "mm")
    |> result.try(fn(month) { int.parse(string.trim(month)) })
    |> result.unwrap(0)
  case month_int >= 1 && month_int <= 12 {
    False -> festival
    True ->
      set_festival_dates(dict_row, festival, month_int, current_year, next_year)
  }
}

fn set_festival_dates(
  dict_row: dict.Dict(String, String),
  festival: Festival,
  month_int: Int,
  current_year: Int,
  next_year: Int,
) -> Festival {
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

/// "YYYY-MM", zero-padded so that sorting the strings sorts by date
/// ("2027-02" before "2027-10").
pub fn get_yearmonth(
  month: Int,
  current_year: Int,
  next_year: Int,
  festival_year_case: YearCase,
) -> String {
  let padded_month = string.pad_start(int.to_string(month), 2, "0")
  case festival_year_case {
    types.Empty -> ""
    types.ThisYear -> int.to_string(current_year) <> "-" <> padded_month
    types.NextYear -> int.to_string(next_year) <> "-" <> padded_month
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

/// Adds https:// when the sheet has a bare domain. Returns "" for an empty
/// cell or anything that isn't a web address, so only http(s) links reach
/// the page.
fn normalize_url(webpage: String) -> String {
  let trimmed_webpage = string.trim(webpage)

  let assert Ok(regex) =
    regexp.compile(
      "^https?://",
      regexp.Options(case_insensitive: True, multi_line: False),
    )

  let url = case regexp.check(with: regex, content: trimmed_webpage) {
    True -> trimmed_webpage
    False -> "https://" <> trimmed_webpage
  }
  case trimmed_webpage, uri.parse(url) {
    "", _ -> ""
    _, Ok(uri.Uri(host: option.Some(host), ..)) ->
      case string.contains(host, ".") && !string.contains(host, " ") {
        True -> url
        False -> ""
      }
    _, _ -> ""
  }
}
