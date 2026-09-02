{smcl}
{* *! version 0.1.1 01sep2026}{...}
{vieweralsosee "targetree" "help targetree"}{...}

{title:Title}

{phang}
{bf:targetree_risk} {hline 2} Confusion-matrix counts and metrics after targetree

{title:Syntax}

{p 8 17 2}
{cmd:targetree_risk} {it:outcome} {ifin} [{cmd:,} {opt honest}]

{title:Description}

{pstd}
Classifies both the supplied outcome and the tree estimate with the strict
rule value > {cmd:e(cut)}. It reports true positives, false negatives, false
positives, true negatives, accuracy, true-positive rate, and precision.

{phang}
{opt honest} evaluates honest leaf estimates previously attached with
{help targetree_honest}.

{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(TP)}}true positives{p_end}
{synopt:{cmd:r(FN)}}false negatives{p_end}
{synopt:{cmd:r(FP)}}false positives{p_end}
{synopt:{cmd:r(TN)}}true negatives{p_end}
{synopt:{cmd:r(N)}}evaluated observations{p_end}
{synopt:{cmd:r(accuracy)}}accuracy{p_end}
{synopt:{cmd:r(tpr)}}true-positive rate{p_end}
{synopt:{cmd:r(precision)}}precision{p_end}
