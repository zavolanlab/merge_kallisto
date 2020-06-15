#!/usr/bin/env Rscript

# (c) 2019 Paula Iborra, Biozentrum, University of Basel

#################
###  IMPORTS  ###
#################

# Import required packages
if ( suppressWarnings(suppressPackageStartupMessages(require("optparse"))) == FALSE ) { stop("[ERROR] Package 'optparse' required! Aborted.") }
if ( suppressWarnings(suppressPackageStartupMessages(require("tximport"))) == FALSE ) { stop("[ERROR] Package 'tximport' required! Aborted.") }
if ( suppressWarnings(suppressPackageStartupMessages(require("rhdf5"))) == FALSE ) { stop("[ERROR] Package 'rhdf5' required! Aborted.") }
if ( suppressWarnings(suppressPackageStartupMessages(require("BUSpaRse"))) == FALSE ) { stop("[ERROR] Package 'BUSpaRse' required! Aborted.") }

#######################
###  PARSE OPTIONS  ###
#######################

# Get script name
script <- sub("--file=", "", basename(commandArgs(trailingOnly=FALSE)[4]))

# Build description message
description <- "Merge kallisto tables.\n"
version <- "Version: 1.0.0 (JUN-2020)"
requirements <- "Requires: optparse, tximport, rhdf5, BUSpaRse"
msg <- paste(description, version, requirements, sep="\n")

# Define list of arguments
option_list <- list(
  make_option(
    "--input",
    action="store",
    type="character",
    default=getwd(),
    help="Comma separated list of tables to merge. Required!",
    metavar="files"
  ),
  make_option(
    "--names",
    action="store",
    type="character",
    default=NULL,
    help="List of samples names for table column (ordered as paths). Default: NULL.",
    metavar="list"
  ),
  make_option(
    "--output",
    action="store",
    type="character",
    default=getwd(),
    help="Directory where output tables shall be written. Default: Working directory. ",
    metavar="directory"
  ),
  make_option(
    "--merge_col",
    action="store",
    type="character",
    default="tpm",
    help="Column to merge (tpm or counts). Default: tpm",
    metavar="tpm/counts"
  ),
  make_option(
    "--txOut",
    action="store",
    type="character",
    default=TRUE,
    help=" Whether the script should output transcript-level. Default: TRUE. If FALSE gene-level summarization.",
    metavar="true/false"
  ), 
  make_option(
    "--anno",
    action="store",
    type="character",
    default=NULL,
    help="Annotation file GTF. Argument required for gene-level summarization.",
    metavar="file"
  ),
  make_option(
    c("-h", "--help"),
    action="store_true",
    default=FALSE,
    help="Show this information and die."
  ),
  make_option(
    c("-u", "--usage"),
    action="store_true",
    default=FALSE,
    dest="help",
    help="Show this information and die."
  ),
  make_option(
    c("-v", "--verbose"),
    action="store_true",
    default=FALSE,
    help="Print log messages to STDOUT."
  )
)

# Parse command-line arguments
opt_parser <- OptionParser(usage=paste("Usage:", script, "[OPTIONS] --input_dir <path/to/input/tables>\n", sep=" "), option_list = option_list, add_help_option=FALSE, description=msg)
opt <- parse_args(opt_parser)

# Re-assign variables
sample_names <- strsplit(opt$`names`,",")
col <- tolower(opt$`merge_col`)
out.dir <- opt$`output`
in.dir <- strsplit(opt$`input`, ",")
txout <- opt$`txOut`
anno <- opt$`anno`
verb <- opt$`verbose`

# Validate required arguments
if ( is.null(in.dir) ) {
  print_help(opt_parser)
  stop("[ERROR] Required input argument missing! Aborted.")
}
if (txout==FALSE & is.null(anno)){
  print_help(opt_parser)
  stop("[ERROR] Required annotation file missing! Aborted.")
}


######################
###      MAIN      ###
######################

# Write log
if ( verb ) {cat("Reading input tables...\n", sep="")}

# Reading tables files and sample names
files <- unlist(in.dir)
names(files) <- unlist(sample_names)

# Write log
if ( verb ) {cat(files,sep="\n")}

# Generate gene/trx ID table for gene-summarization 
if (!is.null(anno)) {
  # Write log
  if ( verb ) cat("Generating table of transcript to gene IDs....\n", sep="")
  # Generating two-column data.frame linking transcript id (column 1) to gene id (column 2).
  tx2gene <- tr2g_gtf(anno, gene_name=NULL, transcript_version=NULL)
}

# Merge table for transcripts or gene level. 
if (txout == TRUE){ #for transcripts
  # Write log
  if ( verb ) cat("Merging tables for transcripts...\n",sep=" ")
  txi.kallisto <- tximport(files, type = "kallisto", txOut=TRUE)
  level <- "transcripts"
} else{ #for genes
  if ( verb ) cat("Merging tables for genes...\n",sep=" ")
  txi.kallisto <- tximport(files, type = "kallisto", txOut = FALSE, tx2gene = tx2gene) 
  level <- "genes"
}

# Extract tpm or counts table
# Write log
if ( verb ) cat("Extracting",col,"\n",sep=" ")
if (col == "tpm") {
  myTable <- txi.kallisto$abundance
} 
if (col == "counts") {
  myTable <- txi.kallisto$counts
}

# Write log
if ( verb ) cat("Writing tables...\n", sep="")
# Define paths
out.myTable <- file.path(out.dir, paste(paste(level,col,sep = "_"), "tsv" , sep="."))
if (!is.null(anno)){out.tx2gene <- file.path(out.dir, paste("tx2geneID","tsv",sep = "."))}

# Write log
if ( verb ) cat(out.myTable,"\n", sep="")
if (!is.null(anno)){ if ( verb ) cat(out.tx2gene,"\n", sep="") }
# Writing tables
write.table(myTable, out.myTable, row.names=TRUE, col.names=TRUE, quote=FALSE, sep="\t")
if (!is.null(anno)){ write.table(tx2gene, out.tx2gene, row.names=FALSE, col.names=TRUE, quote=FALSE, sep="\t") }

# Write log
if ( verb ) cat("Done.\n", sep="")