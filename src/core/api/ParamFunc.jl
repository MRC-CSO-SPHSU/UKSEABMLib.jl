"""
This moduel specifies access function interfaces for parameters

	interfaces to be implemented as parameter arguments and/or model arguments
	to be used in model specificdation and simulation
"""

module ParamFunc

export all_pars, population_pars, birth_pars, marriage_pars,
		divorce_pars, map_pars, work_pars

all_pars(arg)         	= error("all_pars not implemented")
population_pars(arg)  	= error("population_pars not implemented")
birth_pars(arg)       	= error("birth_pars not implemented")
divorce_pars(arg)		= error("divorce_pars not implemented")
marriage_pars(arg)     = error("marriage_pars not implemented")
map_pars(arg)			= error("map_pars not implemented")
work_pars(arg)         = error("work_pars not implemented")

end # ParamFunc
