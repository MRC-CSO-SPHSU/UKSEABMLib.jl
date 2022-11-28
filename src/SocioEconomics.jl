"""
SocioEconomics Library dependent on MultiAgents.jl 
"""
module SocioEconomics

    include("seconstants.jl")

    if ! (XAGENTS_MA_PATH in LOAD_PATH) 
        push!(LOAD_PATH, XAGENTS_MA_PATH)
    end 

    include("semodules.jl")

end  # module SocioEconomics 