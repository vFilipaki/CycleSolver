using Test, CycleSolver

@testset "CycleSolver" begin
    @testset "Equations" begin include("equations.test.jl"); end
end
