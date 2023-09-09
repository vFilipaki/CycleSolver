massEquations = Any[]
MassCoef = Any[]
MassEq1 = Any[]
massParent = Any[]
closedInteractions = Any[]
fluidEq = Any[]
m_fraction = Any[]
m_Cycle = Any[]

function MassFlow(inStt, outStt, isolate=false)
    push!(massParent, [inStt, outStt])
    if isolate
        for i in 1:length(inStt)
            push!(fluidEq, [outStt[i], :($(inStt[i]).Cycle.isRefrigerationCycle), :($(inStt[i]).Cycle.fluid)])
        end
    else
        for i in [inStt..., outStt...]
            push!(fluidEq, [i, CycleSolver.SystemCycles[end].isRefrigerationCycle, CycleSolver.SystemCycles[end].fluid])
    end end

    m_total = :($(inStt[1]).m)
    for i in inStt[2:end]
        m_total = Expr(:call, :+, m_total, :($(i).m)) 
        if !(:($(i).m) in SystemVars)
            push!(SystemVars, :($(i).m))
    end end
    for i in outStt
        if !(:($(i).m) in SystemVars)
            push!(SystemVars, :($(i).m))
    end end

    if size(outStt)[1] > 1
        m_fraction2 = :(1)
        indexProp = size(m_fraction)[1] + 1
        CreateVariable(Expr(:ref, :m_fraction, indexProp, length(outStt)))
        for i in 1:(size(outStt)[1] - 1)
            push!(MassEq1, [:($(outStt[i]).m = $(m_total) * m_fraction[$indexProp, $i]), outStt[i], inStt])
            m_fraction2 = Expr(:call, :-, m_fraction2, Expr(:ref, :m_fraction, indexProp, i))
        end
        push!(MassEq1, [:($(last(outStt)).m = $(m_total) * $(m_fraction2)), last(outStt), inStt])
    else
        push!(MassEq1, [:($(last(outStt)).m = $(m_total)), last(outStt), inStt])
end end

function FindRootState(MassCopy, cycleStatesSymbols)
    MassCoef = Any[]
    for i in cycleStatesSymbols
        for j in 1:length(MassCopy)
            if i[1] in MassCopy[j][1] || i[1] in MassCopy[j][2]
                for k in MassCopy[j][1]
                    push!(MassCoef, [k, 1/length(MassCopy[j][1])])
                end
                for k in MassCopy[j][2]
                    push!(MassCoef, [k, 1/length(MassCopy[j][2])])
                end
                deleteat!(MassCopy, j)
                break
    end end end

    newValue = true
    while newValue
        newValue = false
        for i in length(MassCopy):-1:1
            if length(intersect([j[1] for j in MassCoef], MassCopy[i][1])) == length(MassCopy[i][1])
                sum = 0
                for j in MassCoef
                    if j[1] in MassCopy[i][1]
                        sum += j[2]
                    end
                end
                for j in MassCopy[i][2]
                    push!(MassCoef, [j, sum/length(MassCopy[1][2])])
                end
                deleteat!(MassCopy, i)
                newValue = true
            elseif length(intersect([j[1] for j in MassCoef], MassCopy[i][2])) != 0
                value = -1
                for j in MassCopy[i][2]
                    if j in [j[1] for j in MassCoef]
                        for k in MassCoef
                            if j == k[1]
                                value = k[2]
                end end end end
                for j in MassCopy[i][2]
                    if !(j in [j[1] for j in MassCoef])
                        push!(MassCoef, [j, value])
                end end
                for j in MassCopy[i][1]
                    push!(MassCoef, [j, value * length(MassCopy[i][2]) / length(MassCopy[i][1])])
                end
                deleteat!(MassCopy, i)
                newValue = true
            end
        end
    end
    MassCoef = unique(MassCoef)

    RootStt = Any[]
    for i in cycleStatesSymbols
        bigger = -1
        var = Any[]
        for j in MassCoef
            if j[1] in i
                if j[2] > bigger
                    bigger = j[2]
                    var = Any[j[1]]
                elseif j[2] == bigger
                    push!(var, j[1])
                end
            end
        end
        push!(RootStt, var)
    end

    return RootStt
end

function divideStatesPerCycle(cycleStatesSymbols)
    for i in 1:length(massParent)
        massParent[i] = [massParent[i][1]..., massParent[i][2]...]        
    end
    
    for i in massParent
        next = false
        for j in i
            for k in 1:length(cycleStatesSymbols)
                if j in cycleStatesSymbols[k]
                    for j2 in i
                        if !(j2 in cycleStatesSymbols[k])
                            push!(cycleStatesSymbols[k], j2)
                        end
                    end
                    next = true
                    break
                end
            end
            if next
                break
            end
        end
        if !next
            push!(cycleStatesSymbols, i)
        end
    end

    stopFor = true
    while stopFor
        mergeIndex = nothing
        stopFor = false
        for i in 1:size(cycleStatesSymbols)[1]
            for j in i + 1:size(cycleStatesSymbols)[1]
                inters = intersect(cycleStatesSymbols[i], cycleStatesSymbols[j])
                if size(inters)[1] > 0
                    mergeIndex = [i, j, inters]
                    stopFor = true
                    break
                end
            end
            if stopFor
                break
            end
        end
        if stopFor
            copy1 = copy(cycleStatesSymbols[mergeIndex[1]])
            copy2 = copy(cycleStatesSymbols[mergeIndex[2]])
            deleteat!(cycleStatesSymbols, findall(x->x==copy1, cycleStatesSymbols))
            deleteat!(cycleStatesSymbols, findall(x->x==copy2, cycleStatesSymbols))
            for j in mergeIndex[3]
                deleteat!(copy2, findall(x->x==j, copy2))
            end
            push!(cycleStatesSymbols, Any[copy1..., copy2...])
        end
    end
end

function FindCyclesInteractions(cDependencies, cycleStatesSymbols)
    for i in closedInteractions
        for j in 1:size(cycleStatesSymbols)[1]
            if i[1] in cycleStatesSymbols[j]
                for k in 1:size(cycleStatesSymbols)[1]
                    if i[2] in cycleStatesSymbols[k]
                        if !([j, k] in cDependencies) && !([k, j] in cDependencies)
                            push!(cDependencies, [j, k])                      
    end end end end end end
end

function EquationsHaveMassValues(cDependencies, cycleStatesSymbols)
    for i in unsolvedEquations
        if size(i.vars)[1] == 1 &&
        i.vars[1] isa Expr &&
        (i.vars[1].head == :.) &&
        last(i.vars[1].args) == :(:m)
            for k in 1:size(cycleStatesSymbols)[1]
                if i.vars[1].args[1] in cycleStatesSymbols[k]
                    SystemCycles[k].massDefined = true
                    for w in cDependencies
                        if k in w
                            SystemCycles[w[1]].massDefined = true
                            SystemCycles[w[2]].massDefined = true
    end end end end end end
end

function MainCycleMass(cycleStatesSymbols)
    cDependencies = Vector{Any}()
    FindCyclesInteractions(cDependencies, cycleStatesSymbols)
    EquationsHaveMassValues(cDependencies, cycleStatesSymbols)
    for i in copy(fluidEq)
        if i[3] isa String
            eval(Expr(:(=), :($(i[1]).fluid), i[3]))
            deleteat!(fluidEq, findall(x->x==i, fluidEq))
    end end
    
    for i in cDependencies
        if true in [CycleSolver.SystemCycles[j].massDefined for j in i]
            for j in i
                CycleSolver.SystemCycles[j].massDefined = true   
    end end end
    return cDependencies
end

function GenearateMassEquations(cycleStatesSymbols, RootStt)
    CyclesMassIndex = Array{Any}(undef, size(cycleStatesSymbols)[1])
    MassEq3 = []   
    for i in 1:size(RootStt)[1]
        if CycleSolver.SystemCycles[i].massDefined
            indexProp = size(m_Cycle)[1] + 1       
            CreateVariable(Expr(:ref, :m_Cycle, indexProp))
            CyclesMassIndex[i] = indexProp
            equalityMass = Expr(:ref, :m_Cycle, indexProp)
        else
            equalityMass = :(1)
        end
        for j in 1:size(MassEq1)[1]    
            if MassEq1[j][2] == RootStt[i][1] || (
                    size(MassEq1[j][3])[1] == 1 &&
                    MassEq1[j][3][1] == RootStt[i][1] &&
                    !ExpressionHasItem(MassEq1[j][1], :(m_fraction)))
                local outVars
                for j2 in MassEq1
                    if RootStt[i][1] in j2[3]
                        outVars = j2[3]
                        break
                end end
                
                if size(outVars)[1] == 1
                    if length(MassEq1[j][3]) == 1
                        push!(MassEq3, [:($(MassEq1[j][3][1]).m), equalityMass])    
                    end
                    MassEq1[j][1] = :($(MassEq1[j][1].args[1]) = $(equalityMass))           
                    if CycleSolver.SystemCycles[i].mainMassFlux != -1
                        eval(Expr(:(=), equalityMass, CycleSolver.SystemCycles[i].mainMassFlux))                            
                        push!(MassEq3, [equalityMass, CycleSolver.SystemCycles[i].mainMassFlux])                            
                    end
                else
                    for j2 in outVars
                        for j3 in 1:size(MassEq1)[1]
                            if j2 in MassEq1[j3][2]
                                MassEq1[j3][1] = :($(MassEq1[j3][1].args[1]) = $(equalityMass) * $(MassEq1[i][1].args[2].args[3]))
                                break
                end end end end
                break
    end end end
    MassEq2 = Array{Any}(undef, size(MassEq1)[1])
    for i in 1:size(MassEq1)[1]
        MassEq2[i] = Any[MassEq1[i][1].args[1], MassEq1[i][1].args[2]]
    end       

    push!(MassEq2, MassEq3...)

    newValue = true
    while newValue
        newValue = false
        for i in 1:size(MassEq2)[1]
            if ExpressionHasItem(MassEq2[i][2], QuoteNode(:m))                
                for j in MassEq2                    
                    if ExpressionHasItem(MassEq2[i][2], j[1])
                        MassEq2[i][2] = ExpressionSubstitution(MassEq2[i][2], j[1], j[2])                                   
                        newValue = true
    end end end end end
    for i in 1:size(MassEq2)[1]
        ret = MathEq()
        eq = Expr(:call, :(~), MassEq2[i][1], MassEq2[i][2])
        eq = Symbolics.simplify(CrossMultiplication(eval(eq)); expand=true)
        ret.Eq = eq
        ret.vars = Any[]
        ret.vars = GetEquationVariables(Meta.parse(string(eq.lhs)))
        ret.priority = false
        push!(massEquations, ret)
    end
    return MassEq2
end

function SetupMass()
    cycleStatesSymbols = Any[]
    MassCopy = deepcopy(massParent)
    divideStatesPerCycle(cycleStatesSymbols)
    RootStt = FindRootState(MassCopy, cycleStatesSymbols)    
    MainCycleMass(cycleStatesSymbols)
    GenearateMassEquations(cycleStatesSymbols, RootStt)
    
    for i in 1:length(SystemCycles)
        SystemCycles[i].states = [eval(j) for j in cycleStatesSymbols[i]]
        for j in cycleStatesSymbols[i]
            eval(Expr(:(=), :($(j).Cycle), SystemCycles[i]))
        end
    end
    for i in 1:length(unsolvedEquations)
        SubstituteMassInEq(unsolvedEquations[i])
    end
    for i in fluidEq
        eval(Expr(:(=), :($(i[1]).fluid), eval(i[3])))
    end
    for i in massEquations
        if length(i.vars) > 0
            massTemp = Meta.parse(string(i.Eq.rhs))
            massTemp = ExpressionSubstitution(massTemp, :m_fractionVars, :m_fraction)
            massTemp = ExpressionSubstitution(massTemp, :m_CycleVars, :m_Cycle)
            eval(Expr(:(=), i.vars[1], eval(massTemp)))
    end end
end

function SubstituteMassInEq(Equation)
    for j in copy(Equation.vars)
        if j isa Expr && (j.head == :.) && j.args[end] == QuoteNode(:mFraction)
            sttTemp = j.args[1]
            
            local newProp
            if j.args[1] isa Symbol
                newProp = Symbol(j.args[1], :Stts)
                newProp = Expr(:ref, newProp, 8)
            else
                newProp = copy(j.args[1])
                newProp.args[1] = Symbol(newProp.args[1], :Stts)
                newProp = Expr(:ref, newProp.args... , 8)
            end
            for k in massEquations
                if length(k.vars) > 0 && k.vars[1].args[1] == j.args[1]                    
                    Eq2Expr = Meta.parse(string(Equation.Eq))
                    newValue = string(k.Eq.rhs)
                    newValue = replace(newValue, "Vars" => "")

                    cycleMass = filter(x -> eval(j.args[1]) in x.states, SystemCycles)[1].mainMassFlux
                    if (cycleMass == -1)
                        indexSt = findfirst("m_Cycle[", newValue)[1]
                        indexEnd = indexSt - 1 + findfirst("]", newValue[indexSt:end])[1]
                        newValue = replace(newValue, newValue[indexSt:indexEnd] => "1")
                    else
                        newValue = string("(", newValue, ")/", cycleMass)
                    end

                    Eq2Expr = ExpressionSubstitution(Eq2Expr, newProp, Meta.parse(newValue))
                    Equation.vars = GetEquationVariables(copy(Eq2Expr))
                    
                    if (contains(string(Eq2Expr), "Stts[8]"))                        
                        Eq2Expr = Meta.parse(replace(string(Eq2Expr), "Stts[8]" => ".mFraction"))
                    end
                    eval(Eq2Expr)             
                    Equation.Eq = CrossMultiplication(eval(Eq2Expr))
                    for j2 in Equation.vars
                        if j2 isa Expr && j2.args[1] == :m_Cycle                            
                            Equation.Eq = substitute(Equation.Eq, Dict([eval(j2) => 1]))
                            Equation.vars = GetEquationVariables(Meta.parse(string(Equation.Eq)))
                            break
                    end end
                    break
    end end end end
    isaMassEq = false         
    for j in Equation.vars
        if j isa Expr && j.head == :. && j.args[end] == QuoteNode(:m)
            for k in massEquations
                if length(k.vars) > 0 && k.vars[1] == j
                    Equation.Eq = substitute(Equation.Eq, Dict([eval(j) => k.Eq.rhs]))
                    isaMassEq = true                   
                    break
            end end
    end end
    if isaMassEq        
        Equation.vars = []
        Equation.vars = GetEquationVariables(Meta.parse(string(Equation.Eq)))
        mCycleTimes = 0
        for j in Equation.vars
            if j isa Expr && j.args[1] == :m_Cycle
                mCycleTimes += 1
        end end
        if mCycleTimes == 1
            for j in Equation.vars
                if j isa Expr && j.args[1] == :m_Cycle
                    try
                        if Symbolics.solve_for([Equation.Eq], [eval(j)])[1] == 0
                            Equation.Eq = substitute(Equation.Eq, Dict([eval(j) => 1]))
                            break
                        end
                    catch
            end end end 
            Equation.vars = GetEquationVariables(Meta.parse(string(Equation.Eq)))
        end
        for k in copy(Equation.vars)
            if k isa Expr && k.args[1] == :m_fraction
                changed = false
                ret = Equation.Eq.lhs/(m_fraction[k.args[2], k.args[3]]) ~ Equation.Eq.rhs/(m_fraction[k.args[2], k.args[3]])
                ret = Symbolics.simplify(ret; simplify_fractions=true)                    
                if ((Symbolics.istree(ret.lhs) && Symbolics.istree(ret.rhs)) &&
                (Symbolics.operation(ret.lhs) == /) && (Symbolics.operation(ret.rhs) == /) &&
                (string(Symbolics.arguments(ret.rhs)[end]) == string(Symbolics.arguments(ret.lhs)[end])))
                    ret = Symbolics.arguments(ret.lhs)[1] ~ Symbolics.arguments(ret.lhs)[2]
                else
                    Equation.Eq = Symbolics.simplify(CrossMultiplication(ret); expand=true)
                    Equation.vars = []
                    Equation.vars = GetEquationVariables(Meta.parse(string(ret)))
                end                 

                ret = Equation.Eq.lhs/(1 - m_fraction[k.args[2], k.args[3]]) ~ Equation.Eq.rhs/(1 - m_fraction[k.args[2], k.args[3]])
                ret = Symbolics.simplify(ret; simplify_fractions=true)
                if ((Symbolics.istree(ret.lhs) && Symbolics.istree(ret.rhs)) &&
                (Symbolics.operation(ret.lhs) == /) && (Symbolics.operation(ret.rhs) == /) &&
                (string(Symbolics.arguments(ret.rhs)[end]) == string(Symbolics.arguments(ret.lhs)[end])))
                    ret = Symbolics.arguments(ret.lhs)[1] ~ Symbolics.arguments(ret.lhs)[2]
                else
                    Equation.Eq = Symbolics.simplify(CrossMultiplication(ret); expand=true)
                    Equation.vars = []
                    Equation.vars = GetEquationVariables(Meta.parse(string(ret)))
                end  
        end end           
    end
end

function clearMassVariables()
    global massEquations = Any[]
    global MassCoef = Any[]
    global MassEq1 = Any[]
    global massParent = Any[]
    global closedInteractions = Any[]
    global fluidEq = Any[]
    global m_fraction = Any[]
    global m_Cycle = Any[]
end