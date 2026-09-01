*! version 0.1.0 01sep2026
program define targetree_p
    version 16.0
    syntax newvarname [if] [in], [CLASS HONEST]
    if "`e(cmd)'" != "targetree" {
        display as error "targetree estimation results not found"
        exit 301
    }
    marksample touse, novarlist
    markout `touse' `e(indepvars)'
    confirm new variable `varlist'
    generate double `varlist' = .

    _targetree_load
    tempname nodes catsets
    matrix `nodes' = e(tree)
    matrix `catsets' = e(catsets)
    mata: targetree_restore_stata("`nodes'", "`catsets'", ///
        st_numscalar("e(depth)"), st_numscalar("e(minimum_portion)"), ///
        st_numscalar("e(lbd)"), st_numscalar("e(cut)"), "`e(method)'", ///
        "`e(indepvars)'", "`e(categorical_indices)'")
    mata: targetree_predict_stata("`e(indepvars)'", "`touse'", "`varlist'", ///
        "`honest'" != "", "`class'" != "")
    if "`class'" != "" label variable `varlist' "targetree classification"
    else label variable `varlist' "targetree probability"
end
