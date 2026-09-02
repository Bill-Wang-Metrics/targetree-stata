*! version 0.1.1 01sep2026
program define targetree_risk, rclass
    version 16.0
    syntax varname(numeric) [if] [in], [HONEST]
    if "`e(cmd)'" != "targetree" {
        display as error "targetree estimation results not found"
        exit 301
    }
    marksample touse
    markout `touse' `e(indepvars)'

    _targetree_load
    tempname nodes catsets
    matrix `nodes' = e(tree)
    matrix `catsets' = e(catsets)
    mata: targetree_restore_stata("`nodes'", "`catsets'", ///
        st_numscalar("e(depth)"), st_numscalar("e(minimum_portion)"), ///
        st_numscalar("e(lbd)"), st_numscalar("e(cut)"), "`e(method)'", ///
        "`e(indepvars)'", "`e(categorical_indices)'")
    mata: targetree_risk_stata("`varlist'", "`e(indepvars)'", "`touse'", ///
        "`honest'" != "")

    local TP = scalar(__tr_tp)
    local FN = scalar(__tr_fn)
    local FP = scalar(__tr_fp)
    local TN = scalar(__tr_tn)
    local N = `TP' + `FN' + `FP' + `TN'
    local accuracy = (`TP' + `TN') / `N'
    local tpr = cond(`TP' + `FN', `TP' / (`TP' + `FN'), .)
    local precision = cond(`TP' + `FP', `TP' / (`TP' + `FP'), .)

    return scalar TP = `TP'
    return scalar FN = `FN'
    return scalar FP = `FP'
    return scalar TN = `TN'
    return scalar N = `N'
    return scalar accuracy = `accuracy'
    return scalar tpr = `tpr'
    return scalar precision = `precision'

    display as text _newline "Confusion-matrix counts at cut = " as result e(cut)
    display as text "TP = " as result `TP' as text "   FN = " as result `FN' ///
        as text "   FP = " as result `FP' as text "   TN = " as result `TN'
    display as text "Accuracy = " as result %7.4f `accuracy' ///
        as text "   TPR = " as result %7.4f `tpr' ///
        as text "   Precision = " as result %7.4f `precision'
end
