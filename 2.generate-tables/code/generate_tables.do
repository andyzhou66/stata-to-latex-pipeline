/*==================================================
              0: Program set up
==================================================*/
version 16
clear all
set more off
set varabbrev off

* ── Logging ──
capture mkdir "2.generate-tables/temp"
local _sd = date(c(current_date), "DMY")
local _ts_start = string(year(`_sd'), "%04.0f") + "-" ///
    + string(month(`_sd'), "%02.0f") + "-" ///
    + string(day(`_sd'), "%02.0f") + " " + c(current_time)
log using "2.generate-tables/temp/Sconscript_generate_tables.log", replace text
display "*** Builder log created: {`_ts_start'}"

capture mkdir "2.generate-tables/output"

/*==================================================
   1: Load the prepared panel dataset
   (produced by 1.prepare-data; standardised vars, industry_grp, post)
==================================================*/
use "2.generate-tables/input-data/nlswork_processed.dta", clear
xtset idcode year

/*==================================================
   2: Descriptive-statistics tables
==================================================*/

* ---- Table 1: Overall summary statistics with multiple indicators ----
est clear
estpost tabstat ln_wage_norm tenure_norm ttl_exp_norm hours_norm, ///
    columns(statistics) statistics(sum mean sd min max count) listwise

esttab using "2.generate-tables/output/table1.tex", replace ///
    cells("sum(fmt(%13.0fc)) mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) min max count") ///
    nonumber nomtitle nonote noobs label booktabs f ///
    collabels("Sum" "Mean" "SD" "Min" "Max" "N")

esttab using "2.generate-tables/output/table1_full.tex", replace ///
    cells("sum(fmt(%13.0fc)) mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) min max count") ///
    nonumber nomtitle nonote noobs label booktabs ///
    collabels("Sum" "Mean" "SD" "Min" "Max" "N") ///
    prehead(\begin{tabular}{lrrrrrr}\toprule) ///
    postfoot(\bottomrule\end{tabular})


* ---- Table 2/3: Summary statistics by industry (mean + SD) ----
est clear
estpost tabstat ln_wage_norm tenure_norm ttl_exp_norm hours_norm, ///
    by(industry_grp) stat(mean sd) nototal columns(statistics) listwise

* Method 1: concise main/aux syntax (mean as main column, SD as auxiliary)
esttab using "2.generate-tables/output/table2.tex", replace ///
    main(mean %15.2f) aux(sd %15.2f) nostar nonumber unstack ///
    nonote noobs gap label booktabs f collabels(none) ///
    eqlabels("Agri \& Mining" "Construction" "Manufacturing" ///
             "Utils \& Transp" "Wholesale \& Retail" "Finance" ///
             "Services \& Other") nomtitles

* Method 2: fully customizable cells syntax (SD in parentheses)
esttab using "2.generate-tables/output/table3.tex", replace ///
    cells("mean(fmt(%15.2fc))" "sd(par fmt(%15.2fc))") ///
    nostar unstack nonumber compress nonote noobs gap label booktabs f ///
    collabels(none) ///
    eqlabels("Agri \& Mining" "Construction" "Manufacturing" ///
             "Utils \& Transp" "Wholesale \& Retail" "Finance" ///
             "Services \& Other") nomtitles


* ---- Table T_Test: Two-sample mean comparison (South vs Non-South) ----
est clear
estpost sum ln_wage_norm tenure_norm ttl_exp_norm hours_norm if south==1, listwise
matrix obs_south = e(count)
eststo group_south

estpost sum ln_wage_norm tenure_norm ttl_exp_norm hours_norm if south==0, listwise
matrix obs_nonsouth = e(count)
eststo group_nonsouth

eststo diff_ttest: estpost ttest ln_wage_norm tenure_norm ttl_exp_norm hours_norm, by(south) listwise

esttab group_south group_nonsouth diff_ttest using "2.generate-tables/output/table_ttest.tex", replace ///
    cells("mean(pattern(1 1 0) fmt(2)) b(star pattern(0 0 1) fmt(2)) sd(pattern(1 1 0) par) t(pattern(0 0 1) par)") ///
    nonumbers label booktabs f compress noobs nonote ///
    mlabel("\makecell{South\\N=`=obs_south[1,1]'}" "\makecell{Non-South\\N=`=obs_nonsouth[1,1]'}" "T-test", ///
           prefix(\multicolumn{@span}{c}{) suffix(}) span ///
           erepeat(\cmidrule(lr){@span}))


* ---- Table 5: Custom bracket style (square brackets instead of parentheses) ----
est clear
estpost tabstat ln_wage_norm tenure_norm ttl_exp_norm hours_norm, ///
    by(industry_grp) stat(mean sd) nototal columns(statistics) listwise

esttab using "2.generate-tables/output/table5.tex", replace ///
    cells(mean(fmt(2)) sd(fmt(3) par([ ]))) nostar unstack nonumber ///
    compress nonote noobs gap label booktabs f alignment(D{.}{.}{-1}) ///
    collabels(none) ///
    eqlabels("Agri \& Mining" "Construction" "Manufacturing" ///
             "Utils \& Transp" "Wholesale \& Retail" "Finance" ///
             "Services \& Other") nomtitles


* ---- Table 6: Row-wise custom decimal places ----
esttab using "2.generate-tables/output/table6.tex", replace ///
    cells(mean(fmt(1 2 3 4)) sd(fmt(3 2 1 0) par)) nostar unstack nonumber ///
    compress nonote noobs gap label booktabs f alignment(D{.}{.}{-1}) ///
    collabels(none) ///
    eqlabels("Agri \& Mining" "Construction" "Manufacturing" ///
             "Utils \& Transp" "Wholesale \& Retail" "Finance" ///
             "Services \& Other") nomtitles


* ---- Table 7: Wide descriptive table with multicolumn group headers ----
* Self-contained tabular (prehead/postfoot) because \cmidrule's \noalign is
* illegal inside \CatchFileDef/\loadfrag. Use \input{}, NOT \loadfrag, in LaTeX.
esttab using "2.generate-tables/output/table7.tex", replace ///
    cells("mean(fmt(2)) sd(fmt(2))") unstack nonumber ///
    collabels("\textbf{Mean}" "SD") ///
    booktabs label compress noobs nonote nomtitle ///
    eqlabels("Agri \& Mining" "Construction" "Manufacturing" ///
             "Utils \& Transp" "Wholesale \& Retail" "Finance" ///
             "Services \& Other", ///
             prefix(\multicolumn{@span}{c}{) suffix(}) span ///
             erepeat(\cmidrule(lr){@span})) ///
    prehead(\begin{tabular}{l*{14}{c}}\toprule) ///
    postfoot(\bottomrule\end{tabular})


* ---- Table 7_tblr: Wide descriptive table using tabularray (tblr) ----
* Triple-brace {{{ }}} escaping required for literal braces in \SetCell/collabels.
* \cmidrule uses [lr] square brackets in tabularray, NOT (lr) parentheses.
esttab using "2.generate-tables/output/table7_tblr.tex", replace ///
    cells("mean(fmt(2)) sd(fmt(2))") unstack nonumber ///
    collabels("{{{\textbf{Mean}}}}" "{{{SD}}}") ///
    booktabs label f compress noobs nonote nomtitle ///
    eqlabels("Agri \& Mining" "Construction" "Manufacturing" ///
             "Utils \& Transp" "Wholesale \& Retail" "Finance" ///
             "Services \& Other", ///
             prefix(\SetCell[c=2]{c}{{{) suffix(}}} & ) span ///
             erepeat(\cmidrule[lr]{@span})) ///
    prehead(\begin{tblr}{width=1.8\linewidth,colspec={l *{14}{X[c,si={table-number-alignment=center,group-separator={,},group-minimum-digits=4}]}}} \toprule) ///
    postfoot(\bottomrule\end{tblr})


* ---- Table 8: Grouped descriptive statistics with category headers ----
foreach v of varlist ln_wage_norm tenure_norm {
    label variable `v' `"\hspace{0.25cm}`:variable label `v''"'
}
foreach v of varlist ttl_exp_norm hours_norm age {
    label variable `v' `"\hspace{0.25cm}`:variable label `v''"'
}

estpost tabstat ln_wage_norm tenure_norm ttl_exp_norm hours_norm age, ///
    columns(statistics) stat(mean sd min max count)

esttab using "2.generate-tables/output/table8.tex", replace ///
    refcat(ln_wage_norm "\emph{Labor outcomes}" ttl_exp_norm "\vspace{0.1em} \\ \emph{Individual characteristics}", nolabel) ///
    cells("mean(fmt(%15.2fc)) sd min max count(fmt(0))") nostar unstack nonumber ///
    compress nomtitle nonote noobs gap label booktabs f ///
    collabels("Mean" "SD" "Min" "Max" "N")

* Restore clean labels before the regressions (Table 8 used \hspace indentation)
label variable ln_wage_norm "Log wage (standardized)"
label variable tenure_norm  "Tenure (standardized)"
label variable ttl_exp_norm "Total work experience (standardized)"
label variable hours_norm   "Hours worked (standardized)"


/*==================================================
   3: Regression-analysis tables
==================================================*/

* ---- Regression 1: Basic panel regression ----
est clear
eststo: xtreg ln_wage_norm tenure_norm ttl_exp_norm union, vce(cluster idcode)
eststo: xtreg ln_wage_norm tenure_norm ttl_exp_norm union age south i.race, vce(cluster idcode)

esttab using "2.generate-tables/output/reg1_full.tex", replace ///
    b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs alignment(D{.}{.}{-1}) ///
    title(Baseline regression results \label{reg1}) ///
    addnotes("Dependent variable: Standardized log wage." "Data source: NLS Work Survey.")

esttab using "2.generate-tables/output/reg1_frag.tex", replace f ///
    b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs alignment(D{.}{.}{-1})


* ---- Regression 2: Lags + multi-model comparison + custom estadd statistics ----
est clear
eststo: xtreg ln_wage_norm L1.tenure_norm L1.ttl_exp_norm L1.union, re robust
 estadd local FE  "No"
 estadd local TE  "No"
eststo: xtreg ln_wage_norm L1.tenure_norm L1.ttl_exp_norm L1.union i.year, re robust
 estadd local FE  "No"
 estadd local TE  "Yes"
eststo: xtreg ln_wage_norm L1.tenure_norm L1.ttl_exp_norm L1.union, fe robust
 estadd local FE  "Yes"
 estadd local TE  "No"
eststo: xtreg ln_wage_norm L1.tenure_norm L1.ttl_exp_norm L1.union i.year, fe robust
 estadd local FE  "Yes"
 estadd local TE  "Yes"
eststo: xtreg ln_wage_norm L1.tenure_norm L1.ttl_exp_norm L1.union, vce(cluster idcode)
 estadd local RFE "Yes"
 estadd local TE  "No"
eststo: xtreg ln_wage_norm L1.tenure_norm L1.ttl_exp_norm L1.union i.year, vce(cluster idcode)
 estadd local RFE "Yes"
 estadd local TE  "Yes"

test L1.tenure_norm = L1.ttl_exp_norm
estadd scalar F_test = r(chi2)

esttab using "2.generate-tables/output/reg2.tex", replace f ///
    b(3) se(3) keep(L.tenure_norm L.ttl_exp_norm L.union) ///
    coeflabel(L.tenure_norm "Tenure (t-1)" L.ttl_exp_norm "Experience (t-1)" L.union "Union status (t-1)") ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs nomtitle collabels(none) compress alignment(D{.}{.}{-1}) ///
    scalars("N Obs." "rho \$\rho\$" "TE Time FE" "FE Individual FE" "RFE Cluster SE" F_test) sfmt(3)


* ---- Regression 3: Multi-outcome grouped regressions (mgroups) ----
global controls age south i.race

est clear
foreach y of varlist ln_wage_norm tenure_norm hours_norm {
    eststo: xtreg `y' union $controls, re robust
     estadd local RFE "No"
    eststo: xtreg `y' union $controls, vce(cluster idcode)
     estadd local RFE "Yes"
}

esttab using "2.generate-tables/output/reg3.tex", replace f ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs nonotes nomtitle collabels(none) ///
    scalars("RFE Cluster SE") sfmt(3) ///
    mgroups("Wage" "Tenure" "Hours", pattern(1 0 1 0 1 0) ///
            prefix(\multicolumn{@span}{c}{) suffix(}) span ///
            erepeat(\cmidrule(lr){@span}))


* ---- Regression 4: Single key coefficient extraction (DID style) ----
gen did = post * union

est clear
foreach y of varlist ln_wage_norm tenure_norm hours_norm {
    eststo: xtreg `y' post union did, robust
}
esttab using "2.generate-tables/output/reg4.tex", replace f ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(did) coeflabel(did "Baseline") ///
    label booktabs noobs nonotes collabels(none) alignment(D{.}{.}{-1}) ///
    mtitles("Wage" "Tenure" "Hours")

est clear
foreach y of varlist ln_wage_norm tenure_norm hours_norm {
    eststo: xtreg `y' post union did, vce(cluster idcode)
}
esttab using "2.generate-tables/output/reg4.tex", append f ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(did) coeflabel(did "Cluster SE") ///
    label booktabs nodep nonum nomtitles nolines noobs nonotes collabels(none) alignment(D{.}{.}{-1})

est clear
foreach y of varlist ln_wage_norm tenure_norm hours_norm {
    eststo: xtreg `y' post union did $controls, vce(cluster idcode)
}
esttab using "2.generate-tables/output/reg4.tex", append f ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(did) ///
    label booktabs collabels(none) nomtitles nolines nonum alignment(D{.}{.}{-1}) ///
    varlabels(did "Controls + Cluster SE")


* ---- Regression 6: Multi-lag wide table (paired with sidewaystable) ----
gen month_fe = mod(year, 12)

est clear
foreach y of varlist ln_wage_norm tenure_norm hours_norm {
    eststo: xtreg `y' L(0/2).union i.month_fe, vce(cluster idcode)
     estadd local CNTL "No"
    eststo: xtreg `y' L(0/2).union $controls i.month_fe, vce(cluster idcode)
     estadd local CNTL "Yes"
}

esttab using "2.generate-tables/output/reg6.tex", replace f ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(union L*) label booktabs nonotes noobs nomtitle collabels(none) ///
    scalars("N Obs." "CNTL Controls") sfmt(0) ///
    mgroups("Wage" "Tenure" "Hours", pattern(1 0 1 0 1 0) ///
            prefix(\multicolumn{@span}{c}{) suffix(}) span ///
            erepeat(\cmidrule(lr){@span}))


* ---- Regression 7: Tabularray regression table (tblr with siunitx columns) ----
est clear
eststo: reg ln_wage_norm tenure_norm ttl_exp_norm union, robust
 estadd local Obs  "\SetCell[c=3]{c,cmd} \num[group-minimum-digits=4]{`=e(N)'}"
 estadd local FE  "\SetCell[c=3]{c}{{{No}}}"
eststo: reg ln_wage_norm tenure_norm ttl_exp_norm union age south i.race, robust
 estadd local Obs  "\SetCell[c=3]{c,cmd} \num[group-minimum-digits=4]{`=e(N)'}"
 estadd local FE  "\SetCell[c=3]{c}{{{No}}}"
eststo: xtreg ln_wage_norm tenure_norm ttl_exp_norm union, fe robust
 estadd local Obs  "\SetCell[c=3]{c,cmd} \num[group-minimum-digits=4]{`=e(N)'}"
 estadd local FE  "\SetCell[c=3]{c}{{{Yes}}}"

esttab using "2.generate-tables/output/reg7_tblr.tex", replace f ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep(tenure_norm ttl_exp_norm union) ///
    label booktabs compress noobs nonotes nonumbers nomtitles collabels(none) ///
    stats(Obs FE, labels("Obs." "Ind. FE") fmt(0)) ///
    prehead(\begin{tblr}{width=\linewidth, colspec={l *{3}{X[c]}}} \toprule) ///
    postfoot(\bottomrule\end{tblr})


/*==================================================
   4: texresults -- export statistics as LaTeX macros
   Enables automatic in-text number updates when data changes.
==================================================*/
reg ln_wage_norm tenure age south
texresults using "2.generate-tables/output/macro.tex", texmacro(Nreg) result(e(N)) replace
texresults using "2.generate-tables/output/macro.tex", texmacro(Fstat) result(e(F)) append

/*==================================================
              5: Close log
==================================================*/
display "All tables exported to 2.generate-tables/output/"
local _ed = date(c(current_date), "DMY")
local _ts_end = string(year(`_ed'), "%04.0f") + "-" ///
    + string(month(`_ed'), "%02.0f") + "-" ///
    + string(day(`_ed'), "%02.0f") + " " + c(current_time)
display "*** Builder log completed: {`_ts_end'}"
log close

exit
