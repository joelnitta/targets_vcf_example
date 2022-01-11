#' Run a docker command with file inputs
#'
#' Wrapper around babelwhale::run() that handles volume mounting automatically
#'
#' @param container_id The name of the container, usually the repository name on
#'   dockerhub.
#' @param command Character scalar, the command to run
#' @param args Character vector, arguments to the command. Any arguments that
#'   are files or directories must be named "file". e.g., `c("-arg1", "value1",
#'   "-arg2", "value2", file = "path/to/file")`.
#' @param wd Working directory to run command
#' @param wd_in_container Optional; path to working directory to run command in
#'   the container
#' @param environment_variables A character vector of environment variables.
#'   Format: c("ENVVAR=VALUE")
#' @param debug If `TRUE`, a command will be printed that the user can execute
#'   to enter the container.
#' @param verbose Whether or not to print output
#' @param stdout What to do with standard output of the command. Default ("|")
#'   means to include it as an item in the results list. If it is the empty
#'   string (""), then the child process inherits the standard output stream of
#'   the R process. If it is a string other than "|" and "", then it is taken as
#'   a file name and the output is redirected to this file.
#' @param stderr What to do with standard error of the command. Default ("|")
#'   means to include it as an item in the results list. If it is the empty
#'   string (""), then the child process inherits the standard error stream of
#'   the R process. If it is a string other than "|" and "", then it is taken as
#'   a file name and the standard error is redirected to this file.
#' @param files_delete Character vector; files that should be deleted before
#'   running the command.
#'
#' @return List, formatted as output from processx::run()
#'
run_docker <- function(
  container_id, command, args, 
  wd = NULL, wd_in_container = NULL, environment_variables = NULL,
  debug = FALSE,
  verbose = FALSE,
  stdout = "|",
  stderr = "|",
  files_delete = NULL) {
  
  # Optionally delete existing files
  if (!is.null(files_delete)) {
    for (i in seq_along(files_delete)) {
      if (fs::file_exists(files_delete[[i]])) fs::file_delete(files_delete[[i]])
    }
  }
  
  # Convert paths of file arguments to absolute for docker
  file_args <- args[names(args) == "file"]
  in_path <- fs::path_abs(file_args)
  in_file <- fs::path_file(in_path)
  in_dir <- fs::path_dir(in_path)
  
  # Make (most likely) unique prefix for folder name that
  # won't conflict with an existing folder in the container
  prefix <- digest::digest(c(container_id, command)) |> substr(1,8)
  
  # Specify volume mounting for working directory
  wd_volume <- NULL
  if (!is.null(wd)) {
    wd_path <- fs::path_abs(wd)
    if (is.null(wd_in_container)) wd_in_container <- glue::glue("/{prefix}_wd")
    wd_volume <- glue::glue("{wd_path}:{wd_in_container}")
  }
  
  # Specify all volumes: one per file, plus working directory
  volumes <- c(
    glue::glue("{in_dir}:/{prefix}_{1:length(in_dir)}"),
    wd_volume
  ) |> unique()
  
  # Replace file arg paths with location in container
  files_in_container <- glue::glue("/{prefix}_{1:length(in_dir)}/{in_file}")
  args[names(args) == "file"] <- files_in_container
  
  # Run docker via babelwhale
  babelwhale::run(
    container_id = container_id,
    command = command,
    args = args,
    volumes = volumes,
    workspace = wd_in_container,
    environment_variables = environment_variables,
    debug = debug,
    verbose = verbose,
    stdout = stdout,
    stderr = stderr
  )    
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

