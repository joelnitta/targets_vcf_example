# targets_vcf_example

This is an example workflow using the [targets](https://github.com/ropensci/targets) R package.
It is based on the [Data Carpentry Variant Calling Workflow lesson](https://datacarpentry.org/wrangling-genomics/04-variant_calling/index.html).

## Dependencies

[Docker](https://www.docker.com/get-started) is used to run various programs. The docker daemon needs to be running so that containers can be launched. [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/) is used to maintain the environment for running Docker.

Restore the conda environment used by this project, called `vcf-example-env`:

```
conda env create -f environment.yml
```

Enter the environment:

```
conda activate vcf-example-env
```

The `vcf-example-env` environment includes R, which is used to run the workflow. The [renv](https://rstudio.github.io/renv/index.html) R package is used to maintain packages. The first time the analysis is run, you will need to restore the packages with `renv`:

```
Rscript -e 'renv::restore()'
```

## Running the analysis

Activate the `vcf-example-env` environment, then run `Rscript -e 'targets::tar_make()'`.

## License

[MIT](LICENSE)