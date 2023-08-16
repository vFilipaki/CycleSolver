using Symbolics

SystemVars = Any[]
unsolvedEquations = Any[]
unsolvedConditionalEquation = Any[]

mutable struct MathEq
    Eq
    vars
    priority
    MathEq() = new()
end

mutable struct ConditionalMathEq
    condition
    caseTrue
    caseFalse    
end

function NewEquation(eq) 
    if eq.head == Symbol('=')
        for i in eq.args
            ManageExpression(i)                
        end
        newEquation = MathEq()
        eq = Expr(:call, :(~), eq.args[1], eq.args[2])
        newEquation.Eq = CrossMultiplication(eval(eq))
        newEquation.vars = GetEquationVariables(Meta.parse(string(newEquation.Eq)))
        push!(unsolvedEquations, newEquation)
    elseif eq.head== :ref
        push!(SystemCycles, CycleStruct())

        SystemCycles[end].isRefrigerationCycle = 
        eq.args[1] == Symbol("newRefrigerationCycle")           
    
        if length(eq.args) > 1
            if eq.args[2] isa Expr
                SystemCycles[end].fluid = String(eq.args[2].args[2])
                SystemCycles[end].mainMassFlux = eq.args[2].args[3]
                SystemCycles[end].massDefined = true;
            else
                SystemCycles[end].fluid = String(eq.args[2])
                SystemCycles[end].mainMassFlux = -1
            end
        else
            SystemCycles[end].fluid = "water"
            SystemCycles[end].mainMassFlux = -1
        end
    elseif eq.head == :call
        for i in 2:3                
            if !(eq.args[i] isa Expr && eq.args[i].head == :vect)
                eq.args[i] = Expr(:vect, eq.args[i])
        end end         
        for i in eq.args[2].args
            createState(i)
        end
        for i in eq.args[3].args
            createState(i)
        end
        eval(eq)
    end
end 

function EquationsSolver(eq)
    findNewValue = true  
    while findNewValue
        findNewValue = false

        tempEquations = MathEq[]
        for i in eq
            if length(i.vars) == 1
                push!(tempEquations, i)
            end
        end
        if length(tempEquations) > 0     
            for i in tempEquations
                try
                    newValues = Symbolics.solve_for([i.Eq], [eval(i.vars[1])])
                    eval(Expr(:(=), i.vars[1], newValues[1]))
                    deleteat!(eq, findall(x->x==i, eq))
                    findNewValue = true
                catch
                end
            end             
            
            UpdateEquationList(eq)   
        end            
    end

    findNewValue = false
    VarsSubsets = Any[]
    for i in eq
        intersected = false
        for j in 1:length(VarsSubsets)
            if length(intersect(i.vars, VarsSubsets[j])) > 0
                VarsSubsets[j] = union(VarsSubsets[j], i.vars)
                intersected = true
        end end
        if !intersected
            push!(VarsSubsets, i.vars)
        end
    end
    
    begin
        i = 1
        while i <= length(VarsSubsets)
            j = i+1
            while j <= length(VarsSubsets)
                if length(intersect(VarsSubsets[i], VarsSubsets[j])) > 0
                    VarsSubsets[i] = union(VarsSubsets[i], VarsSubsets[j])
                    deleteat!(VarsSubsets, j)
                    j -= 1
                end
                j += 1
            end
            i += 1
        end
    end

    EquationSubsets = Any[]
    for i in VarsSubsets
        push!(EquationSubsets, Any[])
        for j in eq
            if length(intersect(j.vars, i)) > 0
                push!(EquationSubsets[end], j)        
    end end end

    for i in 1:length(EquationSubsets)
        if (length(EquationSubsets[i]) != length(VarsSubsets[i]))
            continue
        end
        try
            newValues = Symbolics.solve_for([j.Eq for j in EquationSubsets[i]], [eval(j) for j in VarsSubsets[i]])
            
            for j in 1:length(VarsSubsets[i])
                eval(Expr(:(=), VarsSubsets[i][j], newValues[j]))
            end
            for i in EquationSubsets
                deleteat!(eq, findall(x->x==i, eq))
            end
            findNewValue = true
        catch
            continue
        end
    end 

    if findNewValue
        UpdateEquationList(eq)
    end
    
    return findNewValue
end

function ManageConditionalEquations(eq)
    newValue = false    
    for i in 1:length(eq)
        if isnothing(eq[i].condition)
            continue
        end
        checkCondition = eval(eq[i].condition)
        if !(checkCondition isa Bool)
            checkCondition = UpdateEq(checkCondition)
        end
        if checkCondition isa Bool
            if checkCondition
                for j in eq[i].caseTrue
                    NewEquation(j)
                    SubstituteMassInEq(unsolvedEquations[end])
                end
            else
                for j in eq[i].caseFalse
                    NewEquation(j)
                    SubstituteMassInEq(unsolvedEquations[end])
                end
            end
            newValue = true
            eq[i].condition = nothing            
        end
    end
    return newValue
end

function UpdateEquationList(eq)
    deletList = MathEq[]
    for i in eq
        i.Eq = UpdateEq(i.Eq)
        i.vars = GetEquationVariables(Meta.parse(string(i.Eq)))        
        if length(i.vars) == 0
            push!(deletList, i)
        end
    end
    for i in deletList
        deleteat!(eq, findall(x->x==i, eq))
    end      
end

function UpdateEq(eq, start = true)
    if start            
        eq = Meta.parse(string(eq)) 
        UpdateEq(eq, false) 
        return eval(eq)   
    else            
        for i in 1:size(eq.args)[1]                                
            if eq.args[i] isa Expr
                if eq.args[i].head == :ref    
                    if Symbol(string(eq.args[i].args[1])[end-3: end]) == :Stts
                        eq.args[i].args[1] = Symbol(string(eq.args[i].args[1])[1: end-4])
                        sttProp = [
                            :(:T),
                            :(:p),
                            :(:h),
                            :(:s),
                            :(:Q),
                            :(:rho),
                            :(:m),
                            :(:mFraction)
                        ][last(eq.args[i].args)]
                        if size(eq.args[i].args)[1] > 2
                            eq.args[i] = Expr(:., Expr(:ref, eq.args[i].args[1: end-1]...) , sttProp)
                        else
                            eq.args[i] = Expr(:., eq.args[i].args[1] , sttProp)
                        end
                    else                            
                        eq.args[i].args[1] = Symbol(string(eq.args[i].args[1])[1: end-4])
                    end
                else        
                    UpdateEq(eq.args[i], false)
                end
            else
                strTemp = string(eq.args[i])
                if length(strTemp) > 4 && Symbol(strTemp[end-3: end]) == :Vars
                    eq.args[i] = Symbol(strTemp[1: end-4])
                end
        end end 
        return eq
    end           
end

function CrossMultiplication(eq)
    eq = Symbolics.simplify(eq)
    if Symbolics.istree(eq.rhs) && Symbolics.operation(eq.rhs) == /
        eq = Symbolics.arguments(eq.rhs)[2] * eq.lhs ~ Symbolics.arguments(eq.rhs)[2] * eq.rhs
    end
    if Symbolics.istree(eq.lhs) && Symbolics.operation(eq.lhs) == /
        eq = Symbolics.arguments(eq.lhs)[2] * eq.lhs ~ Symbolics.arguments(eq.lhs)[2] * eq.rhs
    end    
    return eq
end

function GetEquationVariables(eq, vars = [])
    if eq isa Expr 
        if eq.head == Symbol("call")
            for i in eq.args[2:1:end]
                GetEquationVariables(i, vars)
            end
        elseif eq.head == Symbol("block")
            for i in eq.args[2:2:end]
                GetEquationVariables(i, vars)
            end
        elseif string(eq.args[1])[end-3: end] == "Stts"
            eq.args[1] = Symbol(string(eq.args[1])[1: end-4]) 
            prop = [
                :(:T),
                :(:p),
                :(:h),
                :(:s),
                :(:Q),
                :(:rho),
                :(:m),
                :(:mFraction)
            ][eq.args[end]]
            if size(eq.args)[1] > 2
                eq = Expr(:., Expr(:ref, eq.args[1: end-1]...), prop)
            else
                eq = Expr(:., eq.args[1], prop)
            end
            if !(eq in vars) 
                push!(vars, eq)
            end
        else
            eq.args[1] = Symbol(string(eq.args[1])[1: end-4])
            if !(eq in vars) 
                push!(vars, eq)
            end
        end    
    elseif eq isa Symbol
        eq = Symbol(string(eq)[1: end-4])
        if !(eq in vars) 
            push!(vars, eq)
        end
    end  
    return vars  
end

function ManageExpression(eq)
    if eq isa Expr 
        if eq.head == Symbol("call")
            for i in eq.args[2:1:end]
                ManageExpression(i)
            end
        elseif eq.head == Symbol("block")
            for i in eq.args[2:2:end]
                ManageExpression(i)
            end
        else
            IdentifyVariables(eq)
        end    
    elseif eq isa Symbol
        IdentifyVariables(eq)
    end
end

function ExpressionHasItem(eq, item)
    if eq == item
        return true
    elseif eq isa Expr
        for i in eq.args
            if ExpressionHasItem(i, item)
                return true                
    end end end
    return false
end

function ExpressionSubstitution(eq, old, new)
    if eq == old
        eq = new
    elseif eq isa Expr
        for i in 1:size(eq.args)[1]
            eq.args[i] = ExpressionSubstitution(eq.args[i], old, new)
    end end
    return eq
end

function IdentifyVariables(var)
    if var isa Expr 
        if var.head == Symbol(".")
            createState(var.args[1])
        elseif var.head == Symbol("ref")  
            CreateVariable(var)                    
        end
        if !(var in SystemVars)
            push!(SystemVars, var)
        end
    elseif !(var in SystemVars)
        push!(SystemVars, var)
        CreateVariable(var) 
    end   
end

function CreateVariable(var) 
    isDefined = nothing
    if var isa Expr
        isDefined = eval(Expr(:macrocall, Symbol("@isdefined"), :(), var.args[1])) && !isnothing(eval(var.args[1]))
    else
        isDefined = eval(Expr(:macrocall, Symbol("@isdefined"), :(), var)) && !isnothing(eval(var))
    end
    
    if !(var isa Expr) && isDefined
        return
    end

    if var isa Expr
        var2 = copy(var)    
        var2.args[1] = Symbol(var2.args[1], :Vars) 

        if isDefined
            oldSz = size(eval(var.args[1]))
            newSz = var.args[2:end]
            for i in 1:length(newSz)
                if i < length(oldSz) && newSz[i] < oldSz[i]
                    newSz[i] = oldSz[i]
            end end
            mult = 1
            for i in newSz
                mult *= i
            end
            for i in 2:size(var2.args)[1]
                var2.args[i] = Expr(:call, :(:), 1, newSz[i-1])
            end
            eval(Expr(:macrocall, Symbol("@variables"), :(), var2))
            eval(Expr(:(=), var2.args[1], Expr(:call, :collect, var2.args[1])))

            var2Eval = eval(var2.args[1])
            copyVarb = copy(eval(var.args[1]))

            varVec = vec(eval(var.args[1]))
            resize!(varVec, mult)
            eval(Expr(:(=), var.args[1], Expr(:call, :reshape, varVec, (newSz...))))            
            var1Eval = eval(var.args[1])

            var1Eval[[(1:i) for i in size(var2Eval)]...] = var2Eval[[(1:i) for i in size(var2Eval)]...]
            var1Eval[[(1:i) for i in size(copyVarb)]...] = copyVarb[[(1:i) for i in size(copyVarb)]...]   
        else
            for i in 2:size(var2.args)[1]
                var2.args[i] = Expr(:call, :(:), 1, var2.args[i])
            end
            eval(Expr(:macrocall, Symbol("@variables"), :(), var2))
            eval(Expr(:(=), var2.args[1], Expr(:call, :collect, var2.args[1])))
            
            eval(Expr(:(=), var.args[1], Expr(:call, :(Array{Any}), :undef, var.args[2:end]...)))       
            var1Eval = eval(var.args[1])
            var2Eval = eval(var2.args[1])
            var1Eval[[(1:i) for i in size(var2Eval)]...] = var2Eval[[(1:i) for i in size(var2Eval)]...]
        end
        eval(Expr(:(=), var2.args[1], :nothing))
    else
        var2 = Symbol(var, :Vars) 
        eval(Expr(:macrocall, Symbol("@variables"), :(), var2))
        eval(Expr(:(=), var, var2))
        eval(Expr(:(=), var2, :nothing))
    end    
end

function ClearEquations()
    for i in SystemVars
        if i isa Expr
            if !(i.head == :.)
                eval(Expr(:(=), i.args[1], nothing))
            end
        else
            eval(Expr(:(=), i, nothing))
    end end

    global SystemVars = Any[]
    global unsolvedEquations = Any[]
    global unsolvedConditionalEquation = Any[]
end
