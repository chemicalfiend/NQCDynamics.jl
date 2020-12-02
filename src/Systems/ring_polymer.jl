using LinearAlgebra: Symmetric, SymTridiagonal

export get_bead_masses
export bead_iterator

struct RingPolymerParameters{T<:AbstractFloat}
    n_beads::UInt
    ω_n::T
    springs::Symmetric{T}
    normal_mode_springs::Vector{T}
    function RingPolymerParameters{T}(n_beads::Integer, temperature::Real) where {T<:AbstractFloat}
        ω_n = n_beads * temperature
        new(n_beads, ω_n, get_spring_matrix(n_beads, ω_n), get_normal_mode_springs(n_beads, ω_n))
    end
end

function RingPolymerParameters(n_beads::Integer, temperature::Real)
    RingPolymerParameters{Float64}(n_beads, temperature)
end

"""
    get_L(n_beads, mass, ω_n)

Return the Circulant symmetric matrix for the ring polymer springs.
"""
function get_spring_matrix(n_beads::Integer, ω_n::Real)::Symmetric
    if n_beads == 1
        spring = zeros(1, 1)
    elseif n_beads == 2
        spring = [2 -2; -2 2]
    else
        spring = SymTridiagonal(fill(2, n_beads), fill(-1, n_beads-1))
        spring = convert(Matrix, spring)
        spring[end,1] = spring[1, end] = -1
    end
    Symmetric(spring .*  ω_n^2 / 2)
end

get_normal_mode_springs(n_beads::Integer, ω_n::Real) = get_matsubara_frequencies(n_beads, ω_n) .^2 / 2
get_matsubara_frequencies(n::Integer, ω_n::Real) = 2ω_n*sin.((0:n-1)*π/n)

get_bead_masses(n_beads::Integer, masses::Vector) = repeat(masses, inner=n_beads)

bead_iterator(n_beads::Integer, vector::Vector) = Iterators.partition(vector, n_beads)