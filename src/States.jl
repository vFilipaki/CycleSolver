using CoolProp
set_reference_state("R134a","ASHRAE")

SystemStates = Any[]
unsolvedStates = Any[]

mutable struct Stt
    T
    p
    h
    s
    Q
    rho
    m
    mFraction
    fluid
    Cycle
    name
end   

function StatesSolver(states)
    newValue = false
    DoAgain = false  
    
    for stt in copy(states)
        vars = ["P", "T", "Q", "H", "S"]        
        values = Any[stt.p, stt.T, stt.Q, stt.h, stt.s]
        knownProperties = []

        for j in 1:5
            if values[j] isa Float64 || values[j] isa Int
                push!(knownProperties, j)
        end end
        blacklist = [[2, 4], [3, 4], [3, 5]]
        chosen = []
        if size(knownProperties)[1] > 1
            for j in 1:size(knownProperties)[1]
                if size(chosen)[1] == 2 
                    break 
                end
                for k in (j + 1):size(knownProperties)[1]
                    if !([knownProperties[j], knownProperties[k]] in blacklist)
                        chosen = [knownProperties[j], knownProperties[k]]
                        break
            end end end
        else  
            continue
        end      
                
        if size(chosen)[1] >= 2
            stTemp = nothing
            stTemp = StateProps(stt.fluid, [vars[chosen[1]], values[chosen[1]], vars[chosen[2]], values[chosen[2]]])
            stt.T = stTemp[1]
            stt.p = stTemp[2]
            stt.h = stTemp[3]
            stt.s = stTemp[4]
            stt.Q = stTemp[5]
            stt.rho = stTemp[6]
            deleteat!(states, findall(x->x==stt, states))
            newValue = true              
        end         
    end
    if DoAgain
        newValue |= StatesSolver()
    end
    return newValue
end

function StateProps(fluid, props)
    returnState = zeros(6)
    if props[1] in ["P", "H", "S"]
        props[2] *= 1000
    end
    if props[3] in ["P", "H", "S"]
        props[4] *= 1000
    end   
    allProp = ["T", "P", "H", "S", "Q", "D"]
    for i in 1:6
        if allProp[i] in props[1:2:end]     
            returnState[i] = props[1] == allProp[i] ? props[2] : props[4]
        else
            returnState[i] = PropsSI(allProp[i], props..., fluid)
        end
    end
    returnState[2] /= 1000 
    returnState[3] /= 1000 
    returnState[4] /= 1000 
    return returnState
end

function createState(state)
    if state in [i.name for i in SystemStates]
        return
    end
    isDefined = nothing
    if state isa Expr
        isDefined = eval(Expr(:macrocall, Symbol("@isdefined"), :(), state.args[1])) && !isnothing(eval(state.args[1]))
    else
        isDefined = eval(Expr(:macrocall, Symbol("@isdefined"), :(), state)) && !isnothing(eval(state))
    end

    if !(state isa Expr) && !(state isa Symbol)
        return
    end
    if !(state isa Expr) && isDefined
        return
    end
    for i in unsolvedStates
        if i.name == state
            return
    end end
    
    local state2
    if state isa Expr
        state2 = copy(state)
        for i in 2:size(state2.args)[1]
            state2.args[i] = Expr(:call, :(:), 1, state2.args[i])
        end
        state2 = Expr(:ref, state2.args..., Expr(:call, :(:), 1, 8))
    else
        state2 = Expr(:ref, state, Expr(:call, :(:), 1, 8))
    end    
    
    state2.args[1] = Symbol(state2.args[1], :Stts)
    eval(Expr(:macrocall, Symbol("@variables"), :(), state2))
    eval(Expr(:(=), state2.args[1], Expr(:call, :collect, state2.args[1])))

    if state isa Expr
        if isDefined            
            newSz = size(eval(state.args[1]))
            newSz = [newSz...]
            for i in 1:size(newSz)[1]
                if newSz[i] < state.args[1+i]
                    newSz[i] = state.args[1+i]
            end end                
            mult = 1
            for i in newSz
                mult *= i
            end
            varVec = vec(eval(state.args[1]))
            resize!(varVec, mult)
            eval(Expr(:(=), state.args[1], Expr(:call, :reshape, varVec, (newSz...))))
        else
            eval(Expr(:(=), state.args[1], Expr(:call, :(Array{Any}), :undef, state.args[2:end]...)))            
        end
        eval(Expr(:(=), state, Expr(:call, Stt, ntuple(x->nothing, fieldcount(Stt))...)))
    else
        eval(Expr(:(=), state, Expr(:call, Stt, ntuple(x->nothing, fieldcount(Stt))...)))
    end    
    sttClass = eval(state)
    state3 = copy(state2)
    for i in 2:(size(state3.args)[1]-1)
        state3.args[i] = state3.args[i].args[3]
    end
    sttVars = eval(state3)
    sttClass.T = sttVars[1]
    sttClass.p = sttVars[2]
    sttClass.h = sttVars[3]
    sttClass.s = sttVars[4]
    sttClass.Q = sttVars[5]
    sttClass.rho = sttVars[6]
    sttClass.m = sttVars[7]
    sttClass.mFraction = sttVars[8]
    sttClass.name = state
    eval(Expr(:(=), state2.args[1], :nothing))
    push!(unsolvedStates, sttClass)
    push!(SystemStates, sttClass)
end

function clearStates()
    for j in SystemStates
        eval(Expr(:(=), j.name, nothing))
    end 
    # for i in SystemCycles
    #     for j in i.states
    #         eval(Expr(:(=), j.name, nothing))
    # end end 
    global unsolvedStates = Any[]
    global SystemStates = Any[]
end