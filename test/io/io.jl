using Test
using NonadiabaticMolecularDynamics.IO

p, R = read_system("test/io/slab.xyz")
@test size(R)[1] == 3
@test p isa AtomicParameters
