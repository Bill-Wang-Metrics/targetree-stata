*! version 0.1.0 01sep2026
program define targetree_plot
    version 16.0
    syntax [, TITLE(string asis) NAME(name) SAVING(string) REPLACE]
    if "`e(cmd)'" != "targetree" {
        display as error "targetree estimation results not found"
        exit 301
    }
    _targetree_load
    tempname nodes catsets
    matrix `nodes' = e(tree)
    matrix `catsets' = e(catsets)
    mata: targetree_restore_stata("`nodes'", "`catsets'", ///
        st_numscalar("e(depth)"), st_numscalar("e(minimum_portion)"), ///
        st_numscalar("e(lbd)"), st_numscalar("e(cut)"), "`e(method)'", ///
        "`e(indepvars)'", "`e(categorical_indices)'")

    preserve
    clear
    mata: targetree_plot_data_stata()
    local graphname
    if "`name'" != "" local graphname name(`name', replace)
    local graphtitle
    if `"`title'"' != "" local graphtitle title(`title')

    twoway ///
        (pcspike tr_y tr_x tr_py tr_px if tr_parent, lcolor(gs8)) ///
        (scatter tr_y tr_x if !tr_leaf, msymbol(square) msize(vlarge) ///
            mcolor(gs13) mlab(tr_label) mlabposition(0) mlabsize(vsmall)) ///
        (scatter tr_y tr_x if tr_leaf & !tr_positive, msymbol(square) ///
            msize(vlarge) mcolor(white) mlab(tr_label) mlabposition(0) ///
            mlabsize(vsmall)) ///
        (scatter tr_y tr_x if tr_leaf & tr_positive, msymbol(square) ///
            msize(vlarge) mcolor(eltblue) mlab(tr_label) mlabposition(0) ///
            mlabcolor(white) mlabsize(vsmall)), ///
        xlabel(none) ylabel(none) xtitle("") ytitle("") ///
        legend(order(3 "P <= cut" 4 "P > cut") rows(1)) ///
        `graphtitle' `graphname'

    if `"`saving'"' != "" {
        local saving_lower = lower(`"`saving'"')
        local is_gph = substr("`saving_lower'", -4, 4) == ".gph"
        if `is_gph' {
            if "`replace'" != "" graph save `"`saving'"', replace
            else graph save `"`saving'"'
        }
        else {
            if "`replace'" != "" graph export `"`saving'"', replace
            else graph export `"`saving'"'
        }
    }
    restore
end
