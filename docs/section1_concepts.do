/*==================================================
   Reference snippet (NOT part of the build pipeline)
   --------------------------------------------------
   Section 1 of the original Stata-to-LaTeX tutorial: Core Concepts --
   Models vs Equations. Uses sysuse auto (a different dataset) purely to
   illustrate esttab options in the Stata console. It produces no persistent
   artifact, so it is excluded from the SCons pipeline (which builds only the
   nlswork-based tables). Kept here as a self-contained teaching reference.
==================================================*/
version 16
clear all
set more off

sysuse auto, clear
eststo clear

// ---- Concept of Models ----
// Each eststo / estimates store saves one "model" == one column in the table.
eststo: regress price weight mpg         // Model 1: baseline
eststo: regress price weight mpg foreign // Model 2: add origin control

esttab                                   // default: column name = dep. var.
esttab, mtitles("Baseline model" "Extended model")
esttab, nomtitles
esttab, nodepvars

// ---- Concept of Equations ----
// estpost multi-group results have a multi-equation structure (row groups).
eststo clear
estpost tabstat price weight mpg, columns(statistics) by(foreign) stat(mean sd min max n)
esttab, cells("count mean")              // equations stacked vertically (default)
esttab, cell(colpct(fmt(2))) unstack noobs   // unstack -> side-by-side column groups
