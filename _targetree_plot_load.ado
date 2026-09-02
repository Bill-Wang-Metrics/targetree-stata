*! version 0.1.1 01sep2026
program define _targetree_plot_load
    version 16.0
    capture quietly mata: assert(targetree_plot_version() == 200)
    if _rc {
        quietly findfile targetree_plot_v2.mata
        quietly do "`r(fn)'"
    }
end

