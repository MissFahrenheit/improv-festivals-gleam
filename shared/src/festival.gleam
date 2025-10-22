import gleam/dynamic/decode
import gleam/json
import types.{type Continent, type Festival, Continent, Festival, Model}

pub fn festival_to_json(festival: Festival) -> json.Json {
  let Festival(
    name:,
    city:,
    country:,
    languages:,
    date:,
    webpage:,
    facebook:,
    year_month:,
    continent:,
    image:,
  ) = festival
  json.object([
    #("name", json.string(name)),
    #("city", json.string(city)),
    #("country", json.string(country)),
    #("languages", json.string(languages)),
    #("date", json.string(date)),
    #("webpage", json.string(webpage)),
    #("facebook", json.string(facebook)),
    #("year_month", json.string(year_month)),
    #("continent", continent_to_json(continent)),
    #("image", json.string(image)),
  ])
}

pub fn festival_decoder() -> decode.Decoder(Festival) {
  use name <- decode.field("name", decode.string)
  use city <- decode.field("city", decode.string)
  use country <- decode.field("country", decode.string)
  use languages <- decode.field("languages", decode.string)
  use date <- decode.field("date", decode.string)
  use webpage <- decode.field("webpage", decode.string)
  use facebook <- decode.field("facebook", decode.string)
  use year_month <- decode.field("year_month", decode.string)
  use continent <- decode.field("continent", continent_decoder())
  use image <- decode.field("image", decode.string)
  decode.success(Festival(
    name:,
    city:,
    country:,
    languages:,
    date:,
    webpage:,
    facebook:,
    year_month:,
    continent:,
    image:,
  ))
}

pub fn continent_to_json(continent: Continent) -> json.Json {
  let Continent(id:, label:) = continent
  json.object([
    #("id", json.string(id)),
    #("label", json.string(label)),
  ])
}

pub fn continent_decoder() -> decode.Decoder(Continent) {
  use id <- decode.field("id", decode.string)
  use label <- decode.field("label", decode.string)
  decode.success(Continent(id:, label:))
}

pub fn model_decoder() -> decode.Decoder(types.Model) {
  use active_tab <- decode.field("active_tab", decode.string)
  use festivals <- decode.field("festivals", decode.list(festival_decoder()))
  use continents <- decode.field("continents", decode.list(continent_decoder()))
  decode.success(Model(active_tab:, festivals:, continents:))
}
