*! version 0.1.1 01sep2026
program define targetree_honest, eclass
    version 16.0
    syntax varname(numeric) [if] [in]
    if "`e(cmd)'" != "targetree" {
        display as error "targetree estimation results not found"
        exit 301
    }
    marksample touse
    markout `touse' `e(indepvars)'
    quietly count if `touse'
    local honest_n = r(N)

    _targetree_load
    tempname nodes catsets updated
    matrix `nodes' = e(tree)
    matrix `catsets' = e(catsets)
    mata: targetree_restore_stata("`nodes'", "`catsets'", ///
        st_numscalar("e(depth)"), st_numscalar("e(minimum_portion)"), ///
        st_numscalar("e(lbd)"), st_numscalar("e(cut)"), "`e(method)'", ///
        "`e(indepvars)'", "`e(categorical_indices)'")
    mata: targetree_honest_stata("`varlist'", "`e(indepvars)'", "`touse'", ///
        "`updated'")
    ereturn matrix tree = `updated'
    ereturn local honest "1"
    display as text "Honest leaf estimates attached using " as result `honest_n' ///
        as text " observations"
end
