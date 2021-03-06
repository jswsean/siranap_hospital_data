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

# importing the kabupaten correspondence file
  district_list <- read.table(paste0(data, "Kode KabupatenKota.csv"), sep = "\t")
  names(district_list) <- c("district_code", "district_name", "province_code")
  district_codes <- as.character(district_list$district_code)

# building the scraper! 

# COVID Beds ---- 
  
  for (i in district_codes) {
    
    # getting the province codes 
    prov_code <- str_sub(i, 1,2)
    district_code <- i
    
    # specifying the base url 
    url <- paste0("https://yankes.kemkes.go.id/app/siranap/rumah_sakit?jenis=1&propinsi=",
                  prov_code, 
                  "prop&kabkota=", 
                  district_code)
    base_html <- read_html(url)
    
    # getting the list of hospitals in Jakarta Pusat
    list_hospital_html <- html_nodes(base_html, "h5")
    list_hospital <- html_text(list_hospital_html)
    
    # getting the hospital address 
    address_html <- html_nodes(base_html, ".col-md-7 p")
    address <- html_text(address_html)
    
    # queue data 
    queue_html <- html_nodes(base_html, ".mb-0:nth-child(3)")
    queue <- html_text(queue_html) %>% 
      gsub("\r\n", "", .) %>% 
      str_trim(side = c("both", "left", "right")) %>% 
      str_squish()
    
    # update time 
    update_html <- html_nodes(base_html, ".mb-0:nth-child(4)")
    update <- html_text(update_html) %>% 
      gsub("\r\n", "", .) %>% 
      gsub("(diupdate|yang lalu)", "", .) %>% 
      str_trim(side = c("both", "left", "right")) %>% 
      str_squish()
    
    # telephone number 
    tlp_html <- html_nodes(base_html, ".text-right span")
    tlp <- html_text(tlp_html)
    tlp <- tlp[-1]
    
    # getting the bed availability data 
    bed_availability_html <- html_nodes(base_html, ".mb-1+ .mb-0")
    bed_availability <- html_text(bed_availability_html) %>% 
      gsub("\r\n", "", .) %>% 
      str_trim(side = c("both", "left", "right")) %>% 
      str_squish()
      
    # combining into df for COVID beds
    half_list <- tibble(
      hospital = list_hospital,
      address = address, 
      bed_availability = bed_availability,
      queue = queue, 
      last_update = update, 
      tlp_number = tlp, 
      province = prov_code, 
      district = district_code, 
      scraped_at = Sys.time(), 
      bed_type = "COVID-19"
    )
    
    # get today's date
    date <- Sys.Date() %>% 
      format("%m%d")
    
    # saving the data 
    assign(paste0("covid_bed_data_", district_code, "_", date), 
           half_list)
    
  }
  
# APPENDING THE COVID BEDS DATA ----
  dflist <- lapply(paste0("covid_bed_data_",district_codes,"_",date), get)
  base_data <- rbindlist(dflist)
  
  saveRDS(base_data, file=paste0(rout, "covid_bed_data_all", "_", date, ".rds"))
  write.csv(base_data, paste0(csvout, "covid_bed_data_all", "_", date, ".csv"))
  write_dta(base_data, paste0(dtaout, "covid_bed_data_all", "_", date, ".dta"))
  
  
  
# Non-COVID Beds ---- 
  
  for (i in district_codes) {
    
  # getting the province codes 
  prov_code <- str_sub(i, 1,2)
  district_code <- i
    
  # specifying the base url 
  url <- paste0("https://yankes.kemkes.go.id/app/siranap/rumah_sakit?jenis=2&propinsi=",
                prov_code, 
                "prop&kabkota=", 
                district_code)
  base_html <- read_html(url)

  # getting the list of hospitals in Jakarta Pusat
  list_hospital_html <- html_nodes(base_html, "h5")
  list_hospital <- html_text(list_hospital_html)
  
  # getting the hospital address 
  address_html <- html_nodes(base_html, "p")
  address <- html_text(address_html)
  
  # beds 
  bed_html <- html_nodes(base_html, ".pt-md-0")
  bed <- html_text(bed_html) %>% 
    gsub("\r\n", "", .) %>% 
    str_trim(side = c("both", "left", "right")) %>% 
    str_squish()

  # class-1 beds
  bed_class1 <- str_extract_all(bed, "[0-9]+ Bed Kosong Kelas I ") %>%
    lapply(function(x) if(identical(x, character(0))) NA_character_ else x) %>% 
    lapply(FUN = function(t) as.numeric(gsub(" Bed Kosong Kelas I", "", x = t))) %>% 
    lapply(.,FUN = sum) %>% 
      unlist(., use.names = F)
  
  # class-2 beds 
  bed_class2 <- str_extract_all(bed, "[0-9]+ Bed Kosong Kelas II ") %>% 
    lapply(function(x) if(identical(x, character(0))) NA_character_ else x) %>% 
    lapply(FUN = function(t) as.numeric(gsub(" Bed Kosong Kelas II", "", x = t))) %>% 
    lapply(.,FUN = sum) %>% 
    unlist(., use.names = F)
  
  # class-3 beds 
  bed_class3 <- str_extract_all(bed, "[0-9]+ Bed Kosong Kelas III ") %>% 
    lapply(function(x) if(identical(x, character(0))) NA_character_ else x) %>% 
    lapply(FUN = function(t) as.numeric(gsub(" Bed Kosong Kelas III", "", x = t))) %>% 
    lapply(.,FUN = sum) %>% 
    unlist(., use.names = F)
  
  # update time (taking the minimum times)
  update_class1 <- str_extract_all(bed, "Kelas I Di Ruang [a-zA-Z\\& ]+ [0-9]+ (jam|menit)") %>% 
    lapply(function(x) if(identical(x, character(0))) NA_character_ else x) %>% 
    lapply(function(t) gsub("[a-zA-Z\\& ]+ diupdate", "", x=t)) %>%
    map(1) %>% 
    unlist(., use.names = F) %>% 
    str_trim(side = c("both", "left", "right")) %>% 
    str_squish()
  
  update_class2 <- str_extract_all(bed, "Kelas II Di Ruang [a-zA-Z\\& ]+ [0-9]+ (jam|menit)") %>% 
    lapply(function(x) if(identical(x, character(0))) NA_character_ else x) %>% 
    lapply(function(t) gsub("[a-zA-Z\\& ]+ diupdate", "", x=t))%>% 
    map(1) %>% 
    unlist(., use.names = F) %>% 
    str_trim(side = c("both", "left", "right")) %>% 
    str_squish()  
    
  update_class3 <- str_extract_all(bed, "Kelas III Di Ruang [a-zA-Z\\& ]+ [0-9]+ (jam|menit)") %>% 
    lapply(function(x) if(identical(x, character(0))) NA_character_ else x) %>% 
    lapply(function(t) gsub("[a-zA-Z\\& ]+ diupdate", "", x=t)) %>% 
    map(1) %>% 
    unlist(., use.names = F) %>% 
    str_trim(side = c("both", "left", "right")) %>% 
    str_squish() 
  
  # telephone number 
  tlp_html <- html_nodes(base_html, ".text-right span")
  tlp <- html_text(tlp_html)
  tlp <- tlp[-1]
  
  # combining into df for COVID beds
  half_list <- tibble(
    hospital = list_hospital,
    address = address, 
    bed_class1 = bed_class1,
    last_update_class1 = update_class1,
    bed_class2 = bed_class2,
    last_update_class2 = update_class2,
    bed_class3 = bed_class3,
    last_update_class3 = update_class3, 
    tlp_number = tlp,
    province = prov_code, 
    district = district_code,
    scraped_at = Sys.time(), 
    bed_type = "Non COVID-19"
  )
  
  # get today's date
  date <- Sys.Date() %>% 
    format("%m%d")
  
  # saving the data 
  assign(paste0("noncovid_bed_data_", district_code, "_", date), 
         half_list)
  
  }
  
# APPENDING THE NON-COVID BEDS DATA ----
  dflist <- lapply(paste0("noncovid_bed_data_",district_codes,"_",date), get)
  base_data <- rbindlist(dflist)
  
  saveRDS(base_data, file=paste0(rout, "noncovid_bed_data_all", "_", date, ".rds"))
  write.csv(base_data, paste0(csvout, "noncovid_bed_data_all", "_", date, ".csv"))
  write_dta(base_data, paste0(dtaout, "noncovid_bed_data_all", "_", date, ".dta"))
  
  