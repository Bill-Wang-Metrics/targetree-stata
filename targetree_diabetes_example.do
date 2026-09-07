version 16.0
clear all
set more off

findfile targetree_diabetes.dta
use "`r(fn)'", clear

local predictors pregnancies glucose bloodpressure skinthickness insulin bmi ///
    diabetespedigreefunction age
local depth 3
local cut .60
local plot_font_size small
local split_rule_lines 2

* Standard CART from the Python empirical example.
targetree outcome `predictors', depth(`depth') minimum_portion(.02) ///
    method(cart) cut(`cut')
targetree_risk outcome
targetree_print
targetree_plot, title("CART") name(diabetes_cart) ///
    font_size(`plot_font_size') split_rule_lines(`split_rule_lines')

* Maximum Distance Final Split from the Python empirical example.
targetree outcome `predictors', depth(`depth') minimum_portion(.02) ///
    method(mdfs) cut(`cut')
targetree_risk outcome
targetree_print
targetree_plot, title("MDFS") name(diabetes_mdfs) ///
    font_size(`plot_font_size') split_rule_lines(`split_rule_lines')

* Penalized Final Split with the same lambda used in Python.
targetree outcome `predictors', depth(`depth') minimum_portion(.02) ///
    method(pfs) lbd(.5) cut(`cut')
targetree_risk outcome
targetree_print
targetree_plot, title("PFS (lambda = 0.5)") name(diabetes_pfs) ///
    font_size(`plot_font_size') split_rule_lines(`split_rule_lines')

* All three graphs remain available in memory:
* graph display diabetes_cart
* graph display diabetes_mdfs
* graph display diabetes_pfs
