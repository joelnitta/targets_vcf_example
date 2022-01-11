#' SNP/indel calling in BCF tools (former "view")
#'
#' @param bcf Input BCF file
#' @param out_file Path to write output
#' @param other_args Other arguments passed to `bcftools call`
#' @return Path to output
#' 
bcftools_call <- function(bcf, out_file, other_args = NULL) {

  run_docker(
    container_id = "quay.io/biocontainers/bcftools:1.9--ha228f0b_4",
    command = "bcftools",
    args = c(
      "call",
      other_args,
      file = bcf),
    stdout = out_file
  )
  
  out_file

}
