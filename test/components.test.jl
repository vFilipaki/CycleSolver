using Test, CycleSolver

@testset "component.test.jl: Energy balance equation" begin
    CycleSolver.ClearSystem()
    CycleSolver.EnergyBalance([:inStt1], [:outStt1])
    CycleSolver.EnergyBalance([:inStt2, :inStt3], [:outStt2])
    CycleSolver.EnergyBalance([:inStt4], [:outStt3, :outStt4])
    CycleSolver.EnergyBalance([:inStt5, :inStt6], [:outStt5, :outStt6])

    @test string(CycleSolver.unsolvedEquations[1].Eq) ==
    "inStt1Stts[3]*inStt1Stts[7] ~ outStt1Stts[3]*outStt1Stts[7]"
    @test string(CycleSolver.unsolvedEquations[2].Eq) ==
    "inStt2Stts[3]*inStt2Stts[7] + inStt3Stts[3]*inStt3Stts[7] ~ outStt2Stts[3]*outStt2Stts[7]"
    @test string(CycleSolver.unsolvedEquations[3].Eq) ==
    "inStt4Stts[3]*inStt4Stts[7] ~ outStt3Stts[3]*outStt3Stts[7] + outStt4Stts[3]*outStt4Stts[7]"
    @test string(CycleSolver.unsolvedEquations[4].Eq) ==
    "inStt5Stts[3]*inStt5Stts[7] + inStt6Stts[3]*inStt6Stts[7] ~ outStt5Stts[3]*outStt5Stts[7] + outStt6Stts[3]*outStt6Stts[7]"
end

@testset "component.test.jl: Pump function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(pump(st1, st2)))
    CycleSolver.NewEquation(:(pump([st3, st4], [st5, st6])))
    CycleSolver.NewEquation(:(pump(st7, st8, 80)))
    CycleSolver.NewEquation(:(pump(st9, st10, find)))

    @test_throws DomainError CycleSolver.NewEquation(:(pump([st11], [st12, st13])))

    @testset "Equations" begin
        expectedResults = [
            "st2Stts[4] ~ st1Stts[4]",
            "st5Stts[4] ~ st3Stts[4]",
            "st6Stts[4] ~ st4Stts[4]",
            "stAuxStts[1, 4] ~ st7Stts[4]",
            "stAuxStts[1, 2] ~ st8Stts[2]",
            "st8Stts[3] ~ st7Stts[3] - 1.25(st7Stts[3] - stAuxStts[1, 3])"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end

    @testset "Properties" begin
        expectedResults = [
            "Win{st1} = st2.m * st2.h - st1.m * st1.h",
            "win{st1} = st2.h - st1.h",
            "Win{st3} = st5.m * st5.h - st3.m * st3.h",
            "win{st3} = st5.h - st3.h",
            "Win{st4} = st6.m * st6.h - st4.m * st4.h",
            "win{st4} = st6.h - st4.h",
            "Win{st7} = st8.m * st8.h - st7.m * st7.h",
            "win{st7} = st8.h - st7.h",
            "Win{st9} = st10.m * st10.h - st9.m * st9.h",
            "win{st9} = st10.h - st9.h"
        ]
        for i in 1:length(CycleSolver.PropsEquations)
            @test string(
                CycleSolver.PropsEquations[i][1],"{",
                CycleSolver.PropsEquations[i][3][2], "} = " ,
                CycleSolver.PropsEquations[i][2]
            ) == expectedResults[i]       
        end
    end

    @test string(CycleSolver.findVariables[1][1]) ==
    "(st9.h - SttTemp_S) / (st9.h - st10.h)"
end

@testset "component.test.jl: Turbine function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(turbine(st1, st2)))
    CycleSolver.NewEquation(:(turbine([st3, st4], [st5, st6])))
    CycleSolver.NewEquation(:(turbine(st7, st8, 80)))
    CycleSolver.NewEquation(:(turbine(st9, st10, find)))
    CycleSolver.NewEquation(:(turbine([st11], [st12, st13])))

    @testset "Equations" begin
        expectedResults = [
            "st2Stts[4] ~ st1Stts[4]",
            "st5Stts[4] ~ st3Stts[4]",
            "st6Stts[4] ~ st4Stts[4]",
            "stAuxStts[1, 4] ~ st7Stts[4]",
            "stAuxStts[1, 2] ~ st8Stts[2]",
            "st8Stts[3] ~ st7Stts[3] - 0.8(st7Stts[3] - stAuxStts[1, 3])",
            "st12Stts[4] ~ st11Stts[4]",
            "st13Stts[4] ~ st11Stts[4]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end

    @testset "Properties" begin
        expectedResults = [
            "Wout{st1} = st1.m * st1.h - st2.m * st2.h",
            "wout{st1} = st1.h - st2.h",
            "Wout{st3} = st3.m * st3.h - st5.m * st5.h",
            "wout{st3} = st3.h - st5.h",
            "Wout{st4} = st4.m * st4.h - st6.m * st6.h",
            "wout{st4} = st4.h - st6.h",
            "Wout{st7} = st7.m * st7.h - st8.m * st8.h",
            "wout{st7} = st7.h - st8.h",
            "Wout{st9} = st9.m * st9.h - st10.m * st10.h",
            "wout{st9} = st9.h - st10.h",
            "Wout{st11} = (st11.m * st11.h - st12.m * st12.h) - st13.m * st13.h",
            "wout{st11} = ((st11.mFraction * st11.h - st12.mFraction * st12.h) - st13.mFraction * st13.h) / st11.mFraction"
        ]
        for i in 1:length(CycleSolver.PropsEquations)
            @test string(
                CycleSolver.PropsEquations[i][1],"{",
                CycleSolver.PropsEquations[i][3][2], "} = " ,
                CycleSolver.PropsEquations[i][2]
            ) == expectedResults[i]       
        end
    end

    @test string(CycleSolver.findVariables[1][1]) ==
    "(st9.h - st10.h) / (st9.h - SttTemp_S)"
end

@testset "component.test.jl: Condenser function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(condenser(st1, st2)))
    CycleSolver.NewEquation(:(condenser([st3, st4], [st5, st6])))
    CycleSolver.NewEquation(:(condenser([st11], [st12, st13])))

    @testset "Equations" begin
        expectedResults = [
            "st2Stts[2] ~ st1Stts[2]",
            "st2Stts[5] ~ 0",
            "st5Stts[2] ~ st3Stts[2]",
            "st5Stts[5] ~ 0",
            "st6Stts[2] ~ st4Stts[2]",
            "st6Stts[5] ~ 0",
            "st11Stts[2] ~ st12Stts[2]",
            "st12Stts[2] ~ st13Stts[2]",
            "st13Stts[2] ~ st11Stts[2]",
            "st12Stts[5] ~ 0",
            "st13Stts[5] ~ 0"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end

    @testset "Properties" begin
        expectedResults = [
            "Qout{st1} = st1.m * st1.h - st2.m * st2.h",
            "qout{st1} = st1.h - st2.h",
            "Qout{st3} = st3.m * st3.h - st5.m * st5.h",
            "qout{st3} = st3.h - st5.h",
            "Qout{st4} = st4.m * st4.h - st6.m * st6.h",
            "qout{st4} = st4.h - st6.h",
            "Qout{st11} = (0 + st11.m * st11.h) - st12.m * st12.h",
            "qout{st11} = (0 + st11.mFraction * st11.h) - st12.h"
        ]
        for i in 1:length(CycleSolver.PropsEquations)
            @test string(
                CycleSolver.PropsEquations[i][1],"{",
                CycleSolver.PropsEquations[i][3][2], "} = " ,
                CycleSolver.PropsEquations[i][2]
            ) == expectedResults[i]       
        end
    end
end

@testset "component.test.jl: Boiler function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(boiler(st1, st2)))
    CycleSolver.NewEquation(:(boiler([st3, st4], [st5, st6])))
    @test_throws DomainError CycleSolver.NewEquation(:(boiler([st11], [st12, st13])))

    @testset "Equations" begin
        expectedResults = [
            "st2Stts[2] ~ st1Stts[2]",
            "st5Stts[2] ~ st3Stts[2]",
            "st6Stts[2] ~ st4Stts[2]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end

    @testset "Properties" begin
        expectedResults = [
            "Qin{st1} = st2.m * st2.h - st1.m * st1.h",
            "qin{st1} = st2.h - st1.h",
            "Qin{st3} = st5.m * st5.h - st3.m * st3.h",
            "qin{st3} = st5.h - st3.h",
            "Qin{st4} = st6.m * st6.h - st4.m * st4.h",
            "qin{st4} = st6.h - st4.h"
        ]
        for i in 1:length(CycleSolver.PropsEquations)
            @test string(
                CycleSolver.PropsEquations[i][1],"{",
                CycleSolver.PropsEquations[i][3][2], "} = " ,
                CycleSolver.PropsEquations[i][2]
            ) == expectedResults[i]       
        end
    end
end

@testset "component.test.jl: Evaporator function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(evaporator(st1, st2)))
    CycleSolver.NewEquation(:(evaporator([st3, st4], [st5, st6])))
    @test_throws DomainError CycleSolver.NewEquation(:(evaporator([st11], [st12, st13])))

    @testset "Equations" begin
        expectedResults = [
            "st2Stts[5] ~ 1",
            "st2Stts[2] ~ st1Stts[2]",
            "st5Stts[5] ~ 1",
            "st5Stts[2] ~ st3Stts[2]",
            "st6Stts[5] ~ 1",
            "st6Stts[2] ~ st4Stts[2]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end

    @testset "Properties" begin
        expectedResults = [
            "Qin{st1} = st2.m * st2.h - st1.m * st1.h",
            "qin{st1} = st2.h - st1.h",
            "Qin{st3} = st5.m * st5.h - st3.m * st3.h",
            "qin{st3} = st5.h - st3.h",
            "Qin{st4} = st6.m * st6.h - st4.m * st4.h",
            "qin{st4} = st6.h - st4.h"
        ]
        for i in 1:length(CycleSolver.PropsEquations)
            @test string(
                CycleSolver.PropsEquations[i][1],"{",
                CycleSolver.PropsEquations[i][3][2], "} = " ,
                CycleSolver.PropsEquations[i][2]
            ) == expectedResults[i]       
        end
    end
end

@testset "component.test.jl: Evaporator_Condenser function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(evaporator_condenser([st1, sta], [st2, stb])))
    @test_throws DomainError CycleSolver.NewEquation(:(evaporator_condenser(st3, st4)))    
    @test_throws DomainError CycleSolver.NewEquation(:(evaporator([st5], [st6, st7])))

    @testset "Equations" begin
        expectedResults = [
            "st1Stts[3]*st1Stts[7] + staStts[3]*staStts[7] ~ st2Stts[3]*st2Stts[7] + stbStts[3]*stbStts[7]",
            "st2Stts[2] ~ st1Stts[2]",
            "stbStts[2] ~ staStts[2]",
            "st2Stts[5] ~ 1",
            "stbStts[5] ~ 0"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end

    @test string(CycleSolver.qflex[1][1],", ",CycleSolver.qflex[1][2]) == 
    "Any[:st1, :sta], Any[:st2, :stb]"
end

@testset "component.test.jl: Expansion valve function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(expansion_valve([st1, sta], [st2, stb])))
    CycleSolver.NewEquation(:(expansion_valve(st3, st4)))    
    @test_throws DomainError CycleSolver.NewEquation(:(expansion_valve([st5], [st6, st7])))

    @testset "Equations" begin
        expectedResults = [
            "st2Stts[3] ~ st1Stts[3]",
            "stbStts[3] ~ staStts[3]",
            "st4Stts[3] ~ st3Stts[3]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end
end

@testset "component.test.jl: Flash chamber function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(flash_chamber([st1, sta], [st2, stb])))
    CycleSolver.NewEquation(:(flash_chamber(st3, st4)))    
    @test_throws DomainError CycleSolver.NewEquation(:(flash_chamber([st5], [st6, st7])))

    @testset "Equations" begin
        expectedResults = [
            "st2Stts[3] ~ st1Stts[3]",
            "stbStts[3] ~ staStts[3]",
            "st4Stts[3] ~ st3Stts[3]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end
end

@testset "component.test.jl: Heater closed function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(heater_closed([st1, sta], [st2, stb])))
    @test_throws DomainError CycleSolver.NewEquation(:(heater_closed(st3, st4)))    
    @test_throws DomainError CycleSolver.NewEquation(:(heater_closed([st5], [st6, st7])))

    @testset "Equations" begin
        expectedResults = [
            "st1Stts[3]*st1Stts[7] + staStts[3]*staStts[7] ~ st2Stts[3]*st2Stts[7] + stbStts[3]*stbStts[7]",
            "st2Stts[2] ~ st1Stts[2]",
            "stbStts[2] ~ staStts[2]",
            "st2Stts[1] ~ stbStts[1]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end

    @test string(CycleSolver.unsolvedConditionalEquation[1].condition) == 
    "st1.h > sta.h"
    @test string(CycleSolver.unsolvedConditionalEquation[1].caseTrue[1]) == 
    "st2.Q = 0"
    @test string(CycleSolver.unsolvedConditionalEquation[1].caseFalse[1]) == 
    "stb.Q = 0"
end

@testset "component.test.jl: Heater open function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    @test_throws DomainError CycleSolver.NewEquation(:(heater_open([st1, sta], [st2, stb])))
    CycleSolver.NewEquation(:(heater_open(st3, st4)))    
    @test_throws DomainError CycleSolver.NewEquation(:(heater_open([st5], [st6, st7])))
    CycleSolver.NewEquation(:(heater_open([st8, st9], st10)))   

    @testset "Equations" begin
        expectedResults = [
            "st3Stts[3]*st3Stts[7] ~ st4Stts[3]*st4Stts[7]",
            "st3Stts[2] ~ st4Stts[2]",
            "st4Stts[5] ~ 0",
            "st8Stts[3]*st8Stts[7] + st9Stts[3]*st9Stts[7] ~ st10Stts[3]*st10Stts[7]",
            "st8Stts[2] ~ st9Stts[2]",
            "st9Stts[2] ~ st10Stts[2]",
            "st10Stts[2] ~ st8Stts[2]",
            "st10Stts[5] ~ 0"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end
end

@testset "component.test.jl: Mix function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(mix([st1, sta], [st2, stb])))
    CycleSolver.NewEquation(:(mix(st3, st4)))    
    CycleSolver.NewEquation(:(mix([st5], [st6, st7])))
    CycleSolver.NewEquation(:(mix([st8, st9], st10)))   

    @testset "Equations" begin
        expectedResults = [
            "st1Stts[3]*st1Stts[7] + staStts[3]*staStts[7] ~ st2Stts[3]*st2Stts[7] + stbStts[3]*stbStts[7]",
            "st1Stts[2] ~ staStts[2]",
            "staStts[2] ~ st2Stts[2]",
            "st2Stts[2] ~ stbStts[2]",
            "stbStts[2] ~ st1Stts[2]",
            "st3Stts[3]*st3Stts[7] ~ st4Stts[3]*st4Stts[7]",
            "st3Stts[2] ~ st4Stts[2]",
            "st5Stts[3]*st5Stts[7] ~ st6Stts[3]*st6Stts[7] + st7Stts[3]*st7Stts[7]",
            "st5Stts[2] ~ st6Stts[2]",
            "st6Stts[2] ~ st7Stts[2]",
            "st7Stts[2] ~ st5Stts[2]",
            "st8Stts[3]*st8Stts[7] + st9Stts[3]*st9Stts[7] ~ st10Stts[3]*st10Stts[7]",
            "st8Stts[2] ~ st9Stts[2]",
            "st9Stts[2] ~ st10Stts[2]",
            "st10Stts[2] ~ st8Stts[2]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end
end

@testset "component.test.jl: Div function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    @test_throws DomainError CycleSolver.NewEquation(:(div([st1, sta], [st2, stb])))
    CycleSolver.NewEquation(:(div(st3, st4)))
    CycleSolver.NewEquation(:(div([st5], [st6, st7])))
    CycleSolver.NewEquation(:(div(st8, [st9, st10, st11])))

    @testset "Equations" begin
        expectedResults = [
            "st3Stts[2] ~ st4Stts[2]",
            "st3Stts[3] ~ st4Stts[3]",
            "st5Stts[2] ~ st6Stts[2]",
            "st5Stts[3] ~ st6Stts[3]",
            "st6Stts[2] ~ st7Stts[2]",
            "st6Stts[3] ~ st7Stts[3]",
            "st7Stts[2] ~ st5Stts[2]",
            "st7Stts[3] ~ st5Stts[3]",
            "st8Stts[2] ~ st9Stts[2]",
            "st8Stts[3] ~ st9Stts[3]",
            "st9Stts[2] ~ st10Stts[2]",
            "st9Stts[3] ~ st10Stts[3]",
            "st10Stts[2] ~ st11Stts[2]",
            "st10Stts[3] ~ st11Stts[3]",
            "st11Stts[2] ~ st8Stts[2]",
            "st11Stts[3] ~ st8Stts[3]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end
end

@testset "component.test.jl: Process heater function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(process_heater([st1, sta], [st2, stb])))
    CycleSolver.NewEquation(:(process_heater(st3, st4)))
    CycleSolver.NewEquation(:(process_heater([st5], [st6, st7])))
    CycleSolver.NewEquation(:(process_heater([st8, st9], st10)))

    @testset "Equations" begin
        expectedResults = [
            "st1Stts[2] ~ staStts[2]",
            "staStts[2] ~ st2Stts[2]",
            "st2Stts[2] ~ stbStts[2]",
            "stbStts[2] ~ st1Stts[2]",
            "st3Stts[2] ~ st4Stts[2]",
            "st5Stts[2] ~ st6Stts[2]",
            "st6Stts[2] ~ st7Stts[2]",
            "st7Stts[2] ~ st5Stts[2]",
            "st8Stts[2] ~ st9Stts[2]",
            "st9Stts[2] ~ st10Stts[2]",
            "st10Stts[2] ~ st8Stts[2]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end
end

@testset "component.test.jl: Compressor function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(compressor(st1, st2)))
    CycleSolver.NewEquation(:(compressor([st3, st4], [st5, st6])))
    CycleSolver.NewEquation(:(compressor(st7, st8, 80)))
    CycleSolver.NewEquation(:(compressor(st9, st10, find)))

    @test_throws DomainError CycleSolver.NewEquation(:(compressor([st11], [st12, st13])))

    @testset "Equations" begin
        expectedResults = [
            "st2Stts[4] ~ st1Stts[4]",
            "st5Stts[4] ~ st3Stts[4]",
            "st6Stts[4] ~ st4Stts[4]",
            "stAuxStts[1, 4] ~ st7Stts[4]",
            "stAuxStts[1, 2] ~ st8Stts[2]",
            "st8Stts[3] ~ st7Stts[3] - 1.25(st7Stts[3] - stAuxStts[1, 3])"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end

    @testset "Properties" begin
        expectedResults = [
            "Win{st1} = st2.m * st2.h - st1.m * st1.h",
            "win{st1} = st2.h - st1.h",
            "Win{st3} = st5.m * st5.h - st3.m * st3.h",
            "win{st3} = st5.h - st3.h",
            "Win{st4} = st6.m * st6.h - st4.m * st4.h",
            "win{st4} = st6.h - st4.h",
            "Win{st7} = st8.m * st8.h - st7.m * st7.h",
            "win{st7} = st8.h - st7.h",
            "Win{st9} = st10.m * st10.h - st9.m * st9.h",
            "win{st9} = st10.h - st9.h"
        ]
        for i in 1:length(CycleSolver.PropsEquations)
            @test string(
                CycleSolver.PropsEquations[i][1],"{",
                CycleSolver.PropsEquations[i][3][2], "} = " ,
                CycleSolver.PropsEquations[i][2]
            ) == expectedResults[i]       
        end
    end

    @test string(CycleSolver.findVariables[1][1]) ==
    "(st9.h - SttTemp_S) / (st9.h - st10.h)"
end

@testset "component.test.jl: Combustion chamber function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(combustion_chamber(st1, st2)))
    @test_throws DomainError CycleSolver.NewEquation(:(combustion_chamber([st3, st4], [st5, st6])))
    @test_throws DomainError CycleSolver.NewEquation(:(combustion_chamber([st11], [st12, st13])))

    @testset "Equations" begin
        expectedResults = [
            "st2Stts[2] ~ st1Stts[2]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end

    @test string(CycleSolver.qflex[1][1],", ",CycleSolver.qflex[1][2]) == 
    "[:st1], [:st2]"
end

@testset "component.test.jl: Heater exchanger function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    CycleSolver.NewEquation(:(heater_exchanger([st1, sta], [st2, stb])))
    @test_throws DomainError CycleSolver.NewEquation(:(heater_exchanger(st3, st4)))    
    @test_throws DomainError CycleSolver.NewEquation(:(heater_exchanger([st5], [st6, st7])))
    CycleSolver.NewEquation(:(heater_exchanger([st8, st9], [st10, st11], 80)))
    CycleSolver.NewEquation(:(heater_exchanger([st12, st13], [st14, st15], find)))

    @testset "Equations" begin
        expectedResults = [
            "st2Stts[2] ~ st1Stts[2]",
            "stbStts[2] ~ staStts[2]",
            "st1Stts[3]*st1Stts[7] + staStts[3]*staStts[7] ~ st2Stts[3]*st2Stts[7] + stbStts[3]*stbStts[7]", 
            "st10Stts[2] ~ st8Stts[2]",
            "st11Stts[2] ~ st9Stts[2]",
            "stAuxStts[1, 1] ~ st8Stts[1]",
            "stAuxStts[1, 2] ~ st9Stts[2]",
            "stAuxStts[2, 1] ~ st9Stts[1]",
            "stAuxStts[2, 2] ~ st8Stts[2]",
            "st14Stts[2] ~ st12Stts[2]",
            "st15Stts[2] ~ st13Stts[2]",
            "st12Stts[3]*st12Stts[7] + st13Stts[3]*st13Stts[7] ~ st14Stts[3]*st14Stts[7] + st15Stts[3]*st15Stts[7]",
            "stAuxStts[3, 1] ~ st12Stts[1]",
            "stAuxStts[3, 2] ~ st13Stts[2]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end

    @testset "Properties" begin
        expectedResults = [
            "Any[:st1, :sta], Any[:st2, :stb]",
            "Any[:st8, :st9], Any[:st10, :st11]",
            "Any[:st12, :st13], Any[:st14, :st15]"
        ]
        for i in 1:length(CycleSolver.qflex)
            @test string(CycleSolver.qflex[i][1],", ",CycleSolver.qflex[i][2]) ==
            expectedResults[i]
        end
    end

    @test string(CycleSolver.findVariables[1][1]) ==
    "(st14.h - st12.h) / ((st13.h - (stAux[3]).h) * (st13.m / st12.m))"

    @test string(CycleSolver.unsolvedConditionalEquation[1].condition) == 
    "abs(st11.h - st9.h) * st9.m > abs(st10.h - st8.h) * st8.m"
    @test string(CycleSolver.unsolvedConditionalEquation[1].caseTrue[1]) == 
    "st10.h = st8.h + (st9.m / st8.m) * 0.8 * (st9.h - (stAux[1]).h)"
    @test string(CycleSolver.unsolvedConditionalEquation[1].caseTrue[2]) == 
    "st11.h = st9.h - 0.8 * (st9.h - (stAux[1]).h)"
    @test string(CycleSolver.unsolvedConditionalEquation[1].caseFalse[1]) == 
    "st11.h = st9.h + (st8.m / st9.m) * 0.8 * (st8.h - (stAux[2]).h)"
    @test string(CycleSolver.unsolvedConditionalEquation[1].caseFalse[2]) == 
    "st10.h = st8.h - 0.8 * (st8.h - (stAux[2]).h)"
end

@testset "component.test.jl: Separator function" begin
    CycleSolver.ClearSystem()
    CycleSolver.NewEquation(:(newCycle[]))
    @test_throws DomainError CycleSolver.NewEquation(:(separator([st1, sta], [st2, stb])))
    @test_throws DomainError CycleSolver.NewEquation(:(separator(st3, st4)))
    CycleSolver.NewEquation(:(separator([st5], [st6, st7])))
    @test_throws DomainError CycleSolver.NewEquation(:(separator(st8, [st9, st10, st11])))

    @testset "Equations" begin
        expectedResults = [
            "st5Stts[2] ~ st6Stts[2]",
            "st6Stts[2] ~ st7Stts[2]",
            "st7Stts[2] ~ st5Stts[2]",
            "st6Stts[5] ~ 1",
            "st7Stts[5] ~ 0",
            "st6Stts[7] ~ st5Stts[5]*st5Stts[7]",
            "st7Stts[7] ~ st5Stts[7] - st6Stts[7]"
        ]
        for i in 1:length(CycleSolver.unsolvedEquations)
            @test string(CycleSolver.unsolvedEquations[i].Eq) ==
            expectedResults[i]
        end
    end
end