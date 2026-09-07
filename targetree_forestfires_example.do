version 16.0
clear all
set more off

findfile targetree_forestfires.dta
use "`r(fn)'", clear

generate byte fire_above_5 = area > 5
label variable fire_above_5 "Burned area exceeds 5 hectares"
local predictors x y ffmc dmc dc isi temp rh wind rain
local cut = 1 / 3
local plot_font_size small
local split_rule_lines 2

* Standard CART from the Python empirical example.
targetree fire_above_5 `predictors', depth(3) minimum_portion(.02) ///
    method(cart) cut(`cut')
targetree_risk fire_above_5
targetree_print
targetree_plot, title("CART") name(forestfires_cart) ///
    font_size(`plot_font_size') split_rule_lines(`split_rule_lines')

* Maximum Distance Final Split from the Python empirical example.
targetree fire_above_5 `predictors', depth(3) minimum_portion(.02) ///
    method(mdfs) cut(`cut')
targetree_risk fire_above_5
targetree_print
targetree_plot, title("MDFS") name(forestfires_mdfs) ///
    font_size(`plot_font_size') split_rule_lines(`split_rule_lines')

* Penalized Final Split with the same lambda used in Python.
targetree fire_above_5 `predictors', depth(3) minimum_portion(.02) ///
    method(pfs) lbd(.5) cut(`cut')
targetree_risk fire_above_5
targetree_print
targetree_plot, title("PFS (lambda = 0.5)") name(forestfires_pfs) ///
    font_size(`plot_font_size') split_rule_lines(`split_rule_lines')

* All three graphs remain available in memory:
* graph display forestfires_cart
* graph display forestfires_mdfs
* graph display forestfires_pfs
