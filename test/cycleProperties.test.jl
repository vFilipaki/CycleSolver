using Test, CycleSolver

@testset "cycleProperties.test.jl: Get index of Cycle by state symbol" begin
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.createState(:st1)
    CycleSolver.createState(:st2)
    CycleSolver.createState(:st3)
    CycleSolver.SystemCycles[end].states = [
        CycleSolver.st1, CycleSolver.st2, CycleSolver.st3
    ]

    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.createState(:sta)
    CycleSolver.createState(:stb)
    CycleSolver.createState(:stc)
    CycleSolver.SystemCycles[end].states = [
        CycleSolver.sta, CycleSolver.stb, CycleSolver.stc
    ]
    
    @test CycleSolver.GetCycleIndexByStateSymbol(:st1) == 1
    @test CycleSolver.GetCycleIndexByStateSymbol(:stb) == 2
    @test CycleSolver.GetCycleIndexByStateSymbol(:st3) == 1
end

@testset "cycleProperties.test.jl: Assign properties to cycle and calculate total" begin
    CycleSolver.ClearSystem()

    inStt = :st1
    outStt = :st2
    push!(CycleSolver.PropsEquations, Any[:qin, 
    :($outStt.h - $inStt.h),
    [string("component1: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 50))
    CycleSolver.NewEquation(:($outStt.h = 100))

    inStt = :sta
    outStt = :stb
    push!(CycleSolver.PropsEquations, Any[:qin, 
    :($outStt.h - $inStt.h),
    [string("component2: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 35))
    CycleSolver.NewEquation(:($outStt.h = 330))

    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)
    CycleSolver.EvaluatePropertiesEquations()
    CycleSolver.PropsEquations[1][3][2] = 1
    CycleSolver.PropsEquations[2][3][2] = 1

    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.AssignPropertiesToCycle()

    @test CycleSolver.SystemCycles[1].thermoProperties.qin[1][1] == 50.0
    @test CycleSolver.SystemCycles[1].thermoProperties.qin[2][1] == 295.0

    CycleSolver.CalculateTotalValueOfProperties(CycleSolver.SystemCycles[1])

    @test CycleSolver.SystemCycles[1].thermoProperties.qin["total"] == 345.0
end

@testset "cycleProperties.test.jl: Calculate cycle efficiency" begin
    CycleSolver.ClearSystem()

    inStt = :st1
    outStt = :st2
    push!(CycleSolver.PropsEquations, Any[:qin, 
    :($outStt.h - $inStt.h),
    [string("component1: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 50))
    CycleSolver.NewEquation(:($outStt.h = 150))

    inStt = :sta
    outStt = :stb
    push!(CycleSolver.PropsEquations, Any[:win, 
    :($outStt.h - $inStt.h),
    [string("component2: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 380))
    CycleSolver.NewEquation(:($outStt.h = 500))

    inStt = :stx
    outStt = :sty
    push!(CycleSolver.PropsEquations, Any[:wout, 
    :($outStt.h - $inStt.h),
    [string("component3: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 100))
    CycleSolver.NewEquation(:($outStt.h = 300))

    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)
    CycleSolver.EvaluatePropertiesEquations()
    CycleSolver.PropsEquations[1][3][2] = 1
    CycleSolver.PropsEquations[2][3][2] = 1
    CycleSolver.PropsEquations[3][3][2] = 1
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false
    CycleSolver.AssignPropertiesToCycle()
    CycleSolver.CalculateTotalValueOfProperties(CycleSolver.SystemCycles[1])

    CycleSolver.CalculateCycleEfficiency(CycleSolver.SystemCycles[1])

    @test CycleSolver.SystemCycles[1].thermoProperties.n == 80
end

@testset "cycleProperties.test.jl: Calculate refrigeration cycle efficiency" begin
    CycleSolver.ClearSystem()

    inStt = :st1
    outStt = :st2
    push!(CycleSolver.PropsEquations, Any[:qin, 
    :($outStt.h - $inStt.h),
    [string("component1: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 50))
    CycleSolver.NewEquation(:($outStt.h = 170))

    inStt = :sta
    outStt = :stb
    push!(CycleSolver.PropsEquations, Any[:win, 
    :($outStt.h - $inStt.h),
    [string("component2: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 350))
    CycleSolver.NewEquation(:($outStt.h = 500))

    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)
    CycleSolver.EvaluatePropertiesEquations()
    CycleSolver.PropsEquations[1][3][2] = 1
    CycleSolver.PropsEquations[2][3][2] = 1
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = true
    CycleSolver.AssignPropertiesToCycle()
    CycleSolver.CalculateTotalValueOfProperties(CycleSolver.SystemCycles[1])

    CycleSolver.CalculateCycleEfficiency(CycleSolver.SystemCycles[1])

    @test CycleSolver.SystemCycles[1].thermoProperties.n == 0.8
end