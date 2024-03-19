# Load in the annotation file and remove all rows other than those containing genes
annotation_in <- read.csv("~/GWAS_EXPERIMENT/Manhat_NEWGENOME/UTM_Trep_v1.0_HEADER.csv") # nolint
annotation <- annotation_in[annotation_in$region == "gene", ]

# Load in the csv files for each other GWAS runs. These files contain the SNP data that will be used for combining with the annotation file

# Create function that will merge the annotation file (y in function) with the csv files (x in function)
gene_annotate <- function(x, y) {
  annolist <- list()
  for (i in seq_along(x)){
    dat <- as.data.frame(x[[i]])
    annolist [[i]] <- dat %>% left_join(y, by = "CHR", relationship = "many-to-many" ) %>% # nolint
      mutate(isRange = as.numeric(Position) >= as.numeric(start) & as.numeric(Position) <= as.numeric(end)) %>%
      filter(isRange)
    annolist [[i]][["FILE"]] <- "NA"
    annolist [[i]][["FILE"]] <- track_list[[i]]
    out <- annolist [[i]]
    if (i == 1) {
      out_merged <- out
    } else {
      out_merged <- rbind(out_merged, annolist [[i]])
    }
  }
  return(out_merged)
}

# Create function that will annotate the csv files with the genes that are upstream of the genes
UPCIS_ANNOTATE<-function(x,y){
annolist <- list()
for(i in seq_along(x)){
dat<-as.data.frame(x[i])
annolist [[i]]<-dat %>%
left_join(y, by="CHR",relationship="many-to-many") %>%
mutate(isRange = as.numeric(Position) >= as.numeric(start) - 10000 & as.numeric(Position) <= as.numeric(end)) %>%
filter(isRange)
annolist[[i]][["FILE"]]<-"NA"
annolist[[i]][["FILE"]]<-track_list[[i]]
out<-annolist[[i]]
if(i==1){
    out_merged<-out
} else {
    out_merged<-rbind(out_merged,annolist [[ i]])
}
    }
    return(out_merged)
}

# Create function that will annotate the csv files with the genes that are downstream of the genes
DOWNCIS_ANNOTATE<-function(x,y){
annolist <- list()
for(i in 1:length(x)){
dat<-as.data.frame(x[i])
annolist [[i]]<-dat %>%
left_join(y, by="CHR",relationship="many-to-many") %>%
mutate(isRange = as.numeric(Position) >= as.numeric(start) & as.numeric(Position) <= as.numeric(end) + 10000) %>%
filter(isRange)
annolist[[i]][["FILE"]]<-"NA"
annolist[[i]][["FILE"]]<-track_list[[i]]
out<-annolist[[i]]
if(i==1){
    out_merged<-out
} else {
    out_merged<-rbind(out_merged,annolist [[ i]])
}
    }
    return(out_merged)
}

# Run the functions on the csv files
# Make sure that the CHR column in the csv files and the CHR column in the annotation file are the same format (eg. Chr01_Occ vs 1)
WG1<-gene_annotate(worklist,annotation)
DCG<-DOWNCIS_ANNOTATE(worklist,annotation)
UCG<-UPCIS_ANNOTATE(worklist,annotation)

# Modify the resulting dataframes to specify the region (ie. within gene, up-cis, down-cis) and calculate the distance from the gene
WG1$region<-"Within_Gene"
UCG$region<-"Up-Cis"
DCG$region<-"Down-Cis"
DCG1<-DCG[DCG$Position>DCG$end,]
UCG1<-UCG[UCG$Position<UCG$start,]
DCG1$Distance<-as.numeric(DCG1$Position) - as.numeric(DCG1$end)
UCG1$Distance<-as.numeric(UCG1$start) - as.numeric(UCG1$Position)
WG1$Distance<-"NA"

# Combine the dataframes 
annotatedFile<-rbind(UCG1,WG1)
annotatedFile<-rbind(annotatedFile,DCG1)

# Modify the dataframe to include the locus, gene, and locus_gene columns
annotatedFile$locus<-gsubfn('(ID=)(ACLI19_g\\d+);locus_tag=(P\\d+_\\d+);(gene=)?(\\w+)?(;)?','\\3',annotatedFile$`function.`)
annotatedFile$gene<-gsubfn('(ID=)(ACLI19_g\\d+);locus_tag=(P\\d+_\\d+);(gene=)?(\\w+)?(;)?','\\5',annotatedFile$`function.`)
annotatedFile$locus_gene<-ifelse(annotatedFile$gene == "", paste(annotatedFile$gene,annotatedFile$locus),annotatedFile$gene)
annotatedFile<-subset(annotatedFile,select=-c(locus,gene))

# Modify the dataframe to include the Name column (this will be used to combine with the RNA seq data)
annotatedFile$Name<-gsubfn('(ID=)(ACLI19_g\\d+);locus_tag=(P\\d+_\\d+);(gene=)?(\\w+)?(;)?','\\2',annotatedFile$`function.`)