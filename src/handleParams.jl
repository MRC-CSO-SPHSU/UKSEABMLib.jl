using ParamUtils
using YAML


"extract name of parameter category from struct type name"
nameOfParType(t) = replace(String(nameof(t)), "Pars" => "") |> Symbol


function saveParametersToFile(simPars::SimulationPars, 
                                dataPars::DataPars, 
                                pars::DemographyPars, fname)
    dict = Dict{Symbol, Any}()

    dict[:Simulation] = parToYaml(simPars)

    dict[:Data] = parToYaml(dataPars)

    for f in fieldnames(DemographyPars)
        name = nameOfParType(fieldtype(DemographyPars, f))
        dict[name] = parToYaml(getfield(pars, f))
    end
    
    YAML.write_file(fname, dict)
end


function loadParametersFromFile(fname)
    DT = Dict{Symbol, Any}
    yaml = fname == "" ? DT() : YAML.load_file(fname, dicttype=DT)

    simpars = parFromYaml(yaml, SimulationPars, :Simulation)

    datapars = parFromYaml(yaml, DataPars, :Data)

    pars = [ parFromYaml(yaml, ft, nameOfParType(ft)) 
            for ft in fieldtypes(DemographyPars) ]
    simpars, datapars, DemographyPars(pars...)
end


function loadParameters(argv, cmdl...)
	arg_settings = ArgParseSettings("run simulation", autofix_names=true)

	@add_arg_table! arg_settings begin
		"--par-file", "-p"
            help = "parameter file"
            default = ""
        "--par-out-file", "-P"
			help = "file name for parameter output"
			default = "parameters.run.yaml"
	end

    if ! isempty(cmdl)
        add_arg_table!(arg_settings, cmdl...)
    end

    # setup command line arguments with docs 
    
	add_arg_group!(arg_settings, "Simulation Parameters")
	fieldsAsArgs!(arg_settings, SimulationPars)

    add_arg_group!(arg_settings, "Data Parameters")
	fieldsAsArgs!(arg_settings, DataPars)

    for t in fieldtypes(DemographyPars)
        groupName =  String(nameOfParType(t)) * " Parameters"
        add_arg_group!(arg_settings, groupName)
        fieldsAsArgs!(arg_settings, t)
    end

    # parse command line
	args = parse_args(argv, arg_settings, as_symbols=true)

    # read parameters from file if provided or set to default
    simpars, datapars, pars = loadParametersFromFile(args[:par_file])

    # override values that were provided on command line

    overrideParsCmdl!(simpars, args)

    overrideParsCmdl!(datapars, args)

    @assert typeof(pars) == DemographyPars
    for f in fieldnames(DemographyPars)
        overrideParsCmdl!(getfield(pars, f), args)
    end

    # Atiyah: for more DRY Code, you may consider using 
    # LPM.ParamTypes.{seed!,reseed0!} within mainHelpers.jl 
    # and remove the following call & the using statement 
    # set time dependent seed
    if simpars.seed == 0
        simpars.seed = floor(Int, time())
    end

    # keep a record of parameters used (including seed!)
    saveParametersToFile(simpars, datapars, pars, args[:par_out_file])

    simpars, datapars, pars, args
end



