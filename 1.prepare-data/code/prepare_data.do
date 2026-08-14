/*==================================================
              0: Program set up
==================================================*/
version 16
clear all
set more off

* ── Logging ──
capture mkdir "1.prepare-data/temp"
local _sd = date(c(current_date), "DMY")
local _ts_start = string(year(`_sd'), "%04.0f") + "-" ///
    + string(month(`_sd'), "%02.0f") + "-" ///
    + string(day(`_sd'), "%02.0f") + " " + c(current_time)
log using "1.prepare-data/temp/Sconscript_prepare_data.log", replace text
display "*** Builder log created: {`_ts_start'}"

/*==================================================
   1: Load panel data (NLS Youth Longitudinal Survey)
   Built-in dataset via webuse. Replaces the original COVID data while
   preserving the panel structure and grouping logic used downstream.
==================================================*/
webuse nlswork, clear

/*==================================================
   2: Build grouping + standardized variables
==================================================*/
* 2.1  Seven major industry groups from the one-digit ind_code (1-12)
*      1 Agri/Forestry/Fish  2 Mining  3 Construction  4 Manufacturing
*      5 Transport/Comm/Util 6 Wholesale/Retail  7 Finance/Insur/RE
*      8 Business/Repair     9 Personal Services 10 Entertainment
*      11 Professional Svcs  12 Public Admin
gen industry_grp = .
replace industry_grp = 1 if inlist(ind_code, 1, 2)                       // Agri & Mining
replace industry_grp = 2 if ind_code == 3                                // Construction
replace industry_grp = 3 if ind_code == 4                                // Manufacturing
replace industry_grp = 4 if ind_code == 5                                // Utils & Transp
replace industry_grp = 5 if ind_code == 6                                // Wholesale & Retail
replace industry_grp = 6 if ind_code == 7                                // Finance
replace industry_grp = 7 if inrange(ind_code, 8, 12) | missing(ind_code) // Services & Other
label define grp 1 "Agri & Mining" 2 "Construction" 3 "Manufacturing" ///
                 4 "Utils & Transp" 5 "Wholesale & Retail" 6 "Finance" ///
                 7 "Services & Other"
label values industry_grp grp

* 2.2  Standardized variables (match the original normalized indicators)
foreach var of varlist ln_wage tenure ttl_exp hours {
    sum `var'
    gen `var'_norm = ( `var' - r(mean) ) / r(sd)
}
label variable ln_wage_norm "Log wage (standardized)"
label variable tenure_norm  "Tenure (standardized)"
label variable ttl_exp_norm "Total work experience (standardized)"
label variable hours_norm   "Hours worked (standardized)"

* 2.3  Simulated policy-time cutoff for the DID demonstration (Section 4)
gen post = (year >= 77)

/*==================================================
   3: Declare panel structure and save the analysis dataset
==================================================*/
xtset idcode year

capture mkdir "1.prepare-data/output"
save "1.prepare-data/output/nlswork_processed.dta", replace

/*==================================================
              4: Close log
==================================================*/
local _ed = date(c(current_date), "DMY")
local _ts_end = string(year(`_ed'), "%04.0f") + "-" ///
    + string(month(`_ed'), "%02.0f") + "-" ///
    + string(day(`_ed'), "%02.0f") + " " + c(current_time)
display "*** Builder log completed: {`_ts_end'}"
log close

exit
