export DependencyBlock
export isdependent, has_dependents, has_providees

mutable struct DependencyBlock{P}
    guardians :: Vector{P}
    dependents :: Vector{P}
    provider :: Union{P, Nothing}
    providees :: Vector{P}
end

DependencyBlock{P}() where {P} = DependencyBlock{P}([], [], nothing, [])

isdependent(p) = !isempty(p.guardians)
has_dependents(p) = isempty(p.dependents)
has_providees(p) = isempty(p.providees)
