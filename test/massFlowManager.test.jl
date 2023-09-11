using Test, Symbolics, CycleSolver

@testset "massFlowManager.test.jl: Clear mass variables" begin
    CycleSolver.clearMassVariables()
    @test length(CycleSolver.massEquations) == 0;
    @test length(CycleSolver.MassCoef) == 0;
    @test length(CycleSolver.MassEq1) == 0;
    @test length(CycleSolver.massParent) == 0;
    @test length(CycleSolver.closedInteractions) == 0;
    @test length(CycleSolver.fluidEq) == 0;
    @test length(CycleSolver.m_fraction) == 0;
    @test length(CycleSolver.m_Cycle) == 0;
end

@testset "massFlowManager.test.jl: Substitute mass in equation" begin
    CycleSolver.NewEquation(:(st1.m = 10))
    push!(CycleSolver.massEquations, CycleSolver.unsolvedEquations[end])
    CycleSolver.NewEquation(:(st1.m * st1.h = 100))    
    CycleSolver.SubstituteMassInEq(CycleSolver.unsolvedEquations[end])
    @test string(CycleSolver.unsolvedEquations[end].Eq) == 
    "10st1Stts[3] ~ 100"
end

@testset "massFlowManager.test.jl: Mass flow generation" begin
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false
    CycleSolver.SystemCycles[end].massDefined = false;
    CycleSolver.SystemCycles[end].massDefined = true;
    CycleSolver.SystemCycles[end].fluid = "Water"
    CycleSolver.SystemCycles[end].mainMassFlux = -1
    CycleSolver.MassFlow([:st1], [:st2])
    CycleSolver.MassFlow([:st2], [:st3, :st4])
    CycleSolver.MassFlow([:st4, :st5, :st6], [:st7])
    @test string(CycleSolver.MassEq1[1][1]) == "st2.m = st1.m"
    @test string(CycleSolver.MassEq1[2][1]) == "st3.m = st2.m * m_fraction[1, 1]"
    @test string(CycleSolver.MassEq1[3][1]) == "st4.m = st2.m * (1 - m_fraction[1, 1])"
    @test string(CycleSolver.MassEq1[4][1]) == "st7.m = (st4.m + st5.m) + st6.m"
end

@testset "massFlowManager.test.jl: Divide states per cycle" begin
    CycleSolver.ClearSystem()
    push!(CycleSolver.massParent, Vector{Any}[[:st1], [:st2]])
    push!(CycleSolver.massParent, Vector{Any}[[:sta], [:stb]])
    push!(CycleSolver.massParent, Vector{Any}[[:st2], [:st3]])
    push!(CycleSolver.massParent, Vector{Any}[[:stc], [:sta]])
    push!(CycleSolver.massParent, Vector{Any}[[:st3], [:st1]])
    push!(CycleSolver.massParent, Vector{Any}[[:stb], [:stc]])
    cycleStatesSymbols = Any[]
    CycleSolver.divideStatesPerCycle(cycleStatesSymbols)
    @test cycleStatesSymbols[1] == Any[:st1, :st2, :st3]
    @test cycleStatesSymbols[2] == Any[:sta, :stb, :stc]

    CycleSolver.ClearSystem()
    push!(CycleSolver.massParent, Vector{Any}[[:st1], [:st2, :st3]])
    push!(CycleSolver.massParent, Vector{Any}[[:sta], [:stb]])
    push!(CycleSolver.massParent, Vector{Any}[[:st3], [:st4]])
    push!(CycleSolver.massParent, Vector{Any}[[:stc], [:sta]])
    push!(CycleSolver.massParent, Vector{Any}[[:st4, :st2], [:st1]])
    push!(CycleSolver.massParent, Vector{Any}[[:stb], [:stc]])
    cycleStatesSymbols = Any[]
    CycleSolver.divideStatesPerCycle(cycleStatesSymbols)
    @test cycleStatesSymbols[1] == Any[:st1, :st2, :st3, :st4]
    @test cycleStatesSymbols[2] == Any[:sta, :stb, :stc]
end

@testset "massFlowManager.test.jl: Find root state" begin
    CycleSolver.ClearSystem()
    push!(CycleSolver.massParent, Vector{Any}[[:st1], [:st2]])
    push!(CycleSolver.massParent, Vector{Any}[[:sta], [:stb]])
    push!(CycleSolver.massParent, Vector{Any}[[:st2], [:st3]])
    push!(CycleSolver.massParent, Vector{Any}[[:stc], [:sta]])
    push!(CycleSolver.massParent, Vector{Any}[[:st3], [:st1]])
    push!(CycleSolver.massParent, Vector{Any}[[:stb], [:stc]])
    cycleStatesSymbols = Any[]
    MassCopy = deepcopy(CycleSolver.massParent)
    CycleSolver.divideStatesPerCycle(cycleStatesSymbols)
    RootStt = CycleSolver.FindRootState(MassCopy, cycleStatesSymbols)
    @test RootStt[1] == Any[:st1, :st2, :st3]
    @test RootStt[2] == Any[:sta, :stb, :stc]

    CycleSolver.ClearSystem()
    push!(CycleSolver.massParent, Vector{Any}[[:st1], [:st2, :st3]])
    push!(CycleSolver.massParent, Vector{Any}[[:sta], [:stb]])
    push!(CycleSolver.massParent, Vector{Any}[[:st3], [:st4]])
    push!(CycleSolver.massParent, Vector{Any}[[:stc], [:sta]])
    push!(CycleSolver.massParent, Vector{Any}[[:st4, :st2], [:st1]])
    push!(CycleSolver.massParent, Vector{Any}[[:stb], [:stc]])
    cycleStatesSymbols = Any[]
    MassCopy = deepcopy(CycleSolver.massParent)
    CycleSolver.divideStatesPerCycle(cycleStatesSymbols)
    RootStt = CycleSolver.FindRootState(MassCopy, cycleStatesSymbols)
    @test RootStt[1] == Any[:st1]
    @test RootStt[2] == Any[:sta, :stb, :stc]

    CycleSolver.ClearSystem()
    push!(CycleSolver.massParent, Vector{Any}[[:st1], [:st2, :st3]])
    push!(CycleSolver.massParent, Vector{Any}[[:st3], [:st4]])
    push!(CycleSolver.massParent, Vector{Any}[[:st4], [:st5, :st6]])
    push!(CycleSolver.massParent, Vector{Any}[[:st6, :st5], [:st7]])
    push!(CycleSolver.massParent, Vector{Any}[[:st7, :st2], [:st1]])
    cycleStatesSymbols = Any[]
    MassCopy = deepcopy(CycleSolver.massParent)
    CycleSolver.divideStatesPerCycle(cycleStatesSymbols)
    RootStt = CycleSolver.FindRootState(MassCopy, cycleStatesSymbols)
    @test RootStt[1] == Any[:st1]

    CycleSolver.ClearSystem()
    push!(CycleSolver.massParent, Vector{Any}[[:st6, :st5], [:st7]])
    push!(CycleSolver.massParent, Vector{Any}[[:st3], [:st4]])
    push!(CycleSolver.massParent, Vector{Any}[[:st7, :st2], [:st1]])
    push!(CycleSolver.massParent, Vector{Any}[[:st1], [:st2, :st3]])
    push!(CycleSolver.massParent, Vector{Any}[[:st4], [:st5, :st6]])
    cycleStatesSymbols = Any[]
    MassCopy = deepcopy(CycleSolver.massParent)
    CycleSolver.divideStatesPerCycle(cycleStatesSymbols)
    RootStt = CycleSolver.FindRootState(MassCopy, cycleStatesSymbols)
    @test RootStt[1] == Any[:st1]
end

@testset "massFlowManager.test.jl: Find main mass" begin
    CycleSolver.ClearSystem()

    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false
    CycleSolver.SystemCycles[end].massDefined = false;
    CycleSolver.SystemCycles[end].massDefined = true;
    CycleSolver.SystemCycles[end].fluid = "Water"
    CycleSolver.SystemCycles[end].mainMassFlux = -1
    CycleSolver.MassFlow([:st1], [:st2])
    CycleSolver.MassFlow([:st3], [:st1])

    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false
    CycleSolver.SystemCycles[end].massDefined = false;
    CycleSolver.SystemCycles[end].massDefined = true;
    CycleSolver.SystemCycles[end].fluid = "Water"
    CycleSolver.SystemCycles[end].mainMassFlux = -1
    CycleSolver.MassFlow([:sta], [:stb])
    CycleSolver.MassFlow([:stc], [:sta])

    push!(CycleSolver.closedInteractions, [:st2, :stb])
    for i in CycleSolver.massParent
        for j in [i[1]..., i[2]...]
            CycleSolver.createState(j)
    end end 
    CycleSolver.NewEquation(:(st1.m = 2))
    cycleStatesSymbols = Any[]
    MassCopy = CycleSolver.deepcopy(CycleSolver.massParent)
    CycleSolver.divideStatesPerCycle(cycleStatesSymbols)
    RootStt = CycleSolver.FindRootState(MassCopy, cycleStatesSymbols)
    cDependencies = CycleSolver.MainCycleMass(cycleStatesSymbols)
    @test length(cDependencies) == 1
    @test cDependencies[1] == [1, 2]
end

@testset "massFlowManager.test.jl: Genearate mass equations" begin
    CycleSolver.ClearSystem()

    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false
    CycleSolver.SystemCycles[end].massDefined = false;
    CycleSolver.SystemCycles[end].massDefined = true;
    CycleSolver.SystemCycles[end].fluid = "Water"
    CycleSolver.SystemCycles[end].mainMassFlux = -1
    CycleSolver.MassFlow([:st1], [:st2])
    CycleSolver.MassFlow([:st3], [:st1])

    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false
    CycleSolver.SystemCycles[end].massDefined = false;
    CycleSolver.SystemCycles[end].massDefined = true;
    CycleSolver.SystemCycles[end].fluid = "Water"
    CycleSolver.SystemCycles[end].mainMassFlux = -1
    CycleSolver.MassFlow([:sta], [:stb])
    CycleSolver.MassFlow([:stc], [:sta])

    push!(CycleSolver.closedInteractions, [:st2, :stb])
    for i in CycleSolver.massParent
        for j in [i[1]..., i[2]...]
            CycleSolver.createState(j)
    end end 
    CycleSolver.NewEquation(:(st1.m = 2))
    cycleStatesSymbols = Any[]
    MassCopy = CycleSolver.deepcopy(CycleSolver.massParent)
    CycleSolver.divideStatesPerCycle(cycleStatesSymbols)
    RootStt = CycleSolver.FindRootState(MassCopy, cycleStatesSymbols)
    CycleSolver.MainCycleMass(cycleStatesSymbols)
    
    testVar = CycleSolver.GenearateMassEquations(cycleStatesSymbols, RootStt)
    @test testVar[1] == Any[:(st2.m), :(m_Cycle[1])]
    @test testVar[2] == Any[:(st1.m), :(st3.m)]
    @test testVar[3] == Any[:(stb.m), :(m_Cycle[2])]
    @test testVar[4] == Any[:(sta.m), :(stc.m)]
    @test testVar[5] == Expr[:(st1.m), :(m_Cycle[1])]
    @test testVar[6] == Expr[:(sta.m), :(m_Cycle[2])]

    @test CycleSolver.MassEq1[1] == Any[:(st2.m = m_Cycle[1]), :st2, [:st1]]
    @test CycleSolver.MassEq1[2] == Any[:(st1.m = st3.m), :st1, [:st3]]
    @test CycleSolver.MassEq1[3] == Any[:(stb.m = m_Cycle[2]), :stb, [:sta]]
    @test CycleSolver.MassEq1[4] == Any[:(sta.m = stc.m), :sta, [:stc]]

    @test string(CycleSolver.massEquations[1].Eq) == "st2Stts[7] ~ m_CycleVars[1]"
    @test string(CycleSolver.massEquations[2].Eq) == "st1Stts[7] ~ st3Stts[7]"
    @test string(CycleSolver.massEquations[3].Eq) == "stbStts[7] ~ m_CycleVars[2]"
    @test string(CycleSolver.massEquations[4].Eq) == "staStts[7] ~ stcStts[7]"
    @test string(CycleSolver.massEquations[5].Eq) == "st1Stts[7] ~ m_CycleVars[1]"
    @test string(CycleSolver.massEquations[6].Eq) == "staStts[7] ~ m_CycleVars[2]"
end

@testset "massFlowManager.test.jl: Mass setup with mass defined" begin
    CycleSolver.ClearSystem()
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false
    CycleSolver.SystemCycles[end].massDefined = true;
    CycleSolver.SystemCycles[end].fluid = "Water"
    CycleSolver.SystemCycles[end].mainMassFlux = 5
    CycleSolver.MassFlow([:st1], [:st2])
    CycleSolver.MassFlow([:st2], [:st3, :st4])
    CycleSolver.MassFlow([:st4], [:st5])
    CycleSolver.MassFlow([:st3, :st5], [:st6])
    CycleSolver.MassFlow([:st6], [:st1])
    for i in CycleSolver.massParent
        for j in [i[1]..., i[2]...]
            CycleSolver.createState(j)
    end end
    CycleSolver.NewEquation(:(st4.mFraction = 0.3))
    CycleSolver.NewEquation(:(st2.m * st2.h = st3.m * st3.h))

    CycleSolver.SetupMass()
    
    @test string(CycleSolver.massEquations[1].Eq) ==
    "st2Stts[7] ~ 5"
    @test string(CycleSolver.massEquations[2].Eq) ==
    "st3Stts[7] ~ 5m_fractionVars[1, 1]"
    @test string(CycleSolver.massEquations[3].Eq) ==
    "st4Stts[7] ~ 5 - 5m_fractionVars[1, 1]"
    @test string(CycleSolver.massEquations[4].Eq) ==
    "st5Stts[7] ~ 5 - 5m_fractionVars[1, 1]"
    @test string(CycleSolver.massEquations[5].Eq) ==
    "st6Stts[7] ~ 5"
    @test string(CycleSolver.massEquations[6].Eq) ==
    "st1Stts[7] ~ 5"
    @test string(CycleSolver.massEquations[7].Eq) ==
    "st1Stts[7] ~ 5"
    @test string(CycleSolver.massEquations[8].Eq) ==
    "5 ~ 5"

    @test string(CycleSolver.unsolvedEquations[1].Eq) ==
    "(1//5)*(5 - 5m_fractionVars[1, 1]) ~ 0.3"
    @test string(CycleSolver.unsolvedEquations[2].Eq) ==
    "5st2Stts[3] ~ 5st3Stts[3]*m_fractionVars[1, 1]"
end

@testset "massFlowManager.test.jl: Mass setup with mass not defined" begin
    CycleSolver.ClearSystem()
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false
    CycleSolver.SystemCycles[end].massDefined = false;
    CycleSolver.SystemCycles[end].fluid = "Water"
    CycleSolver.SystemCycles[end].mainMassFlux = -1
    CycleSolver.MassFlow([:st1], [:st2])
    CycleSolver.MassFlow([:st2], [:st3, :st4])
    CycleSolver.MassFlow([:st4], [:st5])
    CycleSolver.MassFlow([:st3, :st5], [:st6])
    CycleSolver.MassFlow([:st6], [:st1])
    for i in CycleSolver.massParent
        for j in [i[1]..., i[2]...]
            CycleSolver.createState(j)
    end end
    CycleSolver.NewEquation(:(st2.m = 5))
    CycleSolver.NewEquation(:(st4.mFraction = 0.3))
    CycleSolver.NewEquation(:(st2.m * st2.h = st3.m * st3.h))

    CycleSolver.SetupMass()

    @test string(CycleSolver.massEquations[1].Eq) ==
    "st2Stts[7] ~ m_CycleVars[1]"
    @test string(CycleSolver.massEquations[2].Eq) ==
    "st3Stts[7] ~ m_CycleVars[1]*m_fractionVars[1, 1]"
    @test string(CycleSolver.massEquations[3].Eq) ==
    "st4Stts[7] ~ m_CycleVars[1] - m_CycleVars[1]*m_fractionVars[1, 1]"
    @test string(CycleSolver.massEquations[4].Eq) ==
    "st5Stts[7] ~ m_CycleVars[1] - m_CycleVars[1]*m_fractionVars[1, 1]"
    @test string(CycleSolver.massEquations[5].Eq) ==
    "st6Stts[7] ~ m_CycleVars[1]"
    @test string(CycleSolver.massEquations[6].Eq) ==
    "st1Stts[7] ~ m_CycleVars[1]"
    @test string(CycleSolver.massEquations[7].Eq) ==
    "st1Stts[7] ~ m_CycleVars[1]"

    @test string(CycleSolver.unsolvedEquations[1].Eq) ==
    "m_CycleVars[1] ~ 5"
    @test string(CycleSolver.unsolvedEquations[2].Eq) ==
    "1 - m_fractionVars[1, 1] ~ 0.3"
    @test string(CycleSolver.unsolvedEquations[3].Eq) ==
    "st2Stts[3] ~ st3Stts[3]*m_fractionVars[1, 1]"
end

@testset "massFlowManager.test.jl: Mass flux evaluation" begin
    CycleSolver.ClearSystem()
    
    push!(CycleSolver.SystemCycles, CycleSolver.CycleStruct())
    CycleSolver.SystemCycles[end].isRefrigerationCycle = false
    CycleSolver.SystemCycles[end].massDefined = false;
    CycleSolver.SystemCycles[end].fluid = "Water"
    CycleSolver.SystemCycles[end].mainMassFlux = -1
    CycleSolver.MassFlow([:st1], [:st2])
    CycleSolver.MassFlow([:st2], [:st3, :st4])
    CycleSolver.MassFlow([:st4], [:st5])
    CycleSolver.MassFlow([:st3, :st5], [:st6])
    CycleSolver.MassFlow([:st6], [:st1])
    for i in CycleSolver.massParent
        for j in [i[1]..., i[2]...]
            CycleSolver.createState(j)
    end end
    CycleSolver.NewEquation(:(st2.m = 5))
    CycleSolver.NewEquation(:(st4.mFraction = 0.3))
    CycleSolver.SetupMass()
    CycleSolver.EquationsSolver(CycleSolver.unsolvedEquations)

    CycleSolver.EvaluateStatesMassFlux()
    expectedResults = [
        5.0, 5.0, 3.5, 1.5, 1.5, 5.0
    ]
    for i in 1:length(CycleSolver.SystemCycles[1].states)
        @test CycleSolver.SystemCycles[1].states[i].m ==
        expectedResults[i]
    end

    expectedResults = [
        "st1Stts[8]", "st2Stts[8]", "st3Stts[8]",
        "st4Stts[8]", "st5Stts[8]", "st6Stts[8]",
    ]
    for i in 1:length(CycleSolver.SystemCycles[1].states)
        @test string(CycleSolver.SystemCycles[1].states[i].mFraction) ==
        expectedResults[i]
    end

    CycleSolver.EvaluateStatesMassFluxFraction()

    expectedResults = [
        1.0, 1.0, 0.7, 0.3, 0.3, 1.0
    ]
    for i in 1:length(CycleSolver.SystemCycles[1].states)
        @test CycleSolver.SystemCycles[1].states[i].mFraction ==
        expectedResults[i]
    end
end