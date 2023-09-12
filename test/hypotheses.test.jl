using Test, CycleSolver

@testset "hypotheses.test.jl: Check point" begin

    CycleSolver.NewEquation(:(a = 50))
    CycleSolver.NewEquation(:(b = 150))

    checkPoint = CycleSolver.CreateCheckPoint()

    CycleSolver.NewEquation(:(c = 200))
    CycleSolver.NewEquation(:(d = 450))

    CycleSolver.RestoreCheckPoint(checkPoint)
    
    @test string(CycleSolver.unsolvedEquations[1].Eq) ==
    "aVars ~ 50"
    @test string(CycleSolver.unsolvedEquations[2].Eq) ==
    "bVars ~ 150"
end

@testset "hypotheses.test.jl: Solver with hypotheses" begin

    CycleSolver.NewEquation(:(st2.h = st1.h - (st1.h - st2s.h) * 0.8))
    CycleSolver.NewEquation(:(st1.T = 500))
    CycleSolver.NewEquation(:(st1.p = 100))    
    CycleSolver.NewEquation(:(st2.p = 200))
    CycleSolver.NewEquation(:(st1.s = st2s.s))
    CycleSolver.NewEquation(:(st2s.p = 200))

    eval(:(CycleSolver.st1.fluid = "water"))
    eval(:(CycleSolver.st2.fluid = "water"))
    eval(:(CycleSolver.st2s.fluid = "water"))

    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)
    CycleSolver.StatesSolver(CycleSolver.unsolvedStates)
    CycleSolver.UpdateEquationList(CycleSolver.unsolvedEquations)

    solutionFinded = []
    CycleSolver.SolverWithHypotheses("", solutionFinded)

    @test string(solutionFinded[1]) == "Any[:(st2.s), 7.88496093749998]"
end