# targetree for Stata

Native Stata/Mata implementation of classification trees with **PFS**
(Penalized Final Split) and **MDFS** (Maximum Distance Final Split), designed
for threshold-focused binary classification.

This repository ports the functionality of the Python
[`targetree`](https://github.com/lhy-0594/targetree) package to Stata. It has
no Python or community-package dependencies and supports Stata 16 or newer.

## Installation

While this repository is private, clone it and install from the local clone:

```bash
git clone git@github.com:Bill-Wang-Metrics/targetree-stata.git
```

Then run in Stata, replacing the path with the location of your clone:

```stata
net install targetree, from("/path/to/targetree-stata") replace
```

For development, you can load the cloned directory without installing:

```stata
adopath ++ "/path/to/targetree-stata"
```

If the repository becomes public, direct installation will work with:

```stata
net install targetree, ///
    from("https://raw.githubusercontent.com/Bill-Wang-Metrics/targetree-stata/main") ///
    replace
```

## Quick start

```stata
clear
set seed 42
set obs 500

generate double x1 = rnormal()
generate double x2 = rnormal()
generate double true_p = invlogit(x1 + x2)
generate byte closed = runiform() < true_p

targetree closed x1 x2, depth(4) minimum_portion(.05) ///
    method(mdfs) cut(.30)

predict double closure_risk
predict byte targeted, class
targetree_risk closed
targetree_print
targetree_plot, title("MDFS tree")
```

## Methods

| `method()` | Default `lbd()` | Description |
|---|---:|---|
| `cart` | 0 | Standard CART impurity splitting |
| `pfs` | 0 | Penalized Final Split with user-selected `lbd()` |
| `mdfs` | 1 | Maximum Distance Final Split |

## Categorical predictors

Stata stores categorical values as numeric codes. Include their variable names
in `categorical()` so that targetree searches over category subsets instead of
numeric cut points. Encode string variables first if needed.

```stata
encode region_name, generate(region)
targetree closed beds margin region, depth(4) minimum_portion(.05) ///
    method(mdfs) cut(.35) categorical(region)
```

## Probability-assisted fitting

Pass a variable containing continuous probabilities in `[0,1]` to `prob()`:

```stata
targetree closed x1 x2, depth(4) minimum_portion(.05) ///
    method(pfs) lbd(.5) cut(.35) prob(calibrated_probability)
```

Ordinary splits and terminal estimates use the probability variable; the final
PFS/MDFS split uses the observed outcome, matching the reference package.

## Honest estimation

Fit on the tree-building sample, attach leaf estimates from a held-out sample,
and request honest predictions:

```stata
targetree closed x1 x2 if build_sample, depth(4) ///
    minimum_portion(.05) method(mdfs) cut(.35)
targetree_honest closed if honest_sample
predict double honest_risk, honest
targetree_risk closed if test_sample, honest
```

## Tree output

```stata
targetree_print
targetree_plot, saving("tree.gph") replace
```

`targetree_plot` saves Stata `.gph` files natively. It can also export formats
supported by the local Stata installation, such as PNG, PDF, or SVG.

Run `help targetree` in Stata for full command documentation.

## Development

Run the certification suite in batch mode or from Stata:

```stata
do tests/certify.do
```

