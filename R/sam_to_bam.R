#' Convert a SAM file to a BAM file
#'
#' @param sam Input SAM file
#' @param out_dir Directory to write output
#' 
#' @return Path to output BAM file: file extension will be changed to '.bam'
#' 
sam_to_bam <- function(sam, out_dir) {
  
  # Format output file
  out_file <- 
    fs::path_file(sam) %>%
    fs::path_ext_remove() %>%
    fs::path_ext_set(".bam") %>%
    fs::path(out_dir, .)

  run_docker(
    container_id = "quay.io/biocontainers/samtools:1.9--h91753b0_8",
    command = "samtools",
    args = c(
      "view",
      "-S",
      "-b",
      file = sam),
    stdout = out_file
  )
  
  out_file

}
