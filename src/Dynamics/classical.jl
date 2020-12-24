export Classical

struct Classical <: Method end

function motion!(du::DynamicalVariables, u::DynamicalVariables, sim::AbstractSimulation, t)
    set_velocity!(du, u, sim)
    set_force!(du, u, sim)
end

function set_velocity!(du::DynamicalVariables, u::DynamicalVariables, sim::AbstractSimulation)
    get_positions(du) .= get_momenta(u) ./ sim.atoms.masses'
end

function set_force!(du::DynamicalVariables, u::DynamicalVariables, sim::AbstractSimulation) 
    Calculators.evaluate_derivative!(sim.calculator, get_positions(u))
    get_momenta(du) .= -sim.calculator.derivative
end

function motion!(du::DynamicalVariables, u::DynamicalVariables, sim::RingPolymerSimulation, T)
    set_velocity!(du, u, sim)
    set_force!(du, u, sim)
    apply_interbead_coupling!(du, u, sim)
end

function apply_interbead_coupling!(du::DynamicalVariables, u::DynamicalVariables, sim::RingPolymerSimulation)
    for i in sim.beads.quantum_atoms
        for j=1:sim.DoFs
            get_momenta(du)[j,i,:] .-= 2sim.beads.springs*get_positions(u)[j,i,:] .* sim.atoms.masses[i]
        end
    end
end
