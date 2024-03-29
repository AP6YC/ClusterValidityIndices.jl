"""
    CVI.jl

Description:
    Includes all of the CVI/ICVI definitions.
"""

# include("CONN.jl")
include("CH.jl")
include("cSIL.jl")
include("DB.jl")
include("GD43.jl")
include("GD53.jl")
include("PS.jl")
include("rCIP.jl")
include("WB.jl")
include("XB.jl")

"""
List of implemented CVIs, useful for iteration.
Each element is the struct abbreviated name for the CVI, which can be instantiated for iteration with the empty constructor.

For example:

```julia
using ClusterValidityIndices
instantiated_cvis = [local_cvi() for local_cvi in CVI_MODULES]
```
"""
const CVI_MODULES = [
    CH,
    cSIL,
    DB,
    GD43,
    GD53,
    PS,
    rCIP,
    WB,
    XB,
]
