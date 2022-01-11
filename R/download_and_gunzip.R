#' Download and unzip a file
#'
#' @param url URL of file to download
#' @param file_out Path to write unzipped data
#' @return Path to the downloaded, unzipped data
download_and_gunzip <- function(url, file_out) {

  temp_file <- tempfile(pattern = digest::digest(url))
  curl::curl_download(url, destfile = temp_file)
  R.utils::gunzip(
    filename = temp_file,
    destname = file_out,
    overwrite = TRUE,
    remove = TRUE
  )
  file_out

}
