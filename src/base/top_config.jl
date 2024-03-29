"""
    config.jl

# Description
Contains the configuration for the CVI base implementation.
"""

const CVIConfigDict = Dict{String, Any}

const CVI_TOP_CONFIG = CVIConfigDict(
    "params" => Dict(
        # "n_samples" => Dict(
        #     "shape" => 0,
        #     "type" => Float,
        #     "deps" => [],
        #     "expand" => false,
        #     # "update" => "whole",
        #     "monocyclic" => true,
        #     "stage" => 1,
        # ),
        "mu" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => [],
            "expand" => false,
            # "update" => "whole",
            "monocyclic" => true,
            "stage" => 2,
        ),
        "n" => Dict(
            "shape" => 1,
            "type" => Int,
            "deps" => [],
            "expand" => true,
            # "update" => "element",
            "monocyclic" => false,
            "stage" => 3,
        ),
        "v" => Dict(
            "shape" => 2,
            "type" => Float,
            "deps" => ["n"],
            "expand" => true,
            # "update" => "element",
            "monocyclic" => false,
            "stage" => 3,
        ),
        "CP" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => ["v", "n", "G"],
            "expand" => true,
            # "update" => "element",
            "monocyclic" => false,
            "stage" => 3,
        ),
        "G" => Dict(
            "shape" => 2,
            "type" => Float,
            "deps" => ["v", "n"],
            "expand" => true,
            # "update" => "element",
            "monocyclic" => false,
            "stage" => 3,
        ),
        "SEP" => Dict(
            "shape" => 1,
            "type" => Float,
            "deps" => ["v", "n", "mu"],
            "expand" => false,
            # "update" => "whole",
            "monocyclic" => true,
            "stage" => 4,
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
