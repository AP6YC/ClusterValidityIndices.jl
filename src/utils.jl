"""
    sort_cvi_data(data::RealMatrix, labels::IntegerVector)

Sorts the CVI data by the label index, assuring that clusters are provided incrementally.
"""
function sort_cvi_data(data::RealMatrix, labels::IntegerVector)
    index = sortperm(labels)
    data = data[:, index]
    labels = labels[index]

    return data, labels
end # sort_cvi_data(data::RealMatrix, labels::IntegerVector)

"""
    relabel_cvi_data(labels::IntegerVector)

Relabels the vector to present new labels in incremental order.
"""
function relabel_cvi_data(labels::IntegerVector)
    # Get the unique labels and their order of appearance
    unique_labels = unique(labels)
    n_unique_labels = length(unique_labels)
    n_labels = length(labels)

    # Create a new ordered list of unique labels
    new_unique_labels = [x for x in 1:n_unique_labels]

    # Map the old unique labels to the new ones
    label_mapping = Dict(zip(unique_labels, new_unique_labels))

    # Create a new labels vector with ordered labels
    new_labels = zeros(Int, n_labels)
    for ix = 1:n_labels
        new_labels[ix] = label_mapping[labels[ix]]
    end

    return new_labels
end # relabel_cvi_data(labels::IntegerVector)
