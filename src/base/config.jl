"""
    config.jl

# Description
Contains the configuration for the CVI base implementation.
"""

const CVIConfigDict = Dict{String, Any}

const CVI_CONFIG = CVIConfigDict(
    "params" => Dict(
        "n" => Dict(
            "shape" => 1,
            "type" => Int,
            "deps" => [],
            "growth" => "extend",
        ),
        "v" => Dict(
            "shape" => 2,
            "type" => Float,
            "deps" => ["n"],
            "growth" => "extend",
        ),
        "CP" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => ["v", "n", "G"],
            "growth" => "extend",
        ),
        "G" => Dict(
            "shape" => 2,
            "type" => Float,
            "deps" => ["v", "n"],
            "growth" => "extend",
        ),
        "mu" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => [],
            "growth" => "inplace",
        ),
        "SEP" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => ["v", "n", "mu"],
            "growth" => "inplace",
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
