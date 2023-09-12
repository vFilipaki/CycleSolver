SystemCycles = Any[]
fluidDefault = "water"
isRefrigerationSystem = nothing

mutable struct CycleStruct
    states
    fluid
    isRefrigerationCycle
    massDefined
    mainMassFlux
    thermoProperties
    CycleStruct() = new(Any[], nothing, false, false, -1, nothing)
end

function GetCycleIndexByStateSymbol(sttName)
    for i in 1:length(SystemCycles)
        if sttName in [j.name for j in SystemCycles[i].states]
            return i
            break
    end end
end

function AssignPropertiesToCycle()
    for i in 1:length(SystemCycles) 
        SystemCycles[i].thermoProperties = PropertiesStruct()
        for j in PropsEquations
            if j[3][2] == i
                push!(eval(:(SystemCycles[$i].thermoProperties.$(j[1]))), [j[2], j[3][1]])
    end end end
end

function CalculateTotalValueOfProperties(cycle)
    for f in fieldnames(PropertiesStruct)
        if f == :n
            continue
        end
        newDict = Dict()
        total = 0
        for j in getfield(cycle.thermoProperties, f)
            newDict[j[2]] = j[1]
            total += j[1]
        end
        newDict["total"] = total
        setfield!(cycle.thermoProperties, f, newDict)
    end
end

function CalculateCycleEfficiency(cycle)
    if cycle.isRefrigerationCycle
        try
            cycle.thermoProperties.n = cycle.thermoProperties.qin["total"] / cycle.thermoProperties.win["total"]
        catch
            cycle.thermoProperties.n = nothing
        end
    else
        try
            cycle.thermoProperties.n = 100 * (cycle.thermoProperties.wout["total"] - cycle.thermoProperties.win["total"]) /
                cycle.thermoProperties.qin["total"]
        catch
            cycle.thermoProperties.n = nothing     
    end end
end

function ClearCycles()    
    global SystemCycles = Any[]
    global fluidDefault = "water"
    global isRefrigerationSystem = false
end