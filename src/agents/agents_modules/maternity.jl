export MaternityBlock
export start_maternity!, step_maternity!, end_maternity!, is_in_maternity, maternity_duration

mutable struct MaternityBlock
    maternityStatus :: Bool
    monthsSinceBirth :: Int
end

is_in_maternity(mat) = mat.maternityStatus
maternity_duration(mat) = mat.monthsSinceBirth

function start_maternity!(mat)
    mat.maternityStatus = true
    mat.monthsSinceBirth = 0
    nothing
end

step_maternity!(mat) = mat.monthsSinceBirth += 1

function end_maternity!(mat)
    mat.maternityStatus = false
    mat.monthsSinceBirth = 0
    nothing
end
