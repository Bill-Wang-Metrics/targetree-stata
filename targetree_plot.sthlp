{smcl}
{* *! version 0.1.1 01sep2026}{...}
{vieweralsosee "targetree" "help targetree"}{...}

{title:Title}

{phang}
{bf:targetree_plot} {hline 2} Plot a fitted targetree tree

{title:Syntax}

{p 8 17 2}
{cmd:targetree_plot} [{cmd:,} {opt title(string)} {opt name(name)}
{opt saving(filename)} {opt replace} {opt xsize(#)} {opt ysize(#)}]

{title:Description}

{pstd}
Draws internal splits, terminal probabilities, and terminal sample sizes with
Stata graphics. Leaves above {cmd:e(cut)} are blue; other leaves are white.

{title:Options}

{phang}
{opt title(string)} adds a graph title.

{phang}
{opt name(name)} names the graph in memory. An existing graph with that name
is replaced.

{phang}
{opt saving(filename)} saves the graph. A {cmd:.gph} suffix uses Stata's native
graph format; other suffixes are passed to {cmd:graph export}.

{phang}
{opt replace} permits an existing output file to be replaced.

{phang}
{opt xsize(#)} and {opt ysize(#)} set graph dimensions in inches. If omitted,
dimensions are selected automatically from the number of leaves and tree depth.

{title:Example}

{phang2}{cmd:. targetree_plot, title("MDFS tree") saving("tree.gph") replace}
