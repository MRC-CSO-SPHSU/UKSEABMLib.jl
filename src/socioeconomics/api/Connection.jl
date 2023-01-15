module Connection 

export AbsProc, AbsPort, initial_connect!, init! 

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
function initial_connect!() end 

"symmetry of connections"
initial_connect!(x,y,pars) = initial_connect!(y,x,pars) 

initial_connect!(x,y,pars,initPort::PType)  where PType <: AbsPort = 
    initial_connect!(y,x,pars,initPort)

end # Connection 