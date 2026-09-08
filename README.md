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
net install targetree, from("https://raw.githubusercontent.com/Bill-Wang-Metrics/targetree-stata/main") replace
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

targetree closed x1 x2, depth(4) minimum_portion(.05) method(mdfs) cut(.30)

predict double closure_risk
predict byte targeted, class
targetree_risk closed
targetree_print
targetree_plot, title("MDFS tree") font_size(medsmall) split_rule_lines(2)
```

The one-line model command can be pasted directly into Stata's Command window.
Examples that use `///` for line continuation must be run together from the
Do-file Editor; do not submit their lines separately in the Command window.

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
targetree closed beds margin region, depth(4) minimum_portion(.05) method(mdfs) cut(.35) categorical(region)
```


## Tree output

```stata
targetree_print
targetree_plot, saving("tree.gph") replace
```

`targetree_plot` saves Stata `.gph` files natively. It can also export formats
supported by the local Stata installation, such as PNG, PDF, or SVG. Plot size
is selected automatically from the tree, or can be overridden with
`xsize()` and `ysize()`. The default node boxes and graph dimensions provide
more room for labels, and targeted leaves use a dark blue fill with white text
for clear contrast. Every node has a dark, visible frame so that light boxes
remain distinct after resizing or printing. Use `font_size()` to set one
uniform Stata text size for all node labels and the legend; the default is
`medsmall`. Use
`split_rule_lines(1)` to keep each internal-node rule on one line or
`split_rule_lines(2)` to place the variable name and condition on separate
lines. Numerical rules use the mathematical symbol `≤`, and terminal nodes
report their mean as `μ`. For example:

```stata
targetree_plot, font_size(medsmall) split_rule_lines(2) saving("tree.pdf") replace
```

The `minimum_portion()` option is a terminal-node constraint: every terminal
node contains at least `ceil(minimum_portion * e(N))` observations.

Run `help targetree` in Stata for full command documentation.

## Replicating the Python empirical examples

The package includes Stata-native copies of the two datasets used in
`empirical_new.ipynb`. These examples use the same outcomes, predictors,
thresholds, depths, and minimum-portion settings as the Python workflow.

### Diabetes

This example uses the 768-observation Pima Indians diabetes data, sets
`Outcome` as the binary target, and uses `cut = 0.60` with depth 3. The PFS
model uses `lbd(.5)`, matching `lbd=0.5` in the Python notebook.

```stata
findfile targetree_diabetes.dta
use "`r(fn)'", clear
targetree outcome pregnancies glucose bloodpressure skinthickness insulin bmi diabetespedigreefunction age, depth(3) minimum_portion(.02) method(cart) cut(.60)
targetree_risk outcome
targetree_plot, title("CART") name(diabetes_cart) font_size(medsmall) split_rule_lines(2)
targetree outcome pregnancies glucose bloodpressure skinthickness insulin bmi diabetespedigreefunction age, depth(3) minimum_portion(.02) method(mdfs) cut(.60)
targetree_risk outcome
targetree_plot, title("MDFS") name(diabetes_mdfs) font_size(medsmall) split_rule_lines(2)
targetree outcome pregnancies glucose bloodpressure skinthickness insulin bmi diabetespedigreefunction age, depth(3) minimum_portion(.02) method(pfs) lbd(.5) cut(.60)
targetree_risk outcome
targetree_plot, title("PFS (lambda = 0.5)") name(diabetes_pfs) font_size(medsmall) split_rule_lines(2)
```

The complete runnable script is
[`targetree_diabetes_example.do`](targetree_diabetes_example.do).

Diabetes CART tree:

![CART tree for the diabetes example](examples/figures/diabetes-cart.png)

Diabetes MDFS tree:

![MDFS tree for the diabetes example](examples/figures/diabetes-mdfs.png)

Diabetes PFS tree (`lbd = 0.5`):

![PFS tree for the diabetes example](examples/figures/diabetes-pfs.png)

### Forest fires

This example uses the 517-observation forest-fires data, defines the target as
`area > 5`, and uses `cut = 1/3` with depth 3. As above, PFS uses
`lbd(.5)`.

```stata
findfile targetree_forestfires.dta
use "`r(fn)'", clear
generate byte fire_above_5 = area > 5
targetree fire_above_5 x y ffmc dmc dc isi temp rh wind rain, depth(3) minimum_portion(.02) method(cart) cut(.3333333333)
targetree_risk fire_above_5
targetree_plot, title("CART") name(forestfires_cart) font_size(medsmall) split_rule_lines(2)
targetree fire_above_5 x y ffmc dmc dc isi temp rh wind rain, depth(3) minimum_portion(.02) method(mdfs) cut(.3333333333)
targetree_risk fire_above_5
targetree_plot, title("MDFS") name(forestfires_mdfs) font_size(medsmall) split_rule_lines(2)
targetree fire_above_5 x y ffmc dmc dc isi temp rh wind rain, depth(3) minimum_portion(.02) method(pfs) lbd(.5) cut(.3333333333)
targetree_risk fire_above_5
targetree_plot, title("PFS (lambda = 0.5)") name(forestfires_pfs) font_size(medsmall) split_rule_lines(2)
```

The complete runnable script is
[`targetree_forestfires_example.do`](targetree_forestfires_example.do).

Forest-fire CART tree:

![CART tree for the forest-fires example](examples/figures/forestfires-cart.png)

Forest-fire MDFS tree:

![MDFS tree for the forest-fires example](examples/figures/forestfires-mdfs.png)

Forest-fire PFS tree (`lbd = 0.5`):

![PFS tree for the forest-fires example](examples/figures/forestfires-pfs.png)

The confusion-matrix counts reproduce the Python reference implementation:

| Dataset | Method | TP | FN | FP | TN |
|---|---|---:|---:|---:|---:|
| Diabetes | CART | 150 | 118 | 57 | 443 |
| Diabetes | MDFS | 160 | 108 | 63 | 437 |
| Diabetes | PFS (`lbd=.5`) | 160 | 108 | 63 | 437 |
| Forest fires | CART | 28 | 123 | 14 | 352 |
| Forest fires | MDFS | 53 | 98 | 55 | 311 |
| Forest fires | PFS (`lbd=.5`) | 49 | 102 | 47 | 319 |

## Development

Run the certification suite in batch mode or from Stata:

```stata
do tests/certify.do
```
