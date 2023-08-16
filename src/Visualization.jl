using PrettyTables
using Plots

function TSGraph(cycles)
    p = plot()
    for c in cycles
        flow = [[i[3], i[2]] for i in MassEq1]
        FlowGraph = Any[]
        for i in flow
            for j in i[1]
                if j in [k.name for k in SystemCycles[c].states]
                    push!(FlowGraph, Any[j, i[2]])
                end
        end end

        states = SystemCycles[c].states
        t = [i.T for i in states]
        s = [i.s for i in states]
        name = [string(i.name) for i in states]

        push!(t, t[1])
        push!(s, s[1])
        push!(name, "")

        for i in 1:length(t)-1
            if name[i] == ""
                continue
            end
            for j in i+1:length(t)
                if (t[j]-t[i])^2+(100*(s[j]-s[i]))^2 < 50
                    t[i] = (t[i] + t[j])/2
                    s[i] = (s[i] + s[j])/2
                    name[i] = string(name[i], " ", name[j])
                    name[j] = ""
        end end end

        colors = [RGBA{Float64}(0, 0, 0, 0.4), RGBA{Float64}(0, 0, 1, 1)]
        txtColor = RGBA{Float64}(0, 0, 0, 1)
        if length(cycles) > 1
            if c == 1
                colors = [RGBA{Float64}(0, 0, 1, 0.25), RGBA{Float64}(0, 0, 1, 1)]
            elseif  c == 2
                colors = [RGBA{Float64}(1, 0, 0, 0.25), RGBA{Float64}(1, 0, 0, 1)]
            elseif  c == 3
                colors = [RGBA{Float64}(0, 1, 0, 0.25), RGBA{Float64}(0, 1, 0, 1)]
            elseif  c == 4
                colors = [RGBA{Float64}(1, 0, 1, 0.25), RGBA{Float64}(1, 0, 1, 1)]
            end
            txtColor = colors[2]
        end        
        
        for j in 1:length(name)
            if name[j] != ""
                annotate!(s[j], t[j], text("█"^(length(name[j])÷2+1), :white, :center, :center, 10))
                annotate!(s[j], t[j], text(name[j], txtColor, :center, :center, 8))
            end
        end
        fluidTemp = SystemCycles[c].states[1].fluid

        AlltRange = Any[SystemCycles[c].states[1].T, SystemCycles[c].states[1].T]
        isVapor = true
        for i in SystemCycles[c].states
            try
                isVapor &= i.T > PropsSI("T", "P", i.p * 1000, "Q", 0, fluidTemp)
            catch
            end
            if i.T > AlltRange[2]
                AlltRange[2] = i.T
            end
            if i.T < AlltRange[1]
                AlltRange[1] = i.T
            end
        end
        sizeRangeT = AlltRange[2] - AlltRange[1]

        if !isVapor
            res = 15
            tvec = Array{Any}(nothing, 2*res+1)
            svec = Array{Any}(nothing, 2*res+1)
            T0 = PropsSI("Tcrit", fluidTemp)
            Tmin = max(PropsSI("Tmin", fluidTemp), AlltRange[1] - sizeRangeT*0.4)
            tvec[res + 1] = T0
            svec[res + 1] = PropsSI("S", "T", T0, "Q", 1, fluidTemp) / 1000

            for i in 1:res
                T = T0 - (T0 - Tmin)*(i/res)^2
                tvec[res + 1 + i] = T
                tvec[res + 1 - i] = T
                svec[res + 1 + i] = PropsSI("S", "T", T, "Q", 1, fluidTemp) / 1000
                svec[res + 1 - i] = PropsSI("S", "T", T, "Q", 0, fluidTemp) / 1000
            end

            plot!(svec, tvec, color = colors[1])
        end

        for i in FlowGraph
            t = Any[]
            s = Any[]
            localSt1 = eval(i[1])
            localSt2 = eval(i[2])
        
            push!(t, localSt1.T)
            push!(s, localSt1.s)
        
            if localSt1.p == localSt2.p
                if abs(localSt1.T - localSt2.T) < 2
                    push!(t, localSt2.T)
                    push!(s, localSt2.s) 
                else
                    local tQ0
                    try
                        tQ0 = PropsSI("T", "P", localSt2.p * 1000, "Q", 0, fluidTemp)
                    catch
                        tQ0 = -1
                    end
                    steps = ceil(Int, abs(localSt2.T-localSt1.T) / 10)
                    signQ0 = localSt1.T > tQ0
                    j = 0
                    while j < steps
                        j += 1
                        tTemp = localSt1.T + j/steps * (localSt2.T-localSt1.T)
                        if (tTemp > tQ0) != signQ0 
                            if localSt1.Q == -1
                                push!(s, PropsSI("S", "P", localSt2.p * 1000, "Q", localSt2.T < localSt1.T ? 1 : 0, fluidTemp)/1000)
                                push!(t, tQ0)
                            end                           
                            

                            if localSt2.Q != -1
                                push!(s, PropsSI("S", "P", localSt2.p * 1000, "Q", localSt2.Q, fluidTemp)/1000)
                                push!(t, tQ0)
                            else
                                push!(s, PropsSI("S", "P", localSt2.p * 1000, "Q", localSt2.T < localSt1.T ? 0 : 1, fluidTemp)/1000)
                                push!(t, tQ0)
                            end
                        elseif (tTemp == tQ0)
                            push!(s, PropsSI("S", "P", localSt2.p * 1000, "Q", localSt2.T < localSt1.T ? 1 : 0, fluidTemp)/1000)
                            push!(t, tQ0)

                            push!(s, PropsSI("S", "P", localSt2.p * 1000, "Q", localSt2.T < localSt1.T ? 0 : 1, fluidTemp)/1000)
                            push!(t, tQ0)
                        end
                        signQ0 = tTemp > tQ0
                        if abs(tTemp - tQ0) > 1
                            try
                                push!(s, PropsSI("S", "P", localSt2.p * 1000, "T", tTemp, fluidTemp)/1000)
                                push!(t, tTemp)
                            catch
                            end
                        end
                    end
                end
            else
                if abs(localSt1.h-localSt2.h) < 1
                    TRound = round(Int, abs(localSt2.s-localSt1.s) / 0.005)
                    for j in 1:TRound
                        tTemp = localSt1.s + j/(TRound+1) * (localSt2.s-localSt1.s)
                        push!(s, tTemp)
                        push!(t, PropsSI("T", "H", localSt2.h * 1000, "S", tTemp * 1000, fluidTemp))
                    end
                elseif length(cycles) == 1
                    newT = PropsSI("T", "P", localSt2.p * 1000, "S", localSt1.s * 1000, fluidTemp)
                    newC = RGBA{Float64}(colors[2].r, colors[2].g, colors[2].b, 0.5)
                    plot!([localSt1.s, localSt1.s], [localSt1.T, newT], lw=1, ls=:dash, color = newC)
                end
                push!(t, localSt2.T)
                push!(s, localSt2.s)
            end
        
            plot!(s, t, color = colors[2])
        end            
        plot!(legend = false, grid = false,
        xlabel = "s [kJ/kg.K]", ylabel = "T [K]")
       
        if length(cycles) == 1
            pressureRanges = Any[]
            for i in SystemCycles[c].states
                if !(i.p in pressureRanges)
                    push!(pressureRanges, i.p)
                end
            end

            for k in pressureRanges
                tRange = Any[-1, -1]
                for i in SystemCycles[c].states
                    if i.p == k
                        if tRange[1] == -1
                            tRange = Any[i.T, i.T]
                            continue
                        end
                    else
                        continue
                    end
                    if i.T > tRange[2]
                        tRange[2] = i.T
                    end
                    if i.T < tRange[1]
                        tRange[1] = i.T
                    end
                end

                tRange[2] += sizeRangeT * 0.35
                tRange[1] -= sizeRangeT * 0.1
                if PropsSI("Tmax", fluidTemp) < tRange[2] 
                    tRange[2] = PropsSI("Tmax", fluidTemp)
                end

                if !isVapor 
                    tRange[1] = PropsSI("T", "P", k * 1000, "Q", 0, fluidTemp)
                else
                    try
                        if tRange[1] < PropsSI("T", "P", k * 1000, "Q", 0, fluidTemp)
                            tRange[1] = PropsSI("T", "P", k * 1000, "Q", 0, fluidTemp)
                        end
                    catch
                        tRange[1] += sizeRangeT * 0.1
                    end
                end

                t = Any[]
                s = Any[]
                if abs(tRange[1] - tRange[2]) < 0.5
                    push!(t, tRange[2].T)
                    push!(s, tRange[2].s) 
                else
                    local tQ0
                    try
                        tQ0 = PropsSI("T", "P", k * 1000, "Q", 0, fluidTemp)
                    catch
                        tQ0 = -1
                    end
                    steps = ceil(Int, abs(tRange[2]-tRange[1]) / 10)
                    signQ0 = tRange[1] > tQ0
                    j = 0
                    while j < steps
                        j += 1
                        tTemp = tRange[1] + j/steps * (tRange[2]-tRange[1])
                        if (tTemp > tQ0) != signQ0
                            push!(s, PropsSI("S", "P", k * 1000, "Q", tRange[2] < tRange[1] ? 1 : 0, fluidTemp)/1000)
                            push!(t, tQ0)

                            push!(s, PropsSI("S", "P", k * 1000, "Q", tRange[2] < tRange[1] ? 0 : 1, fluidTemp)/1000)
                            push!(t, tQ0)
                        end
                        signQ0 = tTemp > tQ0
                        if abs(tTemp - tQ0) > 0.5
                            push!(s, PropsSI("S", "P", k * 1000, "T", tTemp, fluidTemp)/1000)
                            push!(t, tTemp)
                        end
                    end
                end                
                newC = RGBA{Float64}(colors[2].r, colors[2].g, colors[2].b, 0.4)
                plot!(s, t, lw=1, color = newC)
                txtP = string(round(Int, k), " KPa")
                # annotate!(s[end], t[end], text("█"^(length(txtP)÷2+1), :white, :center, :center, 6, rotation = 45))
                # annotate!(s[end], t[end], text(txtP, txtColor, :center, :center, 5, rotation = 45))
            end            
        end
    end
    return p
end

function PrintResults()
    str = Any[]
    for i in 1:length(SystemCycles)
        TitleTxt = string(i,"- ")
        if SystemCycles[i].isRefrigerationCycle
            TitleTxt = string(TitleTxt, "REFRIGERATION ")
        end
        
        TitleTxt = string(TitleTxt, " CYCLE [", SystemCycles[i].fluid, "]")

        TitleTxt = string("<h1 style='display: block; text-align: center; border: 1px solid #666666;",
        "margin: -17px; margin-bottom: 20px; padding: 10px'>", TitleTxt,"</h1>")
        #####################################################
        DataStates = Any[]
        for j in SystemCycles[i].states
            push!(DataStates, Any["", "", "", "", "", "", "", ""]) 
            DataStates[end][1] = string(j.name)
            if !(j.T isa Num)
                DataStates[end][2] = round(j.T, digits=4)
            end
            if !(j.p isa Num)
                DataStates[end][3] = round(j.p, digits=4)
            end
            if !(j.h isa Num)
                DataStates[end][4] = round(j.h, digits=4)
            end
            if !(j.s isa Num)
                DataStates[end][5] = round(j.s, digits=4)
            end
            if !(j.Q isa Num) && j.Q != -1
                DataStates[end][6] = round(abs(j.Q), digits=4)
            end
            if !isnothing(j.m)
                DataStates[end][7] = round(j.m, digits=4)
            end
            DataStates[end][8] = round(j.mFraction, digits=4)
        end
        DataStates = mapreduce(permutedims, vcat, DataStates)

        io = IOBuffer()
        pretty_table(backend = Val(:html), tf = tf_html_simple,
        alignment=:l, linebreaks=true, io, DataStates; header=(
            ["State", "T [K]", "P [kPa]", "h [kJ/kg]", "s [kJ/kg.K]", "x", "ṁ [kg/s]", "Mass-flux"]
            ), standalone = true)
        propsTb1 = String(take!(io))

        propsTb1 = replace(propsTb1, "State" => "State<br>Name") 
        propsTb1 = replace(propsTb1, "Mass-flux" => "Mass-flux<br>fraction") 
        propsTb1 = replace(propsTb1, "left;" => "left; padding: 8px; font-size: 130%;")
        propsTb1 = replace(propsTb1, "th style = \"text-align: left" => "th style = \"text-align: center")
        propsTb1 = replace(propsTb1, "collapse;" => "collapse; color: black;")
        propsTb1 = string("<div style = \"display: inline-block; border: 1px solid #666666;\">", propsTb1, "</div>")
        #####################################################
        allValues = Any[[SystemCycles[i].thermoProperties.qin, SystemCycles[i].thermoProperties.Qin], [SystemCycles[i].thermoProperties.qout, SystemCycles[i].thermoProperties.Qout],
            [SystemCycles[i].thermoProperties.win, SystemCycles[i].thermoProperties.Win], [SystemCycles[i].thermoProperties.wout, SystemCycles[i].thermoProperties.Wout]]
        propsValues = ["qin\nQ̇in", "qout\nQ̇out", "win\nẆin", "wout\nẆout"]
        tempData = Any[]
        for j in 1:4
            push!(tempData, Array{Any}(nothing, 4))
            tempData[j][1] = propsValues[j]
            tempData[j][2] = string(round(allValues[j][1]["total"], digits=4), " kJ/kg\n", round(allValues[j][2]["total"], digits=4), " kW")
            tempData[j][3] = ""
            tempData[j][4] = ""
            for k in keys(allValues[j][1])
                if k != "total"
                    if k in keys(allValues[j][2])
                        tempData[j][3] = string(tempData[j][3], replace(k, ":" => ":\n  "), "\n\n")
                        tempData[j][4] = string(tempData[j][4], 
                        round(allValues[j][1][k], digits=4), " kJ/kg\n", round(allValues[j][2][k], digits=4), " kW\n\n")
                    else
                        tempData[j][3] = string(tempData[j][3], replace(k, ":" => ":\n  "), "\n\n")
                        tempData[j][4] = string(tempData[j][4], 
                        round(allValues[j][1][k], digits=4), " kJ/kg\n\n\n")
            end end end
            tempData[j][3] = tempData[j][3][1:end-2]
            tempData[j][4] = tempData[j][4][1:end-2]
        end
        tempData = mapreduce(permutedims, vcat, tempData)

        io = IOBuffer()
        pretty_table(backend = Val(:html), tf = tf_html_simple,
        alignment=:l, linebreaks=true, io, tempData; header=["", "Total", "Component", "Value"], standalone = true)
        propsTb2 = String(take!(io))
        propsTb2 = replace(propsTb2, "left;" => "left; padding: 11px; font-size: 130%;")
        propsTb2 = replace(propsTb2, "th style = \"text-align: left" => "th style = \"text-align: center")
        propsTb2 = replace(propsTb2, "collapse;" => "collapse; color: black;")
        propsTb2 = string("<div style = \"display: inline-block; border: 1px solid #666666;\">", propsTb2, "</div>")
        
        #####################################################
        nc = ""
        if !isnothing(SystemCycles[i].thermoProperties.n)
            effTxt2 = ""
            effTxt = ""
            if SystemCycles[i].isRefrigerationCycle
                effTxt = "Coefficient of performance (COP) = "
            else
                effTxt2 = " %"
                effTxt = "Thermal efficiency (n) = "
            end
            nc = string("<h3 style='text-align: center; border: 2px solid #666666; padding: 15px; margin: 10px;'>",
            effTxt, round(SystemCycles[i].thermoProperties.n, digits=4), effTxt2, "</h3>")                    
        end

        #####################################################
        plotHTML = sprint(show, "text/html", TSGraph([i]))

        #####################################################

        push!(str, string("<div style='display: inline-block; padding: 15px; margin: 20px;
        border: 2px solid #666666;'>\n", TitleTxt,
        "<div style='display: flex; justify-content: space-around;'>", propsTb1, "</div>",
        "<div style='display: flex; justify-content: space-around;
        padding: 10px; margin: 10px;'>", plotHTML, "</div><div style=' border: 1px solid;'>",
        "<h3 style='text-align: center;margin: 8px;'>Cycle Properties:</h3>",
        "<div style='display: flex; justify-content: space-around;'>", propsTb2, "</div>", nc,
        "</div>\n</div></br>"))        
    end

    perCycle = ""
    for i in str
        perCycle = string(perCycle, i)
    end

    if length(SystemCycles) > 1
        allValues = Any[[System.qin, System.Qin], [System.qout, System.Qout],
        [System.win, System.Win], [System.wout, System.Wout]]
        propsValues = ["qin\nQ̇in", "qout\nQ̇out", "win\nẆin", "wout\nẆout"]
        tempData = Any[]
        for j in 1:4
            push!(tempData, Array{Any}(nothing, 4))
            tempData[j][1] = propsValues[j]
            tempData[j][2] = string(round(allValues[j][1]["total"], digits=4), " kJ/kg\n", round(allValues[j][2]["total"], digits=4), " kW")
            tempData[j][3] = ""
            tempData[j][4] = ""
            for k in keys(allValues[j][1])
                if k != "total"
                    if k in keys(allValues[j][2])
                        tempData[j][3] = string(tempData[j][3], replace(k, ":" => ":\n  "), "\n\n")
                        tempData[j][4] = string(tempData[j][4], 
                        round(allValues[j][1][k], digits=4), " kJ/kg\n", round(allValues[j][2][k], digits=4), " kW\n\n")
                    else
                        tempData[j][3] = string(tempData[j][3], replace(k, ":" => ":\n  "), "\n\n")
                        tempData[j][4] = string(tempData[j][4], 
                        round(allValues[j][1][k], digits=4), " kJ/kg\n\n\n")
            end end end
            tempData[j][3] = tempData[j][3][1:end-2]
            tempData[j][4] = tempData[j][4][1:end-2]
        end
        tempData = mapreduce(permutedims, vcat, tempData)
        
        io = IOBuffer()
        pretty_table(backend = Val(:html), tf = tf_html_simple,
        alignment=:l, linebreaks=true, io, tempData; header=["", "Total", "Component", "Value"], standalone = true)
        propsTb3 = String(take!(io))
        propsTb3 = replace(propsTb3, "left;" => "left; padding: 11px;  font-size: 130%;")
        propsTb3 = replace(propsTb3, "th style = \"text-align: left" => "th style = \"text-align: center")
        propsTb3 = replace(propsTb3, "collapse;" => "collapse; color: black;")
        propsTb3 = string("<div style = \"display: inline-block; border: 1px solid #666666;\">", propsTb3, "</div>")
        
        #####################################################
        nc = ""
        if !isnothing(System.n)
            effTxt = ""
            effTxt2 = ""
            if isRefrigerationSystem
                effTxt = "Coefficient of performance (COP) = "
            else
                effTxt = "Thermal efficiency (n) = "
                effTxt2 = " %"
            end
            nc = string("<h2 style='text-align: center; border: 3px solid; padding: 15px; margin: 10px;'>",
            effTxt, round(System.n, digits=4), effTxt2, "</h2>")   
        end

        plotHTML = sprint(show, "text/html", TSGraph(collect(1:length(SystemCycles))))

        perCycle = string(perCycle, 
                    "<div style=\"display: inline-block; padding: 15px; margin: 20px;",
                    "border: 2px solid;\"><h1 style=\"text-align: center;
                    margin: -8px;\">SYSTEM PROPERTIES</h1>",
                    "<div style='display: flex; justify-content: space-around;
                    padding: 10px; margin: 10px;'>", plotHTML, "</div>",
                    "<div style=' border: 1px solid;'>",
                    "<div style='display: flex; justify-content: space-around; margin: 20px;'>",
                    propsTb3, "</div>", nc, "</div>"
                    )
    end
    
    if length(findVariables) > 0
        componentsTxt = "<h2 style=\"text-align: center;
                    margin: -8px;\">Calculated Component Properties</h2>"

        for i in findVariables
            if length(i) == 2
                componentsTxt = string(componentsTxt, "<h3 style=\"text-align: left;
                padding: 10px;\">", i[2], " = ", round(i[1], digits=4), "%","</h3>")
            else
                componentsTxt = string(componentsTxt, "<h3 style=\"text-align: left;
                padding: 10px;\">", i[4], " = not found","</h3>")
            end
        end
        perCycle = string(perCycle,"<div style=\"display: inline-block; padding: 15px; margin: 20px auto;",
        "border: 1px solid;\">", componentsTxt, "</div>")
    end

    perCycle = string("<div style='display: inline-block; margin: 1px; text-align: center;
    border: 0.5px solid #666666;'>", perCycle, "</div>")

    display("text/html", perCycle)    
end