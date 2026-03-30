
load_from_thredds <- function(url) {
  # Requires: httr
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("Package 'httr' is required but not installed.")
  }
  
  tmp <- tempfile(fileext = ".RData")
  
  resp <- httr::GET(url, httr::write_disk(tmp, overwrite = TRUE))
  
  if (httr::http_error(resp)) {
    stop("Failed to download file: ", httr::http_status(resp)$message)
  }
  
  # Load into current environment
  load(tmp, envir = .GlobalEnv)
  
  message("Loaded .RData from: ", url)
  
  invisible(tmp)
}
