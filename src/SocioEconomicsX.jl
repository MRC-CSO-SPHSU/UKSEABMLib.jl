"""
UKSEABMLibX library independent from MultiAgents.jl
"""
module UKSEABMLibX

include("Constants.jl")
using .Constants: SESRCPATH, SEPATH, SEVERSION

include("./core/Utilities.jl")

include("generic/XAgents.jl")

include("semodules.jl")

end  # module UKSEABMLibX
