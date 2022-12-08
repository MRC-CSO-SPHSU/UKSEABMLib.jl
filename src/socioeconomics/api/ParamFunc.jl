"""
This moduel specifies access function interfaces for parameters 
	
	interfaces to be implemented as parameter arguments and/or model arguments 
	to be used in model specificdation and simulation 
"""

module ParamFunc 

export allParameters, populationParameters, birthParameters, marriageParameters,
		divorceParameters, mapParameters, workParameters

allParameters(arg)         	= error("allParameters not implemented")  
populationParameters(arg)  	= error("populationParameters not implemented") 
birthParameters(arg)       	= error("birthParameters not implemented") 
divorceParameters(arg)		= error("divorceParameters not implemented") 
marriageParameters(arg)     = error("marriageParameters not implemented")
mapParameters(arg)			= error("mapParameters not implemented") 
workParameters(arg)         = error("workParameters not implemented") 

end # ParamFunc 