*! version 0.1.4 07sep2026
version 16.0

mata:

real scalar targetree_plot_version()
{
    return(202)
}

real scalar tr_assign_positions_v2(struct targetree_model scalar model,
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
        left_x = tr_assign_positions_v2(model, model.nodes[node, 8], depth + 1,
                                        positions, counter)
        right_x = tr_assign_positions_v2(model, model.nodes[node, 9], depth + 1,
                                         positions, counter)
        x = (left_x + right_x) / 2
    }
    positions[node, .] = (x, -1.4 * depth)
    return(x)
}

void targetree_plot_data_stata_v2(real scalar split_rule_lines)
{
    external struct targetree_model scalar targetree_current
    real scalar n, node, parent_node, counter, root_x, string_index
    real matrix positions, values
    real rowvector numeric_indices
    real colvector parents, catset
    string colvector labels, sublabels
    string scalar catlabel

    n = rows(targetree_current.nodes)
    positions = J(n, 2, .)
    parents = J(n, 1, .)
    counter = 0
    root_x = tr_assign_positions_v2(targetree_current, 1, 0, positions, counter)
    for (node = 1; node <= n; node++) {
        if (targetree_current.nodes[node, 1] == 0) {
            parents[targetree_current.nodes[node, 8]] = node
            parents[targetree_current.nodes[node, 9]] = node
        }
    }

    values = J(n, 13, .)
    labels = J(n, 1, "")
    sublabels = J(n, 1, "")
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
        values[node, 10] = positions[node, 2] - 0.20
        values[node, 11] = positions[node, 2] + 0.20
        values[node, 12] = positions[node, 2] +
                           (split_rule_lines == 2 ? 0.07 : 0)
        values[node, 13] = positions[node, 2] - 0.09
        if (targetree_current.nodes[node, 1]) {
            labels[node] = sprintf("P=%6.4f", targetree_current.nodes[node, 5])
            sublabels[node] = sprintf("N=%g", targetree_current.nodes[node, 6])
        }
        else if (targetree_current.nodes[node, 4]) {
            catset = tr_node_catset(targetree_current, node)
            catlabel = invtokens(strofreal(catset'), ",")
            if (split_rule_lines == 1) {
                labels[node] = sprintf("%s in {%s}",
                    targetree_current.feature_names[targetree_current.nodes[node, 2]],
                    catlabel)
            }
            else {
                labels[node] = targetree_current.feature_names[targetree_current.nodes[node, 2]]
                sublabels[node] = sprintf("in {%s}", catlabel)
            }
        }
        else {
            if (split_rule_lines == 1) {
                labels[node] = sprintf("%s <= %7.4f",
                    targetree_current.feature_names[targetree_current.nodes[node, 2]],
                    targetree_current.nodes[node, 3])
            }
            else {
                labels[node] = targetree_current.feature_names[targetree_current.nodes[node, 2]]
                sublabels[node] = sprintf("<= %7.4f", targetree_current.nodes[node, 3])
            }
        }
    }

    st_addobs(n)
    numeric_indices = st_addvar("double", ("tr_x", "tr_y", "tr_px", "tr_py",
                         "tr_parent", "tr_leaf", "tr_positive", "tr_node",
                         "tr_depth", "tr_box_lo", "tr_box_hi", "tr_label_y",
                         "tr_sub_y"))
    string_index = st_addvar("str244", "tr_label")
    string_index = st_addvar("str244", "tr_sublabel")
    st_store(., ("tr_x", "tr_y", "tr_px", "tr_py", "tr_parent", "tr_leaf",
                 "tr_positive", "tr_node", "tr_depth", "tr_box_lo",
                 "tr_box_hi", "tr_label_y", "tr_sub_y"), values)
    st_sstore(., "tr_label", labels)
    st_sstore(., "tr_sublabel", sublabels)
}

end
