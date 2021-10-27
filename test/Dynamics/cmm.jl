
using Test
using NonadiabaticMolecularDynamics
using FiniteDiff
using LinearAlgebra: norm

function test_motion!(sim::Simulation{<:eCMM}, u)
    f(x) = DynamicsUtils.classical_hamiltonian(sim, x)

    grad = FiniteDiff.finite_difference_gradient(f, u)

    du = zero(u)
    DynamicsMethods.motion!(du, u, sim, 0.0)

    @test DynamicsUtils.get_positions(du) ≈ DynamicsUtils.get_velocities(grad) ./ sim.atoms.masses' rtol=1e-3
    @test DynamicsUtils.get_velocities(du) ≈ -DynamicsUtils.get_positions(grad) ./ sim.atoms.masses' rtol=1e-3
    @test DynamicsMethods.MappingVariableMethods.get_mapping_positions(du) ≈ DynamicsMethods.MappingVariableMethods.get_mapping_momenta(grad) rtol=1e-3
    @test DynamicsMethods.MappingVariableMethods.get_mapping_momenta(du) ≈ -DynamicsMethods.MappingVariableMethods.get_mapping_positions(grad) rtol=1e-3
end

sim = Simulation{eCMM}(Atoms(1), DoubleWell(); γ=0.0)
sim1 = Simulation{eCMM}(Atoms(1), DoubleWell(); γ=0.5)

v = randn(1,1)
r = randn(1,1)
u = DynamicsVariables(sim, v, r, SingleState(1))
u1 = DynamicsVariables(sim1, v, r, SingleState(1))

test_motion!(sim, u)
test_motion!(sim1, u1)

sol = run_trajectory(u, (0, 100.0), sim; output=(:hamiltonian, :position, :u), reltol=1e-10, abstol=1e-10)
@test sol.hamiltonian[1] ≈ sol.hamiltonian[end] rtol=1e-3
qmap = [u.qmap for u in sol.u]
pmap = [u.pmap for u in sol.u]
total_population = sum.(DynamicsMethods.MappingVariableMethods.mapping_kernel.(qmap, pmap, sim.method.γ))
@test all(isapprox.(total_population, 1, rtol=1e-3))

sol = run_trajectory(u1, (0, 100.0), sim1; output=(:hamiltonian, :position, :u), reltol=1e-10, abstol=1e-10)
@test sol.hamiltonian[1] ≈ sol.hamiltonian[end] rtol=1e-3
total_population = sum.(DynamicsMethods.MappingVariableMethods.mapping_kernel.(qmap, pmap, sim.method.γ))
@test all(isapprox.(total_population, 1, rtol=1e-3))

@testset "generate_random_points_on_nsphere" begin
    points = DynamicsMethods.MappingVariableMethods.generate_random_points_on_nsphere(10, 1)
    @test norm(points) ≈ 1
    points = DynamicsMethods.MappingVariableMethods.generate_random_points_on_nsphere(10, 10)
    @test norm(points) ≈ 10
end

@testset "Population correlation" begin
    # Tests that the initial state correlated with itself is 1 and correlated with other state is 0.
    gams = -0.5:0.5:1.5
    for γ in gams[2:end]
        @testset "Gamma = $γ" begin
            sim = Simulation{eCMM}(Atoms(1), DoubleWell(); γ=γ)
            out = zeros(2, 2)
            n = 1e4
            for i=1:n
                u = DynamicsVariables(sim, 0, 0, SingleState(1))
                K = DynamicsMethods.MappingVariableMethods.mapping_kernel(u.qmap, u.pmap, sim.method.γ)
                Kinv = DynamicsMethods.MappingVariableMethods.inverse_mapping_kernel(u.qmap, u.pmap, sim.method.γ)
                out .+= 2K * Kinv'
            end
            @test out ./ n ≈ [1 0; 0 1] atol=0.1
        end
    end
end
