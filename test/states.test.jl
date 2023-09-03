using Test, CycleSolver, CoolProp

@testset "states.test.jl: Clear state" begin
    CycleSolver.clearStates()
    @test length(CycleSolver.unsolvedStates) == 0;
    @test length(CycleSolver.SystemStates) == 0;
end

@testset "states.test.jl: State creation" begin
    CycleSolver.createState(:st1)
    @test CycleSolver.st1 isa CycleSolver.Stt

    CycleSolver.createState(:(st[5]))
    @test length(CycleSolver.st) == 5
    @test CycleSolver.st[5] isa CycleSolver.Stt    
end

@testset "states.test.jl: Calculation of state properties" begin
    testVar = CycleSolver.StateProps("Water", ["P", 1000, "T", 300])
    @test testVar[1] == 300
    @test testVar[2] == 1000
    @test testVar[3] == CoolProp.PropsSI("H", "P", 1000 * 1000, "T", 300, "Water") / 1000
    @test testVar[4] == CoolProp.PropsSI("S", "P", 1000 * 1000, "T", 300, "Water") / 1000

    testVar = CycleSolver.StateProps("Water", ["Q", 0, "T", 400])
    @test testVar[1] == 400
    @test testVar[2] == CoolProp.PropsSI("P", "Q", 0, "T", 400, "Water") / 1000
    @test testVar[3] == CoolProp.PropsSI("H", "Q", 0, "T", 400, "Water") / 1000
    @test testVar[4] == CoolProp.PropsSI("S", "Q", 0, "T", 400, "Water") / 1000
end

@testset "states.test.jl: Calculation of unknown properties of states" begin
    CycleSolver.createState(:st2)
    CycleSolver.st2.fluid = "Water"
    CycleSolver.st2.T = 300
    CycleSolver.st2.p = 1000
    CycleSolver.StatesSolver(CycleSolver.unsolvedStates)
    @test CycleSolver.st2.T == 300
    @test CycleSolver.st2.p == 1000
    @test CycleSolver.st2.h == CoolProp.PropsSI("H", "P", 1000 * 1000, "T", 300, "Water") / 1000
    @test CycleSolver.st2.s == CoolProp.PropsSI("S", "P", 1000 * 1000, "T", 300, "Water") / 1000

    CycleSolver.createState(:st3)
    CycleSolver.st3.fluid = "Water"
    CycleSolver.st3.T = 400
    CycleSolver.st3.Q = 0
    CycleSolver.StatesSolver(CycleSolver.unsolvedStates)
    @test CycleSolver.st3.T == 400
    @test CycleSolver.st3.p == CoolProp.PropsSI("P", "Q", 0, "T", 400, "Water") / 1000
    @test CycleSolver.st3.h == CoolProp.PropsSI("H", "Q", 0, "T", 400, "Water") / 1000
    @test CycleSolver.st3.s == CoolProp.PropsSI("S", "Q", 0, "T", 400, "Water") / 1000
end