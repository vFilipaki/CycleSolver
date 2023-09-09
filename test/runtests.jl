using Test, CycleSolver

@testset "CycleSolver" begin
    @testset "Equations" begin include("equations.test.jl"); end
    @testset "States" begin include("states.test.jl"); end
    @testset "Mass flow" begin include("massFlowManager.test.jl"); end
end
