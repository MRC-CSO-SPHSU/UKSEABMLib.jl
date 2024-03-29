"""
    This module describes basic model interfaces to
    be employed within simulation functions in any
    *Simulate module

    This module is within the UKSEABMLib[X] modules
"""
module API

    include("api/Traits.jl")
    include("api/ModelFunc.jl")
    include("api/Connection.jl")
    include("api/ModelOp.jl")

end # API
