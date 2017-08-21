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
library(data.table)
options(shiny.maxRequestSize = 1000*1024^2)

#################################################################

get_metadata <- function(cancer_study){
  file_raw <- pipeline({
    files(legacy=FALSE)
    GenomicDataCommons::filter(~ cases.project.program.name == 'TCGA' &
                                 experimental_strategy      == 'WXS' &
                                 data_format                == 'BAM' &
                                 cases.project.project_id   == cancer_study)
    GenomicDataCommons::expand('cases')
    results_all
  })
  pipeline({
    file_raw
    cbind(map(names(.$cases), f(nn, {.$cases[[nn]]})) %>>% bind_rows)
  })
}


get_manifest <- function(cancer_study){
  manifest <- pipeline({
    files(legacy=FALSE)
    GenomicDataCommons::filter( ~ cases.project.project_id == cancer_study &
                                  experimental_strategy    == 'WXS' &
                                  type                     == 'aligned_reads' &
                                  analysis.workflow_type   == 'BWA with Mark Duplicates and Cocleaning')
    manifest()
  })
} 


get_plot_data <- function(spice_path, manifest_path){
  spice_samples <- list.dirs(spice_path, recursive = F, full.names = F)
  manifest_all <- read.table(file = manifest_path, header = T, stringsAsFactors = F)
  downloaded <- manifest_all[which(manifest_all$id %in% spice_samples),]
  n_downloaded <- as.data.frame(do.call(rbind, as.list(by(data = downloaded, INDICES = downloaded$study, nrow))))
  n_downloaded <- setDT(n_downloaded, keep.rownames = TRUE)[]
  colnames(n_downloaded) <- c('study', 'samples')
  n_all <- as.data.frame(do.call(rbind, as.list(by(data = manifest_all, INDICES = manifest_all$study, nrow))))
  n_all <- setDT(n_all, keep.rownames = TRUE)[]
  colnames(n_all)<- c('study', 'samples')
  plot_data <- left_join(n_all, n_downloaded, by = 'study')
  plot_data$samples.y[which(is.na(plot_data$samples.y))] <- 0
  return(plot_data)
}


#################################################################

shinyServer(function(input, output, session){
  
  output$metadata <- DT::renderDataTable({
    get_metadata(input$cancer_study_metadata)},
    rownames = F,
    class = 'cell-border stripe compact hover',
    options = list(lengthMenu = c(25, 50),
                   pageLength = 25,
                   initComplete = JS(
                     "function(settings, json) {",
                     "$(this.api().table().header()).css({'background-color': '#862d59', 'color': '#ffffff'});",
                     "}"))
    )
  
  
  output$n_samples_metadata <- renderPrint({
    metadata <- get_metadata(input$cancer_study_metadata)
    paste0('Number of samples: ', nrow(metadata))
  })
  
  
  output$size_metadata <- renderPrint({
    metadata <- get_metadata(input$cancer_study_metadata)
    if (nchar(round(sum(as.numeric(metadata$file_size))/1073741824, digits = 0)) >= 4){
      paste0('Total size: ~', round(sum(as.numeric(metadata$file_size))/1099511627776, digits = 0), ' TB')
    } else {
      paste0('Total size: ', round(sum(as.numeric(metadata$file_size))/1073741824, digits = 0), ' GB')
    }
  })
  
  
  metadata_dl <- function(){
    get_metadata(input$cancer_study_metadata)}
    
  output$metadata_dl <- downloadHandler(
    filename = function() {paste0(input$cancer_study_metadata, "_metadata_", Sys.time(), ".txt")},
    content = function(file) {
      write.table(x = metadata_dl(), file = file, quote = F, sep = '\t', row.names = F, col.names = T)
    })
  
  
#################################################################
#################################################################  
  
  
  output$manifest <- DT::renderDataTable({
    get_manifest(input$cancer_study_manifest)},
    rownames = F,
    class = 'cell-border stripe compact hover',
    options = list(lengthMenu = c(25, 50),
                   pageLength = 25,
                   initComplete = JS(
                     "function(settings, json) {",
                     "$(this.api().table().header()).css({'background-color': '#862d59', 'color': '#ffffff'});",
                     "}"))
    )
  
  
  output$n_samples_manifest <- renderPrint({
    manifest <- get_manifest(input$cancer_study_manifest)
    paste0('Number of samples: ', nrow(manifest))
  })
  
  
  output$size_manifest <- renderPrint({
    manifest <- get_manifest(input$cancer_study_manifest)
    if (nchar(round(sum(as.numeric(manifest$size))/1073741824, digits = 0)) >= 4){
      paste0('Total size: ~', round(sum(as.numeric(manifest$size))/1099511627776, digits = 0), ' TB')
    } else {
      paste0('Total size: ', round(sum(as.numeric(manifest$size))/1073741824, digits = 0), ' GB')
    }
  })
  
  
  manifest_dl <- function(){
    get_manifest(input$cancer_study_manifest)}
  
  output$manifest_dl <- downloadHandler(
    filename = function() {paste0(input$cancer_study_manifest, "_manifest_", Sys.time(), ".txt")},
    content = function(file) {
      write.table(x = manifest_dl(), file = file, quote = F, sep = '\t', row.names = F, col.names = T)
    })
            
            
#################################################################
#################################################################

  output$spice_downloads_perc <- renderPlot({
    plot_data <- get_plot_data('/SPICE/downloads', 'manifest_all.txt')
    plot_data$perc <- round((plot_data$samples.y / plot_data$samples.x)*100, digits = 0)
    plot_data$to_do <- 100 - plot_data$perc
    plot_data[,2] <- NULL
    plot_data[,2] <- NULL
    plot_data <- t(plot_data)
    colnames(plot_data) <- plot_data[1,]
    plot_data <- plot_data[-c(1),]

    par(mar=c(6, 3, 2, 6))
    bar <- barplot(as.matrix(plot_data), col = c("chartreuse4", "red3"), xlab = '',
                   xaxt = "n", cex.axis = 1.2, cex.main = 1.5,las=1,
                   main = 'Percentage of downloaded samples, by cancer study')
    text(x = bar, y = par("usr")[3], srt = 60,
         adj= 1, xpd = TRUE, labels = colnames(plot_data), cex = 1.2)
    legend(x = 40, y=60, legend=c("downloaded","downloading"), bty='n', xpd = T,
           fill = c("chartreuse4", "red3"), cex = 1.2)

  })


#################################################################
#################################################################
  
  
  output$spice_downloads_abs <- renderPlot({
    plot_data <- get_plot_data('/SPICE/downloads', 'manifest_all.txt')
    plot_data$diff <- plot_data$samples.x - plot_data$samples.y  
    plot_data <- plot_data[order(-plot_data$samples.x),]
    plot_data <- t(plot_data)
    colnames(plot_data) <- plot_data[1,]
    plot_data <- plot_data[-c(1,2),]
    
    par(mar=c(8, 4, 2, 2))
    bar <- barplot(as.matrix(plot_data), col = c("chartreuse4", "red3"), xlab = '', 
                   xaxt = "n", cex.axis = 1.2, cex.main = 1.5, ylim = c(0,2500),
                   main = 'Number of downloaded samples, by cancer study', las=1)
    text(x = bar, y = par("usr")[3]-50, srt = 60, 
         adj= 1, xpd = TRUE, labels = colnames(plot_data), cex = 1.2)
    legend('topright', legend=c("downloaded","downloading"), bty='n', xpd = T, 
           fill = c("chartreuse4", "red3"), cex = 1.2)
    
    
  })


})





