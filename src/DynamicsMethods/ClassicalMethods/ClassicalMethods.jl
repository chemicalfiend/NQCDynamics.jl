
module ClassicalMethods

using NQCDynamics:
    NQCDynamics,
    AbstractSimulation,
    Simulation,
    RingPolymerSimulation,
    DynamicsUtils,
    DynamicsMethods,
    Estimators,
    RingPolymers
using NQCDynamics.Calculators: Calculators
using NQCBase: Atoms
using NQCModels: Model, ndofs

include("classical.jl")
export Classical
include("langevin.jl")
export Langevin, ThermalLangevin
include("mdef.jl")
export MDEF
include("diabatic_mdef.jl")
export DiabaticMDEF
include("rpmdef.jl")

const ClassicalMethodUnion = Union{Classical, Langevin, ThermalLangevin, MDEF, DiabaticMDEF}

end # module
