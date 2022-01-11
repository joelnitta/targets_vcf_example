#' Download and unzip a tar arhive
#'
#'
#' @param url URL of file to download
#' @param dir_out Directory to unzip files
#' @return Path to the downloaded, unzipped data files
download_and_untar <- function(url, dir_out) {

  temp_file <- tempfile(pattern = digest::digest(url))
  curl::curl_download(url, destfile = temp_file)
  utils::untar(
    tarfile = temp_file,
    exdir = dir_out
  )
  
  if (fs::file_exists(temp_file)) fs::file_delete(temp_file)
  
  list.files(dir_out, full.names = TRUE, recursive = TRUE) |> 
    fs::path_norm()

}
