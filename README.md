# UKSEABMLib.jl 

[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

### Title 

The UKSEABMLib.jl componants library for agent-based UK-oriented socioeconomics modelling applications   

### Description 

A library of types, components and simulation functions for establishing external socioeconomic models studies for the UK. Currently the economic part is not implemented. It replecates the Lone Parent Model implemented in Python, cf. Ref. #[2]. The current implementation is extended from the LoneParentModel.jl V0.6.1 [3]. The space concept is influenced from Agents.jl [1] and it makes uses of the builtin types within ABMSim.jl simulator [4]  

### Author(s) 
[Atiyah Elsheikh](https://www.gla.ac.uk/schools/healthwellbeing/staff/atiyahelsheikh/)

### Contributor(s)  
Atiyah Elsheikh (V0.1-V0.5) 

### Release Notes 
- **V0** (22.11.2022): the state of the Lone parents model package in release V0.6.1

- **V0.1** (28.11.2022): removing simulation programs to another package, first draft of a model API 
   - V0.1.1 (29.11) : Two libraries one of which MA independent, XAgents is a submodule in the library   
   - V0.1.2 (1.12)  : re-organizing Constants within a module (to make them internally accessible with relative paths), reorganzing data parameters & adjusting reading and loading parameters within ParamTypes module
   - V0.1.3 (2.12)  : Cleaning Utilities module (removing unused code, moving Gender type to XAgents, moving applyTransition! to LPM package), Utilities is a submodule of SE[*] libraries, ParamUtils and DeclUtils are a submodule of the SE*.Utilities modules 

- **V0.2.0** (5.12.2022) : unified API for initialize and create functions. Ports and processes concepts for connections and initialisation processes. 

   - V0.2.1  (7.12) : New Simulation Interface for (3 functions doBirths!, doDeaths!, doDivorces), Improved API for parameter accessory functions
   - V0.2.2  (8.12) : doMarriages!, minor improvements 
   - V0.2.3  (9.12) : doAgeTransitions, doSocialTransitions, doWorkTransitions, adoptions
   - V0.2.4  (14.12) : Minor changes for MA Version 0.4, return indicies of dead people (i.e. starting improved return values of simulation functions)
   - V0.2.5  (21.12) : fixing major performance issues (type instabilities, excessive creation of temporary arrays), tuning API of some simulation functions (dodeaths!, dobirths! and dodivorces!), improved memory allocation (2x better) and storage allocation (25% better)
   - V0.2.6 (27.12)  : improved data structure for Town, constant for undefined house (related routines can return one type), Improved implementation of allocation algorithms (no temporary arrays), tuning do marriage algorithm (memoization can be avoided), Improved runtime performance (3x faster & 4x less memory allocation and storage) 
   - V0.2.7 (6.1.2023) : final API of four simulation functions including agent-based transition functions 
   - V0.2.8 (8.1.2023) : fixing API of assigning guardians. runtime performance improvements 15% - 20%, memory / storage improvement 25% - 33% w.r.t. V0.2.7
     
- **V0.3** (10.1.2023): Unifying the API of the rest of simulation functions (age transitions, social transitions, work transitions), speedup 25 % (w.r.t. Version 0.2.8, overall ~6x faster than V0), Memory allocation reduced (~380k instead of 24M V0.2.8, 290M V0.2, 400M V0), Storage usage reduced (90 MB instead of 10GB V0.2, 12.5 GB V0) 
   - V0.3.1 (16.1): Arbitray initial population size, following blue style code (partially conducted)  
   - V0.3.2 (20.1): blue style, improved implementation of adjacent towns
     
- **V0.4** (12.3.2023): Agents.jl-conform space type, consistency verification of initial population, removal of many significant bug related to initial population declaration, model-based operation-oriented function (starting phase) 
   - V0.4.1 (15.5) : enabling simulation with Agents.jl  
   - V0.4.2 (16.5) : simplification of main simulation functions (now without time argument)
   - V0.4.3 (19.5) : Full population as a default value for population feature across simulation functions 
   - V0.4.4 (23.5) : Attempting caching pre-computation, tiny low-level tuning

- **V0.5** (29.8.2023): Initial set of unit tests, employing ABMSim.jl V0.6 instead of MulitiAgents.jl, minor simplifications and improvements
- **V0.6** (30.8.2023): Renaming to UKSEABMLib.jl 
 
 ### License
MIT License

Copyright (c) 2023 Atiyah Elsheikh, MRC/CSO Social & Public Health Sciences Unit, School of Health and Wellbeing, University of Glasgow, Cf. [License](https://github.com/MRC-CSO-SPHSU/UKSEABMLib.jl/blob/master/LICENSE) for further information 

### Platform 
This code was developed and experimented on 
- Ubuntu 22.04.2 LTS
- VSCode V1.71.2
- Julia language V1.9.1
- Agents.jl V5.14.0

### Exeution 

This is a library with no internal examples. However, cf. [LPM.jl package](https://github.com/MRC-CSO-SPHSU/LPM.jl) as an example. Execution of unit tests within REPL: 

<code>  
  > include("tests/runtests")
</code> 

### References

[1] George Datseris, Ali R. Vahdati, Timothy C. DuBois: Agents.jl: a performant and feature-full agent-based modeling software of minimal code complexity. SIMULATION. 2022. doi:10.1177/00375497211068820 

[2] Umberto Gostoli and Eric Silverman Social and child care provision in kinship networks: An agent-based model. PLoS ONE 15(12): 2020 (https://doi.org/10.1371/journal.pone.0242779) 

[3] [LoneParentsModel.jl V0.6.1](https://archive.softwareheritage.org/browse/origin/directory/?branch=refs/tags/V0.6.1&origin_url=https://github.com/MRC-CSO-SPHSU/LoneParentsModel.jl&snapshot=7b7095bbf44a61414ed6d1abec7861c162a10e60) 

[4] [ABMSim.jl: An agent-based model simulator (V0.6.1). Zenodo. https://doi.org/10.5281/zenodo.8284009, 2023](https://github.com/MRC-CSO-SPHSU/ABMSim.jl/blob/master/README.md)

### Cite as 

TODO 

### Acknowledgments 

For the purpose of open access, the author(s) has applied a Creative Commons Attribution (CC BY) licence to any Author Accepted Manuscript version arising from this submission.

### Fundings 
[Dr. Atyiah Elsheikh](https://www.gla.ac.uk/schools/healthwellbeing/staff/atiyahelsheikh/), by the time of publishing Version 0.5 of this software, is a Research Software Engineer at MRC/CSO Social & Public Health Sciences Unit, School of Health and Wellbeing, University of Glasgow. He is in the Complexity in Health programme. He is supported  by the Medical Research Council (MC_UU_00022/1) and the Scottish Government Chief Scientist Office (SPHSU16). 
