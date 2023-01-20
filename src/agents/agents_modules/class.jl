export ClassBlock

export increment_class_rank!

mutable struct ClassBlock
    classRank :: Int
end

increment_class_rank!(class, n=1) = class.classRank += n
