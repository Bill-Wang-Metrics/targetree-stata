*! version 0.1.4 07sep2026
program define targetree_plot
    version 16.0
    syntax [, TITLE(string asis) NAME(name) SAVING(string) REPLACE ///
        XSIZE(real 0) YSIZE(real 0) FONT_size(string) ///
        SPLIT_rule_lines(integer 2)]
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
    _targetree_plot_load

    if !inlist(`split_rule_lines', 1, 2) {
        display as error "split_rule_lines() must be 1 or 2"
        exit 198
    }
    local font_size = strtrim("`font_size'")
    if "`font_size'" == "" local font_size "small"

    local cut_text = strtrim(string(e(cut), "%6.3g"))
    if `xsize' <= 0 local xsize = max(9, min(16, 1.25 * e(nleaves) + 1.75))
    if `ysize' <= 0 local ysize = max(6, min(12, 1.60 * (e(depth) + 1)))

    preserve
    clear
    mata: targetree_plot_data_stata_v2(`split_rule_lines')
    quietly summarize tr_x, meanonly
    local xmin = r(min) - 0.65
    local xmax = r(max) + 0.65
    quietly summarize tr_y, meanonly
    local ymin = r(min) - 0.45
    local ymax = r(max) + 0.45
    local graphname
    if "`name'" != "" local graphname name(`name', replace)
    local graphtitle
    if `"`title'"' != "" {
        local graphtitle title(`title', size(medium) color(navy) margin(small))
    }

    twoway ///
        (pcspike tr_y tr_x tr_py tr_px if tr_parent, ///
            lcolor(gs9) lwidth(medthin)) ///
        (rbar tr_box_lo tr_box_hi tr_x if !tr_leaf, barwidth(.86) ///
            bcolor(gs14) lcolor(gs8) lwidth(medthin)) ///
        (rbar tr_box_lo tr_box_hi tr_x if tr_leaf & !tr_positive, ///
            barwidth(.86) bcolor(gs15) lcolor(gs7) lwidth(medthin)) ///
        (rbar tr_box_lo tr_box_hi tr_x if tr_leaf & tr_positive, ///
            barwidth(.86) bcolor(eltblue) lcolor(ebblue) lwidth(medthin)) ///
        (scatter tr_label_y tr_x if !tr_leaf, msymbol(none) ///
            mlabel(tr_label) mlabposition(0) mlabcolor(gs2) mlabsize(`font_size')) ///
        (scatter tr_sub_y tr_x if !tr_leaf, msymbol(none) ///
            mlabel(tr_sublabel) mlabposition(0) mlabcolor(gs5) mlabsize(`font_size')) ///
        (scatter tr_label_y tr_x if tr_leaf & !tr_positive, msymbol(none) ///
            mlabel(tr_label) mlabposition(0) mlabcolor(gs2) mlabsize(`font_size')) ///
        (scatter tr_sub_y tr_x if tr_leaf & !tr_positive, msymbol(none) ///
            mlabel(tr_sublabel) mlabposition(0) mlabcolor(gs5) mlabsize(`font_size')) ///
        (scatter tr_label_y tr_x if tr_leaf & tr_positive, msymbol(none) ///
            mlabel(tr_label) mlabposition(0) mlabcolor(white) mlabsize(`font_size')) ///
        (scatter tr_sub_y tr_x if tr_leaf & tr_positive, msymbol(none) ///
            mlabel(tr_sublabel) mlabposition(0) mlabcolor(white) mlabsize(`font_size')), ///
        xscale(range(`xmin' `xmax') off) yscale(range(`ymin' `ymax') off) ///
        xlabel(none, nogrid) ylabel(none, nogrid) xtitle("") ytitle("") ///
        legend(order(3 "P <= `cut_text'" 4 "P > `cut_text'") rows(1) ///
            position(6) ring(1) size(`font_size') ///
            region(lcolor(none) fcolor(none))) ///
        plotregion(margin(small) color(white) lcolor(none)) ///
        graphregion(color(white) margin(medsmall)) ///
        xsize(`xsize') ysize(`ysize') `graphtitle' `graphname'

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
