"""
    config.jl

# Description
Contains the configuration for the CVI base implementation.
"""

const CVIConfigDict = Dict{String, Any}

const CVI_TOP_CONFIG = CVIConfigDict(
    "params" => Dict(
        "mu" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => [],
            "expand" => false,
            "update" => "whole",
            "stage" => 1,
        ),
        "n" => Dict(
            "shape" => 1,
            "type" => Int,
            "deps" => [],
            "expand" => true,
            "update" => "element",
            "stage" => 2,
        ),
        "v" => Dict(
            "shape" => 2,
            "type" => Float,
            "deps" => ["n"],
            "expand" => true,
            "update" => "element",
            "stage" => 2,
        ),
        "CP" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => ["v", "n", "G"],
            "expand" => true,
            "update" => "element",
            "stage" => 2,
        ),
        "G" => Dict(
            "shape" => 2,
            "type" => Float,
            "deps" => ["v", "n"],
            "expand" => true,
            "update" => "element",
            "stage" => 2,
        ),
        "SEP" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => ["v", "n", "mu"],
            "expand" => true,
            "update" => "whole",
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
