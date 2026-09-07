*! version 0.1.4 07sep2026
program define targetree, eclass sortpreserve
    version 16.0
    syntax varlist(min=2 numeric) [if] [in], DEPth(integer) ///
        MINimum_portion(real) [METHOD(string) CUT(real 0.5) ///
        LBD(real -999999) LAMBDA(real -999999) ///
        CATEGORICAL(varlist numeric) PROB(varname numeric)]

    marksample touse
    gettoken depvar indepvars : varlist
    if "`prob'" != "" markout `touse' `prob'

    if `depth' < 0 {
        display as error "depth() must be a nonnegative integer"
        exit 198
    }
    if `minimum_portion' < 0 | `minimum_portion' > 1 {
        display as error "minimum_portion() must be in [0,1]"
        exit 198
    }
    if `cut' < 0 | `cut' > 1 {
        display as error "cut() must be in [0,1]"
        exit 198
    }

    local method = lower(strtrim("`method'"))
    if "`method'" == "" local method "pfs"
    if !inlist("`method'", "cart", "pfs", "mdfs") {
        display as error "method() must be cart, pfs, or mdfs"
        exit 198
    }
    if `lbd' != -999999 & `lambda' != -999999 {
        display as error "specify only one of lbd() or lambda()"
        exit 198
    }
    local penalty = cond(`lbd' != -999999, `lbd', `lambda')
    if `penalty' == -999999 local penalty = cond("`method'" == "mdfs", 1, 0)
    if "`method'" == "cart" & `penalty' != 0 {
        display as error "lbd() must be 0 when method(cart)"
        exit 198
    }
    if "`method'" == "mdfs" & `penalty' != 1 {
        display as error "lbd() must be 1 when method(mdfs)"
        exit 198
    }

    quietly count if `touse'
    if r(N) == 0 {
        display as error "no observations"
        exit 2000
    }
    quietly summarize `depvar' if `touse', meanonly
    if r(min) < 0 | r(max) > 1 {
        display as error "outcome must contain values in [0,1]"
        exit 459
    }
    if "`prob'" != "" {
        quietly summarize `prob' if `touse', meanonly
        if r(min) < 0 | r(max) > 1 {
            display as error "prob() variable must contain values in [0,1]"
            exit 459
        }
    }

    local catidx
    foreach variable of local categorical {
        local position : list posof "`variable'" in indepvars
        if `position' == 0 {
            display as error "categorical variable `variable' is not a predictor"
            exit 198
        }
        local catidx `catidx' `position'
    }

    _targetree_load
    tempname nodes catsets
    mata: targetree_fit_stata("`depvar'", "`indepvars'", "`touse'", ///
        `depth', `minimum_portion', `penalty', `cut', "`method'", ///
        "`catidx'", "`prob'", "`nodes'", "`catsets'")

    ereturn clear
    ereturn scalar N = scalar(__tr_N)
    ereturn scalar depth = `depth'
    ereturn scalar minimum_portion = `minimum_portion'
    ereturn scalar lbd = `penalty'
    ereturn scalar cut = `cut'
    ereturn scalar nnodes = scalar(__tr_nnodes)
    ereturn scalar nleaves = scalar(__tr_nleaves)
    ereturn matrix tree = `nodes'
    ereturn matrix catsets = `catsets'
    ereturn local cmd "targetree"
    ereturn local predict "targetree_p"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local method "`method'"
    ereturn local categorical "`categorical'"
    ereturn local categorical_indices "`catidx'"
    ereturn local probvar "`prob'"
    ereturn local honest "0"
    ereturn local cmdline `"targetree `0'"'

    display as text _newline "Threshold-focused classification tree"
    display as text "Method: " as result upper("`method'") ///
        as text "    Observations: " as result %9.0g e(N)
    display as text "Depth:  " as result e(depth) ///
        as text "    Leaves:       " as result %9.0g e(nleaves)
    display as text "Cut:    " as result %6.4f e(cut) ///
        as text "    Nodes:        " as result %9.0g e(nnodes)
end
