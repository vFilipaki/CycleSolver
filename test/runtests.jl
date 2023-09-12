using Test, CycleSolver

@testset "CycleSolver" begin
    @testset "Equations" begin include("equations.test.jl"); end
    @testset "States" begin include("states.test.jl"); end
    @testset "Mass flow" begin include("massFlowManager.test.jl"); end
    @testset "Components" begin include("components.test.jl"); end
    @testset "Cycle Properties" begin include("cycleProperties.test.jl"); end
    @testset "System Properties" begin include("systemProperties.test.jl"); end
    @testset "Thermo Properties" begin include("thermoProperties.test.jl"); end
    @testset "Hypotheses" begin include("hypotheses.test.jl"); end
end
