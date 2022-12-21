module Traits 

export PopulationFeature, FullPopulation, AlivePopulation
export FuncReturn, NoReturn, WithReturn

abstract type PopulationFeature end
struct FullPopulation <: PopulationFeature end 
struct AlivePopulation <: PopulationFeature end 


abstract type FuncReturn end 
struct NoReturn <: FuncReturn end 
struct WithReturn <: FuncReturn end 

end 