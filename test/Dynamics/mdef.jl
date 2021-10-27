using Test
using NonadiabaticMolecularDynamics
using Unitful
using UnitfulAtomic
using RecursiveArrayTools: ArrayPartition
using LinearAlgebra: diag
using ComponentArrays

atoms = Atoms([:H, :H])
sim = Simulation{MDEF}(atoms, ConstantFriction(Free(),atoms.masses[1]); temperature=10u"K")

v = zeros(size(sim))
r = randn(size(sim))
u = ComponentVector(v=v, r=r)
du = zero(u)

@testset "friction!" begin
    gtmp = zeros(length(r), length(r))
    NonadiabaticMolecularDynamics.DynamicsMethods.ClassicalMethods.friction!(gtmp, r, sim, 0.0)
    @test all(diag(gtmp) .≈ 1.0)
end

sol = run_trajectory(u, (0.0, 100.0), sim; dt=1)
@test sol.u[1] ≈ u

f(t) = 100u"K"*exp(-ustrip(t))
sim = Simulation{MDEF}(atoms, NonadiabaticModels.RandomFriction(Harmonic()); temperature=f)
sol = run_trajectory(u, (0.0, 100.0), sim; dt=1)