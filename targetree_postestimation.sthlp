{smcl}
{* *! version 0.1.0 01sep2026}{...}
{vieweralsosee "targetree" "help targetree"}{...}

{title:Title}

{phang}
{bf:targetree postestimation} {hline 2} Predictions after targetree

{title:Syntax for predict}

{p 8 17 2}
{cmd:predict} [{it:type}] {it:newvar} {ifin} [{cmd:,} {opt class} {opt honest}]

{title:Options}

{phang}
{opt class} stores a 0/1 classification using the strict rule predicted
probability > {cmd:e(cut)}. Without this option, {cmd:predict} stores leaf
probabilities.

{phang}
{opt honest} uses held-out leaf means attached by {help targetree_honest}.
An error is issued if honest estimates have not been attached.

{title:Examples}

{phang2}{cmd:. predict double risk}
{phang2}{cmd:. predict byte targeted, class}
{phang2}{cmd:. predict double honest_risk, honest}

{title:Other postestimation commands}

{pstd}
See {help targetree_risk}, {help targetree_honest}, {help targetree_print}, and
{help targetree_plot}.

