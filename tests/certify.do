version 16.0
clear all
set more off

if !fileexists("targetree.ado") {
    display as error "Run this certification file from the targetree-stata repository root."
    exit 601
}
local package_dir "`c(pwd)'"
adopath ++ "`package_dir'"
tempfile graph_file
tempname fitted_tree

set obs 80
generate double i = _n - 1
generate double x1 = mod(i, 17) / 16
generate double x2 = mod(i * 7, 23) / 22
generate double p = invlogit(-2.1 + 3 * x1 + 1.4 * x2)
generate byte y = mod(i * 13, 101) / 100 < p

targetree y x1 x2, depth(3) minimum_portion(.09) method(cart) cut(.35)
matrix `fitted_tree' = e(tree)
mata: st_numscalar("__tr_test_min_leaf", min(select(st_matrix("`fitted_tree'")[, 6], st_matrix("`fitted_tree'")[, 1] :== 1)))
assert scalar(__tr_test_min_leaf) >= ceil(.09 * e(N))
assert abs(el(e(tree), 1, 3) - .40625) < 1e-10
predict double pred_cart
predict byte class_cart, class
assert pred_cart < .
assert class_cart < .
targetree_risk y
assert r(TP) == 41
assert r(FN) == 1
assert r(FP) == 30
assert r(TN) == 8
targetree_print

targetree y x1 x2, depth(3) minimum_portion(.09) method(mdfs) cut(.35)
matrix `fitted_tree' = e(tree)
mata: st_numscalar("__tr_test_min_leaf", min(select(st_matrix("`fitted_tree'")[, 6], st_matrix("`fitted_tree'")[, 1] :== 1)))
assert scalar(__tr_test_min_leaf) >= ceil(.09 * e(N))
assert abs(el(e(tree), 1, 3) - .40625) < 1e-10
predict double pred_mdfs
targetree_risk y
assert r(TP) == 41
assert r(FN) == 1
assert r(FP) == 30
assert r(TN) == 8

targetree y x1 x2, depth(3) minimum_portion(.09) method(pfs) cut(.35) prob(p)
matrix `fitted_tree' = e(tree)
mata: st_numscalar("__tr_test_min_leaf", min(select(st_matrix("`fitted_tree'")[, 6], st_matrix("`fitted_tree'")[, 1] :== 1)))
assert scalar(__tr_test_min_leaf) >= ceil(.09 * e(N))
assert abs(el(e(tree), 1, 3) - .46875) < 1e-10
predict double pred_prob

preserve
clear
set obs 80
generate double i = _n - 1
generate double x = mod(i, 17) / 16
generate byte cat = mod(i, 4) + 1
generate byte y = x + .45 * inlist(cat, 1, 3) > .72
targetree y x cat, depth(3) minimum_portion(.09) method(mdfs) ///
    cut(.35) categorical(cat)
assert abs(el(e(tree), 1, 3) - .28125) < 1e-10
predict byte pred_cat, class
assert pred_cat == y
restore

targetree y x1 x2, depth(3) minimum_portion(.09) method(cart) cut(.35)
targetree_honest y
assert "`e(honest)'" == "1"
predict double pred_honest, honest

targetree_plot, title("Certification tree") name(targetree_certify) ///
    font_size(medsmall) split_rule_lines(2) ///
    saving("`graph_file'.gph") replace
targetree_plot, title("One-line certification tree") ///
    name(targetree_certify_one_line) font_size(small) split_rule_lines(1)

capture noisily targetree_plot, split_rule_lines(3)
assert _rc == 198

display as result "targetree Stata certification tests passed"
exit, clear
