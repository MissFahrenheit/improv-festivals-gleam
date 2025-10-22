pub type GeneratorError {
  FetchGoogleSpreadsheetError(msg: String)
  FetchCachedDataError(msg: String)
  SaveCacheError(msg: String)
  ParseJSONError(msg: String)
  FetchWebsiteImageError(msg: String)
  GetFacebookIdError(msg: String)
  FetchFacebookImageError(msg: String)
  HTMLFileWriteError(msg: String)
}
