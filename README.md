# SocioEconomics.jl 

A library of types, components and simulation functions for establishing socio-economic studies. The initial code is based on the LoneParentsModel.jl package initially implemented by Atiyah Elsheikh and Martin Hinsch.  

### Releases of the Lone 
- **V0**     (22.11.2022) : the state of the Lone parents model package in release V0.6.1

- **V0.1**  (28.11.2022) : removing simulation programs to another package, first draft of a model API 

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


