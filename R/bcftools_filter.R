#' Apply fixed-threshold filters to VCF
#'
#' @param vcf Input VCF file
#' @param other_args Character vector of other arguments
#' @param out_file Path to write output
#' @return
#' @author Joel Nitta
#' @export
bcftools_filter <- function(vcf, other_args = NULL, out_file) {

  run_docker(
    container_id = "quay.io/biocontainers/bcftools:1.9--ha228f0b_4",
    command = "bcftools",
    args = c(
      "filter",
      other_args,
      file = vcf),
    stdout = out_file
  )
  
  out_file

}
