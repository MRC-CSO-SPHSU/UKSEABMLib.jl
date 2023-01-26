""" 
    This module describes basic model interfaces to
    be employed within simulation functions in any 
    *Simulate module
    
    This module is within the SocioEconomics[X] modules 
"""
module API

    include("api/Traits.jl")
	include("api/ParamFunc.jl")
    include("api/ModelFunc.jl")
    include("api/Connection.jl")
    
end # API 