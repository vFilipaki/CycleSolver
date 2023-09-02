using Test, CycleSolver, Symbolics

function testExprEquality(eq1, eq2)
    testValue1 = eq1.args[1] == eq2.args[1]
    testValue2 = eq1.args[2].args[1] == eq2.args[2].args[1]
    return testValue1 && testValue2
end

@testset "equations.test.jl: Clear equations and variables" begin
    CycleSolver.ClearEquations()
    @test length(CycleSolver.SystemVars) == 0;
    @test length(CycleSolver.unsolvedEquations) == 0;
    @test length(CycleSolver.unsolvedConditionalEquation) == 0;
end

@testset "equations.test.jl: Variable creation" begin
    CycleSolver.CreateVariable(:v1)
    @test CycleSolver.v1 isa Num

    CycleSolver.CreateVariable(:(v2[2]))
    for i in CycleSolver.v2
        @test i isa Num
    end

    CycleSolver.CreateVariable(:(v3[2, 3]))
    for i in CycleSolver.v3
        for j in i
            @test j isa Num
        end
    end
end

@testset "equations.test.jl: Expression has item" begin
    @test CycleSolver.ExpressionHasItem(:(2 * a + b = (c / 2)), :a) == true

    @test CycleSolver.ExpressionHasItem(:(2 * a + b = (c / 2)), :d) == false
    
    @test CycleSolver.ExpressionHasItem(:(2 * a + b = (c / 2)), :(c / 2)) == true
end

@testset "equations.test.jl: Expression substitution" begin
    @test testExprEquality(
        CycleSolver.ExpressionSubstitution(:(2 * a + b = (c / 2)), :a, :d),
        :(2 * d + b = (c / 2)))

    @test testExprEquality(
        CycleSolver.ExpressionSubstitution(:(2 * a + b = (c / 2)), :(c / 2), :e),
        :(2 * a + b = e))

    @test testExprEquality(
        CycleSolver.ExpressionSubstitution(:(2 * a + b = (c / 2)), :x, :z),
        :(2 * a + b = (c / 2)))
end

@testset "equations.test.jl: Equation creation" begin
    CycleSolver.NewEquation(:(a1 = a2))
    @test CycleSolver.unsolvedEquations[end] isa CycleSolver.MathEq
    @test length(CycleSolver.unsolvedEquations[end].vars) == 2
    @test string(CycleSolver.unsolvedEquations[end].Eq) == "a1Vars ~ a2Vars"

    CycleSolver.NewEquation(:(b1 / b2 = b3 / b4))
    @test CycleSolver.unsolvedEquations[end] isa CycleSolver.MathEq
    @test length(CycleSolver.unsolvedEquations[end].vars) == 4
    @test string(CycleSolver.unsolvedEquations[end].Eq) == "b1Vars*b4Vars ~ b2Vars*b3Vars"

    CycleSolver.NewEquation(:(c1 = c2 / (c3 + c4 / c5) + c6 / c7))
    @test CycleSolver.unsolvedEquations[end] isa CycleSolver.MathEq
    @test length(CycleSolver.unsolvedEquations[end].vars) == 7
    @test string(CycleSolver.unsolvedEquations[end].Eq) == 
    "c1Vars*c7Vars*(c4Vars + c3Vars*c5Vars) ~ c4Vars*c6Vars + c2Vars*c5Vars*c7Vars + c3Vars*c5Vars*c6Vars"
end

@testset "equations.test.jl: Equation solution" begin
    CycleSolver.NewEquation(:(d1 = 10))
    CycleSolver.EquationsSolver([CycleSolver.unsolvedEquations[end]])
    @test CycleSolver.d1 == 10.0
    
    CycleSolver.NewEquation(:(d2 = d3 + 10))
    CycleSolver.NewEquation(:(d3 = 20))
    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations[end-1:end])
    @test CycleSolver.d2 == 30.0
    @test CycleSolver.d3 == 20.0
    
    CycleSolver.NewEquation(:(x1 + x2 = 12))
    CycleSolver.NewEquation(:(3 * x1 - x2 = 20))
    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations[end-1:end])
    @test CycleSolver.x1 == 8.0
    @test CycleSolver.x2 == 4.0
    
    CycleSolver.NewEquation(:(z1 + 2*z2 + z3 = 12))
    CycleSolver.NewEquation(:(z1 - 3*z2 + 5*z3 = 1))
    CycleSolver.NewEquation(:(2*z1 - z2 + 3*z3 = 10))
    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations[end-2:end])
    @test CycleSolver.z1 == 5.0
    @test CycleSolver.z2 == 3.0
    @test CycleSolver.z3 == 1.0
end

@testset "equations.test.jl: Equation update" begin
    CycleSolver.NewEquation(:(w1 + w2 = w3))
    CycleSolver.NewEquation(:(w3 = 5))
    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)
    CycleSolver.UpdateEquationList(CycleSolver.unsolvedEquations)
    @test length(CycleSolver.unsolvedEquations[end].vars) == 2
    @test string(CycleSolver.unsolvedEquations[end].Eq) == "w1Vars + w2Vars ~ 5.0"
    
    CycleSolver.NewEquation(:(w4 * w5 = w6 * w7))
    CycleSolver.NewEquation(:(w4 = w6 + 5))
    CycleSolver.NewEquation(:(w4 = 2))
    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)
    CycleSolver.UpdateEquationList(CycleSolver.unsolvedEquations)
    @test length(CycleSolver.unsolvedEquations[end].vars) == 2
    @test string(CycleSolver.unsolvedEquations[end].Eq) == "2.0w5Vars ~ -3.0w7Vars"
end

@testset "equations.test.jl: Conditional equation" begin
    condVar1 = CycleSolver.ConditionalMathEq(
        :(true), 
        [:(vc1 = 0)],
        [:(vc1 = 1)])
    @test condVar1 isa CycleSolver.ConditionalMathEq
    CycleSolver.ManageConditionalEquations([condVar1])
    @test length(CycleSolver.unsolvedEquations[end].vars) == 1
    @test string(CycleSolver.unsolvedEquations[end].Eq) == "vc1Vars ~ 0"

    condVar2 = CycleSolver.ConditionalMathEq(
            :(false), 
            [:(vc2 = 0)],
            [:(vc2 = 1)])
    @test condVar2 isa CycleSolver.ConditionalMathEq
    CycleSolver.ManageConditionalEquations([condVar2])
    @test length(CycleSolver.unsolvedEquations[end].vars) == 1
    @test string(CycleSolver.unsolvedEquations[end].Eq) == "vc2Vars ~ 1"
end
