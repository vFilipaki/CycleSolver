using Test, CycleSolver

@testset "thermoProperties.test.jl: Manage component tag" begin
    tags = [
        "component1: st1 >> st2",
        "component2: :st1 >> :st2",
        "component3: st1 >> [st2, st3]",
        "component4: :st1 >> Any[:st2, :st3]",
        "component4: Any[:st1, :st2] >> Any[:st3, :st4, :st5]",
    ]
    expectedResults = [
        "component1: st1 >> st2",
        "component2: :st1 >> :st2",
        "component3: st1 >> [st2, st3]",
        "component4: :st1 >> [st2, st3]",
        "component4: [st1, st2] >> [st3, st4, st5]",
    ]
    for i in 1:5        
        @test CycleSolver.ManageComponentTag(tags[i]) ==
        expectedResults[i]
    end
end

@testset "thermoProperties.test.jl: Evaluate properties" begin
    CycleSolver.ClearSystem()
    inStt = :st1
    outStt = :st2
    push!(CycleSolver.PropsEquations, Any[:qin, 
    :($outStt.h - $inStt.h),
    [string("component1: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 50))
    CycleSolver.NewEquation(:($outStt.h = 100))
    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)
    CycleSolver.EvaluatePropertiesEquations()

    @test CycleSolver.PropsEquations[1][2] == 50
end

@testset "thermoProperties.test.jl: Generate flex heat equations" begin
    CycleSolver.ClearSystem()
    inStt = :st1
    outStt = :st2

    push!(CycleSolver.qflex, Any[[inStt], [outStt],
    string("component1: ", string(inStt), " >> ", string(outStt))])

    result = CycleSolver.GenerateFlexHeatEquations(false, CycleSolver.qflex[1])
    @test string(result[1][1]) == "Union{Nothing, Expr}[nothing, :(st1.h)]"
    @test string(result[2]) == "Expr[:(st2.h)]"

    result = CycleSolver.GenerateFlexHeatEquations(true, CycleSolver.qflex[1])
    @test string(result[1][1]) == "Union{Nothing, Expr}[nothing, :(st1.h * st1.m)]"
    @test string(result[2]) == "Expr[:(st2.h * st2.m)]"

    inStt = [:st1, :sta]
    outStt = [:st2, :stb]
    push!(CycleSolver.qflex, Any[inStt, outStt,
    string("component2: ", string(inStt), " >> ", string(outStt))])

    result = CycleSolver.GenerateFlexHeatEquations(false, CycleSolver.qflex[2])
    @test string(result[1][1]) == "Union{Nothing, Expr}[nothing, :(st1.h + sta.h)]"
    @test string(result[2]) == "Expr[:(st2.h + stb.h)]"

    result = CycleSolver.GenerateFlexHeatEquations(true, CycleSolver.qflex[2])
    @test string(result[1][1]) == "Union{Nothing, Expr}[nothing, :(st1.h * st1.m + sta.h * sta.m)]"
    @test string(result[2]) == "Expr[:(st2.h * st2.m + stb.h * stb.m)]"
end

@testset "thermoProperties.test.jl: Evaluate flex heat properties without mass" begin
    CycleSolver.ClearSystem()
    inStt = :st1
    outStt = :st2
    CycleSolver.NewEquation(:(st1.h = 50))
    CycleSolver.NewEquation(:(st2.h = 100))
    CycleSolver.NewEquation(:(sta.h = 200))
    CycleSolver.NewEquation(:(stb.h = 75))
    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)
    CycleSolver.st1.m = nothing
    CycleSolver.st2.m = nothing
    CycleSolver.sta.m = nothing
    CycleSolver.stb.m = nothing

    push!(CycleSolver.qflex, Any[[inStt], [outStt],
    string("component1: ", string(inStt), " >> ", string(outStt))])

    inStt = [:st1, :sta]
    outStt = [:st2, :stb]
    push!(CycleSolver.qflex, Any[inStt, outStt,
    string("component2: ", string(inStt), " >> ", string(outStt))])

    CycleSolver.EvaluateFlexHeatProperties()

    @test string(CycleSolver.PropsEquations[1][1], ", ", CycleSolver.PropsEquations[1][2]) ==
    "qin, 50.0"
    @test string(CycleSolver.PropsEquations[2][1], ", ", CycleSolver.PropsEquations[2][2]) ==
    "qout, 75.0"
end

@testset "thermoProperties.test.jl: Evaluate flex heat properties with mass" begin
    CycleSolver.ClearSystem()
    inStt = :st1
    outStt = :st2
    CycleSolver.NewEquation(:(st1.h = 50))
    CycleSolver.NewEquation(:(st2.h = 100))
    CycleSolver.NewEquation(:(sta.h = 200))
    CycleSolver.NewEquation(:(stb.h = 75))
    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)
    CycleSolver.st1.m = 2
    CycleSolver.st2.m = 2
    CycleSolver.sta.m = 5
    CycleSolver.stb.m = 5

    push!(CycleSolver.qflex, Any[[inStt], [outStt],
    string("component1: ", string(inStt), " >> ", string(outStt))])

    inStt = [:st1, :sta]
    outStt = [:st2, :stb]
    push!(CycleSolver.qflex, Any[inStt, outStt,
    string("component2: ", string(inStt), " >> ", string(outStt))])

    CycleSolver.EvaluateFlexHeatProperties()
    
    @test string(CycleSolver.PropsEquations[1][1], ", ", CycleSolver.PropsEquations[1][2]) ==
    "Qin, 100.0"
    @test string(CycleSolver.PropsEquations[2][1], ", ", CycleSolver.PropsEquations[2][2]) ==
    "qin, 50.0"
    @test string(CycleSolver.PropsEquations[3][1], ", ", CycleSolver.PropsEquations[3][2]) ==
    "Qout, 525.0"
    @test string(CycleSolver.PropsEquations[4][1], ", ", CycleSolver.PropsEquations[4][2]) ==
    "qout, 75.0"
end