"""
    common.jl

# Description:
All common types, aliases, structs, and methods for the ClusterValidityIndices.jl package.
"""

# -----------------------------------------------------------------------------
# DOCSTRING TEMPLATES
# -----------------------------------------------------------------------------

# Constants template
@template CONSTANTS =
"""
$(FUNCTIONNAME)

# Description
$(DOCSTRING)
"""

# Types template
@template TYPES =
"""
$(TYPEDEF)

# Summary
$(DOCSTRING)

# Fields
$(TYPEDFIELDS)
"""

# Template for functions, macros, and methods (i.e., constructors)
@template (FUNCTIONS, METHODS, MACROS) =
"""
$(TYPEDSIGNATURES)

# Summary
$(DOCSTRING)

# Method List / Definition Locations
$(METHODLIST)
"""

# -----------------------------------------------------------------------------
# ABSTRACT TYPES
# -----------------------------------------------------------------------------

# Type for all CVIs
"""
Abstract supertype for all CVI objects.
All index instantiations are subtypes of `CVI`.
"""
abstract type CVI end

# -----------------------------------------------------------------------------
# ALIASES
# -----------------------------------------------------------------------------

"""
Internal label mapping for incremental CVIs.

Alias for a dictionary mapping of integers to integers as cluster labels.
"""
const LabelMap = Dict{Int, Int}

"""
The type of tensor used by the ClusterValidityIndices.jl package, used to configure array growth behavior.

Though perhaps an abuse of notation, CVIExpandTensor is defined as only a 3-D array here due to the frequent use of 3-dimensional arrays in the package.
This maintains that the Julia Array type allows multiple orders (i.e., 3-D and onwards).
"""
const CVIExpandTensor{T<:Real} = ElasticArray{T, 3}

"""
The type of matrix used by the ClusterValidityIndices.jl package, used to configure matrix growth behavior.
"""
const CVIExpandMatrix = ElasticMatrix

"""
The type of vector used by the ClusterValidityIndices.jl package, used to configure vector growth behavior
"""
const CVIExpandVector = Vector

# -----------------------------------------------------------------------------
# STRUCTS
# -----------------------------------------------------------------------------

"""
Container for the common elastic parameters of CVIs.

This is defined as an immutable struct because the
"""
struct CVIElasticParams
    n::CVIExpandVector{Int}         # dim
    CP::CVIExpandVector{Float}      # dim
    v::CVIExpandMatrix{Float}       # dim x n_clusters
    G::CVIExpandMatrix{Float}       # dim x n_clusters
end

# -----------------------------------------------------------------------------
# CONSTRUCTORS
# -----------------------------------------------------------------------------

"""
Constructor for the CVIElasticParams struct, using the dimension to prime the 2-D elastic matrices.

The empty constructor should only be used when initializing empty CVIs before setup.
CVI setup should instead create this struct with a specified dimension `dim`, and batch updates can set both `dim` and `n_clusters` immediately.

# Arguments
- `dim::Integer`: the dimension to use for the first dimension of the 2-D matrices.
- `n_clusters::Integer`: optional, the number of clusters if known. Default 0.
"""
function CVIElasticParams(dim::Integer=0, n_clusters::Integer=0)
    return CVIElasticParams(
        CVIExpandVector{Int}(undef, n_clusters),             # n
        CVIExpandVector{Float}(undef, n_clusters),           # CP
        CVIExpandMatrix{Float}(undef, dim, n_clusters),      # v
        CVIExpandMatrix{Float}(undef, dim, n_clusters),      # G
    )
end


# """
# Empty constructor for the CVIElasticParams that creates an empty, unprimed struct.

# This constructor should only be used when initializing empty CVIs before setup.
# CVI setup should instead create this struct with a specified dimension `dim`.
# """
# function CVIElasticParams()
#     return CVIElasticParams(0)
# end

# -----------------------------------------------------------------------------
# FUNCTIONS
# -----------------------------------------------------------------------------

"""
Returns an updated mean vector with a new vector and adjusted count of samples.

# Arguments
- `old_mean::RealVector`:
- `sample::RealVector`:
- `n_new::Integer`:
"""
function update_mean(old_mean::RealVector, sample::RealVector, n_new::Integer)
    new_mean = (
        (1 - 1 / n_new) .* old_mean
        + (1 / n_new) .* sample
    )
    return new_mean
end

"""
Initializes incremental CVI updates.
"""
function init_cvi_inc!(cvi::CVI, sample::RealVector, label::Integer)
    # Get the internal label
    i_label = get_internal_label!(cvi.label_map, label)

    # Increment to a new sample count
    cvi.n_samples += 1

    # If uninitialized, setup the CVI
    if isempty(cvi.mu)
        cvi.mu = sample
        setup!(cvi, sample)
    # Otherwise, update the mean
    else
        cvi.mu = update_mean(cvi.mu, sample, cvi.n_samples)
    end

    # Return the internal label
    return i_label
end

"""
Implements the strategy for expanding a 1-D CVIExpandVector with an arbitrary number.

# Arguments
- `cvi_vec::CVIExpandVector`: the 1-D vector to append a number to.
- `n_new::Real`: a floating point or integer number to append to the vector.
"""
function expand_strategy_1d!(cvi_vec::CVIExpandVector, n_new::Real)
    # Use the push! method, which implements the ElasticMatrix append! function
    push!(cvi_vec, n_new)
end

"""
Implements the strategy for expanding a 2-D CVIExpandMatrix with a vector on the last dimension.

# Arguments
- `mat::CVIExpandMatrix`: the 2-D matrix to append a vector to its last dimension.
- `v_new::RealVector`: the 1-D vector to append to the matrix.
"""
function expand_strategy_2d!(cvi_mat::CVIExpandMatrix, v_new::RealVector)
    # Use the ElasticMatrix append! function
    append!(cvi_mat, v_new)
end

"""
Implements the strategy for expanding a 3-D CVI array with a 2-D matrix.

# Arguments
- `cvi_mat::CVIExpandTensor`: the 3-D CVI array to append to.
- `mat_new::RealMatrix`: the 2-D matrix to append to the CVI array.
"""
function expand_strategy_3d!(cvi_mat::CVIExpandTensor, mat_new::RealMatrix)
    # Use the ElasticArray append! function
    append!(cvi_mat, mat_new)
end

"""
Expands the CVIElasticParams struct with the provided CVI parameters.

# Arguments
- `params::CVIElasticParams`:
- `n::Integer`:
- `CP::Float`:
- `v::RealVector`:
- `G::RealVector`:
"""
function expand_params!(
    params::CVIElasticParams,
    n::Integer,
    CP::Float,
    v::RealVector,
    G::RealVector
)
    # Update 1-D parameters with a push
    expand_strategy_1d!(params.n, n)
    expand_strategy_1d!(params.CP, CP)
    # Update 2-D parameters with appending and reassignment
    expand_strategy_2d!(params.v, v)
    expand_strategy_2d!(params.G, G)
end

"""
Internal method, sets up the CVI based upon the type of the provided sample.

# Arguments
- `cvi::CVI`: the CVI to setup to the correct dimensions.
- `sample::RealVector`: The sample to use as a basis for setting up the CVI.
"""
function setup!(cvi::CVI, sample::RealVector)
    # Get the feature dimension
    cvi.dim = length(sample)
    # Initialize the elastic parameters with the correct dimension
    cvi.params = CVIElasticParams(cvi.dim)
end


"""
Compute and return the criterion value incrementally.

This method takes the CVI object, a single sample as a vector of floats, and a single integer that represents the label prescribed to the sample by your clustering algorithm.

!!! note "Note"
    You cannot switch to batch mode after incrementally evaluating a CVI.
    To evaluate in batch, you much create a new CVI object.

# Arguments
- `cvi::CVI`: the stateful information of the ICVI providing the criterion value.
- `sample::RealVector`: a vector of features used in clustering the sample.
- `label::Integer`: the cluster label prescribed to the sample by the clustering algorithm.

# Examples
```julia
# Create a new CVI object
my_cvi = CH()

# Load in random data as an example; 10 samples with feature dimenison 3
dim = 3
n_samples = 10
data = rand(dim, n_samples)
labels = repeat(1:2, inner=n_samples)

# Iteratively compute and extract the criterion value at every step
criterion_values = zeros(n_samples)
for ix = 1:n_samples
    sample = data[:, ix]
    label = labels[ix]
    criterion_values[ix] = get_icvi!(my_cvi, sample, label)
end
```
"""
function get_cvi!(cvi::CVI, sample::RealVector, label::Integer)
    # Update the ICVI parameters
    param_inc!(cvi, sample, label)

    # Compute the criterion value
    evaluate!(cvi)

    # Return that value
    return cvi.criterion_value
end

"""
Compute and return the criterion value in batch mode.

This method takes the CVI object, a batch of samples as a matrix of floats, and a vector of integers that represent the labels prescribed to the data by your clustering algorithm.

!!! note "Note"
    You cannot switch to incremental mode after evaluating a CVI in batch mode.
    To evaluate incrementally, you much create a new CVI object.

# Arguments
- `cvi::CVI`: the stateful information of the CVI providing the criterion value.
- `data::RealMatrix`: a matrix of data, columns as samples and rows as features, used in the external clustering process.
- `labels::IntegerVector`: a vector of integers representing labels prescribed to the `data` by the external clustering algorithm.

# Examples
```julia
# Create a new CVI object
my_cvi = CH()

# Load in random data as an example; 10 samples with feature dimenison 3
dim = 3
n_samples = 10
data = rand(dim, n_samples)
labels = repeat(1:2, inner=n_samples)

# Compute the final criterion value in batch mode
criterion_value = get_cvi!(cvi, data, labels)
```
"""
function get_cvi!(cvi::CVI, data::RealMatrix, labels::IntegerVector)
    # Update the CVI parameters in batch
    param_batch!(cvi, data, labels)

    # Compute the criterion value
    evaluate!(cvi)

    # Return that value
    return cvi.criterion_value
end

"""
Get the internal label and update the label map if the label is new.

# Arguments
- `label_map::LabelMap`: label map to extract the internal label from.
- `label::Integer`: the external label that corresponds to an internal label.
"""
function get_internal_label!(label_map::LabelMap, label::Integer)
    # If the label map contains the key, return that internal label
    if haskey(label_map, label)
        internal_label = label_map[label]
    # Otherwise, increment the internal label to preserve monotonicity and store
    else
        internal_label = length(label_map) + 1
        label_map[label] = internal_label
    end

    return internal_label
end

# -----------------------------------------------------------------------------
# COMMON DOCUMENTATION
# -----------------------------------------------------------------------------

@doc raw"""
Compute the CVI parameters incrementally.

This method updates only internal parameters of the ICVI algorithm incrementally.
When the criterion value itself is needed, use `evaluate!` and extract it from `cvi.criterion_value`.

# Arguments
- `cvi::CVI`: the stateful information of the CVI/ICVI algorithm.
- `sample::RealVector`: a vector of features used in the external clustering algorithm.
- `label::Integer`: the label that the external clustering algorithm prescribed to the `sample`.

# Examples
```julia-repl
julia> my_cvi = CH()
julia> data = load_some_data()
julia> labels = my_cluster_algorithm(data)
julia> param_inc!(my_cvi, data[:, 1], labels[1])
```
"""
param_inc!(cvi::CVI, sample::RealVector, label::Integer)

@doc raw"""
Compute the CVI parameters in batch.

This method updates only the internal parameters of the CVI algorithm in batch.
When the criterion value itself is needed, use `evaluate!` and extract it from `cvi.criterion_value`.

# Arguments
- `cvi::CVI`: the stateful information of the CVI/ICVI algorithm.
- `data::RealMatrix`: a matrix of data where rows are features and columns are samples, used in the external clustering algorithm.
- `labels::IntegerVector`: a vector of labels that the external clustering algorithm prescribed to each column in `data`.

# Examples
```julia-repl
julia> my_cvi = CH()
julia> data = load_some_data()
julia> labels = my_cluster_algorithm(data)
julia> param_batch!(my_cvi, data, labels)
```
"""
param_batch!(cvi::CVI, data::RealMatrix, labels::IntegerVector)

@doc raw"""
Compute the criterion value of the CVI.

After computation, the resulting criterion value can be extracted from `cvi.criterion_value`.
The criterion value is a function of the CVI/ICVI internal parameters, so at least two classes (i.e., unique labels) must be presented to the CVI in `param_inc!` or `param_batch!` before a non-zero value is returned.

# Arguments
- `cvi::CVI`: the stateful information of the CVI/ICVI to use for computing the criterion value.

# Examples
```julia-repl
julia> my_cvi = CH()
julia> data = load_some_data()
julia> labels = my_cluster_algorithm(data)
julia> param_batch!(my_cvi, data, labels)
julia> evaluate!(my_cvi)
julia> my_criterion_value = my_cvi.criterion_value
```
"""
evaluate!(cvi::CVI)
