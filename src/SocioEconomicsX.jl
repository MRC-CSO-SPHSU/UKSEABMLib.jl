"""
SocioEconomicsX library independent from MultiAgents.jl
"""
module SocioEconomicsX

include("Constants.jl")
using .Constants: SESRCPATH, SEPATH, SEVERSION, 
                    XAGENTS_GENERIC_PATH, XAGENTS_MA_PATH

include("generic/XAgents.jl")

include("semodules.jl")

end  # module SocioEconomicsX 