*! version 0.1.1 01sep2026
program define _targetree_load
    version 16.0
    capture quietly mata: assert(targetree_version() == 100)
    if _rc {
        quietly findfile targetree.mata
        quietly do "`r(fn)'"
    }
end
