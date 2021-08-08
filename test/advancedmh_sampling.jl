using Test
using NonadiabaticMolecularDynamics
using StatsBase: mean
using RecursiveArrayTools
using Random
Random.seed!(1)

ats = [3, 1, 10]
Ds = [1, 3, 7]
Ts = [0.5, 1, 10]

@testset "Classical" begin
    for (natoms, DoFs, T) in zip(ats, Ds, Ts)
        sim = Simulation(Atoms(rand(natoms)), Harmonic(); DoFs=DoFs, temperature=T)
        R0 = rand(DoFs, natoms)
        u0 = ArrayPartition(zero(R0), R0)
        chain = InitialConditions.sample_configurations(sim, u0, 1e5, Dict(:X=>1))
        energy = evaluate_hamiltonian.(sim, chain)
        @test mean(energy) / (DoFs*natoms) ≈ T rtol=1e-1
    end
end

# @testset "Ring polymer" begin
#     natoms = 1
#     DoFs = 1
#     nbeads = 10
#     T = 1
#     sim = RingPolymerSimulation(Atoms(1.0), Harmonic(), nbeads; DoFs=DoFs, temperature=T)
#     R0 = rand(DoFs, natoms, nbeads)
#     chain = InitialConditions.sample_configurations(sim, R0, 1e5, Dict(:X=>10); move_ratio=0.2)
#     potential = evaluate_potential_energy.(sim, chain)
#     @test mean(potential) / (DoFs*natoms*nbeads) ≈ nbeads*T / 2 rtol=1e-1
# end

# natoms = 1
# DoFs = 1
# sim = Simulation(Atoms([1]), Harmonic(); DoFs=DoFs, temperature=1)
# V0 = zeros(DoFs, natoms)
# R0 = rand(DoFs, natoms)
# u0 = ArrayPartition(V0, R0)
# chain = InitialConditions.sample_configurations(sim, u0, 1e3, Dict(:X=>1))
# mean(evaluate_hamiltonian.(sim, chain))

# using Plots


# scatter([p[1] for p in get_velocities.(chain)], [p[1] for p in get_positions.(chain)])




