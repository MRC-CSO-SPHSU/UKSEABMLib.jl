module Traits 

using ....XAgents: Person 
using ....Utilities
import ....Utilities: verbose 

export PopulationFeature, FullPopulation, AlivePopulation
export FuncReturn, NoReturn, WithReturn
export MaxDistance, InTown, AdjTown, AnyWhere 
export SimProcess, Death, Birth, Divorce, Marriage, AssignGuardian, 
        AgeTransition, WorkTransition, SocialTransition 
export SimFullReturn
export init_return!, progress_return!, fullreturn_object, select_population
export verbose, verbosemsg

abstract type PopulationFeature end
struct FullPopulation <: PopulationFeature end 
struct AlivePopulation <: PopulationFeature end 

abstract type FuncReturn end 
struct NoReturn <: FuncReturn end
# number of occurances a simulation process was applied to a population  
struct IntReturn <: FuncReturn end 
# people that were subject to a simulation process 
struct PeopleReturn <: FuncReturn end 
# people and their indices in the selected population 
struct FullReturn <: FuncReturn end 

abstract type MaxDistance end 
struct InTown <: MaxDistance end 
struct AdjTown <: MaxDistance end 
struct AnyWhere  <: MaxDistance end 

abstract type SimProcess end 
struct Death <: SimProcess end 
struct Birth <: SimProcess end 
struct Divorce <: SimProcess end 
struct Marriage <: SimProcess end
struct AssignGuardian <: SimProcess end
struct AgeTransition <: SimProcess end 
struct WorkTransition <: SimProcess end 
struct SocialTransition <: SimProcess end 

# default local simulation functions 

const SimFullReturn = NamedTuple{(:indices,:people),Tuple{Vector{Int},Vector{Person}}}
fullreturn_object!(::SimFullReturn) = (indices = Int[], people = Person[])

init_return!(::Nothing) = nothing 
#init_return!(ret,::NoReturn) = init_return!(::Nothing)
init_return!(ret::Int)  = ret 
init_return!(ret::Vector{Person}) = empty!(ret)
function init_return!(ret::SimFullReturn) 
    empty!(ret.indices)
    empty!(ret.people)
    return ret
end 
init_return!(ret,process::SimProcess) = 
    error("init_return!(ret,$(typeof(process))) not implemented")

progress_return!(::Nothing,args) = nothing 
progress_return!(ret::Int,args) = ret+1
progress_return!(ret::Vector{Person},args) = push!(ret,args.person)
function progress_return!(ret::SimFullReturn,args)
    push!(ret.indices,args.ind)
    push!(ret.people,args.person)
    return ret
end
progress_return!(ret,args,process::SimProcess) = 
    error("progress_return!(ret,args,$(typeof(process))) not implemented")

verbosemsg(process::SimProcess) = error("verbosemsg($(typeof(process))) not implemented")
verbosemsg(::Person,process::SimProcess) = 
    error("verbosemsg(::Person,$(typeof(process))) not implemented")

function verbose(person::Person,process::SimProcess)
   delayedVerbose() do 
        println("$(verbosemsg(person,process))")
   end 
end
verbose(::Nothing,::SimProcess) = nothing 
function verbose(ret::Int, process::SimProcess)
    delayedVerbose() do 
        println("# of $(verbosemsg(process)) : $ret")
    end
end
verbose(ret::Vector{Person},process::SimProcess) = verbose(length(ret),process)
verbose(ret::SimFullReturn,process::SimProcess) = verbose(length(ret.people),process)

end # module Traits 