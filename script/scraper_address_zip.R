# Author        : Sean Hambali 
# Project       : Scraping Hospital Availability Data
# Last updated  : 14 July 2021

# remove previous environment 
rm(list=ls())

# loading the necessary packages 
library(tidyverse)
library(rvest)
library(data.table)
library(haven)

# setting the working directories 
data <- "C:/Users/Sean Hambali/Desktop/DATA/"
rout <- "C:/Users/Sean Hambali/Documents/Github/siranap_hospital_data/rdata/"
csvout <- "C:/Users/Sean Hambali/Documents/Github/siranap_hospital_data/csv/"
dtaout <- "C:/Users/Sean Hambali/Documents/Github/siranap_hospital_data/dta/"

# importing the keywords data 
keywords_data <- read_delim(file = paste0(csvout, "hospital_keywords.csv"), delim = "\t")

# google search url
keywords_data$keyword <- gsub(" ", "+", keywords_data$keyword)
example <- keywords_data$keyword[1]
url <- "https://www.google.com/search?q=BMC+Mayapada+Hospital+Kota+Bogor&oq=BMC+&aqs=edge.1.69i59l2j69i57j0i67l3j0.2918j0j9&sourceid=chrome&ie=UTF-8"
address_text <- read_html(url) %>% 
  html_nodes(".QsDR1c:nth-child(4) .wDYxhc , .QsDR1c .w8qArf+ .LrzXr") %>% 
  html_text()
