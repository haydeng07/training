/******************************************************************************

TrainingTask.do

This file exports a regression table and a summary statistic for training
purposes.

*******************************************************************************/

** Create a program to write commands to a latex file in the output folder
cap program drop latex_write
program define latex_write
	* Arguments: (1) name of the command, (2) content of the command
	if "`c(os)'" == "MacOSX" local command '\\newcommand{\\`1'}{`2'}'
	else local command \newcommand{\\`1'}{`2'}
	! echo `command'  >> "$github/analysis/output/numbersfortext.tex"
end

** Remove previous version of file to prevent duplication of commands
cap rm "$github/analysis/output/numbersfortext.tex"

*******************************************************************************
set more off

** Install necessary packages if not already installed
foreach pkg in estout esttab{
	cap which `pkg'
	if _rc ssc install `pkg'
	}

** Declare global (Note: change this to your local path if it differs)
if "`c(os)'" == "MacOSX" global github = "/Users/haydeng07/training"
else global github = "C:/Users/`c(username)'/Documents/GitHub/training"

** Load data
sysuse auto, clear // use example dataset that comes with Stata

** Separate the manufacturer from the model name
gen car_make = word(strtrim(make), 1)
label variable car_make "Car make"

** Create a numeric identifier for use in the fixed-effects regression
encode car_make, gen(car_make_id)

** Fixed effects require manufacturers represented by multiple cars
** bysort car_make_id: gen make_observations = _N
** keep if make_observations > 1

** Store the mean MPG
sum mpg
local mean : di %3.1f r(mean) // format so one decimal place is showing
latex_write meanMPG "`mean'" // the command name should only consist of letters

** Run a regression of car weight on length
eststo clear
reg weight length, r
eststo spec1
estadd local makefe "No" // note whether car make fixed effects are included

** Run a regression of car weight on length, with car make fixed effects
reg weight length i.car_make_id, r
eststo spec2
estadd local makefe "Yes"

** Export table
esttab spec2 spec1 using "$github/analysis/output/car_weight_regs.tex", ///
	replace se nonote numbers b(%8.2f) se(%8.2f) ///
	keep(length) nomtitles star(* 0.10 ** 0.05 *** 0.01) ///
	varlabels(length "Car length (inches)") ///
	stats(makefe r2 N, l("Car make fixed effects" "\$R^{2}$" "Observations") ///
	fmt(%8.0fc %8.2fc %8.0fc))
