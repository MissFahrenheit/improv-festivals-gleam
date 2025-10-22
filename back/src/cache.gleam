import back_types.{type GeneratorError, FetchCachedDataError, SaveCacheError}
import gleam/result
import simplifile

pub fn get_cached_data(filepath: String) -> Result(String, GeneratorError) {
  filepath
  |> simplifile.read()
  |> result.replace_error(FetchCachedDataError(
    "Error in fetching data from cached file",
  ))
}

pub fn save_data_to_cache(
  data_json: String,
  filepath: String,
) -> Result(String, GeneratorError) {
  filepath
  |> simplifile.write(data_json)
  |> result.replace(data_json)
  |> result.replace_error(SaveCacheError("Error in writing data to cache file"))
}
