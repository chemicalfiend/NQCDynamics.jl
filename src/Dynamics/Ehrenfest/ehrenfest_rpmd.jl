
function acceleration!(dv, v, r, sim::RingPolymerSimulation{<:Ehrenfest}, t, σ)
    dv .= zero(eltype(dv))
    for I in eachindex(dv)
        for J in eachindex(σ)
            dv[I] -= sim.calculator.adiabatic_derivative[I][J] * real(σ[J])
        end
    end
    divide_by_mass!(dv, sim.atoms.masses)
    apply_interbead_coupling!(dv, r, sim)
    return nothing
end

function set_density_matrix_derivative!(dσ, v, σ, sim::RingPolymerSimulation{<:Ehrenfest})
    V = sim.method.density_propagator

    V .= diagm(sum(sim.calculator.eigenvalues))
    for I in eachindex(v)
        @. V -= im * v[I] * sim.calculator.nonadiabatic_coupling[I]
    end
    V ./= length(sim.beads)
    mul!(sim.calculator.tmp_mat_complex1, V, σ)
    mul!(sim.calculator.tmp_mat_complex2, σ, V)
    @. dσ = -im * (sim.calculator.tmp_mat_complex1 - sim.calculator.tmp_mat_complex2)
    return nothing
end

function get_diabatic_population(sim::RingPolymerSimulation{<:Ehrenfest}, u)
    Calculators.evaluate_centroid_potential!(sim.calculator, get_positions(u))
    U = eigvecs(sim.calculator.potential[1])

    σ = get_density_matrix(u)
    return real.(diag(U * σ * U'))
end

function NonadiabaticMolecularDynamics.evaluate_hamiltonian(sim::RingPolymerSimulation{<:Ehrenfest}, u)
    k = evaluate_kinetic_energy(sim.atoms.masses, get_velocities(u))
    Calculators.evaluate_potential!(sim.calculator, get_positions(u))
    Calculators.eigen!(sim.calculator)

    population = get_adiabatic_population(sim, u)
    p = sum([dot(population, eigs) for eigs in sim.calculator.eigenvalues])
    return k + p
end
