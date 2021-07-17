/*
	Author		: Sean Hambali
	Project		: Cleaning SIRANAP data scraped from Yankes website 
	Version		: 1.0 - 16 July 2021
*/

// clearing previous work environment 
clear all 
clear matrix
clear mata
set more off

// listing the work directories 
if "`c(username)'" == "Sean Hambali" {
	gl csv "C:/Users/Sean Hambali/Documents/GitHub/siranap_hospital_data/csv"
	gl do "C:/Users/Sean Hambali/Documents/GitHub/siranap_hospital_data/do"
	gl dta "C:/Users/Sean Hambali/Documents/GitHub/siranap_hospital_data/dta"
	gl graph "C:/Users/Sean Hambali/Documents/GitHub/siranap_hospital_data/graph"
	gl rdata "C:/Users/Sean Hambali/Documents/GitHub/siranap_hospital_data/rdata"
	gl script "C:/Users/Sean Hambali/Documents/GitHub/siranap_hospital_data/script"
	gl data "C:/Users/Sean Hambali/Desktop/DATA"
}

// first, we append all the covid beds data in the folder 
	loc allfiles: dir "$dta" files "covid_bed_data_*"
	
	foreach f in `allfiles' {
		append using "$dta/`f'"
	}

// cleaning bed availability data 
	replace bed_availability = strltrim(bed_availability)
	replace bed_availability = strrtrim(bed_availability)
	replace bed_availability = subinstr(bed_availability, " bed kosong IGD", "",.)
	replace bed_availability = subinstr(bed_availability, "Tersedia ", "",.)
	replace bed_availability = "0" if bed_availability == "Bed IGD Penuh!"
	destring bed_availability, force replace
	
// cleaning queue data
	replace queue = "0" if queue == "tanpa antrian pasien."
	replace queue = subinstr(queue, "dengan antrian ", "",.)
	replace queue = subinstr(queue, " pasien", "",.)
	destring queue, force replace
	
// scraped_at data in stata lags 7 hours 
	replace scraped_at = scraped_at + (7*3600000)
	
// cleaning last_update data 
	g update_1 = regexs(0) if regexm(last_update, "^[0-9]+")
	replace update_1 = "1" if last_update == "kurang dari 1 menit"
	destring update_1, force replace
	
	* replacing for hours 
	replace update_1 = update_1*3600000 if strpos(last_update, "jam") >0
	
	* replacing for minutes 
	replace update_1 = update_1*60000 if strpos(last_update, "menit") >0 
	
	* renewing last update 
	drop last_update
	g last_update = scraped_at - update_1 
	format %tc last_update
	drop update_1
	
	* generating date for each row 
	g date = dofc(scraped_at)
	format %td date
	
// destring province and district codes data 
	foreach v of varlist province district {
		destring `v', force replace
	}
	
// merging with region names 
	ren district kode 
	merge m:1 kode using "$data/Kode Provinsi dan Kabupaten Kota", ///
	assert(2 3) keep(3) nogen
	drop kodeprov id province
	
// temporarily ordering the data 
	order nama_prov prov_name kode_prov nama kode hospital address tlp_number ///
	date bed_type bed_availability queue last_update scraped_at
	
// cleaning hospital names 
	replace hospital = strltrim(hospital)
	replace hospital = strrtrim(hospital)
	replace hospital = stritrim(hospital)

// cleaning up white spaces in address 
	replace address = strltrim(address)
	replace address = strrtrim(address)
	replace address = stritrim(address)
	
	* sorting the data 
	gsort +kode_prov +kode +hospital +date
	
// generating hospital ID 
	egen hospital_id = group(hospital tlp_number)
	bys hospital_id: assert address[_n] == address[_n-1] if _n>1
	
// labelling the variables 	
	la var nama_prov "Province name (ID)"
	la var prov_name "Province name (EN)"
	la var kode_prov "Province code"
	la var nama "District name"
	la var kode "District code"
	la var hospital "Hospital name"
	la var address "Hospital address"
	la var tlp_number "Telephone number"
	la var date "Date"
	la var bed_type "Bed type"
	la var bed_availability "Number of available COVID beds"
	la var queue "Total patient queue during scraping time"
	la var last_update "Last data update by hospital"
	la var scraped_at "Scraping date"
	la var hospital_id "Hospital ID"
	
	gsort +hospital_id +date
	
// saving the final data 
	save "$dta/siranap_covid", replace