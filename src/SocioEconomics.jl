"""
SocioEconomics Library dependent on MultiAgents.jl 

pre-request: MultiAgents.jl should be loadable or within LOAD_PATH 
"""

module SocioEconomics

    # ensuring consistent version of MultiAgents.jl library
    using MultiAgents: MAVERSION
    @assert MAVERSION == v"0.3.1"  

    include("seconstants.jl")

    if ! (XAGENTS_MA_PATH in LOAD_PATH) 
        push!(LOAD_PATH, XAGENTS_MA_PATH)
    end 

    include("semodules.jl")

end  # module SocioEconomics 