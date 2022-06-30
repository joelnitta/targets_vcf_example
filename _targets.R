# Load packages
source("packages.R")

# Load functions
source("R/functions.R")

# Set parallel back-end
plan(callr)

# Define folders to store files
# - data
data_dir <- "_targets/user/data"
# - intermediate results
inter_dir <- "_targets/user/intermediates"
# - final results
results_dir <- "_targets/user/results"

# Set up analysis plan
tar_plan(
  # Download and unzip data ----
  tar_target(
    ecoli_url,
    "ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/017/985/GCA_000017985.1_ASM1798v1/GCA_000017985.1_ASM1798v1_genomic.fna.gz"), #nolint
  tar_file(
    ecoli_ref,
    download_and_gunzip(
      url = ecoli_url,
      file_out = path(data_dir, "ref_genome/ecoli_rel606.fasta"))
  ),
  tar_target(
    trimmed_reads_url,
    "https://ndownloader.figshare.com/files/14418248"
  ),
  tar_file(
    trimmed_reads,
    download_and_untar(
      url = trimmed_reads_url,
      dir_out = path(data_dir, "trimmed_fastq_small/"))
  ),
  # Index the reference genome ----
  tar_file(
    ecoli_ref_indexed,
    bwa_index(
      fasta_in = ecoli_ref,
      prefix = "ecoli_rel606",
      wd = path(data_dir, "ref_genome"))
  ),
  # Align reads to reference genome ----
  # Reformat input reads for mapping
  tar_target(
    f_reads,
    sort(trimmed_reads[str_detect(trimmed_reads, "_1")])
  ),
  tar_target(
    r_reads,
    sort(trimmed_reads[str_detect(trimmed_reads, "_2")])
  ),
  # Align
  tar_file(
    aligned_sam,
    bwa_mem(
      f_reads, r_reads,
      ref_files = ecoli_ref_indexed,
      out_dir = path(inter_dir, "sam")
    ),
    pattern = map(f_reads, r_reads)
  ),
  # Convert SAM to BAM
  tar_file(
    aligned_bam,
    sam_to_bam(
      aligned_sam,
      out_dir = path(inter_dir, "bam")
    ),
    pattern = map(aligned_sam)
  ),
  # Sort BAM
  tar_file(
    aligned_sorted_bam,
    sort_bam(
      aligned_bam,
      out_dir = path(inter_dir, "bam/sorted")
    ),
    pattern = map(aligned_bam)
  ),
  # Variant calling ----
  # Step 1: Calculate the read coverage of positions in the genome
  tar_file(
    pileup,
    bcftools_mpileup(
      ref = ecoli_ref,
      align = aligned_sorted_bam,
      out_file = path_from_prefix(
        aligned_sorted_bam, path(inter_dir, "bcf"), ".raw.bcf")
    ),
    pattern = map(aligned_sorted_bam)
  ),
  # Step 2: Detect the single nucleotide variants (SNVs)
  tar_file(
    called_variants,
    bcftools_call(
      bcf = pileup,
      out_file = path_from_prefix(
        pileup, path(inter_dir, "vcf"), ".vcf"),
      other_args = c(
        "--ploidy", 1,
        "-m", "-v"
      )
    ),
    pattern = map(pileup)
  ),
  # Step 3: Filter single nucleotide variants (SNVs)
  # use `bcftools filter` instead of `vcfutils.pl varFilter`
  # as recommended by https://github.com/samtools/bcftools/issues/30
  tar_file(
    filtered_variants,
    bcftools_filter(
      vcf = called_variants,
      other_args = c("-O", "v"), # Output uncompressed VCF (v)
      out_file = path_from_prefix(
        called_variants, path(inter_dir, "vcf"), ".final.vcf")
    ),
    pattern = map(called_variants)
  ),
  # Summarize results ----
  # Read in VCF files
  tar_target(
    filtered_variants_tbl,
    load_vcf(filtered_variants),
    pattern = map(filtered_variants)
  ),
  # Render report
  tar_render(
    vcf_report,
    "doc/vcf_report.Rmd",
    output_dir = results_dir
  )
)
