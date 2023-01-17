"""
    config.jl

# Description
Contains the configuration for the CVI base implementation.
"""

const CVI_CONFIG = Dict(
    "params" => Dict(
        "n" => Dict(
            "shape" => 1,
            "type" => Int,
        ),
        "v" => Dict(
            "shape" => 2,
            "type" => Float,
        ),
        "CP" => Dict(
            "shape" => 1,
            "type" => Float,
        ),
        "G" => Dict(
            "shape" => 2,
            "type" => Float,
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

"""
An object containing all of the information about a single type of CVI parameter.

This includes symbolic pointers to its related functions, the type of the parameter, its shape, and the subsequent element type for expansion.
"""
struct CVIParamConfig
    update::Symbol
    add::Symbol
    expand::Symbol
    type::Type
    shape::Int
    el_type::Type
end

const CVIStrategy = Dict{String, CVIParamConfig}

function get_el_type(shape::Integer, type::Type)
    if shape == 1
        el_type = type
    else
        el_type = Array{type, shape - 1}
    end
    return el_type
end

function get_cvi_strategy(config::AbstractDict)
    # Initialize the strategy
    strategy = CVIStrategy()
    for (name, subconfig) in config["params"]
        strategy[name] = CVIParamConfig(
            Symbol(name * "_update"),
            Symbol(name * "_add"),
            config["container"][subconfig["shape"]]["expand"],
            config["container"][subconfig["shape"]]["type"]{subconfig["type"]},
            subconfig["shape"],
            get_el_type(subconfig["shape"], subconfig["type"]),
        )
    end
    return strategy
end

const CVI_STRATEGY::CVIStrategy = get_cvi_strategy(CVI_CONFIG)
