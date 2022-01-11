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
