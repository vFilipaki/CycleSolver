using Test, CycleSolver

@testset "systemProperties.test.jl: Filter and assign properties to system" begin
    CycleSolver.ClearSystem()

    inStt = :st1
    outStt = :st2
    push!(CycleSolver.PropsEquations, Any[:Qin, 
    :($outStt.h - $inStt.h),
    [string("component1: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 50))
    CycleSolver.NewEquation(:($outStt.h = 170))

    inStt = :sta
    outStt = :stb
    push!(CycleSolver.PropsEquations, Any[:Qin, 
    :($outStt.h - $inStt.h),
    [string("component2: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 350))
    CycleSolver.NewEquation(:($outStt.h = 500))

    inStt = :stx
    outStt = :sty
    push!(CycleSolver.PropsEquations, Any[:Qin, 
    :($outStt.h - $inStt.h),
    [string("heater_exchanger: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 250))
    CycleSolver.NewEquation(:($outStt.h = 600))

    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)
    CycleSolver.EvaluatePropertiesEquations()
    CycleSolver.PropsEquations[1][3][2] = 1
    CycleSolver.PropsEquations[2][3][2] = 2
    CycleSolver.PropsEquations[3][3][2] = 2
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = true
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = true
    CycleSolver.AssignPropertiesToCycle()
    CycleSolver.CalculateTotalValueOfProperties(CycleSolver.SystemCycles[1])
    CycleSolver.CalculateCycleEfficiency(CycleSolver.SystemCycles[1])
    CycleSolver.CalculateTotalValueOfProperties(CycleSolver.SystemCycles[2])
    CycleSolver.CalculateCycleEfficiency(CycleSolver.SystemCycles[2])

    CycleSolver.FilterAndAssignPropertiesToSystem()

    @test CycleSolver.System.Qin["total"] == 270.0
end

@testset "systemProperties.test.jl: Define refrigeration system" begin
    CycleSolver.ClearSystem()
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = true    
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = true    
    CycleSolver.DefineRefrigerationSystem()
    @test CycleSolver.isRefrigerationSystem

    CycleSolver.ClearSystem()
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false    
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false    
    CycleSolver.DefineRefrigerationSystem()
    @test !CycleSolver.isRefrigerationSystem

    CycleSolver.ClearSystem()
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = true    
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false    
    CycleSolver.DefineRefrigerationSystem()
    @test isnothing(CycleSolver.isRefrigerationSystem)
end

@testset "systemProperties.test.jl: Calculate system efficiency" begin
    CycleSolver.ClearSystem()

    inStt = :st1
    outStt = :st2
    push!(CycleSolver.PropsEquations, Any[:Qin, 
    :($outStt.h - $inStt.h),
    [string("component1: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 50))
    CycleSolver.NewEquation(:($outStt.h = 150))

    inStt = :sta
    outStt = :stb
    push!(CycleSolver.PropsEquations, Any[:Win, 
    :($outStt.h - $inStt.h),
    [string("component2: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 380))
    CycleSolver.NewEquation(:($outStt.h = 500))

    inStt = :stx
    outStt = :sty
    push!(CycleSolver.PropsEquations, Any[:Wout, 
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

    CycleSolver.FilterAndAssignPropertiesToSystem()
    CycleSolver.DefineRefrigerationSystem()
    CycleSolver.CalculateSystemEfficiency()

    @test CycleSolver.System.n == 80
end

@testset "systemProperties.test.jl: Calculate refrigeration system efficiency" begin
    CycleSolver.ClearSystem()

    inStt = :st1
    outStt = :st2
    push!(CycleSolver.PropsEquations, Any[:Qin, 
    :($outStt.h - $inStt.h),
    [string("component1: ", string(inStt), " >> ", string(outStt)), inStt]])
    CycleSolver.NewEquation(:($inStt.h = 50))
    CycleSolver.NewEquation(:($outStt.h = 170))

    inStt = :sta
    outStt = :stb
    push!(CycleSolver.PropsEquations, Any[:Win, 
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

    CycleSolver.FilterAndAssignPropertiesToSystem()
    CycleSolver.DefineRefrigerationSystem()
    CycleSolver.CalculateSystemEfficiency()

    @test CycleSolver.System.n == 0.8
end

@testset "systemProperties.test.jl: Evaluate find variables (effectiveness)" begin
    CycleSolver.ClearSystem()

    inStt = [:st1, :sta]
    outStt = [:st2, :stb]

    push!(CycleSolver.findVariables, Any[:(($(outStt[1]).h - $(inStt[1]).h) /
        (($(inStt[2]).h - $(Expr(:ref, :stAux, 1)).h) * 
        ($(inStt[2]).m / $(inStt[1]).m))),
        string("effectiveness of [heater_exchanger: ",
        string(inStt), " >> ", string(outStt),"]"), nothing, nothing, 2])

    CycleSolver.NewEquation(:($(Expr(:ref, :stAux, 1)).h = 100))
    CycleSolver.NewEquation(:($(outStt[1]).h = 300))
    CycleSolver.NewEquation(:($(inStt[1]).h = 150))
    CycleSolver.NewEquation(:($(inStt[2]).h = 200))
    CycleSolver.NewEquation(:($(inStt[2]).m = 20))
    CycleSolver.NewEquation(:($(inStt[1]).m = 10))
    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)
    CycleSolver.EvaluatePropertiesEquations()

    CycleSolver.EvaluateFindVariables()

    @test CycleSolver.findVariables[1][1] == 75.0
end

@testset "systemProperties.test.jl: Evaluate find variables (efficiency)" begin
    CycleSolver.ClearSystem()

    inStt = :st1
    outStt = :st2

    CycleSolver.NewEquation(:($outStt.h = 1200))
    CycleSolver.NewEquation(:($inStt.h = 100))
    CycleSolver.NewEquation(:($outStt.p = 300))
    CycleSolver.NewEquation(:($inStt.s = 3))
    eval(:(CycleSolver.$inStt.fluid = "water"))
    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)

    push!(CycleSolver.findVariables, Any[:(($inStt.h - SttTemp_S)/($inStt.h - $outStt.h)),
    eval(:(CycleSolver.$inStt)), eval(:(CycleSolver.$outStt)), string("efficiency of [pump: ",
    string(inStt), " >> ", string(outStt),"]"), 1])    

    CycleSolver.EvaluateFindVariables()
    @test string(CycleSolver.findVariables[1][1])[1:6] == 
    "91.054"
end