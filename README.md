# spice_downloads
Shiny app to simplify the download of manifests and metadata files from GDC (https://portal.gdc.cancer.gov/) 

## Genomic Data Commons
The NCI's Genomic Data Commons (GDC) provides the cancer research community with
a unified data repository that enables data sharing across cancer genomic 
studies in support of precision medicine (https://gdc.cancer.gov/).
The GDC Data Portal provides a platform for efficiently querying and downloading 
high quality and complete data (https://portal.gdc.cancer.gov/). The GDC also 
provides a GDC Data Transfer Tool and a GDC API for programmatic access.

## GDC
### Introduction
The GDC supports several cancer genome programs at the NCI Center for Cancer 
Genomics (CCG), including The Cancer Genome Atlas (TCGA) and Therapeutically 
Applicable Research to Generate Effective Treatments (TARGET).
Some of these data are free to access and download, but there are also 
controlled data files, for which authentication using eRA Commons credentials is
required. 
Raw sequence data, stored as BAM files, make up the bulk of data stored at the 
NCI GDC. The size of a single file can vary greatly. Most BAM files stored are 
in the 50 MB - 40 GB size range, with some of the whole genome BAM files 
reaching sizes of 200-300 GB. In order to download those kind of data, GDC 
suggest to use the GDC Data Transfer Tool, a command-line driven application 
which provides an optimized method of transferring data to and from the GDC.
In order to use the GDC Data Transfer Tool, the syntax is the following: 
```{r, gdc-client, eval=F}
$ ./gdc-client download -m [manifest] -t [token]
```
The `manifest` can be obtained through the `R` package `GenomicDataCommons`, 
from `Bioconductor` (https://github.com/Bioconductor/GenomicDataCommons). 
The data model for the GDC is complex, but it worth a quick overview. The data 
model is encoded as a so-called property graph. Nodes represent entities such as 
Projects, Cases, Diagnoses, Files (various kinds), and Annotations. The 
relationships between these entities are maintained as edges. Both nodes and 
edges may have Properties that supply instance details. The GDC API exposes 
these nodes and edges in a somewhat simplified set of RESTful endpoints.
The `GenomicDataCommons` R package design is meant to have some similarities to 
the "hadleyverse" approach of dplyr. Roughly, the functionality for finding and 
accessing files and metadata can be divided into:

* Simple query constructors based on GDC API endpoints
* A set of verbs that when applied, adjust filtering, field selection, and 
faceting (fields for aggregation) and result in a new query object 
* A set of verbs that take a query and return results from the GDC

\newpage

For example, the following code builds a manifest that can be used to guide the 
download of raw data. Here, filtering finds gene expression files quantified as 
raw counts using HTSeq from ovarian cancer patients. 

```{r, gdc-manifest, eval=F}
library(GenomicDataCommons)
library(magrittr)
manifest = files() %>% 
    GenomicDataCommons::filter( 
				~ cases.project.project_id == 'TCGA-OV' &
                type                       == 'gene_expression' &
                analysis.workflow_type     == 'HTSeq - Counts') %>%
    manifest()
```

Vast amounts of metadata about cases (patients, basically), files, projects, and 
so-called annotations are available via the NCI GDC API. Typically, one will 
want to query metadata to either focus in on a set of files for download or 
transfer or to perform so-called aggregations (such as pivot-tables).
For example, the following code retrives metadata about ovarian cancer BAM files
from whole exome sequencing experiment: 

```{r, gdc-metadata, eval=F}
library(GenomicDataCommons)
library(magrittr)
metadata = files() %>% 
      GenomicDataCommons::filter(~ cases.project.program.name  == 'TCGA' &
                                   experimental_strategy       == 'WXS'  &
                                   data_format                 == 'BAM' &
                                   cases.project.project_id    == 'TCGA-OV') %>% 
      GenomicDataCommons::expand('cases') %>% 
      results_all %>% 
	  cbind(map(names(.$cases), f(nn, {.$cases[[nn]]})) %>>% bind_rows)
```

The GDC Data Portal allows to build and download manifests, but the same thing is
not feasible for metadata quering, making the access through the
`GenomicDataCommons R` package the only way to inspect those data.

### spice_explorer webapp
In order to provide an easy to use graphical web-based interface, to allow quick 
access to GDC Data Portal, spice_explorer webapp was build. 
No programming skills are required to use it, so even people without any 
knoledge about `R` and the `GenomicDataCommons` package can access GDC data.
The aim of spice_explorer is:

* facilitate the GDC open-access data retrieval;
* prepare the data to download;
* easily reproduce earlier research results.

spice_explorer webapp is a `Shiny` webapp (https://shiny.rstudio.com/) build around
the `GenomicDataCommons R` package. It allows to build and download manifests,
as well as query metdata files and download them. 
More specifically, users can:

* Access metadata of BAM files for every TCGA study (currently there are 33 
TCGA projects) and for whole exome sequencing (WXS) data: 
* Build manifest, ready to input to `gdc-client` for download, for:
    + WXS BAM files: aligned reads, BWA with mark duplicates and cocleaning;
* Download every table as `txt` file format
* Get information about the number of samples within a database and the total
size of the database.

The interface is composed by two main sections:

* a sidebar, on the left side: contains the buttons to manage the app;
* a main panel: display the output in tabular format; it contains two subsections:
    + *metadata*: access metadata files;
    + *manifest*: access manifest files.

spice_explorer webapp relies on different `R` packages:

* shiny
* shinydashboard
* shinythemes
* shinyjs
* DT
* pipeR
* pryr
* purrr
* dplyr
* httr
* magrittr
* curl

and it requires `R >= 3.3.3`. Currently the app code is hosted on github, at 
https://github.com/l0ka/spice_explorer; users can get free access, download and 
edit it.
