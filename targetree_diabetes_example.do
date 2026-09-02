version 16.0
clear all
set more off

findfile targetree_diabetes.dta
use "`r(fn)'", clear

local predictors pregnancies glucose bloodpressure skinthickness insulin bmi ///
    diabetespedigreefunction age

* Standard CART from the Python empirical example.
targetree outcome `predictors', depth(2) minimum_portion(.02) method(cart) cut(.60)
targetree_risk outcome
targetree_print
targetree_plot, title("CART") name(diabetes_cart)

* Maximum Distance Final Split from the Python empirical example.
targetree outcome `predictors', depth(2) minimum_portion(.02) method(mdfs) cut(.60)
targetree_risk outcome
targetree_print
targetree_plot, title("MDFS") name(diabetes_mdfs)

graph combine diabetes_cart diabetes_mdfs, cols(2) ///
    title("Diabetes example") name(diabetes_comparison, replace)
