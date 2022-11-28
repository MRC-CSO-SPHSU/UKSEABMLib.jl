"""
SocioEconomics Library dependent on MultiAgents.jl 

pre-request: MultiAgents.jl should be loadable or within LOAD_PATH 
"""
module SocioEconomics

    using MultiAgents: MAVERSION 
    export verifyCompatibleMAVERSION

    include("seconstants.jl")

    if ! (XAGENTS_MA_PATH in LOAD_PATH) 
        push!(LOAD_PATH, XAGENTS_MA_PATH)
    end 

    @assert MAVERSION == v"0.3.1"   # ensure MultiAgents.jl latest update 

    include("semodules.jl")

end  # module SocioEconomics 