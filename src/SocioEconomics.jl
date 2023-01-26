"""
SocioEconomics Library dependent on MultiAgents.jl

pre-request: MultiAgents.jl should be loadable or within LOAD_PATH
"""

module SocioEconomics

# ensuring consistent version of MultiAgents.jl library
using MultiAgents: MAVERSION
@assert MAVERSION == v"0.4"

include("Constants.jl")
using .Constants: SESRCPATH, SEPATH, SEVERSION,
                    XAGENTS_GENERIC_PATH, XAGENTS_MA_PATH

include("./core/Utilities.jl")

include("multiagents/XAgents.jl")

include("semodules.jl")

end  # module SocioEconomics
