"""
    Ensembles

This module provides two main functions [`run_trajectories`](@ref Ensembles.run_trajectories)
and [`run_ensemble`](@ref Ensembles.run_ensemble).
Each of these serves to run multiple trajectories for a given simulation type, sampling
from an initial distribution.
"""
module Ensembles

using SciMLBase: remake, EnsembleThreads, EnsembleProblem, solve
using RecursiveArrayTools: ArrayPartition
using TypedTables: TypedTables

using NonadiabaticDynamicsBase: NonadiabaticDynamicsBase
using NonadiabaticMolecularDynamics:
    AbstractSimulation,
    Simulation,
    RingPolymerSimulation,
    DynamicsUtils,
    DynamicsMethods,
    RingPolymers

using ..InitialConditions: DynamicalDistribution

function select_u0(sim::Simulation{<:Union{DynamicsMethods.ClassicalMethods.Classical, DynamicsMethods.ClassicalMethods.AbstractMDEF}}, v, r, state, type)
    DynamicsMethods.DynamicsVariables(sim, v, r)
end

function select_u0(sim::RingPolymerSimulation{<:DynamicsMethods.ClassicalMethods.ThermalLangevin}, v, r, state, type)
    DynamicsMethods.DynamicsVariables(sim, RingPolymers.RingPolymerArray(v), RingPolymers.RingPolymerArray(r))
end

function select_u0(sim::AbstractSimulation{<:DynamicsMethods.SurfaceHoppingMethods.FSSH}, v, r, state, type)
    DynamicsMethods.DynamicsVariables(sim, v, r, state; type=type)
end

function select_u0(sim::AbstractSimulation{<:DynamicsMethods.EhrenfestMethods.Ehrenfest}, v, r, state, type)
    DynamicsMethods.DynamicsVariables(sim, v, r, state; type=type)
end

function select_u0(sim::RingPolymerSimulation{<:DynamicsMethods.MappingVariableMethods.NRPMD}, v, r, state, type)
    DynamicsMethods.DynamicsVariables(sim, v, r, state; type=type)
end

function select_u0(sim::AbstractSimulation{<:DynamicsMethods.SurfaceHoppingMethods.IESH}, v, r, state, type)
    DynamicsMethods.DynamicsVariables(sim, v, r)
end

include("selections.jl")
include("reductions.jl")
include("outputs.jl")

"""
    run_ensemble(sim::AbstractSimulation, tspan, distribution;
        selection=nothing,
        output=(sol,i)->(sol,false),
        reduction=(u,data,I)->(append!(u,data),false),
        ensemble_algorithm=EnsembleThreads(),
        algorithm=DynamicsMethods.select_algorithm(sim),
        kwargs...
        )

Run multiple trajectories for timespan `tspan` sampling from `distribution`.
The DifferentialEquations ensemble interface is used which allows us to specify
functions to modify the output and how it is reduced across trajectories.

# Keywords

* `selection` should be an `AbstractVector` containing the indices to sample from the `distribution`
By default, `nothing` leads to random sampling.
* `output` should be a function as described in the DiffEq docs that takes the solution and returns the output.
* `algorithm` is the algorithm used to integrate the equations of motion.
* `ensemble_algorithm` is the algorithm from DifferentialEquations which determines which
form of parallelism is used.

This function wraps the EnsembleProblem from DifferentialEquations and passes the `kwargs`
to the `solve` function.
"""
function run_ensemble(
    sim::AbstractSimulation, tspan,
    distribution;
    selection=nothing,
    output=(sol,i)->(sol,false),
    reduction=(u,data,I)->(append!(u,data),false),
    ensemble_algorithm=EnsembleThreads(),
    algorithm=DynamicsMethods.select_algorithm(sim),
    kwargs...
    )

    stripped_kwargs = NonadiabaticDynamicsBase.austrip_kwargs(;kwargs...)

    u = rand(distribution)
    u0 = select_u0(sim, u.v, u.r, distribution.state, distribution.type)
    problem = DynamicsMethods.create_problem(u0, austrip.(tspan), sim)

    if hasfield(typeof(reduction), :u_init)
        u_init = reduction.u_init
    else
        u_init = []
    end

    if selection isa AbstractVector
        selection = OrderedSelection(distribution, selection)
    else
        selection = RandomSelection(distribution)
    end

    ensemble_problem = EnsembleProblem(
        problem,
        prob_func=selection,
        output_func=output,
        reduction=reduction,
        u_init=u_init
    )

    solve(ensemble_problem, algorithm, ensemble_algorithm; stripped_kwargs...)
end

"""
    run_trajectories(sim::AbstractSimulation, tspan, distribution;
        selection=nothing, output=(:u),
        ensemble_algorithm=EnsembleThreads(), saveat=[], kwargs...)

Run multiple trajectories and output the results in the same way as the
[`run_trajectory`](@ref DynamicsMethods.run_trajectory) function.
"""
function run_trajectories(sim::AbstractSimulation, tspan, distribution;
    selection=nothing, output=(:u),
    ensemble_algorithm=EnsembleThreads(), saveat=[], kwargs...)

    if !(output isa Tuple)
        output = (output,)
    end

    stripped_kwargs = NonadiabaticDynamicsBase.austrip_kwargs(;kwargs...)
    saveat = austrip.(saveat)

    u = rand(distribution)
    problem = DynamicsMethods.create_problem(
        select_u0(sim, u.v, u.r,
            distribution.state, distribution.type),
        austrip.(tspan),
        sim)

    if selection isa AbstractVector
        selection = OrderedSelection(distribution, selection)
    else
        selection = RandomSelection(distribution)
    end

    new_selection = SelectWithCallbacks(selection, DynamicsMethods.get_callbacks(sim), output, kwargs[:trajectories], saveat=saveat)

    ensemble_problem = EnsembleProblem(problem, prob_func=new_selection)

    solve(ensemble_problem, DynamicsMethods.select_algorithm(sim), ensemble_algorithm; saveat=saveat, stripped_kwargs...)
    [TypedTables.Table(t=vals.t, [(;zip(output, val)...) for val in vals.saveval]) for vals in new_selection.values]
end

end # module
