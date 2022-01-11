#' Run multi-way pileup producing genotype likelihoods
#' 
#' @param ref Reference FASTA
#' @param align Input alignment in BAM format, sorted
#' @param out_file Path to write output
#' @return Path to output file
bcftools_mpileup <- function(ref, align, out_file) {

  run_docker(
    container_id = "quay.io/biocontainers/bcftools:1.9--ha228f0b_4",
    command = "bcftools",
    args = c(
      "mpileup",
      "-O", "b", # Output compressed BCF (b)
      "-f", file = ref,
      file = align),
    stdout = out_file
  )
  
  out_file

}
