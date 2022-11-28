"""
SocioEconomics library independent from MultiAgents.jl
"""
module SocioEconomicsX

    include("seconstants.jl")

    if ! (XAGENTS_GENERIC_PATH in LOAD_PATH) 
        push!(LOAD_PATH, XAGENTS_GENERIC_PATH)
    end

    include("semodules.jl")

end  # module SocioEconomicsX 