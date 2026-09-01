*! version 0.1.0 01sep2026
version 16.0

mata:

struct targetree_model {
    real scalar depth
    real scalar minimum_portion
    real scalar lbd
    real scalar cut
    real scalar min_samples
    real scalar mmin_samples
    string scalar method
    string rowvector feature_names
    real rowvector is_categorical
    real matrix nodes
    real matrix catsets
}

targetree_current = targetree_model()

real scalar targetree_version()
{
    return(100)
}

real scalar tr_choose_index(real colvector objective,
                            real colvector left_count,
                            real scalar n)
{
    real scalar i, lower, upper, largest0, smallest0, start, finish
    real colvector candidates
    real matrix ranked

    if (rows(objective) <= 10) {
        ranked = order((objective, (1::rows(objective))), (1, 2))
        return(ranked[1])
    }

    lower = floor(0.1 * n)
    upper = floor(0.9 * n)
    largest0 = 0
    smallest0 = .
    for (i = 1; i <= rows(left_count); i++) {
        if (left_count[i] <= lower) largest0 = i - 1
        else if (left_count[i] >= upper & missing(smallest0)) smallest0 = i - 1
    }

    start = largest0 + 1
    finish = missing(smallest0) ? rows(objective) : smallest0
    if (start > finish) {
        ranked = order((objective, (1::rows(objective))), (1, 2))
        return(ranked[1])
    }
    candidates = (start::finish)
    ranked = order((objective[candidates], candidates), (1, 2))
    return(candidates[ranked[1]])
}

void tr_numerical_candidates(real colvector x,
                             real colvector y,
                             real colvector xs,
                             real colvector lc,
                             real colvector ls,
                             real colvector lsq)
{
    real scalar i, n
    real colvector ord, ys, positions, cumulative_sum, cumulative_sq

    n = rows(x)
    ord = order(x, 1)
    xs = x[ord]
    ys = y[ord]
    positions = J(0, 1, .)
    for (i = 1; i < n; i++) {
        if (xs[i] != xs[i + 1]) positions = positions \ i
    }
    if (!rows(positions)) {
        lc = ls = lsq = J(0, 1, .)
        return
    }
    cumulative_sum = runningsum(ys)
    cumulative_sq = runningsum(ys:^2)
    lc = positions
    ls = cumulative_sum[positions]
    lsq = cumulative_sq[positions]
}

void tr_best_split_numerical(real colvector x,
                             real colvector y,
                             real scalar threshold,
                             real scalar impurity)
{
    real scalar n, sum_y, sum_y2, index, position
    real colvector xs, lc, ls, lsq, rc, left_var, right_var, objective

    threshold = impurity = .
    n = rows(y)
    tr_numerical_candidates(x, y, xs, lc, ls, lsq)
    if (!rows(lc)) return
    sum_y = sum(y)
    sum_y2 = sum(y:^2)
    rc = J(rows(lc), 1, n) - lc
    left_var = lsq :/ lc - (ls :/ lc):^2
    right_var = (J(rows(lc), 1, sum_y2) - lsq) :/ rc -
                ((J(rows(lc), 1, sum_y) - ls) :/ rc):^2
    objective = (left_var :* lc + right_var :* rc) * 2
    index = tr_choose_index(objective, lc, n)
    position = lc[index]
    threshold = (xs[position] + xs[position + 1]) / 2
    impurity = objective[index]
}

void tr_best_split_categorical(real colvector x,
                               real colvector y,
                               real scalar threshold,
                               real scalar impurity,
                               real colvector catset)
{
    real scalar j, k, n, sum_y, sum_y2, index
    real colvector categories, counts, totals, totals2, means, ord
    real colvector lc, ls, lsq, rc, left_var, right_var, objective

    threshold = impurity = .
    catset = J(0, 1, .)
    categories = uniqrows(sort(x, 1))
    k = rows(categories)
    if (k <= 1) return
    n = rows(y)
    counts = totals = totals2 = J(k, 1, 0)
    for (j = 1; j <= k; j++) {
        counts[j] = sum(x :== categories[j])
        totals[j] = sum(select(y, x :== categories[j]))
        totals2[j] = sum(select(y:^2, x :== categories[j]))
    }
    means = totals :/ counts
    ord = order((means, categories), (1, 2))
    counts = counts[ord]
    totals = totals[ord]
    totals2 = totals2[ord]
    lc = runningsum(counts)
    ls = runningsum(totals)
    lsq = runningsum(totals2)
    lc = lc[|1 \ k - 1|]
    ls = ls[|1 \ k - 1|]
    lsq = lsq[|1 \ k - 1|]
    rc = J(rows(lc), 1, n) - lc
    sum_y = sum(y)
    sum_y2 = sum(y:^2)
    left_var = lsq :/ lc - (ls :/ lc):^2
    right_var = (J(rows(lc), 1, sum_y2) - lsq) :/ rc -
                ((J(rows(lc), 1, sum_y) - ls) :/ rc):^2
    objective = (left_var :* lc + right_var :* rc) * 2
    index = tr_choose_index(objective, lc, n)
    catset = categories[ord[|1 \ index|]]
    impurity = objective[index]
}

void tr_best_split(struct targetree_model scalar model,
                   real matrix X,
                   real colvector y,
                   real scalar feature,
                   real scalar threshold,
                   real scalar categorical,
                   real colvector catset)
{
    real scalar j, trial_threshold, trial_impurity, best_impurity
    real colvector trial_catset

    feature = threshold = categorical = .
    catset = J(0, 1, .)
    best_impurity = .
    for (j = 1; j <= cols(X); j++) {
        if (rows(uniqrows(sort(X[, j], 1))) <= 1) continue
        trial_catset = J(0, 1, .)
        if (model.is_categorical[j]) {
            tr_best_split_categorical(X[, j], y, trial_threshold,
                                      trial_impurity, trial_catset)
        }
        else {
            tr_best_split_numerical(X[, j], y, trial_threshold, trial_impurity)
        }
        if (missing(trial_impurity)) continue
        if (missing(best_impurity) | trial_impurity < best_impurity) {
            feature = j
            threshold = trial_threshold
            categorical = model.is_categorical[j]
            catset = trial_catset
            best_impurity = trial_impurity
        }
    }
}

void tr_best_final_split(struct targetree_model scalar model,
                         real colvector x,
                         real colvector y,
                         real scalar categorical,
                         real scalar threshold,
                         real colvector catset)
{
    real scalar j, k, n, index, position, sum_y, sum_y2
    real colvector categories, counts, totals, means
    real colvector xs, lc, ls, lsq, rc, lp, rp, objective

    threshold = .
    catset = J(0, 1, .)
    if (categorical) {
        categories = uniqrows(sort(x, 1))
        k = rows(categories)
        counts = totals = J(k, 1, 0)
        for (j = 1; j <= k; j++) {
            counts[j] = sum(x :== categories[j])
            totals[j] = sum(select(y, x :== categories[j]))
        }
        means = totals :/ counts
        catset = select(categories, means :> model.cut)
        return
    }

    n = rows(y)
    tr_numerical_candidates(x, y, xs, lc, ls, lsq)
    if (!rows(lc)) return
    rc = J(rows(lc), 1, n) - lc
    sum_y = sum(y)
    sum_y2 = sum(y:^2)
    lp = lsq :/ lc
    rp = (J(rows(lc), 1, sum_y2) - lsq) :/ rc
    objective = ((lp - (ls :/ lc):^2) :* lc +
                 (rp - ((J(rows(lc), 1, sum_y) - ls) :/ rc):^2) :* rc) *
                 (1 - model.lbd) +
                (-abs(J(rows(lc), 1, model.cut) - lp) :* lc -
                 abs(J(rows(lc), 1, model.cut) - rp) :* rc) * model.lbd
    index = tr_choose_index(objective, lc, n)
    position = lc[index]
    threshold = (xs[position] + xs[position + 1]) / 2
}

real colvector tr_left_mask(real colvector x,
                            real scalar threshold,
                            real scalar categorical,
                            real colvector catset)
{
    real scalar j
    real colvector left

    if (!categorical) return(x :<= threshold)
    left = J(rows(x), 1, 0)
    for (j = 1; j <= rows(catset); j++) left = left :| (x :== catset[j])
    return(left)
}

real scalar tr_add_leaf(struct targetree_model scalar model,
                        real colvector values,
                        real scalar depth)
{
    real rowvector row
    row = (1, ., ., 0, mean(values), rows(values), ., ., ., depth)
    model.nodes = model.nodes \ row
    return(rows(model.nodes))
}

real scalar tr_add_node(struct targetree_model scalar model,
                        real scalar feature,
                        real scalar threshold,
                        real scalar categorical,
                        real colvector catset,
                        real scalar depth)
{
    real scalar index
    real rowvector row

    row = (0, feature, threshold, categorical, ., ., ., ., ., depth)
    model.nodes = model.nodes \ row
    index = rows(model.nodes)
    if (categorical & rows(catset)) {
        model.catsets = model.catsets \ (J(rows(catset), 1, index), catset)
    }
    return(index)
}

real scalar tr_grow(struct targetree_model scalar model,
                    real matrix X,
                    real colvector y,
                    real scalar depth)
{
    real scalar feature, threshold, categorical, node, left_node, right_node
    real scalar at_leaf
    real colvector catset, final_catset, left, right

    if (depth == model.depth |
        rows(uniqrows(sort(y, 1))) == 1 |
        rows(y) < model.min_samples) return(tr_add_leaf(model, y, depth))

    tr_best_split(model, X, y, feature, threshold, categorical, catset)
    if (missing(feature)) return(tr_add_leaf(model, y, depth))
    left = tr_left_mask(X[, feature], threshold, categorical, catset)
    right = !left
    if (min((sum(left), sum(right))) < model.mmin_samples) {
        return(tr_add_leaf(model, y, depth))
    }

    at_leaf = depth == model.depth - 1 |
              min((sum(left), sum(right))) < model.min_samples
    if (at_leaf & model.method != "cart") {
        tr_best_final_split(model, X[, feature], y, categorical,
                            threshold, final_catset)
        if (!categorical & missing(threshold)) return(tr_add_leaf(model, y, depth))
        catset = final_catset
        left = tr_left_mask(X[, feature], threshold, categorical, catset)
        right = !left
        if (min((sum(left), sum(right))) < model.mmin_samples) {
            return(tr_add_leaf(model, y, depth))
        }
        node = tr_add_node(model, feature, threshold, categorical, catset, depth)
        left_node = tr_add_leaf(model, select(y, left), depth + 1)
        right_node = tr_add_leaf(model, select(y, right), depth + 1)
        model.nodes[node, 8] = left_node
        model.nodes[node, 9] = right_node
        return(node)
    }

    node = tr_add_node(model, feature, threshold, categorical, catset, depth)
    left_node = tr_grow(model, select(X, left), select(y, left), depth + 1)
    right_node = tr_grow(model, select(X, right), select(y, right), depth + 1)
    model.nodes[node, 8] = left_node
    model.nodes[node, 9] = right_node
    return(node)
}

real scalar tr_grow_prob(struct targetree_model scalar model,
                         real matrix X,
                         real colvector y,
                         real colvector p,
                         real scalar depth)
{
    real scalar feature, threshold, categorical, node, left_node, right_node
    real scalar at_leaf
    real colvector catset, final_catset, left, right

    if (depth == model.depth | min(p) > model.cut | max(p) < model.cut |
        rows(y) < model.min_samples) return(tr_add_leaf(model, p, depth))

    tr_best_split(model, X, p, feature, threshold, categorical, catset)
    if (missing(feature)) return(tr_add_leaf(model, p, depth))
    left = tr_left_mask(X[, feature], threshold, categorical, catset)
    right = !left
    if (min((sum(left), sum(right))) < model.mmin_samples) {
        return(tr_add_leaf(model, p, depth))
    }

    at_leaf = depth == model.depth - 1 |
              min((sum(left), sum(right))) < model.min_samples
    if (at_leaf & model.method != "cart") {
        tr_best_final_split(model, X[, feature], y, categorical,
                            threshold, final_catset)
        if (!categorical & missing(threshold)) return(tr_add_leaf(model, p, depth))
        catset = final_catset
        left = tr_left_mask(X[, feature], threshold, categorical, catset)
        right = !left
        if (min((sum(left), sum(right))) < model.mmin_samples) {
            return(tr_add_leaf(model, p, depth))
        }
        node = tr_add_node(model, feature, threshold, categorical, catset, depth)
        left_node = tr_add_leaf(model, select(p, left), depth + 1)
        right_node = tr_add_leaf(model, select(p, right), depth + 1)
        model.nodes[node, 8] = left_node
        model.nodes[node, 9] = right_node
        return(node)
    }

    node = tr_add_node(model, feature, threshold, categorical, catset, depth)
    left_node = tr_grow_prob(model, select(X, left), select(y, left),
                             select(p, left), depth + 1)
    right_node = tr_grow_prob(model, select(X, right), select(y, right),
                              select(p, right), depth + 1)
    model.nodes[node, 8] = left_node
    model.nodes[node, 9] = right_node
    return(node)
}

void targetree_fit_stata(string scalar depvar,
                         string scalar xvars,
                         string scalar touse,
                         real scalar depth,
                         real scalar minimum_portion,
                         real scalar lbd,
                         real scalar cut,
                         string scalar method,
                         string scalar categorical_indices,
                         string scalar probvar,
                         string scalar nodes_name,
                         string scalar cats_name)
{
    external struct targetree_model scalar targetree_current
    struct targetree_model scalar model
    real scalar n, j, root
    real matrix X, catsout
    real colvector y, p, catidx

    X = st_data(., tokens(xvars), touse)
    y = st_data(., depvar, touse)
    n = rows(y)
    model.depth = depth
    model.minimum_portion = minimum_portion
    model.lbd = lbd
    model.cut = cut
    model.method = method
    model.feature_names = tokens(xvars)
    model.min_samples = floor(minimum_portion * n)
    model.mmin_samples = floor(minimum_portion * n / 3)
    model.is_categorical = J(1, cols(X), 0)
    if (strtrim(categorical_indices) != "") {
        catidx = strtoreal(tokens(categorical_indices))'
        for (j = 1; j <= rows(catidx); j++) model.is_categorical[catidx[j]] = 1
    }
    model.nodes = J(0, 10, .)
    model.catsets = J(0, 2, .)
    if (strtrim(probvar) == "") root = tr_grow(model, X, y, 0)
    else {
        p = st_data(., probvar, touse)
        root = tr_grow_prob(model, X, y, p, 0)
    }
    targetree_current = model
    st_matrix(nodes_name, model.nodes)
    catsout = rows(model.catsets) ? model.catsets : (., .)
    st_matrix(cats_name, catsout)
    st_numscalar("__tr_N", n)
    st_numscalar("__tr_nnodes", rows(model.nodes))
    st_numscalar("__tr_nleaves", sum(model.nodes[, 1] :== 1))
}

void targetree_restore_stata(string scalar nodes_name,
                             string scalar cats_name,
                             real scalar depth,
                             real scalar minimum_portion,
                             real scalar lbd,
                             real scalar cut,
                             string scalar method,
                             string scalar feature_names,
                             string scalar categorical_indices)
{
    external struct targetree_model scalar targetree_current
    struct targetree_model scalar model
    real scalar j
    real colvector catidx

    model.nodes = st_matrix(nodes_name)
    model.catsets = st_matrix(cats_name)
    if (rows(model.catsets) == 1 & missing(model.catsets[1, 1])) {
        model.catsets = J(0, 2, .)
    }
    model.depth = depth
    model.minimum_portion = minimum_portion
    model.lbd = lbd
    model.cut = cut
    model.method = method
    model.feature_names = tokens(feature_names)
    model.is_categorical = J(1, length(model.feature_names), 0)
    if (strtrim(categorical_indices) != "") {
        catidx = strtoreal(tokens(categorical_indices))'
        for (j = 1; j <= rows(catidx); j++) model.is_categorical[catidx[j]] = 1
    }
    targetree_current = model
}

real colvector tr_node_catset(struct targetree_model scalar model,
                              real scalar node)
{
    if (!rows(model.catsets)) return(J(0, 1, .))
    return(select(model.catsets[, 2], model.catsets[, 1] :== node))
}

real scalar tr_predict_one(struct targetree_model scalar model,
                           real rowvector x,
                           real scalar honest)
{
    real scalar node, go_left
    real colvector catset

    node = 1
    while (model.nodes[node, 1] == 0) {
        if (model.nodes[node, 4]) {
            catset = tr_node_catset(model, node)
            go_left = any(x[model.nodes[node, 2]] :== catset)
        }
        else go_left = x[model.nodes[node, 2]] <= model.nodes[node, 3]
        node = go_left ? model.nodes[node, 8] : model.nodes[node, 9]
    }
    if (honest) {
        if (missing(model.nodes[node, 7])) {
            errprintf("honest estimates are unavailable; run targetree_honest first\n")
            _error(498)
        }
        return(model.nodes[node, 7])
    }
    return(model.nodes[node, 5])
}

real colvector tr_predict_matrix(struct targetree_model scalar model,
                                 real matrix X,
                                 real scalar honest)
{
    real scalar i
    real colvector result
    result = J(rows(X), 1, .)
    for (i = 1; i <= rows(X); i++) result[i] = tr_predict_one(model, X[i, .], honest)
    return(result)
}

void targetree_predict_stata(string scalar xvars,
                             string scalar touse,
                             string scalar newvar,
                             real scalar honest,
                             real scalar classification)
{
    external struct targetree_model scalar targetree_current
    real matrix X
    real colvector estimate
    X = st_data(., tokens(xvars), touse)
    estimate = tr_predict_matrix(targetree_current, X, honest)
    if (classification) estimate = estimate :> targetree_current.cut
    st_store(., newvar, touse, estimate)
}

void targetree_risk_stata(string scalar depvar,
                          string scalar xvars,
                          string scalar touse,
                          real scalar honest)
{
    external struct targetree_model scalar targetree_current
    real matrix X
    real colvector y, estimate, above, predicted_above
    X = st_data(., tokens(xvars), touse)
    y = st_data(., depvar, touse)
    estimate = tr_predict_matrix(targetree_current, X, honest)
    above = y :> targetree_current.cut
    predicted_above = estimate :> targetree_current.cut
    st_numscalar("__tr_tp", sum(predicted_above :& above))
    st_numscalar("__tr_fn", sum((!predicted_above) :& above))
    st_numscalar("__tr_fp", sum(predicted_above :& (!above)))
    st_numscalar("__tr_tn", sum((!predicted_above) :& (!above)))
}

real scalar tr_leaf_index(struct targetree_model scalar model,
                          real rowvector x)
{
    real scalar node, go_left
    real colvector catset
    node = 1
    while (model.nodes[node, 1] == 0) {
        if (model.nodes[node, 4]) {
            catset = tr_node_catset(model, node)
            go_left = any(x[model.nodes[node, 2]] :== catset)
        }
        else go_left = x[model.nodes[node, 2]] <= model.nodes[node, 3]
        node = go_left ? model.nodes[node, 8] : model.nodes[node, 9]
    }
    return(node)
}

void targetree_honest_stata(string scalar depvar,
                            string scalar xvars,
                            string scalar touse,
                            string scalar nodes_name)
{
    external struct targetree_model scalar targetree_current
    real scalar i, node
    real matrix X
    real colvector y, leaf_index, selected

    X = st_data(., tokens(xvars), touse)
    y = st_data(., depvar, touse)
    leaf_index = J(rows(X), 1, .)
    for (i = 1; i <= rows(X); i++) leaf_index[i] = tr_leaf_index(targetree_current, X[i, .])
    for (node = 1; node <= rows(targetree_current.nodes); node++) {
        if (targetree_current.nodes[node, 1] == 1) {
            selected = leaf_index :== node
            targetree_current.nodes[node, 7] = sum(selected) ?
                mean(select(y, selected)) : 0
        }
    }
    st_matrix(nodes_name, targetree_current.nodes)
}

string scalar tr_indent(real scalar depth)
{
    real scalar i
    string scalar indent
    indent = ""
    for (i = 1; i <= depth; i++) indent = indent + "  "
    return(indent)
}

void tr_print_node(struct targetree_model scalar model,
                   real scalar node,
                   real scalar depth)
{
    real colvector catset
    string scalar label
    if (model.nodes[node, 1] == 1) {
        printf("%sLeaf: mean=%6.3f, n=%g\n", tr_indent(depth),
               model.nodes[node, 5], model.nodes[node, 6])
        return
    }
    if (model.nodes[node, 4]) {
        catset = tr_node_catset(model, node)
        label = invtokens(strofreal(catset'))
        printf("%s[%s in {%s}]\n", tr_indent(depth),
               model.feature_names[model.nodes[node, 2]], label)
    }
    else {
        printf("%s[%s <= %7.4f]\n", tr_indent(depth),
               model.feature_names[model.nodes[node, 2]], model.nodes[node, 3])
    }
    tr_print_node(model, model.nodes[node, 8], depth + 1)
    tr_print_node(model, model.nodes[node, 9], depth + 1)
}

void targetree_print_stata()
{
    external struct targetree_model scalar targetree_current
    tr_print_node(targetree_current, 1, 0)
}

real scalar tr_assign_positions(struct targetree_model scalar model,
                                real scalar node,
                                real scalar depth,
                                real matrix positions,
                                real scalar counter)
{
    real scalar x, left_x, right_x
    if (model.nodes[node, 1] == 1) {
        counter = counter + 1
        x = counter
    }
    else {
        left_x = tr_assign_positions(model, model.nodes[node, 8], depth + 1,
                                     positions, counter)
        right_x = tr_assign_positions(model, model.nodes[node, 9], depth + 1,
                                      positions, counter)
        x = (left_x + right_x) / 2
    }
    positions[node, .] = (x, -depth)
    return(x)
}

void targetree_plot_data_stata()
{
    external struct targetree_model scalar targetree_current
    real scalar n, node, parent_node, counter, root_x, string_index
    real matrix positions, values
    real rowvector numeric_indices
    real colvector parents, catset
    string colvector labels
    string scalar catlabel

    n = rows(targetree_current.nodes)
    positions = J(n, 2, .)
    parents = J(n, 1, .)
    counter = 0
    root_x = tr_assign_positions(targetree_current, 1, 0, positions, counter)
    for (node = 1; node <= n; node++) {
        if (targetree_current.nodes[node, 1] == 0) {
            parents[targetree_current.nodes[node, 8]] = node
            parents[targetree_current.nodes[node, 9]] = node
        }
    }

    values = J(n, 9, .)
    labels = J(n, 1, "")
    for (node = 1; node <= n; node++) {
        parent_node = parents[node]
        values[node, 1] = positions[node, 1]
        values[node, 2] = positions[node, 2]
        values[node, 3] = missing(parent_node) ? . : positions[parent_node, 1]
        values[node, 4] = missing(parent_node) ? . : positions[parent_node, 2]
        values[node, 5] = !missing(parent_node)
        values[node, 6] = targetree_current.nodes[node, 1]
        values[node, 7] = targetree_current.nodes[node, 1] ?
                          targetree_current.nodes[node, 5] > targetree_current.cut : 0
        values[node, 8] = node
        values[node, 9] = targetree_current.nodes[node, 10]
        if (targetree_current.nodes[node, 1]) {
            labels[node] = sprintf("P=%7.4f; N=%g",
                                   targetree_current.nodes[node, 5],
                                   targetree_current.nodes[node, 6])
        }
        else if (targetree_current.nodes[node, 4]) {
            catset = tr_node_catset(targetree_current, node)
            catlabel = invtokens(strofreal(catset'), ",")
            labels[node] = sprintf("%s in {%s}",
                                   targetree_current.feature_names[targetree_current.nodes[node, 2]],
                                   catlabel)
        }
        else {
            labels[node] = sprintf("%s <= %7.4f",
                                   targetree_current.feature_names[targetree_current.nodes[node, 2]],
                                   targetree_current.nodes[node, 3])
        }
    }

    st_addobs(n)
    numeric_indices = st_addvar("double", ("tr_x", "tr_y", "tr_px", "tr_py", "tr_parent",
                         "tr_leaf", "tr_positive", "tr_node", "tr_depth"))
    string_index = st_addvar("str244", "tr_label")
    st_store(., ("tr_x", "tr_y", "tr_px", "tr_py", "tr_parent",
                 "tr_leaf", "tr_positive", "tr_node", "tr_depth"), values)
    st_sstore(., "tr_label", labels)
}

end
