
struct BoltzmannVelocityDistribution{T} <: Sampleable{Multivariate,Continuous}
    dist::MvNormal{T}
end

function BoltzmannVelocityDistribution(temperature, masses)
    dist = MvNormal(sqrt.(temperature ./ masses))
    BoltzmannVelocityDistribution(dist)
end

Base.length(s::BoltzmannVelocityDistribution) = length(s.dist)
function Distributions._rand!(rng::AbstractRNG, s::BoltzmannVelocityDistribution, x::AbstractVector{<:Real})
    Distributions._rand!(rng, s.dist, x)
end
function select_item(x::BoltzmannVelocityDistribution, ::Integer, size::Tuple{Int,Int})
    permutedims(rand(x, size[1]))
end
function select_item(x::BoltzmannVelocityDistribution, ::Integer, size::Tuple{Int,Int,Int})
    out = zeros(eltype(x), size)
    for i=1:size[3]
        out[:,:,i] .= permutedims(rand(x, size[1]))
    end
    return out
end