module CycleSolver
include("Equations.jl")
include("States.jl")
include("Visualization.jl")
include("Components.jl")
include("MassFlowManager.jl")



System = nothing
SystemCycles = Any[]
    
massEquations = Any[]
massParent = Any[]

MassEq1 = Any[]    
MassCoef = Any[]
fluidDefault = "water"
fluidEq = Any[]
closedInteractions = Any[]
cycleProps = Any[]
isRefrigerationSystem = nothing

m_fraction = Any[]
m_Cycle = Any[]
stAux = Any[]

find = :find
findVariables = Any[]

PropsEquations = Any[]
Qflex = Any[]
qflex = Any[]

mutable struct CycleStruct
    states
    fluid
    isRefrigerationCycle
    massDefined
    mainMassFlux
    thermoProperties
    CycleStruct() = new(Any[], nothing, false, false, -1, nothing)
end

mutable struct PropertiesStruct
    Win
    win
    Wout
    wout
    Qin
    qin
    Qout
    qout
    n
    PropertiesStruct() = new(Any[], Any[], Any[], Any[], Any[], Any[], Any[], Any[], nothing)
end

macro solve(eqs)
    ClearSystem()

    global SystemVars = Any[]
    for i in eqs.args[2:2:end]
        NewEquation(i)
    end
    
    SetupMass()
        
    newValue = true
    while newValue
        newValue = EquationsSolver(unsolvedEquations)        
        
        newValue |= StatesSolver(unsolvedStates)

        newValue |= ManageConditionalEquations(unsolvedConditionalEquation)
        
        if newValue
            UpdateEquationList(unsolvedEquations)
        elseif length(unsolvedStates) != 0
            solutionFinded = []
            EquationStateSolver("", solutionFinded)
            newValue = length(solutionFinded) > 0
            for j in solutionFinded
                eval(Expr(:(=), j[1], j[2]))
            end
        end
    end
    Conclusion()

end

function Conclusion()
    
    for i in massEquations
        if length(i.vars) > 0
            massTemp = Meta.parse(string(i.Eq.rhs))
            massTemp = ExpressionSubstitution(massTemp, :m_fractionVars, :m_fraction)
            massTemp = ExpressionSubstitution(massTemp, :m_CycleVars, :m_Cycle)
            eval(Expr(:(=), i.vars[1], eval(massTemp)))
    end end
    for j in 1:length(SystemCycles)
        if SystemCycles[j].massDefined
            systemMass = 0
            for k in SystemCycles[j].states
                if eval(Expr(:., k, :(:m))) > systemMass                        
                    systemMass = eval(Expr(:., k, :(:m)))
            end end
            for k in SystemCycles[j].states
                eval(Expr(:(=), Expr(:., k, :(:mFraction)), eval(Expr(:., k, :(:m))) / systemMass))
            end
        else
            for k in SystemCycles[j].states
                eval(Expr(:(=), Expr(:., k, :(:mFraction)), eval(Expr(:., k, :(:m)))))
                eval(Expr(:(=), Expr(:., k, :(:m)), nothing))
    end end end

    removeList = Any[]
    for i in 1:length(PropsEquations)
        try                
            PropsEquations[i][2] = eval(PropsEquations[i][2])
            PropsEquations[end][3][1] = ManageComponentTag(PropsEquations[end][3][1])
            PropsEquations[i][3][2] = SttCycleIndex(PropsEquations[i][3][2])
        catch
            push!(removeList, i)
        end
    end
    for i in length(removeList):-1:1
        deleteat!(PropsEquations, removeList[i])
    end

    for i in qflex
        if isnothing(eval(i[1][1]).m)                 
            inTemp, outTemp = ManipulateFlexHeat(false, i)
            for j in 1:length(inTemp)
                eq = Expr(:call, :-, inTemp[j][2], outTemp[j])
                eq = eval(eq)
                if eq == 0
                    continue
                end
                if eq < 0
                    push!(PropsEquations, Any[:qin, -eq,
                    [i[end], inTemp[j][1]]])
                else                        
                    push!(PropsEquations, Any[:qout, eq,
                    [i[end], inTemp[j][1]]])
                end
                PropsEquations[end][3][1] = ManageComponentTag(PropsEquations[end][3][1])
            end
        else
            inTemp, outTemp = ManipulateFlexHeat(true, i)
            for j in 1:length(inTemp)
                eq = Expr(:call, :-, inTemp[j][2], outTemp[j])
                eq = eval(eq)
                
                if eq == 0
                    continue
                end
                if eq < 0
                    push!(PropsEquations, Any[:Qin, -eq,
                    [i[end], inTemp[j][1]]])
                else                        
                    push!(PropsEquations, Any[:Qout, eq,
                    [i[end], inTemp[j][1]]])
                end
                PropsEquations[end][3][1] = ManageComponentTag(PropsEquations[end][3][1])
            end

            inTemp, outTemp = ManipulateFlexHeat(false, i)
            for j in 1:length(inTemp)
                
                eq = Expr(:call, :-, inTemp[j][2], outTemp[j])
                eq = eval(eq)
                if eq == 0
                    continue
                end
                if eq < 0
                    push!(PropsEquations, Any[:qin, -eq,
                    [i[end], inTemp[j][1]]])
                else                        
                    push!(PropsEquations, Any[:qout, eq,
                    [i[end], inTemp[j][1]]])
                end
                PropsEquations[end][3][1] = ManageComponentTag(PropsEquations[end][3][1])
            end
        end
    end            
   
    for i in 1:length(SystemCycles) 
        SystemCycles[i].thermoProperties = PropertiesStruct()
        for j in PropsEquations
            if j[3][2] == i
                push!(eval(:(SystemCycles[$i].thermoProperties.$(j[1]))), [j[2], j[3][1]])
    end end end

    for i in 1:length(SystemCycles)  
        for f in fieldnames(PropertiesStruct)
            if f == :n
                continue
            end
            newDict = Dict()
            total = 0
            for j in getfield(SystemCycles[i].thermoProperties, f)
                newDict[j[2]] = j[1]
                total += j[1]
            end
            newDict["total"] = total
            setfield!(SystemCycles[i].thermoProperties, f, newDict)
        end

        if SystemCycles[i].isRefrigerationCycle
            try
                SystemCycles[i].thermoProperties.n = SystemCycles[i].thermoProperties.qin["total"] / SystemCycles[i].thermoProperties.win["total"]
            catch
                SystemCycles[i].thermoProperties.n = nothing
            end
        else
            try
                SystemCycles[i].thermoProperties.n = 100 * (SystemCycles[i].thermoProperties.wout["total"]  - SystemCycles[i].thermoProperties.win["total"]) /
                    SystemCycles[i].thermoProperties.qin["total"]
            catch
                SystemCycles[i].thermoProperties.n = nothing     
        end end
    end  

    global System = PropertiesStruct()
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
    global isRefrigerationSystem = SystemCycles[1].isRefrigerationCycle
    for i in 2:length(SystemCycles)
        if SystemCycles[i].isRefrigerationCycle != isRefrigerationSystem
            global isRefrigerationSystem = nothing
            break
        end
    end

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
    
    for i in 1:length(findVariables)
        if findVariables[i][5] == 1 # efficiency
            findVariables[i][4] = replace(findVariables[i][4], "(" => "")                
            findVariables[i][4] = replace(findVariables[i][4], ")" => "")
            findVariables[i][4] = replace(findVariables[i][4], "Any" => "")
            findVariables[i][4] = replace(findVariables[i][4], "[:" => "[")
            findVariables[i][4] = replace(findVariables[i][4], ", :" => ", ")
            
            SttTemp_S = PropsSI("H", "P", findVariables[i][3].p * 1000, "S",
                findVariables[i][2].s * 1000, findVariables[i][2].fluid) / 1000
            findVariables[i][1] =  ExpressionSubstitution(findVariables[i][1], :SttTemp_S, SttTemp_S)
            findVariables[i] = Any[100 * eval(findVariables[i][1]), findVariables[i][4]]
        else # effectiveness
            findVariables[i][2] = replace(findVariables[i][2], "(" => "")                
            findVariables[i][2] = replace(findVariables[i][2], ")" => "")
            findVariables[i][2] = replace(findVariables[i][2], "Any" => "")
            findVariables[i][2] = replace(findVariables[i][2], "[:" => "[")
            findVariables[i][2] = replace(findVariables[i][2], ", :" => ", ")
            findVariables[i] = Any[100 * eval(findVariables[i][1]), findVariables[i][2]]
        end
    end   
end

function ManipulateFlexHeat(useMass, q)
    local inTemp
    local outTemp
    if useMass
        inTemp = [[SttCycleIndex(q[1][1]), :($(q[1][1]).h * $(q[1][1]).m)]]
        outTemp = [:($(q[2][1]).h * $(q[2][1]).m)]
        for j in 2:length(q[1])
            newQ = true
            myIndex = SttCycleIndex(q[1][j])
            for k in 1:length(inTemp)
                if inTemp[k][1] == myIndex
                    inTemp[k][2] = Expr(:call, :+, inTemp[k][2], :($(q[1][j]).h * $(q[1][j]).m))
                    outTemp[k] = Expr(:call, :+, outTemp[k], :($(q[2][j]).h * $(q[2][j]).m))
                    newQ = false
                    break
            end end
            if newQ
                push!(inTemp, [myIndex, :($(q[1][j]).h * $(q[1][j]).m)])
                push!(outTemp, :($(q[2][j]).h * $(q[2][j]).m))
        end end
    else
        inTemp = [[SttCycleIndex(q[1][1]), :($(q[1][1]).h)]]
        outTemp = [:($(q[2][1]).h)]
        for j in 2:length(q[1])
            newQ = true
            myIndex = SttCycleIndex(q[1][j])
            for k in 1:length(inTemp)
                if inTemp[k][1] == myIndex
                    inTemp[k][2] = Expr(:call, :+, inTemp[k][2], :($(q[1][j]).h))
                    outTemp[k] = Expr(:call, :+, outTemp[k], :($(q[2][j]).h))
                    newQ = false
                    break
            end end
            if newQ
                push!(inTemp, [myIndex, :($(q[1][j]).h)])
                push!(outTemp, :($(q[2][j]).h))
        end end
    end
    return [inTemp, outTemp]
end

function ManageComponentTag(component)
    component = replace(component, "(" => "")                
    component = replace(component, ")" => "")
    component = replace(component, "Any" => "")
    component = replace(component, "[:" => "[")
    component = replace(component, ", :" => ", ")
    return component
end

function SttCycleIndex(sttName)
    for i in 1:length(SystemCycles)
        if sttName in [j.name for j in SystemCycles[i].states]
            return i
            break
    end end
end

function ClearSystem()
    set_reference_state("R134a","ASHRAE")
    
    clearStates()       

    ClearEquations()
     
    global massEquations = Any[]
    global MassEq1 = Any[]
    global massParent = Any[]
    global SystemCycles = Any[]
    global MassCoef = Any[]
    global fluidDefault = "water"
    global fluidEq = Any[]
    global closedInteractions = Any[]
    global cycleProps = Any[]
    global isRefrigerationSystem = false
    global m_fraction = Any[]
    global m_Cycle = Any[]
    global stAux = Any[]    
    global System = PropertiesStruct()   
    global PropsEquations = Any[]
    global qflex = Any[]
    global Qflex = Any[]
    global findVariables = Any[]
end

function EquationStateSolver(tempVarZ, solutionFinded)
    
    localCheckPoint = CreateCheckPoint()
    for i in 1:length(unsolvedConditionalEquation)
        if isnothing(unsolvedConditionalEquation[i].condition) ||
        unsolvedConditionalEquation[i].condition isa Bool
            continue
        end
        if :(unsolvedConditionalEquation[$i].condition) in [j[1] for j in solutionFinded]
            eval(Expr(:(=), j[1], j[2]))
            continue
        end
        for tryValue in [true, false]            
            checkCondition = unsolvedConditionalEquation[i].condition
            unsolvedConditionalEquation[i].condition = tryValue
            ManageConditionalEquations(unsolvedConditionalEquation)
            acceptedCondition = true
            try
                newValue = true
                while newValue           
                    newValue = false
                    newValue = EquationsSolver(unsolvedEquations)
                    newValue |= StatesSolver(unsolvedStates)
                    UpdateEquationList(unsolvedEquations)
                    newValue |= ManageConditionalEquations(unsolvedConditionalEquation)
                    
                    if !newValue && length(unsolvedStates) != 0
                        oldLenght = length(solutionFinded)
                        EquationStateSolver(string(tempVarZ, "   "), solutionFinded)
                        newValue = oldLenght < length(solutionFinded)
                        for j in solutionFinded
                            eval(Expr(:(=), j[1], j[2]))
                        end
                    end
                end            
                
                checkCondition = eval(checkCondition)
                if !(checkCondition isa Bool)
                    checkCondition = UpdateEq(checkCondition)
                end

                if checkCondition != tryValue
                    acceptedCondition = false
                end                
            catch e
                acceptedCondition = false
            end             
            RestoreCheckPoint(localCheckPoint)
            if acceptedCondition
                push!(solutionFinded, Any[
                    :(unsolvedConditionalEquation[$i].condition), 
                    tryValue])
                return nothing
            end            
        end
    end
    ##########################################################

    unsolvedVarsAndStates = Any[]
    for i in unsolvedEquations
        push!(unsolvedVarsAndStates,
            [j isa Expr && j.head == :. ? j.args[1] : j for j in i.vars]...)
    end
    unsolvedVarsAndStates = unique(unsolvedVarsAndStates)
    
    if length(unsolvedEquations) <= length(unsolvedVarsAndStates) - 1
        return nothing
    end

    States2guess = Any[]
    for i in unsolvedVarsAndStates
        valuated = eval(i)
        if !(valuated isa Stt)
            continue
        end
        props = Any[valuated.p, valuated.T, valuated.Q, valuated.h, valuated.s]
        baseProp = 0
        for k in 1:5
            if !(props[k] isa Num)
                baseProp = k < 3 ? 1 : 2
                break
            end
        end
        if baseProp != 0
            propGuess = nothing
            count = 0            
            if baseProp == 1
                propGuess = Any[Expr(:., i, :(:s)), 0, 12, 0.05]
                count = 1
            else
                propGuess = Any[Expr(:., i, :(:p)), 
                    1, PropsSI("pmax", valuated.fluid) / 1000, 5]
                count = 2
            end

            for j in unsolvedEquations
                for k in j.vars
                    if k isa Expr && k.head == :. && k.args[1] == i
                        if k.args[2] == :(:Q)
                            propGuess = Any[Expr(:., i, :(:Q)), 0, 1, 0.1]##!!!!!
                            count = 3
                        end
                    end
                end
            end

            push!(States2guess, Any[propGuess..., count])
        end
    end

    if length(States2guess) == 0
        return nothing
    end    

    States2guess = sort!(States2guess, by = x -> x[5], rev = true)

    localCheckPoint = CreateCheckPoint()
    local smaller

    for guesses in States2guess
        if guesses[1] in [j[1] for j in solutionFinded]
            eval(Expr(:(=), j[1], j[2]))
            return nothing
        end
        smaller = Any[100000, -1, nothing] 
        errorCount = 0
        valuesQuery = Any[]
        validIntervalStarted = false
        go2nextGuess = false
        i = guesses[2]    
        while i < guesses[3]
            endWhile = false
            eval(Expr(:(=), guesses[1], i))
            try
                newValue = true

                while newValue           
                    newValue = false
                    newValue = StatesSolver(unsolvedStates)
                    UpdateEquationList(unsolvedEquations)
                    newValue |= ManageConditionalEquations(unsolvedConditionalEquation)
                    newValue |= EquationsSolver(unsolvedEquations)                    
  
                    if !newValue && length(unsolvedStates) != 0
                        oldLenght = length(solutionFinded)
                        EquationStateSolver(string(tempVarZ, "   "), solutionFinded)
                        newValue = oldLenght < length(solutionFinded)
                        for j in solutionFinded
                            eval(Expr(:(=), j[1], j[2]))
                        end
                    end
                end
                if length(unsolvedEquations) == 0     
                                  
                    testValue = 0
                    for j in localCheckPoint[2]
                        updatedEq = UpdateEq(j.Eq)
                        testValue += abs(updatedEq.rhs - updatedEq.lhs)                            
                    end
                    if testValue < smaller[1]
                        smaller = Any[testValue, i, nothing]
                    end
                    push!(valuesQuery, testValue)
                    validIntervalStarted = true
                    errorCount = 0
                elseif validIntervalStarted    
                    errorCount += 1
                end
            catch e
                if validIntervalStarted
                    errorCount += 1
                end
            end        
            
            RestoreCheckPoint(localCheckPoint)

            if length(valuesQuery) > 5
                closeness = 0
                for j in length(valuesQuery) - 1 : length(valuesQuery)
                    closeness += 1 - abs(valuesQuery[j]) / abs(valuesQuery[j-1])
                end
                if valuesQuery[end] <= valuesQuery[end - 1] && valuesQuery[end - 1] <= valuesQuery[end - 2] && closeness < 0.01
                    endWhile = true                       
                elseif valuesQuery[end] > valuesQuery[end - 1] && valuesQuery[end - 1] > valuesQuery[end - 2]
                    endWhile = true
                end                    
            end
            if errorCount > 2
                endWhile = true
            end
            if i + guesses[4] > guesses[3] || endWhile
                if smaller[2] == -1
                    go2nextGuess = true
                    break
                end
                if smaller[1] > 0.0001
                    guesses[2] = smaller[2] - guesses[4] 
                    guesses[3] = smaller[2] + guesses[4]
                    guesses[4] /= 4
                    i = guesses[2]
                    errorCount = 0
                    valuesQuery = Any[]
                    validIntervalStarted = false
                    go2nextGuess = false
                else
                    break
                end
            else
                i += guesses[4]
            end
        end
        if !go2nextGuess
            smaller[3] = guesses[1]
            break
        end
    end

    if isnothing(smaller[3]) || smaller[1] > 0.001
        return nothing
    end
    push!(solutionFinded, Any[smaller[3], smaller[2]])
end

function CreateCheckPoint()
    return [
        [i.name for i in unsolvedStates],
        deepcopy(unsolvedEquations),
        [eval(i) for i in SystemVars],
        deepcopy(SystemStates),
        deepcopy(m_fraction),
        deepcopy(m_Cycle),
        deepcopy(unsolvedConditionalEquation)
    ]
end

function RestoreCheckPoint(checkPoint)
    global unsolvedEquations = deepcopy(checkPoint[2])
    global unsolvedConditionalEquation = deepcopy(checkPoint[7])      
    for j in 1:length(SystemStates)
        for f in fieldnames(Stt)
            setfield!(SystemStates[j], f, getfield(checkPoint[4][j], f))
        end
    end
    global unsolvedStates = [eval(j) for j in checkPoint[1]]
    global m_fraction = deepcopy(checkPoint[5])
    global m_Cycle = deepcopy(checkPoint[6])
end

end