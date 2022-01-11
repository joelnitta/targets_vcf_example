#' Align 70bp-1Mbp query sequences with the BWA-MEM algorithm
#'
#' @param f_read Forward read
#' @param r_read Reverse read
#' @param ref_files Character vector; reference genome files,
#' including paths to all indexed files. Must all be in the same
#' directory.
#' @param out_dir Directory to write output
#' @return Path to output
#' 
bwa_mem <- function(f_read, r_read, ref_files, out_dir) {
  
  # Extract ref index ref_prefix (part of file name before extension)
  ref_prefix <- fs::path_file(ref_files) |> 
    fs::path_ext_remove() |>
    unique()
  assertthat::assert_that(length(ref_prefix) == 1)
  
  # Extract path to ref index
  ref_dir <- fs::path_dir(ref_files) |> 
    unique()
  assertthat::assert_that(length(ref_dir) == 1)
  
  # Construct argument for bwa mem reference
  ref <- fs::path(ref_dir, ref_prefix)
  
  # Extract reads prefix, format output file
  f_prefix <- str_match(f_read, "(SRR[0-9]+)_") %>% magrittr::extract(,2)
  r_prefix <- str_match(r_read, "(SRR[0-9]+)_") %>% magrittr::extract(,2)
  assertthat::assert_that(
    f_prefix == r_prefix,
    msg = "Read prefixes don't match"
  )
  outfile <- fs::path(
    out_dir,
    glue::glue("{f_prefix}.sam")
  )

  run_docker(
    container_id = "quay.io/biocontainers/bwa:0.7.8--hed695b0_5",
    command = "bwa",
    args = c(
      "mem",
      file = ref,
      file = f_read,
      file = r_read),
    stdout = outfile
  )
  
  outfile

}