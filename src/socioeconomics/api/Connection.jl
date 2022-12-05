module Connection 

export AbsProc, AbsPort, initialConnect!, init! 

"""
to be used as a trait for generic functions implementing 
    candidates of processes
"""
abstract type AbsProcess end 

"Only for initialisation process"
abstract type AbsInitProcess <: AbsProcess end 

"""two components with identical port are connectable"""
abstract type AbsPort <: AbsProcess end 

"Port used only for initial connection"
abstract type AbsInitPort <: AbsPort end 

"Interface"
function init!() end 

"Interface" 
function initialConnect!() end 

"symmetry of connections"
initialConnect!(x,y,pars) = initialConnect!(y,x,pars) 

initialConnect!(x,y,pars,initPort::PType)  where PType <: AbsPort = 
    initialConnect!(y,x,pars,initPort)

end # Connection 