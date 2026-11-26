import back_types.{
  type Config, type GeneratorError, FetchFacebookImageError,
  FetchWebsiteImageError, GetFacebookIdError,
}
import cache
import gleam/bool
import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import helpers

pub type CachedImage {
  CachedImage(webpage: String, image_src: String)
}

pub fn get_cached_images(config: Config) {
  case cache.get_cached_data(helpers.get_images_json_filepath(config)) {
    Error(_) -> []
    Ok(images_json) -> {
      case json.parse(images_json, decode.list(cached_image_decoder())) {
        Error(_) -> []
        Ok(cached_images) -> cached_images
      }
    }
  }
}

const timeout_ms = 10_000

fn fetch_image(webpage: String, facebook: String) -> String {
  fetch_from_webpage(webpage)
  |> result.lazy_or(fn() { fetch_from_facebook(facebook) })
  |> result.unwrap("")
}

fn extract_facebook_id(facebook_url: String) -> Result(String, GeneratorError) {
  facebook_url
  |> string.trim
  |> string.split("/")
  |> list.filter(fn(item) { item != "" })
  |> list.last
  |> result.replace_error(GetFacebookIdError("Could not extract Facebook ID"))
}

fn fetch_from_facebook(facebook_url: String) -> Result(String, GeneratorError) {
  use <- bool.guard(
    facebook_url == "",
    Error(FetchFacebookImageError("No Facebook page")),
  )
  use facebook_id <- result.try(extract_facebook_id(facebook_url))
  let fb_request_url =
    "https://graph.facebook.com/" <> facebook_id <> "/picture?type=large"

  use req <- result.try(
    request.to(fb_request_url)
    |> result.replace_error(FetchFacebookImageError(
      "Could not fetch image from Facebook",
    )),
  )
  use resp <- result.try(
    httpc.configure()
    |> httpc.timeout(timeout_ms)
    |> httpc.dispatch(req)
    |> result.replace_error(FetchFacebookImageError(
      "Could not fetch image from Facebook",
    )),
  )
  case list.key_find(resp.headers, "location") {
    Error(_) -> Error(FetchFacebookImageError("Could not find location header"))
    Ok(location) -> Ok(location)
  }
}

fn fetch_from_webpage(webpage: String) -> Result(String, GeneratorError) {
  use <- bool.guard(webpage == "", Error(FetchWebsiteImageError("No website")))
  use req <- result.try(
    request.to(webpage)
    |> result.replace_error(FetchWebsiteImageError("Could not find website")),
  )
  use resp <- result.try(
    httpc.configure()
    |> httpc.follow_redirects(True)
    |> httpc.timeout(timeout_ms)
    |> httpc.dispatch(req)
    |> result.replace_error(FetchWebsiteImageError(
      "Could not fetch image from website",
    )),
  )
  find_image_in_body(resp.body)
}

fn find_image_in_body(body: String) -> Result(String, GeneratorError) {
  let assert Ok(regex) =
    regexp.from_string("<meta property=\"og:image\" content=\"([^\"]+)\"")

  case regexp.check(with: regex, content: body) {
    True -> {
      let matches = regexp.scan(regex, body)
      let assert Ok(first_match) = list.first(matches)
      let assert Ok(first_sub) = list.first(first_match.submatches)
      Ok(option.unwrap(first_sub, ""))
    }
    False -> Error(FetchWebsiteImageError("OG image not found on website"))
  }
}

pub fn get_image_and_cache(
  cached_images: List(CachedImage),
  webpage: String,
  facebook: String,
) -> #(List(CachedImage), String) {
  // The cache is keyed by website, or by Facebook page when there is no
  // website. A festival with neither gets no image and no cache entry, so it
  // can't pick up another festival's picture.
  let cache_key = case webpage {
    "" -> facebook
    _ -> webpage
  }
  case
    cache_key,
    list.find(cached_images, fn(cached_image) {
      cached_image.webpage == cache_key
    })
  {
    "", _ -> #(cached_images, "")
    _, Ok(cached_image) -> #(cached_images, cached_image.image_src)
    _, Error(_) -> {
      let image_src = fetch_image(webpage, facebook)
      let updated_cache =
        list.append(cached_images, [
          CachedImage(webpage: cache_key, image_src:),
        ])
      #(updated_cache, image_src)
    }
  }
}

pub fn cached_images_to_json(cached_images: List(CachedImage)) -> json.Json {
  json.array(cached_images, cached_image_to_json)
}

fn cached_image_to_json(cached_image: CachedImage) -> json.Json {
  let CachedImage(webpage:, image_src:) = cached_image
  json.object([
    #("webpage", json.string(webpage)),
    #("image_src", json.string(image_src)),
  ])
}

fn cached_image_decoder() -> decode.Decoder(CachedImage) {
  use webpage <- decode.field("webpage", decode.string)
  use image_src <- decode.field("image_src", decode.string)
  decode.success(CachedImage(webpage:, image_src:))
}
