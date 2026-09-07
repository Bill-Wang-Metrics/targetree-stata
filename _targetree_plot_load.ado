*! version 0.1.4 07sep2026
program define _targetree_plot_load
    version 16.0
    capture quietly mata: assert(targetree_plot_version() == 202)
    if _rc {
        capture quietly mata: mata drop targetree_plot_version()
        capture quietly mata: mata drop tr_assign_positions_v2()
        capture quietly mata: mata drop targetree_plot_data_stata_v2()
        quietly findfile targetree_plot_v2.mata
        quietly do "`r(fn)'"
    }
end
