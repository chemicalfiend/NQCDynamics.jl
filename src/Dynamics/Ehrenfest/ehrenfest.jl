using StatsBase: mean
using .Calculators: DiabaticCalculator, RingPolymerDiabaticCalculator

export Ehrenfest

struct Ehrenfest{T} <: AbstractEhrenfest
    density_propagator::Matrix{Complex{T}}
    function Ehrenfest{T}(n_states::Integer) where {T}
        density_propagator = zeros(n_states, n_states)
        new{T}(density_propagator)
    end
end


function acceleration!(dv, v, r, sim::Simulation{<:Ehrenfest}, t, σ)
    for i in axes(dv, 2)
        for j in axes(dv, 1)
            dv[j,i] = -round(sum(sim.calculator.adiabatic_derivative[j,i] .* σ) / sim.atoms.masses[i])
        end
    end
    return nothing
end

"""
    get_population(sim::Simulation{<:Ehrenfest}, u)

"""
function get_population(sim::Simulation{<:Ehrenfest}, u)
    Calculators.evaluate_potential!(sim.calculator, get_positions(u))
    Calculators.eigen!(sim.calculator)
    U = sim.calculator.eigenvectors

    σ = get_density_matrix(u)

    return real.(diag(U * σ * U'))
end

function NonadiabaticMolecularDynamics.evaluate_hamiltonian(sim::Simulation{<:Ehrenfest}, u)
    k = evaluate_kinetic_energy(sim.atoms.masses, get_velocities(u))
    Calculators.evaluate_potential!(sim.calculator, get_positions(u))
    Calculators.eigen!(sim.calculator)
    p = diag(get_density_matrix(u)) .* sim.calculator.eigenvalues
    return k + p
end
