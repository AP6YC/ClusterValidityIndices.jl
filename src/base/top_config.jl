"""
    config.jl

# Description
Contains the configuration for the CVI base implementation.
"""

const CVIConfigDict = Dict{String, Any}

const CVI_TOP_CONFIG = CVIConfigDict(
    "params" => Dict(
        "n" => Dict(
            "shape" => 1,
            "type" => Int,
            "deps" => [],
            "growth" => "extend",
            "stage" => 2,
        ),
        "v" => Dict(
            "shape" => 2,
            "type" => Float,
            "deps" => ["n"],
            "growth" => "extend",
            "stage" => 2,
        ),
        "CP" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => ["v", "n", "G"],
            "growth" => "extend",
            "stage" => 2,
        ),
        "G" => Dict(
            "shape" => 2,
            "type" => Float,
            "deps" => ["v", "n"],
            "growth" => "extend",
            "stage" => 2,
        ),
        "mu" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => [],
            "growth" => "inplace",
            "stage" => 3,
        ),
        "SEP" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => ["v", "n", "mu"],
            "growth" => "inplace",
            "stage" => 3,
        ),
    ),
    "container" => Dict(
        1 => Dict(
            "expand" => :expand_strategy_1d!,
            "type" => CVIExpandVector,
        ),
        2 => Dict(
            "expand" => :expand_strategy_2d!,
            "type" => CVIExpandMatrix,
        ),
        3 => Dict(
            "expand" => :expand_strategy_3d!,
            "type" => CVIExpandTensor,
        ),
    ),
)
