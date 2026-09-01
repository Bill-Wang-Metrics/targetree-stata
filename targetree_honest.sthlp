{smcl}
{* *! version 0.1.0 01sep2026}{...}
{vieweralsosee "targetree" "help targetree"}{...}

{title:Title}

{phang}
{bf:targetree_honest} {hline 2} Attach honest leaf estimates to a fitted tree

{title:Syntax}

{p 8 17 2}
{cmd:targetree_honest} {it:outcome} {ifin}

{title:Description}

{pstd}
Passes the supplied held-out observations through the existing tree and stores
their within-leaf outcome means. Empty leaves receive 0, matching the reference
implementation. The tree structure is unchanged.

{pstd}
Afterward, use {cmd:predict ..., honest} or
{cmd:targetree_risk ..., honest}. Running this command again replaces the
previous honest estimates.

