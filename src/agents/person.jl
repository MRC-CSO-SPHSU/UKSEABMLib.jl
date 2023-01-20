using TypedDelegation

using ....Utilities.DeclUtils

export Person, PersonHouse, PersonTown
export UNDEFINED_HOUSE, UNDEFINED_TOWN

export move_to_house!, reset_house!, resolve_partnership!, household_income
export household_income_percapita

export home, are_living_together
export set_as_parent_child!, set_as_partners!
export age_youngest_alive_child, yearsold
export has_alive_child_at_home, are_parent_child, related_first_degreeree, aresiblings
export can_live_alone, isorphan, set_as_guardian_dependent!, set_as_provider_providee!,
    resolve_dependency!
export set_as_independent!, set_as_selfprovidingviding!
export check_consistency_dependents
export max_parent_rank

include("agents_modules/basicinfo.jl")
include("agents_modules/kinship.jl")
include("agents_modules/maternity.jl")
include("agents_modules/work.jl")
include("agents_modules/care.jl")
include("agents_modules/class.jl")
include("agents_modules/dependencies.jl")

"""
Specification of a Person Agent Type.

This file is included in the module XAgents

Type Person extends from AbstractAgent.

Person ties various agent modules into one compound agent type.
"""

# vvv More classification of attributes (Basic, Demography, Relatives, Economy )
mutable struct Person <: AbstractXAgent
    id::Int
    """
    location of a parson's house in a map which implicitly
    - (x-y coordinates of a house)
    - (town::Town, x-y location in the map)
    """
    pos::House{Person,Town}
    info::BasicInfoBlock
    kinship::KinshipBlock{Person}
    maternity :: MaternityBlock
    work :: WorkBlock
    care :: CareBlock
    class :: ClassBlock
    dependencies :: DependencyBlock{Person}

    # Person(id,pos,age) = new(id,pos,age)
    "Internal constructor"
    function Person(pos, info, kinship, maternity, work, care, class, dependencies)
        person = new(getIDCOUNTER(),pos,info,kinship, maternity, work, care, class, dependencies)
        if !undefined(pos)
            addOccupant!(pos, person)
        end
        if kinship.father != nothing
            add_child!(kinship.father,person)
        end
        if kinship.mother != nothing
            add_child!(kinship.mother,person)
        end
        if kinship.partner != nothing
            reset_partner!(kinship.partner)
            partner.partner = person
        end
        if length(kinship.children) > 0
            for child in kinship.children
                set_as_parent_child!(person,child)
            end
        end
        person
    end # Person Cor
end # struct Person

# delegate functions to components
# and export accessors

@delegate_onefield Person pos [hometown]

@export_forward Person info [age, gender, alive]
@delegate_onefield Person info [isfemale, ismale, agestep!, agestep_ifalive!, has_birthday, yearsold]

@export_forward Person kinship [father, mother, partner, children]
@delegate_onefield Person kinship [has_children, add_child!, issingle, parents, siblings, youngest_child]

@delegate_onefield Person maternity [start_maternity!, step_maternity!, end_maternity!,
    is_in_maternity, maternity_duration]

@export_forward Person work [status, outOfTownStudent, newEntrant, initialIncome, finalIncome,
    wage, income, potentialIncome, jobTenure, schedule, workingHours, weeklyTime,
    availableWorkingHours, workingPeriods, pension]
@delegate_onefield Person work [set_empty_job_schedule!, set_full_weekly_time!]

@export_forward Person care [careNeedLevel, socialWork, childWork]

@export_forward Person class [classRank]
@delegate_onefield Person class [increment_class_rank!]

@export_forward Person dependencies [guardians, dependents, provider, providees]
@delegate_onefield Person dependencies [isdependent, has_dependents, has_providees]

"costum @show method for Agent person"
function Base.show(io::IO,  person::Person)
    print(person.info)
    undefined(person.pos) ? nothing : print(" @ House id : $(person.pos.id)")
    print(person.kinship)
    println()
end

const PersonHouse = House{Person, Town}
const PersonTown = Town{PersonHouse}

const UNDEFINED_TOWN = Town{House}(UNDEFINED_2DLOCATION, 0.0)
const UNDEFINED_HOUSE = PersonHouse(UNDEFINED_TOWN, UNDEFINED_2DLOCATION)

"Constructor with default values"
Person(pos,age; gender=unknown,
    father=nothing,mother=nothing,
    partner=nothing,children=Person[]) =
        Person(pos,BasicInfoBlock(;age, gender),
               KinshipBlock{Person}(father,mother,partner,children),
            MaternityBlock(false, 0),
            WorkBlock(),
            CareBlock(0, 0, 0),
            ClassBlock(0), DependencyBlock{Person}())


"Constructor with default values"
Person(;pos=UNDEFINED_HOUSE,age=0,
        gender=unknown,
        father=nothing,mother=nothing,
        partner=nothing,children=Person[]) =
            Person(pos,BasicInfoBlock(;age,gender),
                   KinshipBlock{Person}(father,mother,partner,children),
                MaternityBlock(false, 0),
                WorkBlock(),
                CareBlock(0, 0, 0),
                ClassBlock(0), DependencyBlock{Person}())

home(person) = person.pos

"associate a house to a person, removes person from previous house"
function move_to_house!(person::Person,house)
    if ! undefined(person.pos)
        removeOccupant!(person.pos, person)
    end
    person.pos = house
    addOccupant!(house, person)
end

"reset house of a person (e.g. became dead)"
function reset_house!(person::Person)
    if ! undefined(person.pos)
        removeOccupant!(person.pos, person)
    end
    person.pos = UNDEFINED_HOUSE
    nothing
end

are_living_together(person1, person2) = person1.pos == person2.pos
are_parent_child(person1, person2) =
    person1 in children(person2) || person2 in children(person1)
aresiblings(person1, person2) =
    father(person1) == father(person2) != nothing ||
    mother(person1) == mother(person2) != nothing
related_first_degreeree(person1, person2) =
    are_parent_child(person1, person2) || aresiblings(person1, person2)

# TODO check if correct
household_income(person) = sum(p -> income(p), person.pos.occupants)
household_income_percapita(person) =
    household_income(person) / length(person.pos.occupants)

"set the father of a child"
function set_as_parent_child!(child::Person,parent::Person)
    @assert ismale(parent) || isfemale(parent)
    @assert age(child) < age(parent)
    @assert (ismale(parent) && father(child) == nothing) ||
        (isfemale(parent) && mother(child) == nothing)
    add_child!(parent, child)
    _set_parent!(child, parent)
    # would be nice to ensure consistency of dependence/provision at this point as well
    # but there are so many specific situations that it is easier to do that in simulation
    # code
    nothing
end

function reset_partner!(person)
    other = partner(person)
    if other != nothing
        partner!(person, nothing)
        partner!(other, nothing)
    end
    nothing
end

"resolving partnership"
function resolve_partnership!(person1::Person, person2::Person)
    @assert partner(person1) == person2 && partner(person2) == person1
    reset_partner!(person1)
end

"set two persons to be a partner"
function set_as_partners!(person1::Person,person2::Person)
    @assert ismale(person1) == isfemale(person2)
    reset_partner!(person1)
    reset_partner!(person2)
    partner!(person1, person2)
    partner!(person2, person1)
end

"set child of a parent"
function _set_parent!(child, parent)
    @assert isfemale(parent) || ismale(parent)
    if isfemale(parent)
        mother!(child, parent)
    else
        father!(child, parent)
    end
    nothing
end

function has_alive_child(person)
    for child in children(person)
        if alive(child) return true end
    end
    return false
end

function has_alive_child_at_home(person)
    for c in children(person)
        if alive(c) && c.pos == person.pos
            return true
        end
    end
    return false
end

function age_youngest_alive_child(person::Person)
    youngest = Rational{Int}(Inf)
    for child in children(person)
        if alive(child)
            youngest = min(youngest,age(child))
        end
    end
    return youngest
end

can_live_alone(person) = age(person) >= 18
isorphan(person) = !can_live_alone(person) && !isdependent(person)

function resolve_dependency!(guardian, dependent)
    deps = dependents(guardian)
    idx_d = findfirst(==(dependent), deps)
    if idx_d == nothing  # an error should be returned?
        return
    end
    deleteat!(deps, idx_d)
    guards = guardians(dependent)
    idx_g = findfirst(==(guardian), guards)
    if idx_g == nothing
        error("inconsistent dependency!")
    end
    deleteat!(guards, idx_g)
end

function set_as_guardian_dependent!(guardian, dependent)
    push!(dependents(guardian), dependent)
    push!(guardians(dependent), guardian)
    nothing
end

function set_as_independent!(person)
    if !isdependent(person)
        return
    end
    for g in guardians(person)
        g_deps = dependents(g)
        deleteat!(g_deps, findfirst(==(person), g_deps))
    end
    empty!(guardians(person))
    nothing
end

# check basic consistency, if there's an error on any of these
# then something is seriously wrong
function check_consistency_dependents(person)
    for guard in guardians(person)
        @assert guard != nothing && alive(guard)
        @assert person in dependents(guard)
    end

    for dep in dependents(person)
        @assert dep != nothing && alive(dep)
        @assert age(dep) < 18
        @assert person.pos == dep.pos
        @assert person in guardians(dep)
    end
end

function set_as_provider_providee!(prov, providee)
    @assert provider(providee) == nothing
    @assert !(providee in providees(prov))
    push!(providees(prov), providee)
    provider!(providee, prov)
    nothing
end

function set_as_selfprovidingviding!(person)
    if provider(person) == nothing
        return
    end

    provs = providees(provider(person))
    deleteat!(provs, findfirst(==(person), provs))
    provider!(person, nothing)
    nothing
end

function max_parent_rank(person)
    f = father(person)
    m = mother(person)
    if f == m == nothing
        classRank(person)
    elseif f == nothing
        classRank(m)
    elseif m == nothing
        classRank(f)
    else
        max(classRank(m), classRank(f))
    end
end
