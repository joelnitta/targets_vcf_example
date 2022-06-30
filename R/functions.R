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

#' Index database sequences in the FASTA format for BWA
#'
#' @param fasta_in Path to input FASTA file
#' @param prefix Prefix of the output database
#' @param wd Directory to write output
#'
#' @return Path to output files
#'
bwa_index <- function(fasta_in, prefix, wd) {
  run_auto_mount(
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

  run_auto_mount(
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

  run_auto_mount(
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

  run_auto_mount(
    container_id = "quay.io/biocontainers/samtools:1.9--h91753b0_8",
    command = "samtools",
    args = c(
      "sort",
      file = bam),
    stdout = out_file
  )

  out_file

}

#' Run multi-way pileup producing genotype likelihoods
#' 
#' @param ref Reference FASTA
#' @param align Input alignment in BAM format, sorted
#' @param out_file Path to write output
#' @return Path to output file
bcftools_mpileup <- function(ref, align, out_file) {

  run_auto_mount(
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

#' SNP/indel calling in BCF tools (former "view")
#'
#' @param bcf Input BCF file
#' @param out_file Path to write output
#' @param other_args Other arguments passed to `bcftools call`
#' @return Path to output
#' 
bcftools_call <- function(bcf, out_file, other_args = NULL) {

  run_auto_mount(
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

#' Apply fixed-threshold filters to VCF
#'
#' @param vcf Input VCF file
#' @param other_args Character vector of other arguments
#' @param out_file Path to write output
#' @return
#' @author Joel Nitta
#' @export
bcftools_filter <- function(vcf, other_args = NULL, out_file) {

  run_auto_mount(
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

#' Load a VCF file into R as a tibble
#' 
#' @param vcf Path to VCF file
#' 
#' @return Tibble. Includes standard VCF columns plus one column called 'file',
#' with the vcf filename
#' 
load_vcf <- function(vcf) {

  data <-
  suppressMessages(read_tsv(vcf, comment = "##") %>%
    janitor::clean_names())

  colnames(data)[length(colnames(data))] <- "results"

  data$file <- fs::path_file(vcf)

  data

}

# Extract the file prefix from a path
# (part of the file name before any extensions)
get_prefix <- function(path) {
  path %>%
    fs::path_file() %>%
    str_match("^([^\\.]+)\\.") %>% 
    magrittr::extract(,2)
}

#' Create a new file name based on another file name
#' 
#' The directory and extension will be changed to create
#' the new file name
#' 
#' @param path Filename
#' @param dir Directory for new filename
#' @param ext Extension for new filename
#' @return Character string; the new, modified filename
#'
#' @examples
#' path_from_prefix("data/input.fasta", "results", ".sam")
path_from_prefix <- function(path, dir, ext) {
  fs::path(dir, get_prefix(path)) %>%
    fs::path_ext_set(ext)
}
