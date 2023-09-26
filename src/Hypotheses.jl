function SolverWithHypotheses(tempVarZ, solutionFinded)
    
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
                        SolverWithHypotheses(string(tempVarZ, "   "), solutionFinded)
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
                        SolverWithHypotheses(string(tempVarZ, "   "), solutionFinded)
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