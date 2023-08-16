function testExprEquality(eq1, eq2)
    testValue1 = eq1.args[1] == eq2.args[1]
    testValue2 = eq1.args[2].args[1] == eq2.args[2].args[1]
    return testValue1 && testValue2
end

@testset "equations.test.jl: Clear equations and variables" begin
    ClearEquations()
    @test length(SystemVars) == 0;
    @test length(unsolvedEquations) == 0;
    @test length(unsolvedConditionalEquation) == 0;
end

@testset "equations.test.jl: Variable creation" begin
    CreateVariable(:v1)
    @test v1 isa Num

    CreateVariable(:(v2[2]))
    for i in v2
        @test i isa Num
    end

    CreateVariable(:(v3[2, 3]))
    for i in v3
        for j in i
            @test j isa Num
        end
    end
end

@testset "equations.test.jl: Expression has item" begin
    @test ExpressionHasItem(:(2 * a + b = (c / 2)), :a) == true

    @test ExpressionHasItem(:(2 * a + b = (c / 2)), :d) == false
    
    @test ExpressionHasItem(:(2 * a + b = (c / 2)), :(c / 2)) == true
end

@testset "equations.test.jl: Expression substitution" begin
    @test testExprEquality(
        ExpressionSubstitution(:(2 * a + b = (c / 2)), :a, :d),
        :(2 * d + b = (c / 2)))

    @test testExprEquality(
        ExpressionSubstitution(:(2 * a + b = (c / 2)), :(c / 2), :e),
        :(2 * a + b = e))

    @test testExprEquality(
        ExpressionSubstitution(:(2 * a + b = (c / 2)), :x, :z),
        :(2 * a + b = (c / 2)))
end

@testset "equations.test.jl: Equation creation" begin
    NewEquation(:(a1 = a2))
    @test unsolvedEquations[end] isa MathEq
    @test length(unsolvedEquations[end].vars) == 2
    @test string(unsolvedEquations[end].Eq) == "a1Vars ~ a2Vars"

    NewEquation(:(b1 / b2 = b3 / b4))
    @test unsolvedEquations[end] isa MathEq
    @test length(unsolvedEquations[end].vars) == 4
    @test string(unsolvedEquations[end].Eq) == "b1Vars*b4Vars ~ b2Vars*b3Vars"

    NewEquation(:(c1 = c2 / (c3 + c4 / c5) + c6 / c7))
    @test unsolvedEquations[end] isa MathEq
    @test length(unsolvedEquations[end].vars) == 7
    @test string(unsolvedEquations[end].Eq) == 
    "c1Vars*c7Vars*(c4Vars + c3Vars*c5Vars) ~ c4Vars*c6Vars + c2Vars*c5Vars*c7Vars + c3Vars*c5Vars*c6Vars"
end

@testset "equations.test.jl: Equation solution" begin
    NewEquation(:(d1 = 10))
    EquationsSolver([unsolvedEquations[end]])
    @test d1 == 10.0
    
    NewEquation(:(d2 = d3 + 10))
    NewEquation(:(d3 = 20))
    EquationsSolver(unsolvedEquations[end-1:end])
    @test d2 == 30.0
    @test d3 == 20.0
    
    NewEquation(:(x1 + x2 = 12))
    NewEquation(:(3 * x1 - x2 = 20))
    EquationsSolver(unsolvedEquations[end-1:end])
    @test x1 == 8.0
    @test x2 == 4.0
    
    NewEquation(:(z1 + 2*z2 + z3 = 12))
    NewEquation(:(z1 - 3*z2 + 5*z3 = 1))
    NewEquation(:(2*z1 - z2 + 3*z3 = 10))
    EquationsSolver(unsolvedEquations[end-2:end])
    @test z1 == 5.0
    @test z2 == 3.0
    @test z3 == 1.0
end

@testset "equations.test.jl: Equation update" begin
    NewEquation(:(w1 + w2 = w3))
    NewEquation(:(w3 = 5))
    EquationsSolver(unsolvedEquations)
    UpdateEquationList(unsolvedEquations)
    @test length(unsolvedEquations[end].vars) == 2
    @test string(unsolvedEquations[end].Eq) == "w1Vars + w2Vars ~ 5.0"
    
    NewEquation(:(w4 * w5 = w6 * w7))
    NewEquation(:(w4 = w6 + 5))
    NewEquation(:(w4 = 2))
    EquationsSolver(unsolvedEquations)
    UpdateEquationList(unsolvedEquations)
    @test length(unsolvedEquations[end].vars) == 2
    @test string(unsolvedEquations[end].Eq) == "2.0w5Vars ~ -3.0w7Vars"
end

@testset "equations.test.jl: Conditional equation" begin
    condVar1 = ConditionalMathEq(
        :(true), 
        [:(vc1 = 0)],
        [:(vc1 = 1)])
    @test condVar1 isa ConditionalMathEq
    ManageConditionalEquations([condVar1])
    @test length(unsolvedEquations[end].vars) == 1
    @test string(unsolvedEquations[end].Eq) == "vc1Vars ~ 0"

    condVar2 = ConditionalMathEq(
            :(false), 
            [:(vc2 = 0)],
            [:(vc2 = 1)])
    @test condVar2 isa ConditionalMathEq
    ManageConditionalEquations([condVar2])
    @test length(unsolvedEquations[end].vars) == 1
    @test string(unsolvedEquations[end].Eq) == "vc2Vars ~ 1"
end
