import envoy

// import gleam/list
// import gleam/result
import simplifile

pub fn get_resource_dir() -> String {
  let assert Ok(sheet_file_src) = envoy.get("DATA_DIR")
  sheet_file_src
}

pub fn get_images_json_filepath() -> String {
  get_resource_dir() <> "/images.json"
}

pub fn get_sheet_info_filepath() -> String {
  get_resource_dir() <> "/improv_festivals-info.json"
}

pub fn get_output_dir() -> String {
  let assert Ok(output_dir) = envoy.get("OUTPUT_DIR")
  output_dir
}

pub fn get_static_dir() -> String {
  let assert Ok(static_dir) = envoy.get("STATIC_DIR")
  static_dir
}

pub fn copy_static_assets() -> Nil {
  let target_path = get_output_dir() <> "/static"
  let _ = simplifile.copy_directory("./priv/static", target_path)
  Nil
}
