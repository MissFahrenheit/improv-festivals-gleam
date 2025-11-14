import back_types.{type Config}

pub fn get_images_json_filepath(config: Config) -> String {
  config.resources_dir <> "/images.json"
}

pub fn get_sheet_info_filepath(config: Config) -> String {
  config.resources_dir <> "/improv_festivals-info.json"
}
