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
library(xml2)
library(RSelenium)

# setting the working directories 
data <- "C:/Users/Sean Hambali/Desktop/DATA/"
rout <- "C:/Users/Sean Hambali/Documents/Github/siranap_hospital_data/rdata/"
csvout <- "C:/Users/Sean Hambali/Documents/Github/siranap_hospital_data/csv/"
dtaout <- "C:/Users/Sean Hambali/Documents/Github/siranap_hospital_data/dta/"

# importing the keywords data 
keywords_data <- read_delim(file = paste0(csvout, "hospital_keywords.csv"), delim = "\t")[,1:4]

# open the required browser
rD <- rsDriver(browser = "firefox", port = 4005L, verbose = F)
remDr <- rD[["client"]]

# navigating to the page of interest 
remDr$navigate("https://www.google.com/")

# developing the scraping function 
scrape_address <- function(keyword) {
  
  # hit the search button 
  remDr$findElement("name", "q")$sendKeysToElement(list(keyword, key = "enter"))
  
  # giving time to the system to reload 
  Sys.sleep(3)
  
  # obtaining the page source of the inputted text 
  html <- remDr$getPageSource()[[1]]
  
  # getting the address page
  address_new <- read_html(html) %>% 
  html_nodes(".QsDR1c .w8qArf+ .LrzXr") %>% 
  html_text()
  
  address_df <- data.frame(new_address = address_new)
  
  # clearing the input box
  remDr$findElement("name", "q")$clearElement()
  
  return(address_df)
  
  # giving time to reload
  Sys.sleep(runif(1,1,3))
  
}

# testing the basic function 
keywords_data <- keywords_data %>% 
  group_by(keyword) %>% 
  do(scrape_address(.$keyword))


