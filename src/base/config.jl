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
        ),
        "v" => Dict(
            "shape" => 2,
            "type" => Float,
            "deps" => ["n"],
        ),
        "CP" => Dict(
            "shape" => 1,
            "type" => Float,
            # "deps" => ["v", "n", "G"],
            "deps" => ["v", "n"],
        ),
        "G" => Dict(
            "shape" => 2,
            "type" => Float,
            "deps" => ["v", "n"],
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
