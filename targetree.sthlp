{smcl}
{* *! version 0.1.0 01sep2026}{...}
{vieweralsosee "targetree postestimation" "help targetree_postestimation"}{...}
{vieweralsosee "targetree_risk" "help targetree_risk"}{...}
{vieweralsosee "targetree_honest" "help targetree_honest"}{...}
{vieweralsosee "targetree_print" "help targetree_print"}{...}
{vieweralsosee "targetree_plot" "help targetree_plot"}{...}

{title:Title}

{phang}
{bf:targetree} {hline 2} Threshold-focused classification trees with CART,
PFS, and MDFS splitting

{title:Syntax}

{p 8 17 2}
{cmd:targetree} {it:depvar} {it:indepvars} {ifin}{cmd:,}
{opt depth(#)} {opt minimum_portion(#)}
[{opt method(name)} {opt cut(#)} {opt lbd(#)} {opt lambda(#)}
{opt categorical(varlist)} {opt prob(varname)}]

{title:Description}

{pstd}
{cmd:targetree} fits the threshold-focused tree implemented by the Python
targetree reference package. Ordinary levels use CART impurity splitting. At
the terminal split, PFS and MDFS can focus the partition on distance from a
policy threshold {cmd:cut()}.

{pstd}
The implementation is native Mata and has no Python or community-package
dependencies. The dependent variable and all predictors must be numeric.
Observations with missing estimation variables are omitted.

{title:Required options}

{phang}
{opt depth(#)} sets the maximum tree depth. A value of 0 returns one leaf.

{phang}
{opt minimum_portion(#)} sets the minimum fraction of the full estimation
sample required to attempt a split. It must lie in [0,1].

{title:Options}

{phang}
{opt method(name)} selects {cmd:cart}, {cmd:pfs}, or {cmd:mdfs}. The default
is {cmd:pfs}.

{phang}
{opt cut(#)} sets the threshold used for final-split selection and
classification. The default is 0.5.

{phang}
{opt lbd(#)} sets the PFS penalty weight. Its default is 0 for CART and PFS
and 1 for MDFS. CART requires 0; MDFS requires 1. {opt lambda()} is an alias.

{phang}
{opt categorical(varlist)} identifies numeric predictors that represent
categories. Splits search over category subsets. Use {cmd:encode} first for
string-valued categories.

{phang}
{opt prob(varname)} supplies continuous probabilities in [0,1] for
probability-assisted fitting. Ordinary splits and terminal estimates use this
variable; the final PFS/MDFS split uses {it:depvar}.

{title:Examples}

{phang2}{cmd:. targetree closed beds margin quality, depth(4) minimum_portion(.05) method(mdfs) cut(.35)}
{phang2}{cmd:. predict double closure_risk}
{phang2}{cmd:. predict byte targeted, class}
{phang2}{cmd:. targetree_risk closed}
{phang2}{cmd:. targetree_plot, title("Hospital closure tree")}

{title:Stored results}

{pstd}
{cmd:targetree} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(N)}}number of estimation observations{p_end}
{synopt:{cmd:e(depth)}}maximum depth{p_end}
{synopt:{cmd:e(minimum_portion)}}minimum sample fraction{p_end}
{synopt:{cmd:e(lbd)}}final-split penalty weight{p_end}
{synopt:{cmd:e(cut)}}classification threshold{p_end}
{synopt:{cmd:e(nnodes)}}number of tree nodes{p_end}
{synopt:{cmd:e(nleaves)}}number of terminal leaves{p_end}
{synopt:{cmd:e(method)}}selected method{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}predictor variables{p_end}
{synopt:{cmd:e(categorical)}}categorical predictors{p_end}
{synopt:{cmd:e(probvar)}}probability variable, if supplied{p_end}
{synopt:{cmd:e(honest)}}1 after honest estimates are attached; 0 otherwise{p_end}
{synopt:{cmd:e(tree)}}serialized node matrix{p_end}
{synopt:{cmd:e(catsets)}}serialized categorical split sets{p_end}

{title:Author}

{pstd}
Lei Bill Wang and targetree contributors

