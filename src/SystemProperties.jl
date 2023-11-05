System = nothing

find = :find
findVariables = Any[]
SystemImbalanceAndEntropyGeneration = []

function EvaluateFindVariables()
    for i in 1:length(findVariables)
        if findVariables[i][5] == 1 # efficiency
            findVariables[i][4] = ManageComponentTag(findVariables[i][4])            
            SttTemp_S = PropsSI("H", "P", findVariables[i][3].p * 1000, "S",
                findVariables[i][2].s * 1000, findVariables[i][2].fluid) / 1000
            findVariables[i][1] =  ExpressionSubstitution(findVariables[i][1], :SttTemp_S, SttTemp_S)
            findVariables[i] = Any[100 * eval(findVariables[i][1]), findVariables[i][4]]
        else # effectiveness
            findVariables[i][2] = ManageComponentTag(findVariables[i][2])
            findVariables[i] = Any[100 * eval(findVariables[i][1]), findVariables[i][2]]
        end
    end   
end

function FilterAndAssignPropertiesToSystem()
    for f in fieldnames(PropertiesStruct)
        if f == :n
            continue
        end
        newDict = Dict()
        total = 0
        for i in 1:length(SystemCycles)         
            for j in getfield(SystemCycles[i].thermoProperties, f)
                if j.first != "total" && !occursin("heater_exchanger", j.first) && !occursin("evaporator_condenser", j.first)     
                    newDict[j.first] = j.second
                    total += j.second
                end
            end
        end
        newDict["total"] = total
        setfield!(System, f, newDict)
    end
end

function DefineRefrigerationSystem()
    global isRefrigerationSystem = SystemCycles[1].isRefrigerationCycle
    for i in 2:length(SystemCycles)
        if SystemCycles[i].isRefrigerationCycle != isRefrigerationSystem
            global isRefrigerationSystem = nothing
            break
        end
    end
end

function CalculateSystemEfficiency()
    if isnothing(isRefrigerationSystem)
        System.n = nothing
    elseif isRefrigerationSystem
        if System.Win["total"] != 0 && System.Qin["total"] != 0
            System.n = System.Qin["total"] / System.Win["total"]
        else
            System.n = nothing
        end
    else
        if System.Wout["total"] != 0 && System.Win["total"] != 0 &&
            System.Qin["total"] != 0
                System.n = 100 * (System.Wout["total"]  - System.Win["total"]) /
                System.Qin["total"]
        else
            System.n = nothing
        end
    end
end

function ClearSystem()
    set_reference_state("R134a","ASHRAE")    
    clearStates()
    ClearEquations()
    clearMassVariables()
    ClearProperties()    
    ClearCycles()

    global SystemImbalanceAndEntropyGeneration = []
    global SystemComponents = Any[]
    global System = PropertiesStruct()
    global findVariables = Any[]
end