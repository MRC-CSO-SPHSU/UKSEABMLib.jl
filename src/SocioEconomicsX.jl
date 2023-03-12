"""
SocioEconomicsX library independent from MultiAgents.jl
"""
module SocioEconomicsX

include("Constants.jl")
using .Constants: SESRCPATH, SEPATH, SEVERSION

include("./core/Utilities.jl")

include("generic/XAgents.jl")

include("semodules.jl")

end  # module SocioEconomicsX
