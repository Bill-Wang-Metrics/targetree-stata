{smcl}
{* *! version 0.1.8 08sep2026}{...}
{vieweralsosee "targetree" "help targetree"}{...}

{title:Title}

{phang}
{bf:targetree_plot} {hline 2} Plot a fitted targetree tree

{title:Syntax}

{p 8 17 2}
{cmd:targetree_plot} [{cmd:,} {opt title(string)} {opt name(name)}
{opt saving(filename)} {opt replace} {opt xsize(#)} {opt ysize(#)}
{opt font_size(size)} {opt split_rule_lines(#)}]

{title:Description}

{pstd}
Draws internal splits, terminal probabilities, and terminal sample sizes with
Stata graphics. A single font size is used for every node label and the
legend. Node boxes are generously sized for legibility. Leaves above
{cmd:e(cut)} use a dark blue fill with white text; other leaves are white.
All nodes have a clearly visible frame so that light boxes remain distinct
when the graph is resized or printed. The legend keys use the same framed
appearance as the corresponding terminal nodes.

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

{phang}
{opt font_size(size)} sets one common Stata graph text size for internal-node
rules, terminal-node statistics, and the legend. Named sizes such as
{cmd:vsmall}, {cmd:small}, {cmd:medsmall}, and {cmd:medium}, or a numeric Stata
size specification, are accepted. The default is {cmd:medsmall}.

{phang}
{opt split_rule_lines(#)} controls the layout of internal-node rules. Specify
{cmd:1} to display, for example, {cmd:x} {&le} {cmd:1.25} on one line, or
{cmd:2} to put the variable name and condition on separate lines. The default
is {cmd:2}.
Terminal-node statistics remain on two lines.

{title:Example}

{phang2}{cmd:. targetree_plot, title("MDFS tree") font_size(medsmall) split_rule_lines(2) saving("tree.pdf") replace}
