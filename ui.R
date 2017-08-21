library(GenomicDataCommons)
library(shiny)
library(shinyjs)
library(shinythemes)
library(shinydashboard)
library(DT)
library(pipeR)
library(dplyr)
library(httr)
library(curl)
library(purrr)
library(magrittr)
library(pryr)
options(shiny.maxRequestSize = 1000*1024^2)

cancer_studies <- c("TCGA-ACC","TCGA-BLCA","TCGA-BRCA","TCGA-CESC","TCGA-CHOL","TCGA-COAD","TCGA-DLBC",
                    "TCGA-ESCA","TCGA-GBM","TCGA-HNSC","TCGA-KICH","TCGA-KIRC","TCGA-KIRP","TCGA-LAML",
                    "TCGA-LGG","TCGA-LIHC","TCGA-LUAD","TCGA-LUSC","TCGA-MESO","TCGA-OV","TCGA-PAAD",
                    "TCGA-PCPG","TCGA-PRAD","TCGA-READ","TCGA-SARC","TCGA-SKCM","TCGA-STAD","TCGA-TGCT",
                    "TCGA-THCA","TCGA-THYM","TCGA-UCEC","TCGA-UCS","TCGA-UVM" )

#################################################################

header <- dashboardHeader(
  title = 'SPICE explorer',
  titleWidth = 280,
  tags$li(class = 'dropdown',
          tags$div(style="display:inline-block",
                   tags$a(href = "https://gdc.cancer.gov/", target = "_blank",
                          tags$img(height = "40px", src = "nih.png",
                                   style = "margin-top: 5px; margin-bottom: 5px;")),
                   tags$a(href = "https://github.com/Bioconductor/GenomicDataCommons", target = "_blank",
                          tags$img(height = "40px", src = "github.png",
                                   style = "margin-right: 10px; margin-top: 5px; margin-bottom: 5px;"))
          )
  )
)

#################################################################

sidebar <- dashboardSidebar(width=280,
                            
                            conditionalPanel(
                              condition = "input.tabvals == 1",
                
                              selectizeInput(inputId = 'cancer_study_metadata', label = h3('Project'), 
                                             choices = cancer_studies),
                              
                              hr(),
                              
                              h4('Number of Samples'),
                              div(style = "display: block; margin-left: 2%; margin-right: 2%; margin-bottom: 14px",
                                  verbatimTextOutput('n_samples_metadata', placeholder = T)),
                              
                              h4('Dataset Size'),
                              div(style = "display: block; margin-left: 2%; margin-right: 2%; margin-bottom: 14px",
                                  verbatimTextOutput('size_metadata', placeholder = T)),
                              
                              hr(),
                              
                              div(style = "display: block; margin-left: 20%; margin-bottom: 14px",
                                  downloadButton(outputId = 'metadata_dl', label = 'Download Metadata'))
                              
                              ),
                            
                            #################################################################
                            
                            conditionalPanel(
                              condition = "input.tabvals == 2",
                              
                              selectizeInput(inputId = 'cancer_study_manifest', label = h3('Project'), 
                                             choices = cancer_studies),
                              
                              hr(),
                              
                              h4('Number of Samples'),
                              div(style = "display: block; margin-left: 2%; margin-right: 2%; margin-bottom: 14px",
                                  verbatimTextOutput('n_samples_manifest', placeholder = T)),
                              
                              h4('Dataset Size'),
                              div(style = "display: block; margin-left: 2%; margin-right: 2%; margin-bottom: 14px",
                                  verbatimTextOutput('size_manifest', placeholder = T)),
                              
                              hr(),
                              
                              div(style = "display: block; margin-left: 20%; margin-bottom: 14px",
                                  downloadButton(outputId = 'manifest_dl', label = 'Download Manifest'))
                              )
                            
)

                          
#################################################################

body <- dashboardBody(
  fluidRow(
    tabBox(id = "tabvals", width = 12,
           tabPanel("Metadata", DT::dataTableOutput(outputId = "metadata"), value = 1),
           tabPanel("Manifest", DT::dataTableOutput(outputId = "manifest"), value = 2),
           tabPanel("Percentage of samples", plotOutput("spice_downloads_perc", height = "900px"), value = 3),
           tabPanel("Number of samples", plotOutput("spice_downloads_abs", height = "900px"), value = 4)
    
  )))

#################################################################
#################################################################

dashboardPage(
  skin = "blue",
  header,
  sidebar,
  body
)
