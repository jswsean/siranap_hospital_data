/*
	Author		: Sean Hambali
	Project		: Preparing for geocoding Siranap hospitals data
	Version		: 1.0 - 17 July 2021
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

/*
	Prior to executing this dofile, ensure that 
	you have executed cleaning_siranap_data do file 
	to ensure the COVID bed data has been cleaned. 
	
	The cleaned dataset is named the siranap_covid
	dataset.
*/
	use "$dta/siranap_covid", clear

// we only want to keep the unique combinations of hospital and address 
	duplicates drop hospital_id, force 
	keep hospital address nama 
	
// generating search keywords 
	g keyword = hospital + " " + nama
	
// export this data to csv 
	export delimited using "$csv/hospital_keywords.csv", delim(tab) replace