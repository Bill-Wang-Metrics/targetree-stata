version 16.0
clear all
set more off
set seed 42
set obs 500

generate double x1 = rnormal()
generate double x2 = rnormal()
generate double true_p = invlogit(x1 + x2)
generate byte closed = runiform() < true_p

* Maximum Distance Final Split.
targetree closed x1 x2, depth(4) minimum_portion(.05) ///
    method(mdfs) cut(.30)
predict double closure_risk
predict byte targeted, class
targetree_risk closed
targetree_print
targetree_plot, title("MDFS tree")

* Probability-assisted Penalized Final Split.
targetree closed x1 x2, depth(4) minimum_portion(.05) ///
    method(pfs) lbd(.5) cut(.30) prob(true_p)
predict double assisted_risk

* Honest leaf estimation using a sample split.
generate byte build_sample = _n <= 300
generate byte honest_sample = inrange(_n, 301, 400)
generate byte test_sample = _n > 400

targetree closed x1 x2 if build_sample, depth(4) ///
    minimum_portion(.05) method(mdfs) cut(.30)
targetree_honest closed if honest_sample
predict double honest_risk, honest
targetree_risk closed if test_sample, honest

