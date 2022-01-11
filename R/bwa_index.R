#' Index database sequences in the FASTA format for BWA
#'
#' @param fasta_in Path to input FASTA file
#' @param prefix Prefix of the output database
#' @param wd Directory to write output
#'
#' @return Path to output files
#' 
bwa_index <- function(fasta_in, prefix, wd) {
  run_docker(
    container_id = "quay.io/biocontainers/bwa:0.7.8--hed695b0_5",
    command = "bwa",
    wd = wd,
    args = c(
      "index",
      file = fasta_in,
      "-p", prefix)
  )
  # Return path to output
  fs::path(wd, paste0(prefix, c(".amb", ".ann", ".pac", ".bwt", ".sa")))
}
