pub type GeneratorError {
  FetchGoogleSpreadsheetError(msg: String)
  FetchCachedDataError(msg: String)
  SaveCacheError(msg: String)
  ParseJSONError(msg: String)
  FetchWebsiteImageError(msg: String)
  GetFacebookIdError(msg: String)
  FetchFacebookImageError(msg: String)
  HTMLFileWriteError(msg: String)
  FailedToLoadConfig(msg: String)
  DirectoryCreationError(msg: String)
  StaticAssetCopyError(msg: String)
}

pub type Config {
  Config(
    use_cache: Bool,
    refresh_images: Bool,
    spreadsheet_id: String,
    google_developer_key: String,
    google_api_url: String,
    app_url: String,
    resources_dir: String,
    output_dir: String,
    static_dir: String,
  )
}
