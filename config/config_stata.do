clear all
set more off

program main
    * *** Required SSC packages for this pipeline ***
    * estout provides esttab / estpost / estadd / texresults, used throughout
    * 2.generate-tables/code/generate_tables.do.
    local ssc_packages "estout"
    * *** Required SSC packages for this pipeline ***

    if !missing("`ssc_packages'") {
        foreach pkg in "`ssc_packages'" {
        * install using ssc, but avoid re-installing if already present
            capture which `pkg'
            if _rc == 111 {
               dis "Installing `pkg'"
                ssc install `pkg', replace
               }
        }
    }

    * Standard GSLab stata utilities (optional, harmless if present)
    quietly net from "https://raw.githubusercontent.com/gslab-econ/gslab_stata/master/gslab_misc/ado"
       quietly cap net uninstall matrix_to_txt
       quietly net install matrix_to_txt
       quietly cap net uninstall preliminaries
       quietly net install preliminaries

end

main
