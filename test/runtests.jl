using Test, CycleSolver

@testset "CycleSolver" begin
    # @testset "Equations" begin include("equations.test.jl"); end
    @testset "States" begin include("states.test.jl"); end
end
