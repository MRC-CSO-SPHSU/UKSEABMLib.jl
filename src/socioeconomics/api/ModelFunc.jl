""" 
    This module describes basic model interfaces to
    be employed within simulation functions in any 
    *Simulate module
    
    This module is within the SocioEconomics[X] modules 
"""
module ModelFunc

#import ..ParamTypes: populationParameters ?

export allPeople, alivePeople, dataOf, houses, towns 
export add_person!, add_house!, remove_person! 
#export populationParameters    # This one implies that parameters are part of the model definition
                               # @todo check if this is necessary 

allPeople(model) = error("allPeople not implemeneted") 
alivePeople(model)  = error("alivePeople not implemented") 
dataOf(model) = error("dataOf not implemeneted") 
houses(model) = error("houses not implemented")
towns(model)  = error("towns not implemented")

add_person!(model,person) = error("add_person! not implemented")
add_house!(model,person)  = error("add_house! not implemented")
remove_person!(model,personidx::Int) = error("remove_person! not implemented")

# The following assumes that parameters are a part of the model definition
# populationParameters(model) = error("populationParameters not implemeneted")

#= Examples of implementation
# the following accessory functions to be moved to an internal module 
allPeople(model)    = model.pop      
alivePeople(model)   = Iterators.filter(a->alive(a), population(model))  
populationPars(pars) = pars.poppars        
=# 

end # ModelFunc