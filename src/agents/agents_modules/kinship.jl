export KinshipBlock
export has_children, issingle, add_child!, parents, siblings, youngest_child,
    noperson, isnoperson

mutable struct KinshipBlock{P}
  father::Union{P,Nothing}
  mother::Union{P,Nothing}
  partner::Union{P,Nothing}
  children::Vector{P}
end

children(person::KinshipBlock) = person.children

noperson() = nothing
noperson(::KinshipBlock) = noperson()
noperson(::Nothing) = noperson()
isnoperson(person::KinshipBlock) = person == noperson(person)
isnoperson(::Nothing) = true

has_children(parent::KinshipBlock{P}) where{P} = length(parent.children) > 0
add_child!(parent::KinshipBlock{P}, child::P) where{P} = push!(parent.children, child)
youngest_child(person::KinshipBlock) = person.children[end]
issingle(person::KinshipBlock) = isnoperson(person.partner)
parents(person::KinshipBlock) = [person.father, person.mother]

function siblings(person::KinshipBlock{P}) where P
    sibs = P[]
    for p in parents(person)
        if isnoperson(p) continue end
        for c in children(p)
            if c != person
                push!(sibs, c)
            end
        end
    end
    sibs
end

"costum @show method for Agent person"
function Base.show(io::IO, kinship::KinshipBlock)
  father = kinship.father; mother = kinship.mother; partner = kinship.partner; children = kinship.children;
  isnoperson(father)     ? nothing : print(" , father    : $(father.id)")
  isnoperson(mother)     ? nothing : print(" , mother    : $(mother.id)")
  isnoperson(partner)    ? nothing : print(" , partner   : $(partner.id)")
  length(children) == 0  ? nothing : print(" , children  : ")
  for child in children
    print(" $(child.id) ")
  end
  println()
end
