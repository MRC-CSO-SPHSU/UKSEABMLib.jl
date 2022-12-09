# SocioEconomics.jl 

A library of types, components and simulation functions for establishing socio-economic studies. The initial code is based on the LoneParentsModel.jl package initially implemented by Atiyah Elsheikh and Martin Hinsch.  

### Releases of the Lone 
- **V0**     (22.11.2022) : the state of the Lone parents model package in release V0.6.1
- **V0.1**  (28.11.2022) : removing simulation programs to another package, first draft of a model API 
   - V0.1.1 (29.11) : Two libraries one of which MA independent, XAgents is a submodule in the library   
   - V0.1.2 (1.12)  : re-organizing Constants within a module (to make them internally accessible with relative paths), reorganzing data parameters & adjusting reading and loading parameters within ParamTypes module
   - V0.1.3 (2.12)  : Cleaning Utilities module (removing unused code, moving Gender type to XAgents, moving applyTransition! to LPM package), Utilities is a submodule of SE[*] libraries, ParamUtils and DeclUtils are a submodule of the SE*.Utilities modules 
- **V0.2.0** (5.12.2022) : unified API for initialize and create functions. Ports and processes concepts for connections and initialisation processes. 
   - V0.2.1  (7.12) : - New Simulation Interface for (3 functions doBirths!, doDeaths!, doDivorces), Improved API for parameter accessory functions
   - V0.2.2  (8.12) : - doMarriages!, minor improvements 
   - V0.2.3  (9.12) : - doAgeTransitions, doSocialTransitions, doWorkTransitions, adoptions


