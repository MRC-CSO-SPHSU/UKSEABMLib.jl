module Traits 

export PopulationFeature, FullPopulation, AlivePopulation
export FuncReturn, NoReturn, WithReturn
export MaxDistance, InTown, AdjTown, AnyWhere 

abstract type PopulationFeature end
struct FullPopulation <: PopulationFeature end 
struct AlivePopulation <: PopulationFeature end 

abstract type FuncReturn end 
struct NoReturn <: FuncReturn end 
struct WithReturn <: FuncReturn end 

abstract type MaxDistance end 
struct InTown <: MaxDistance end 
struct AdjTown <: MaxDistance end 
struct AnyWhere  <: MaxDistance end 

end 