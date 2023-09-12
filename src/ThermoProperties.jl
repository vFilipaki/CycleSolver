PropsEquations = Any[]
qflex = Any[]

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

function GenerateFlexHeatEquations(useMass, q)
    local inTemp
    local outTemp
    if useMass
        inTemp = [[GetCycleIndexByStateSymbol(q[1][1]), :($(q[1][1]).h * $(q[1][1]).m)]]
        outTemp = [:($(q[2][1]).h * $(q[2][1]).m)]
        for j in 2:length(q[1])
            newQ = true
            myIndex = GetCycleIndexByStateSymbol(q[1][j])
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
        inTemp = [[GetCycleIndexByStateSymbol(q[1][1]), :($(q[1][1]).h)]]
        outTemp = [:($(q[2][1]).h)]
        for j in 2:length(q[1])
            newQ = true
            myIndex = GetCycleIndexByStateSymbol(q[1][j])
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

function EvaluateFlexHeatProperties()
    for i in qflex
        if isnothing(eval(i[1][1]).m)                 
            inTemp, outTemp = GenerateFlexHeatEquations(false, i)
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
            inTemp, outTemp = GenerateFlexHeatEquations(true, i)
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

            inTemp, outTemp = GenerateFlexHeatEquations(false, i)
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
end

function ManageComponentTag(component)
    component = replace(component, "(" => "")                
    component = replace(component, ")" => "")
    component = replace(component, "Any" => "")
    component = replace(component, "[:" => "[")
    component = replace(component, ", :" => ", ")
    return component
end

function EvaluatePropertiesEquations()
    removeList = Any[]
    for i in 1:length(PropsEquations)
        try                
            PropsEquations[i][2] = eval(PropsEquations[i][2])
            PropsEquations[end][3][1] = ManageComponentTag(PropsEquations[end][3][1])
            PropsEquations[i][3][2] = GetCycleIndexByStateSymbol(PropsEquations[i][3][2])
        catch
            push!(removeList, i)
        end
    end
    for i in length(removeList):-1:1
        deleteat!(PropsEquations, removeList[i])
    end
end

function ClearProperties()
    global PropsEquations = Any[]
    global qflex = Any[]
end