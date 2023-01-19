using ....Utilities: age2yearsmonths

export isfemale, ismale, agestep!, agestep_ifalive!, hasbirthday, yearsold
export Gender, male, female, unknown

#"Gender type enumeration"
@enum Gender unknown female male 

# TODO think about whether to make this immutable
mutable struct BasicInfoBlock
    age::Rational{Int} 
    # (birthyear, birthmonth)
    gender::Gender  
    alive::Bool 
end

"Default constructor"
BasicInfoBlock(;age=0//1, gender=unknown, alive = true) = BasicInfoBlock(age,gender,alive)

isfemale(person::BasicInfoBlock) = person.gender == female
ismale(person::BasicInfoBlock) = person.gender == male

"costum @show method for Agent person"
function Base.show(io::IO,  info::BasicInfoBlock)
  year, month = age2yearsmonths(info.age)
  print(" $(year) years & $(month) months, $(info.gender) ")
  info.alive ? print(" alive ") : print(" dead ")  
end

"increment an age for a person to be used in typical stepping functions"
agestep!(person::BasicInfoBlock, dt=1//12) = person.age += dt  

"increment an age for a person to be used in typical stepping functions"
function agestep_ifalive!(person::BasicInfoBlock, dt=1//12) 
    person.age += person.alive ? dt : 0  
end 

hasbirthday(person::BasicInfoBlock) = person.age % 1 == 0

function yearsold(person::BasicInfoBlock) 
    years, = age2yearsmonths(person.age)
    return years 
end 
