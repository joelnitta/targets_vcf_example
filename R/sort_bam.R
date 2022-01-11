#' Sort a BAM file
#'
#' @param bam Input BAM file
#' @param out_dir Directory to write sorted BAM output
#' @return Path to sorted BAM output. Will be named by replacing
#' ".bam" part of original file with ".sorted.bam"
#' 
sort_bam <- function(bam, out_dir = "results/bam/sorted") {
  
  # Format output file
  out_file <- 
    fs::path_file(bam) %>%
    fs::path_ext_remove() %>%
    fs::path_ext_set(".sorted.bam") %>%
    fs::path(out_dir, .)

  run_docker(
    container_id = "quay.io/biocontainers/samtools:1.9--h91753b0_8",
    command = "samtools",
    args = c(
      "sort",
      file = bam),
    stdout = out_file
  )
  
  out_file

}
