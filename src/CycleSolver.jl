module CycleSolver
    export FirstTest
    FirstTest(x) = x

    using Symbolics
    using CoolProp
    using PrettyTables
    using Plots
    set_reference_state("R134a","ASHRAE")
    AllVars = Any[]
    MyEquations = Any[]
    MyStates = Any[]
    AllStates = Any[]
    
    BaseEqualities = Any[]
    Eq2CalcAtEnd = Any[]
    AllStates = Any[]
    WhoisTheHeater = Any[]
    MassEq1 = Any[]
    MassParent = Any[]
    CyclesStts = Any[]
    MassCoef = Any[]
    cycleInfos = Any[0, -1]
    fluidDefault = "water"
    fluidEq = Any[]
    closedInteractions = Any[]
    cycleProps = Any[]
    CyclesCalcMass = Any[]
    itsRefrigeration = false
    storeCycleProp = Any[]
    cycleIndex = -1

    m_fraction = Any[]
    m_Cycle = Any[]
    stAux = Any[]

    find = :find
    findVariables = Any[]
    
    System = nothing
    Cycles = Any[]

    PropsEquations = Any[]
    Win = Any[]
    win = Any[]
    Wout = Any[]
    wout = Any[]
    Qin = Any[]
    qin = Any[]
    Qout = Any[]
    qout = Any[]
    Qflex = Any[]
    qflex = Any[]

    PropsInputEq = Any[]

    props = Dict(
        "air"=> [0.2870, 1.005, 0.718, 1.400],
        "argon"=> [0.2081, 0.5203, 0.3122, 1.667],
        "butane"=> [0.1433, 1.7164, 1.5734, 1.091],
        "co2"=> [0.1889, 0.846, 0.657, 1.289],
        "carbondioxide"=> [0.1889, 0.846, 0.657, 1.289],
        "carbonmonoxide"=> [0.2968, 1.040, 0.744, 1.400],
        "co"=> [0.2968, 1.040, 0.744, 1.400],
        "ethanol"=> [0.2765, 1.7662, 1.4897, 1.186],
        "c2h6o"=> [0.2765, 1.7662, 1.4897, 1.186],
        "ethylene"=> [0.2964, 1.5482, 1.2518, 1.237],
        "helium"=> [2.0769, 5.1926, 3.1156, 1.667],
        "he"=> [2.0769, 5.1926, 3.1156, 1.667],
        "hydrogen"=> [4.1240, 14.307, 10.183, 1.405],
        "h2"=> [4.1240, 14.307, 10.183, 1.405],
        "methane"=> [0.5182, 2.2537, 1.7354, 1.299],
        "ch4"=> [0.5182, 2.2537, 1.7354, 1.299],
        "neon"=> [0.4119, 1.0299, 0.6179, 1.667],
        "nitrogen"=> [0.2968, 1.039, 0.743, 1.400],
        "n2"=> [0.2968, 1.039, 0.743, 1.400],
        "octane"=> [0.0729, 1.7113, 1.6385, 1.044],
        "noctane"=> [0.0729, 1.7113, 1.6385, 1.044],
        "oxygen"=> [0.2598, 0.918, 0.658, 1.395],
        "o2"=> [0.2598, 0.918, 0.658, 1.395],
        "propane"=> [0.1885, 1.6794, 1.4909, 1.126],
        "c3h8"=> [0.1885, 1.6794, 1.4909, 1.126],
        "water"=> [0.4615, 1.8723, 1.4108, 1.327]
    )

    TableA17 = [
        [200, 199.97, 0.3363, 142.56, 1707.0, 1.29559],
        [210, 209.97, 0.3987, 149.69, 1512.0, 1.34444],
        [220, 219.97, 0.4690, 156.82, 1346.0, 1.39105],
        [230, 230.02, 0.5477, 164.00, 1205.0, 1.43557],
        [240, 240.02, 0.6355, 171.13, 1084.0, 1.47824],
        [250, 250.05, 0.7329, 178.28, 979.0, 1.51917],
        [260, 260.09, 0.8405, 185.45, 887.8, 1.55848],
        [270, 270.11, 0.9590, 192.60, 808.0, 1.59634],
        [280, 280.13, 1.0889, 199.75, 738.0, 1.63279],
        [285, 285.14, 1.1584, 203.33, 706.1, 1.65055],
        [290, 290.16, 1.2311, 206.91, 676.1, 1.66802],
        [295, 295.17, 1.3068, 210.49, 647.9, 1.68515],
        [298, 298.18, 1.3543, 212.64, 631.9, 1.69528],
        [300, 300.19, 1.3860, 214.07, 621.2, 1.70203],
        [305, 305.22, 1.4686, 217.67, 596.0, 1.71865],
        [310, 310.24, 1.5546, 221.25, 572.3, 1.73498],
        [315, 315.27, 1.6442, 224.85, 549.8, 1.75106],
        [320, 320.29, 1.7375, 228.42, 528.6, 1.76690],
        [325, 325.31, 1.8345, 232.02, 508.4, 1.78249],
        [330, 330.34, 1.9352, 235.61, 489.4, 1.79783],
        [340, 340.42, 2.149, 242.82, 454.1, 1.82790],
        [350, 350.49, 2.379, 250.02, 422.2, 1.85708],
        [360, 360.58, 2.626, 257.24, 393.4, 1.88543],
        [370, 370.67, 2.892, 264.46, 367.2, 1.91313],
        [380, 380.77, 3.176, 271.69, 343.4, 1.94001],
        [390, 390.88, 3.481, 278.93, 321.5, 1.96633],
        [400, 400.98, 3.806, 286.16, 301.6, 1.99194],
        [410, 411.12, 4.153, 293.43, 283.3, 2.01699],
        [420, 421.26, 4.522, 300.69, 266.6, 2.04142],
        [430, 431.43, 4.915, 307.99, 251.1, 2.06533],
        [440, 441.61, 5.332, 315.30, 236.8, 2.08870],
        [450, 451.80, 5.775, 322.62, 223.6, 2.11161],
        [460, 462.02, 6.245, 329.97, 211.4, 2.13407],
        [470, 472.24, 6.742, 337.32, 200.1, 2.15604],
        [480, 482.49, 7.268, 344.70, 189.5, 2.17760],
        [490, 492.74, 7.824, 352.08, 179.7, 2.19876],
        [500, 503.02, 8.411, 359.49, 170.6, 2.21952],
        [510, 513.32, 9.031, 366.92, 162.1, 2.23993],
        [520, 523.63, 9.684, 374.36, 154.1, 2.25997],
        [530, 533.98, 10.37, 381.84, 146.7, 2.27967],
        [540, 544.35, 11.10, 389.34, 139.7, 2.29906],
        [550, 555.74, 11.86, 396.86, 133.1, 2.31809],
        [560, 565.17, 12.66, 404.42, 127.0, 2.33685],
        [570, 575.59, 13.50, 411.97, 121.2, 2.35531],
        [580, 586.04, 14.38, 419.55, 115.7, 2.37348],
        [590, 596.52, 15.31, 427.15, 110.6, 2.39140],
        [600, 607.02, 16.28, 434.78, 105.8, 2.40902],
        [610, 617.53, 17.30, 442.42, 101.2, 2.42644],
        [620, 628.07, 18.36, 450.09, 96.92, 2.44356],
        [630, 638.63, 19.84, 457.78, 92.84, 2.46048],
        [640, 649.22, 20.64, 465.50, 88.99, 2.47716],
        [650, 659.84, 21.86, 473.25, 85.34, 2.49364],
        [660, 670.47, 23.13, 481.01, 81.89, 2.50985],
        [670, 681.14, 24.46, 488.81, 78.61, 2.52589],
        [680, 691.82, 25.85, 496.62, 75.50, 2.54175],
        [690, 702.52, 27.29, 504.45, 72.56, 2.55731],
        [700, 713.27, 28.80, 512.33, 69.76, 2.57277],
        [710, 724.04, 30.38, 520.23, 67.07, 2.58810],
        [720, 734.82, 32.02, 528.14, 64.53, 2.60319],
        [730, 745.62, 33.72, 536.07, 62.13, 2.61803],
        [740, 756.44, 35.50, 544.02, 59.82, 2.63280],
        [750, 767.29, 37.35, 551.99, 57.63, 2.64737],
        [760, 778.18, 39.27, 560.01, 55.54, 2.66176],
        [780, 800.03, 43.35, 576.12, 51.64, 2.69013],
        [800, 821.95, 47.75, 592.30, 48.08, 2.71787],
        [820, 843.98, 52.59, 608.59, 44.84, 2.74504],
        [840, 866.08, 57.60, 624.95, 41.85, 2.77170],
        [860, 888.27, 63.09, 641.40, 39.12, 2.79783],
        [880, 910.56, 68.98, 657.95, 36.61, 2.82344],
        [900, 932.93, 75.29, 674.58, 34.31, 2.84856],
        [920, 955.38, 82.05, 691.28, 32.18, 2.87324],
        [940, 977.92, 89.28, 708.08, 30.22, 2.89748],
        [960, 1000.55, 97.00, 725.02, 28.40, 2.92128],
        [980, 1023.25, 105.2, 741.98, 26.73, 2.94468],
        [1000, 1046.04, 114.0, 758.94, 25.17, 2.96770],
        [1020, 1068.89, 123.4, 776.10, 23.72, 2.99034],
        [1040, 1091.85, 133.3, 793.36, 23.29, 3.01260],
        [1060, 1114.86, 143.9, 810.62, 21.14, 3.03449],
        [1080, 1137.89, 155.2, 827.88, 19.98, 3.05608],
        [1100, 1161.07, 167.1, 845.33, 18.896, 3.07732],
        [1120, 1184.28, 179.7, 862.79, 17.886, 3.09825],
        [1140, 1207.57, 193.1, 880.35, 16.946, 3.11883],
        [1160, 1230.92, 207.2, 897.91, 16.064, 3.13916],
        [1180, 1254.34, 222.2, 915.57, 15.241, 3.15916],
        [1200, 1277.79, 238.0, 933.33, 14.470, 3.17888],
        [1220, 1301.31, 254.7, 951.09, 13.747, 3.19834],
        [1240, 1324.93, 272.3, 968.95, 13.069, 3.21751],
        [1260, 1348.55, 290.8, 986.90, 12.435, 3.23638],
        [1280, 1372.24, 310.4, 1004.76, 11.835, 3.25510],
        [1300, 1395.97, 330.9, 1022.82, 11.275, 3.27345],
        [1320, 1419.76, 352.5, 1040.88, 10.747, 3.29160],
        [1340, 1443.60, 375.3, 1058.94, 10.247, 3.30959],
        [1360, 1467.49, 399.1, 1077.10, 9.780, 3.32724],
        [1380, 1491.44, 424.2, 1095.26, 9.337, 3.34474],
        [1400, 1515.42, 450.5, 1113.52, 8.919, 3.36200],
        [1420, 1539.44, 478.0, 1131.77, 8.526, 3.37901],
        [1440, 1563.51, 506.9, 1150.13, 8.153, 3.39586],
        [1460, 1587.63, 537.1, 1168.49, 7.801, 3.41247],
        [1480, 1611.79, 568.8, 1186.95, 7.468, 3.42892],
        [1500, 1635.97, 601.9, 1205.41, 7.152, 3.44516],
        [1520, 1660.23, 636.5, 1223.87, 6.854, 3.46120],
        [1540, 1684.51, 672.8, 1242.43, 6.569, 3.47712],
        [1560, 1708.82, 710.5, 1260.99, 6.301, 3.49276],
        [1580, 1733.17, 750.0, 1279.65, 6.046, 3.50829],
        [1600, 1757.57, 791.2, 1298.30, 5.804, 3.52364],
        [1620, 1782.00, 834.1, 1316.96, 5.574, 3.53879],
        [1640, 1806.46, 878.9, 1335.72, 5.355, 3.55381],
        [1660, 1830.96, 925.6, 1354.48, 5.147, 3.56867],
        [1680, 1855.50, 974.2, 1373.24, 4.949, 3.58335],
        [1700, 1880.1, 1025, 1392.7, 4.761, 3.5979],
        [1750, 1941.6, 1161, 1439.8, 4.328, 3.6336],
        [1800, 2003.3, 1310, 1487.2, 3.994, 3.6684],
        [1850, 2065.3, 1475, 1534.9, 3.601, 3.7023],
        [1900, 2127.4, 1655, 1582.6, 3.295, 3.7354],
        [1950, 2189.7, 1852, 1630.6, 3.022, 3.7677],
        [2000, 2252.1, 2068, 1678.7, 2.776, 3.7994],
        [2050, 2314.6, 2303, 1726.8, 2.555, 3.8303],
        [2100, 2377.7, 2559, 1775.3, 2.356, 3.8605],
        [2150, 2440.3, 2837, 1823.8, 2.175, 3.8901],
        [2200, 2503.2, 3138, 1872.4, 2.012, 3.9191],
        [2250, 2566.4, 3464, 1921.3, 1.864, 3.9474]
    ]

    mutable struct CycleStruct
        states
        properties
        CycleStruct() = new()
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
        # println("\n \n \n \n \n \n \n \n \n \n \n \n \n \n \n")
        # println("\n \n \n \n \n \n \n \n \n \n \n \n \n \n \n")
        ClearVars()

        global AllVars = Any[]
        for i in eqs.args[2:2:end]
            newEq(i)
        end
        
        SetupMass()

        copyPropsInputEq = copy(PropsInputEq)
        global PropsInputEq = Any[]
        for i in copyPropsInputEq
            typeProp = [string(i[1])[2:2], string(i[1])[3:end]]
            
            tempValue = [:(0), Any[]]
            if typeProp[2] == "net"        
                resp = Any[:(0), :(0)]        
                for j in PropsEquations
                    if i[2] > 0 && !(j[3][2] in CyclesStts[i[2]])
                        continue
                    end
                    typePropEq =[string(j[1])[1:1], string(j[1])[2:end]]
                    if typePropEq[1] == typeProp[1]
                        if typePropEq[2] == "out"
                            resp[1] = Expr(:call, :(+), resp[1], j[2])
                        elseif typePropEq[2] == "in"
                            resp[2] = Expr(:call, :(+), resp[2], j[2])
                        end
                    end
                end            
                tempValue[1] = Expr(:call, :(-), resp[1], resp[2])
            else
                for j in PropsEquations
                    if i[2] > 0 && !(j[3][2] in CyclesStts[i[2]])
                        continue
                    end
                    typePropEq =[string(j[1])[1:1], string(j[1])[2:end]]
                    if typePropEq[1] == typeProp[1] && typePropEq[2] == typeProp[2]
                        tempValue[1] = Expr(:call, :(+), tempValue[1], j[2])
                    end
                end    
                for j in qflex
                    states = Any[Any[], Any[]]
                    for k in 1:length(j[1])
                        if j[1][k] in CyclesStts[i[2]]
                            push!(states[1], j[1][k])
                            push!(states[2], j[2][k])
                    end end
                    if length(states[1]) != 0
                        push!(tempValue[2], states)
                    end
                end
            end            

            if length(tempValue[2]) == 0
                newEq(:($(i[3]) = $(tempValue[1])))
                for j in MyEquations[end].vars
                    if j isa Expr && j.head == :. && j.args[end] == QuoteNode(:m)
                        for k in BaseEqualities
                            if k.vars[1] == j
                                MyEquations[end].Eq = substitute(MyEquations[end].Eq, Dict([eval(j) => k.Eq.rhs])) 
                                break
                        end end
                end end
                MyEquations[end].Eq = SimplifyEq(MyEquations[end].Eq)
                MyEquations[end].vars = GetVars(Meta.parse(string(MyEquations[end].Eq)))
            else
                ########################                
                push!(tempValue, i[3])
                push!(PropsInputEq, tempValue)
            end           

        end

        # println(CyclesCalcMass)
        # return

        
        # println()
        # for i in MyEquations
        #     println(i.Eq)
        # end
        # return
        # println()
        # for i in BaseEqualities
        #     println(i.Eq)
        # end
        # println()
        # return
        
        newValue = true
        while newValue
            newValue = FindEquationsResults()

            newValue |= ManagePropsInput()

            for i in copy(WhoisTheHeater)
                bigger = -1
                index = -1
                for j in 1:length(i[1])
                    testValue = eval(:($(i[1][j]).h))
                    if !(testValue isa Num)
                        if testValue > bigger
                            bigger = testValue
                            index = j
                        end
                    else
                        break
                end end
                if index > -1
                    eval(Expr(:(=), :($(i[2][index]).Q), 0))
                    for j in i[2]
                        eval(Expr(:(=), :($(j).blocked), false))
                    end
                    deleteat!(WhoisTheHeater, findall(x->x==i, WhoisTheHeater))
                    newValue = true
            end end

            newValue |= FindStates()
            
            if newValue 
                deletList = MathEq[]
                for i in 1:length(MyEquations)
                    MyEquations[i].Eq = UpdateEq(MyEquations[i].Eq)
                    MyEquations[i].vars = GetVars(Meta.parse(string(MyEquations[i].Eq)))
                    if length(MyEquations[i].vars) == 0
                        push!(deletList, MyEquations[i])
                    end
                end
                for i in deletList
                    deleteat!(MyEquations, findall(x->x==i, MyEquations))
                end
            end

        end
        

        Conclusion()

    end

    function Conclusion()       
        
        for i in BaseEqualities
            if length(i.vars) > 0
                massTemp = Meta.parse(string(i.Eq.rhs))
                massTemp = ExprSubs(massTemp, :m_fractionVars, :m_fraction)
                massTemp = ExprSubs(massTemp, :m_CycleVars, :m_Cycle)
                eval(Expr(:(=), i.vars[1], eval(massTemp)))
        end end
        for j in 1:length(CyclesStts)
            if CyclesCalcMass[j]
                systemMass = 0
                for k in CyclesStts[j]   
                    if eval(Expr(:., k, :(:m))) > systemMass                        
                        systemMass = eval(Expr(:., k, :(:m)))
                end end
                for k in CyclesStts[j]
                    eval(Expr(:(=), Expr(:., k, :(:mFraction)), eval(Expr(:., k, :(:m))) / systemMass))
                end
            else
                for k in CyclesStts[j]
                    eval(Expr(:(=), Expr(:., k, :(:mFraction)), eval(Expr(:., k, :(:m)))))
                    eval(Expr(:(=), Expr(:., k, :(:m)), nothing))
        end end end
        removeList = Any[]
        for i in 1:length(PropsEquations)
            try                
                PropsEquations[i][2] = eval(PropsEquations[i][2])
                component = PropsEquations[i][3][1]
                component = replace(component, "(" => "")                
                component = replace(component, ")" => "")
                component = replace(component, "Any" => "")
                component = replace(component, "[:" => "[")
                component = replace(component, ", :" => ", ")
                PropsEquations[i][3][1] = component
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
                inTemp = [[SttCycleIndex(i[1][1]), :($(i[1][1]).h)]]
                outTemp = [:($(i[2][1]).h)]
                for j in 2:length(i[1])
                    newQ = true
                    myIndex = SttCycleIndex(i[1][j])
                    for k in 1:length(inTemp)
                        if inTemp[k][1] == myIndex
                            inTemp[k][2] = Expr(:call, :+, inTemp[k][2], :($(i[1][j]).h))
                            outTemp[k] = Expr(:call, :+, outTemp[k], :($(i[2][j]).h))
                            newQ = false
                            break
                    end end
                    if newQ
                        push!(inTemp, [myIndex, :($(i[1][j]).h)])
                        push!(outTemp, :($(i[2][j]).h))
                end end

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
                    component = PropsEquations[end][3][1]
                    component = replace(component, "(" => "")                
                    component = replace(component, ")" => "")
                    component = replace(component, "Any" => "")
                    component = replace(component, "[:" => "[")
                    component = replace(component, ", :" => ", ")
                    PropsEquations[end][3][1] = component
                end
            else
                inTemp = [[SttCycleIndex(i[1][1]), :($(i[1][1]).h * $(i[1][1]).m)]]
                outTemp = [:($(i[2][1]).h * $(i[2][1]).m)]
                for j in 2:length(i[1])
                    newQ = true
                    myIndex = SttCycleIndex(i[1][j])
                    for k in 1:length(inTemp)
                        if inTemp[k][1] == myIndex
                            inTemp[k][2] = Expr(:call, :+, inTemp[k][2], :($(i[1][j]).h * $(i[1][j]).m))
                            outTemp[k] = Expr(:call, :+, outTemp[k], :($(i[2][j]).h * $(i[2][j]).m))
                            newQ = false
                            break
                    end end
                    if newQ
                        push!(inTemp, [myIndex, :($(i[1][j]).h * $(i[1][j]).m)])
                        push!(outTemp, :($(i[2][j]).h * $(i[2][j]).m))
                end end
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
                    component = PropsEquations[end][3][1]
                    component = replace(component, ":(" => "")
                    component = replace(component, ")" => "")
                    component = replace(component, "Any" => "")
                    component = replace(component, "[:" => "[")
                    component = replace(component, ", :" => ", ")
                    PropsEquations[end][3][1] = component
                end

                inTemp = [[SttCycleIndex(i[1][1]), :($(i[1][1]).h)]]
                outTemp = [:($(i[2][1]).h)]
                for j in 2:length(i[1])
                    newQ = true
                    myIndex = SttCycleIndex(i[1][j])
                    for k in 1:length(inTemp)
                        if inTemp[k][1] == myIndex
                            inTemp[k][2] = Expr(:call, :+, inTemp[k][2], :($(i[1][j]).h))
                            outTemp[k] = Expr(:call, :+, outTemp[k], :($(i[2][j]).h))
                            newQ = false
                            break
                    end end
                    if newQ
                        push!(inTemp, [myIndex, :($(i[1][j]).h)])
                        push!(outTemp, :($(i[2][j]).h))
                end end

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
                    component = PropsEquations[end][3][1]
                    component = replace(component, "(" => "")                
                    component = replace(component, ")" => "")
                    component = replace(component, "Any" => "")
                    component = replace(component, "[:" => "[")
                    component = replace(component, ", :" => ", ")                    
                    PropsEquations[end][3][1] = component
                end
            end
        end               

        global Cycles = Any[] 
        for i in 1:length(CyclesStts)            
            push!(Cycles, CycleStruct())
            global Cycles[end].properties = PropertiesStruct()
            for j in PropsEquations
                if j[3][2] == i
                    push!(eval(:(Cycles[end].properties.$(j[1]))), [j[2], j[3][1]])
        end end end
        
        for i in 1:length(Cycles)  
            newDict = Dict()
            total = 0
            for j in Cycles[i].properties.Qin
                newDict[j[2]] = j[1]
                total += j[1]
            end
            newDict["total"] = total
            Cycles[i].properties.Qin = newDict
            ###########################
            newDict = Dict()
            total = 0
            for j in Cycles[i].properties.qin
                newDict[j[2]] = j[1]
                total += j[1]
            end
            newDict["total"] = total
            Cycles[i].properties.qin = newDict
            ###########################
            newDict = Dict()
            total = 0
            for j in Cycles[i].properties.Qout
                newDict[j[2]] = j[1]
                total += j[1]
            end
            newDict["total"] = total
            Cycles[i].properties.Qout = newDict
            ###########################
            newDict = Dict()
            total = 0
            for j in Cycles[i].properties.qout
                newDict[j[2]] = j[1]
                total += j[1]
            end
            newDict["total"] = total
            Cycles[i].properties.qout = newDict
            ###########################
            newDict = Dict()
            total = 0
            for j in Cycles[i].properties.Win
                newDict[j[2]] = j[1]
                total += j[1]
            end
            newDict["total"] = total
            Cycles[i].properties.Win = newDict
            ###########################
            newDict = Dict()
            total = 0
            for j in Cycles[i].properties.win
                newDict[j[2]] = j[1]
                total += j[1]
            end
            newDict["total"] = total
            Cycles[i].properties.win = newDict
            ###########################
            newDict = Dict()
            total = 0
            for j in Cycles[i].properties.Wout
                newDict[j[2]] = j[1]
                total += j[1]
            end
            newDict["total"] = total
            Cycles[i].properties.Wout = newDict
            ###########################
            newDict = Dict()
            total = 0
            for j in Cycles[i].properties.wout
                newDict[j[2]] = j[1]
                total += j[1]
            end
            newDict["total"] = total
            Cycles[i].properties.wout = newDict
            ###########################
            Cycles[i].states = Stt[]
            for j in CyclesStts[i]
                push!(Cycles[i].states, eval(j)) 
            end       

            ###########################
            if itsRefrigeration
                if Cycles[i].properties.win["total"] != 0 && Cycles[i].properties.qin["total"] != 0
                    Cycles[i].properties.n = Cycles[i].properties.qin["total"] / Cycles[i].properties.win["total"]
                else
                    Cycles[i].properties.n = nothing
                end
            else
                if Cycles[i].states[1].cycleInfos[1] == 0
                    if Cycles[i].properties.qin["total"] != 0 && Cycles[i].properties.qout["total"] != 0
                        Cycles[i].properties.n = 100 * (1 - (Cycles[i].properties.qout["total"] / Cycles[i].properties.qin["total"]))
                    else
                        Cycles[i].properties.n = nothing
                    end
                else
                    if Cycles[i].properties.wout["total"] != 0 && Cycles[i].properties.win["total"] != 0 &&
                    Cycles[i].properties.qin["total"] != 0
                        Cycles[i].properties.n = 100 * (Cycles[i].properties.wout["total"]  - Cycles[i].properties.win["total"]) /
                         Cycles[i].properties.qin["total"]
                    else
                        Cycles[i].properties.n = nothing                        
            end end end
        end  

        global System = PropertiesStruct()

        newDict = Dict()
        total = 0
        for i in 1:length(Cycles)            
            for j in Cycles[i].properties.Qin
                if j.first != "total" && !occursin("heater_exchanger", j.first) && !occursin("evaporator_condenser", j.first)     
                    newDict[j.first] = j.second
                    total += j.second
                end
            end
        end
        newDict["total"] = total
        System.Qin = newDict
        #######################################

        newDict = Dict()
        total = 0
        for i in 1:length(Cycles)            
            for j in Cycles[i].properties.qin
                if j.first != "total" && !occursin("heater_exchanger", j.first) && !occursin("evaporator_condenser", j.first)     
                    newDict[j.first] = j.second
                    total += j.second
                end
            end
        end
        newDict["total"] = total
        System.qin = newDict
        #######################################

        newDict = Dict()
        total = 0
        for i in 1:length(Cycles)            
            for j in Cycles[i].properties.Qout
                if j.first != "total" && !occursin("heater_exchanger", j.first) && !occursin("evaporator_condenser", j.first)     
                    newDict[j.first] = j.second
                    total += j.second
                end
            end
        end
        newDict["total"] = total
        System.Qout = newDict
        #######################################

        newDict = Dict()
        total = 0
        for i in 1:length(Cycles)            
            for j in Cycles[i].properties.qout
                if j.first != "total" && !occursin("heater_exchanger", j.first) && !occursin("evaporator_condenser", j.first)     
                    newDict[j.first] = j.second
                    total += j.second
                end
            end
        end
        newDict["total"] = total
        System.qout = newDict
        #######################################

        newDict = Dict()
        total = 0
        for i in 1:length(Cycles)            
            for j in Cycles[i].properties.Win
                if j.first != "total" && !occursin("heater_exchanger", j.first) && !occursin("evaporator_condenser", j.first)     
                    newDict[j.first] = j.second
                    total += j.second
                end
            end
        end
        newDict["total"] = total
        System.Win = newDict
        #######################################

        newDict = Dict()
        total = 0
        for i in 1:length(Cycles)            
            for j in Cycles[i].properties.win
                if j.first != "total" && !occursin("heater_exchanger", j.first) && !occursin("evaporator_condenser", j.first)     
                    newDict[j.first] = j.second
                    total += j.second
                end
            end
        end
        newDict["total"] = total
        System.win = newDict
        #######################################

        newDict = Dict()
        total = 0
        for i in 1:length(Cycles)            
            for j in Cycles[i].properties.Wout
                if j.first != "total" && !occursin("heater_exchanger", j.first) && !occursin("evaporator_condenser", j.first)     
                    newDict[j.first] = j.second
                    total += j.second
                end
            end
        end
        newDict["total"] = total
        System.Wout = newDict
        #######################################

        newDict = Dict()
        total = 0
        for i in 1:length(Cycles)            
            for j in Cycles[i].properties.wout
                if j.first != "total" && !occursin("heater_exchanger", j.first) && !occursin("evaporator_condenser", j.first)     
                    newDict[j.first] = j.second
                    total += j.second
                end
            end
        end
        newDict["total"] = total
        System.wout = newDict
        #######################################

        if itsRefrigeration
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

        #######################################
        
        for i in 1:length(findVariables)            


            if findVariables[i][5] == 1 # efficiency
                findVariables[i][4] = replace(findVariables[i][4], "(" => "")                
                findVariables[i][4] = replace(findVariables[i][4], ")" => "")
                findVariables[i][4] = replace(findVariables[i][4], "Any" => "")
                findVariables[i][4] = replace(findVariables[i][4], "[:" => "[")
                findVariables[i][4] = replace(findVariables[i][4], ", :" => ", ")
                if findVariables[i][2].cycleInfos[1] == 0 #Steam
                    SttTemp_S = PropsSI("H", "P", findVariables[i][3].p * 1000, "S",
                    findVariables[i][2].s * 1000, findVariables[i][2].fluid) / 1000
                    findVariables[i][1] =  ExprSubs(findVariables[i][1], :SttTemp_S, SttTemp_S)
                    findVariables[i] = Any[100 * eval(findVariables[i][1]), findVariables[i][4]]

                elseif findVariables[i][2].cycleInfos[1] == 1
                    findVariables[i] = Any[100 * eval(findVariables[i][1]), findVariables[i][4]]                   
                
                else
                    if findVariables[i][1] == 1
                        findVariables[i] = Any[100 * (findVariables[i][3].h - findVariables[i][2].h) /
                        (getValuesLA17(findVariables[i][3].p / findVariables[i][2].p *
                                            getValuesLA17(findVariables[i][2].h, 2)[3], 3)[2]
                            - findVariables[i][2].h), findVariables[i][4]]
                    else
                        findVariables[i] = Any[100 *
                        (getValuesLA17(findVariables[i][3].p / findVariables[i][2].p *
                                            getValuesLA17(findVariables[i][2].h, 2)[3], 3)[2]
                            - findVariables[i][2].h) /
                            (findVariables[i][3].h - findVariables[i][2].h), findVariables[i][4]]
                    end                   

                end
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

    function SttCycleIndex(sttName)
        for j in 1:length(CyclesStts)
            if sttName in CyclesStts[j]
                return j
                break
        end end
    end

    function ClearVars()
        set_reference_state("R134a","ASHRAE")
        for i in AllVars
            if i isa Expr
                if !(i.head == :.)
                    eval(Expr(:(=), i.args[1], nothing))
                end
            else
                eval(Expr(:(=), i, nothing))
        end end
        for i in Cycles
            for j in i.states
                eval(Expr(:(=), j.name, nothing))
        end end

        global AllVars = Any[]
        global MyEquations = Any[]
        global MyStates = Any[]
        global AllStates = Any[]        
        global BaseEqualities = Any[]
        global Eq2CalcAtEnd = Any[]
        global WhoisTheHeater = Any[]
        global MassEq1 = Any[]
        global MassParent = Any[]
        global CyclesStts = Any[]
        global MassCoef = Any[]
        global cycleInfos = Any[0, -1]
        global fluidDefault = "water"
        global fluidEq = Any[]
        global closedInteractions = Any[]
        global cycleProps = Any[]
        global CyclesCalcMass = Any[]
        global itsRefrigeration = false
        global storeCycleProp = Any[]
        global cycleIndex = -1    
        global m_fraction = Any[]
        global m_Cycle = Any[]
        global stAux = Any[]    
        global System = PropertiesStruct()    
        global Cycles = Any[]
        global PropsEquations = Any[]
        global Win = Any[]
        global win = Any[]
        global Wout = Any[]
        global wout = Any[]
        global Qin = Any[]
        global qin = Any[]
        global Qout = Any[]
        global qout = Any[]
        global Qflex = Any[]
        global qflex = Any[]
        global findVariables = Any[]
        global PropsInputEq = Any[]
    end

    function ManagePropsInput()        
        newValue = false
        deletList = Any[]
        for i in 1:length(PropsInputEq)
            for j in copy(PropsInputEq[i][2])
                HsttIn = 0
                HsttOut = 0
                canCalc = true;
                for k in 1:length(j[1])
                    if !(eval(:($(j[1][k]).h)) isa Num) && !(eval(:($(j[2][k]).h)) isa Num)
                        HsttIn += eval(:($(j[1][k]).h))
                        HsttOut += eval(:($(j[2][k]).h))
                    else
                        canCalc = false
                        break
                    end
                end
                if canCalc
                    sttIn = :(0)
                    sttOut = :(0)
                    for k in 1:length(j[1])
                        sttIn = Expr(:call, :(+), sttIn, :($(eval(:($(j[1][k]).h))) * $(j[1][k]).m))
                        sttOut = Expr(:call, :(+), sttOut, :($(eval(:($(j[2][k]).h))) * $(j[2][k]).m))
                    end
                    if HsttOut > HsttIn
                        PropsInputEq[i][1] = Expr(:call, :(+), PropsInputEq[i][1],
                        Expr(:call, :(-), sttOut, sttIn))
                    else
                        PropsInputEq[i][1] = Expr(:call, :(+), PropsInputEq[i][1],
                        Expr(:call, :(-), sttIn, sttOut))
                    end

                    deleteat!(PropsInputEq[i][2], findall(x->x==j, PropsInputEq[i][2]))                    
                end
            end
            # println()
            # println(">> ", PropsInputEq)
            if length(PropsInputEq[i][2]) == 0
                newEq(:($(PropsInputEq[i][3]) = $(PropsInputEq[i][1])))  
                for j in MyEquations[end].vars
                    if j isa Expr && j.head == :. && j.args[end] == QuoteNode(:m)
                        for k in BaseEqualities
                            if k.vars[1] == j
                                MyEquations[end].Eq = substitute(MyEquations[end].Eq, Dict([eval(j) => k.Eq.rhs])) 
                                break
                        end end
                end end
                MyEquations[end].Eq = SimplifyEq(MyEquations[end].Eq)
                MyEquations[end].vars = GetVars(Meta.parse(string(MyEquations[end].Eq)))
                newValue = true
                push!(deletList, PropsInputEq[i])
            end            
        end
        for i in deletList
            deleteat!(PropsInputEq, findall(x->x==i, PropsInputEq))
        end
        
        return newValue
    end

    function FindEquationsResults()
        findNewValue = true
        countTEMP = 0        

        while findNewValue && countTEMP < 10
            countTEMP += 1
            findNewValue = false

            eqs3 = Any[]
            vars3 = Any[]
            for i in 1:length(MyEquations)          
                if length(MyEquations[i].vars) == 1
                    push!(vars3, MyEquations[i].vars[1])
                    push!(eqs3, MyEquations[i])
                end
            end
            if length(vars3) > 0               
                try                
                    newValues = Symbolics.solve_for([i.Eq for i in eqs3], [eval(i) for i in vars3])
                    for i in 1:length(vars3)                        
                        eval(Expr(:(=), vars3[i], newValues[i]))
                    end                            
                    for i in eqs3
                        deleteat!(MyEquations, findall(x->x==i, MyEquations))
                    end                                              
                catch
                    for i in 1:length(eqs3)
                        try
                            newValues = Symbolics.solve_for([eqs3[i].Eq], [eval(vars3[i])])
                            eval(Expr(:(=), vars3[i], newValues[1]))
                            deleteat!(MyEquations, findall(x->x==eqs3[i], MyEquations))
                        catch
                        end
                    end
                end 
                
                findNewValue = true
                    deletList = MathEq[]
                    for i in 1:length(MyEquations)
                        MyEquations[i].Eq = UpdateEq(MyEquations[i].Eq)
                        MyEquations[i].vars = GetVars(Meta.parse(string(MyEquations[i].Eq)))
                        if length(MyEquations[i].vars) == 0
                            push!(deletList, MyEquations[i])
                        end
                    end
                    for i in deletList
                        deleteat!(MyEquations, findall(x->x==i, MyEquations))
                    end      
            end            
        end
        findNewValue = false
        local copyEqs = copy(MyEquations)
        countTEMP = 0
        while size(copyEqs)[1] > 0 && countTEMP < 10     
            countTEMP += 1
            vars2 = copy(copyEqs[1].vars)
            for i in 2:size(copyEqs)[1]
                for j in copyEqs[i].vars
                    if !(j in vars2)
                        push!(vars2, j)
                end end
            end
            if size(copyEqs)[1] == size(vars2)[1]
                ###################################
                try
                    newValues = Symbolics.solve_for([i.Eq for i in copyEqs], [eval(i) for i in vars2])
                    for i in 1:length(vars2)
                        eval(Expr(:(=), vars2[i], newValues[i]))
                    end
                    global MyEquations = Any[]
                    findNewValue = true
                    break
                catch
                    listDivision = Any[]
                    for i in copyEqs
                        intersected = false
                        for j in 1:length(listDivision)
                            if length(intersect(i.vars, listDivision[j])) > 0
                                listDivision[j] = union(listDivision[j], i.vars)
                                intersected = true
                        end end
                        if !intersected
                            push!(listDivision, i.vars)
                        end
                    end
                    listDivisionCopy = copy(listDivision)
                    listDivision = Any[]
                    ignoreIndexs = Any[]
                    EqDivision = Any[]
                    for i in 1:(length(listDivisionCopy))
                        if i in ignoreIndexs
                            continue
                        end
                        push!(listDivision, listDivisionCopy[i])
                        for j in (i+1):length(listDivisionCopy)
                            if length(intersect(listDivision[end], listDivisionCopy[j])) > 0
                                listDivision[end] = union(listDivision[end], listDivisionCopy[j])
                                push!(ignoreIndexs, j)
                        end end
                        push!(EqDivision, Any[])
                        for j in copyEqs
                            if length(intersect(j.vars, listDivision[end])) > 0
                                push!(EqDivision[end], j)        
                    end end end
                    for i in 1:length(EqDivision)
                        try
                            newValues = Symbolics.solve_for([j.Eq for j in EqDivision], [eval(j) for j in listDivision[i]])
                            for j in 1:length(listDivision[i])
                                eval(Expr(:(=), listDivision[i][j], newValues[j]))
                            end
                            for i in EqDivision
                                deleteat!(MyEquations, findall(x->x==i, MyEquations))
                            end
                            findNewValue = true
                        catch
                            continue
                        end
                    end
                end                
            else
                for i in size(vars2)[1]-1:-1:1
                    breakMain = false;
                    for k in 1:size(copyEqs)[1]
                        eqs3 = Any[]
                        vars3 = Any[]
                        for j in k:size(copyEqs)[1]
                            vars4 = Any[]
                            for k in copyEqs[j].vars
                                if !(k in vars3)
                                    push!(vars4, k)
                                end             
                            end
                            if size(vars4)[1] + size(vars3)[1] <= i
                                push!(vars3, vars4...)
                                push!(eqs3, copyEqs[j])
                            end
                        end
                        if size(eqs3)[1] == i
                            for i in eqs3
                                deleteat!(copyEqs, findall(x->x==i, copyEqs))
                            end
                            ###################################
                            try
                                newValues = Symbolics.solve_for([i.Eq for i in eqs3], [eval(i) for i in vars3])
                                for i in 1:length(vars3)
                                    eval(Expr(:(=), vars3[i], newValues[i]))
                                end                            
                                for i in eqs3
                                    deleteat!(MyEquations, findall(x->x==i, MyEquations))
                                end
                                findNewValue = true
                            catch
                                listDivision = Any[]
                                for i in eqs3
                                    intersected = false
                                    for j in 1:length(listDivision)
                                        if length(intersect(i.vars, listDivision[j])) > 0
                                            listDivision[j] = union(listDivision[j], i.vars)
                                            intersected = true
                                    end end
                                    if !intersected
                                        push!(listDivision, i.vars)
                                    end
                                end
                                listDivisionCopy = copy(listDivision)
                                listDivision = Any[]
                                ignoreIndexs = Any[]
                                EqDivision = Any[]
                                for i in 1:(length(listDivisionCopy))
                                    if i in ignoreIndexs
                                        continue
                                    end
                                    push!(listDivision, listDivisionCopy[i])
                                    for j in (i+1):length(listDivisionCopy)
                                        if length(intersect(listDivision[end], listDivisionCopy[j])) > 0
                                            listDivision[end] = union(listDivision[end], listDivisionCopy[j])
                                            push!(ignoreIndexs, j)
                                    end end
                                    push!(EqDivision, Any[])
                                    for j in eqs3
                                        if length(intersect(j.vars, listDivision[end])) > 0
                                            push!(EqDivision[end], j)        
                                end end end
                                for i in 1:length(EqDivision)
                                    try
                                        newValues = Symbolics.solve_for([j.Eq for j in EqDivision], [eval(j) for j in listDivision[i]])
                                        for j in 1:length(listDivision[i])
                                            eval(Expr(:(=), listDivision[i][j], newValues[j]))
                                        end
                                        for i in EqDivision
                                            deleteat!(MyEquations, findall(x->x==i, MyEquations))
                                        end
                                        findNewValue = true
                                    catch
                                        continue
                                    end
                                end
                            end    
                            @goto breakLoops1
                        end
                    end
                end
                @label breakLoops1
            end
        end

        if findNewValue
            deletList = MathEq[]
            for i in 1:length(MyEquations)
                MyEquations[i].Eq = UpdateEq(MyEquations[i].Eq)
                MyEquations[i].vars = GetVars(Meta.parse(string(MyEquations[i].Eq)))
                if length(MyEquations[i].vars) == 0
                    push!(deletList, MyEquations[i])
                end
            end
            for i in deletList
                deleteat!(MyEquations, findall(x->x==i, MyEquations))
            end
        end
        
        return findNewValue
    end

    function getValuesLA17(var, typeVar)
        min = 1
        max = length(TableA17)
        while max - min > 1
          tryValue = round(Int, (max + min) / 2)
          if TableA17[tryValue][typeVar] < var
            min = tryValue
          else
            max = tryValue
        end end
        a = (var - TableA17[min][typeVar]) / (TableA17[max][typeVar] - TableA17[min][typeVar])
        ret = Any[]
        for j in 1:6
            push!(ret, TableA17[min][j] + a * (TableA17[max][j] - TableA17[min][j]))
        end
        return ret        
    end

    function GetGasEntropy(T, p, gas)
        R = props[lowercase(gas)][1]
        specific_heat = props[lowercase(gas)][2]
        return specific_heat * log(T) - R * log(p / 101.325)        
    end

    function FindStates()
        newValue = false
        DoAgain = false  
        for stt in copy(MyStates)
            if !isnothing(stt.cycleInfos)
                if stt.cycleInfos[1] == 1
                    deleteIt = false
                    if !(stt.T isa Num)
                        if stt.h isa Num
                            stt.h = stt.T * props[lowercase(stt.fluid)][2]
                            newValue = true
                            DoAgain = true
                        end
                        deleteIt = true
                    elseif !(stt.h isa Num)
                        stt.T = stt.h / props[lowercase(stt.fluid)][2]
                        newValue = true
                        DoAgain = true
                    end
                    if !(stt.T isa Num) && !(stt.p isa Num)
                        stt.s = GetGasEntropy(stt.T, stt.p, stt.fluid)
                    end
                    if deleteIt
                        deleteat!(MyStates, findall(x->x==stt, MyStates))
                    end
                    continue           
                #############################################################
                elseif stt.cycleInfos[1] == 2
                    deleteIt = false
                    if !(stt.T isa Num)
                        if stt.h isa Num
                            stt.h = getValuesLA17(stt.T, 1)[2]
                            newValue = true
                            DoAgain = true
                        end
                        deleteIt = true
                    elseif !(stt.h isa Num)
                        stt.T = getValuesLA17(stt.h, 2)[1]
                        newValue = true
                        DoAgain = true
                        deleteIt = true
                    else
                        if !isnothing(stt.n)    
                            if !(stt.previous.h isa Num) &&
                            !(stt.previous.p isa Num) &&
                            !(stt.p isa Num)
                                if stt.n != 0
                                    stt.h = stt.previous.h + (
                                            getValuesLA17(stt.p / stt.previous.p *
                                                          getValuesLA17(stt.previous.h, 2)[3], 3)[2]
                                            - stt.previous.h) * stt.n
                                    stt.T = getValuesLA17(stt.h, 2)[1]
                                    newValue = true
                                    DoAgain = true
                                    deleteIt = true
                                else
                                    stt.h = getValuesLA17(stt.p / stt.previous.p * getValuesLA17(stt.previous.h, 2)[3], 3)
                                    stt.T = stt.h[1]
                                    stt.h = stt.h[2]
                                    newValue = true
                                    DoAgain = true
                                    deleteIt = true
                                end                        
                            end
                        elseif !isnothing(stt.next)
                            if !(stt.next[1].h isa Num) &&
                            !(stt.next[1].p isa Num) &&
                            !(stt.p isa Num)
                                if stt.next[2] != 0
                                    min = TableA17[1][2]
                                    max = TableA17[end][2]
                                    h1 = (max + min) / 2
                                    diff = 1
                                    for i in 1:20
                                        Pr1 = Pr1 = getValuesLA17(h1, 2)[3]
                                        Pr2 = stt.next[1].p / stt.p * Pr1
                                        h2s = getValuesLA17(Pr2, 3)[2]
                                        diff = abs(h1 - (h2s * stt.next[2] - stt.next[1].h)/(stt.next[2] - 1))
                                        if h1 > (h2s * stt.next[2] - stt.next[1].h)/(stt.next[2] - 1)
                                            max = h1
                                            h1 = (max + min) / 2
                                        else
                                            min = h1
                                            h1 = (max + min) / 2
                                    end end
                                    if diff > 0.5
                                        continue
                                    end
                                    stt.h = h1
                                    stt.T = getValuesLA17(stt.h, 2)[1]
                                    newValue = true
                                    DoAgain = true
                                    deleteIt = true
                                else
                                    print("DO IT NEXT")
                                end
                            end                            
                    end end
                    if !(stt.T isa Num) && !(stt.p isa Num)
                        stt.s = GetGasEntropy(stt.T, stt.p, stt.fluid)
                    end
                    if deleteIt
                        deleteat!(MyStates, findall(x->x==stt, MyStates))
                    end
                    continue
            end end
                            
            if stt.blocked
                continue
            end
    
            oldStt = nothing       
            if !isnothing(stt.n) && !(stt.s isa Num)
                oldStt = Stt(ntuple(x->nothing, fieldcount(Stt))...)
                oldStt.Q = stt.Q
                oldStt.T = stt.T
                oldStt.p = stt.p
                oldStt.h = stt.h
                oldStt.s = stt.s
                resetProp(stt, :(:Q))
                resetProp(stt, :(:T))                
            end
            vars = ["P", "T", "Q", "H", "S"]        
            values = Any[stt.p, stt.T, stt.Q, stt.h, stt.s]
            use = []

            for j in 1:5
                if !(values[j] isa Num)
                    push!(use, j)
            end end
            blacklist = [[2, 4], [3, 4], [3, 5]]
            chosen = []
            if size(use)[1] > 1
                for j in 1:size(use)[1]
                    if size(chosen)[1] == 2 
                        break 
                    end
                    for k in (j + 1):size(use)[1]
                        if !([use[j], use[k]] in blacklist)
                            chosen = [use[j], use[k]]
                            break
                end end end
            elseif isnothing(stt.next)     
                if !isnothing(oldStt) && size(use)[1] == 1 && use[1] == 5       
                    oldStt.s = nothing
                    values2 = Any[oldStt.p, oldStt.T, oldStt.Q, oldStt.h, oldStt.s]
                    use = []
                    for j in 1:5
                        if !(values2[j] isa Num) && !isnothing(values2[j])
                            push!(use, j)
                    end end
                    if size(use)[1] > 0
                        Ttop = PropsSI("Tcrit", stt.fluid)
                        Tbot = 274
                        T0 = (Ttop + Tbot) / 2
                        tempSt1 = nothing
                        for i in 1:20
                            tempSt1 = StateProps(stt.fluid, [vars[use[1]], values2[use[1]], "T", T0])
                            tempSt2 = StateProps(stt.fluid, ["S", stt.s, "T", T0])
                            tempSt3 = StateProps(stt.fluid, ["P", tempSt2[2], "H", stt.previous.h - stt.n * (stt.previous.h - tempSt2[3])])
                            if tempSt1[4] > tempSt3[4]
                                Tbot = T0
                                T0 = (Ttop + T0) / 2
                            else
                                Ttop = T0
                                T0 = (T0 + Tbot) / 2
                        end end
                        stt.T = tempSt1[1]
                        stt.p = tempSt1[2]
                        stt.h = tempSt1[3]
                        stt.s = tempSt1[4]
                        stt.Q = tempSt1[5]
                        stt.rho = tempSt1[6]
                        deleteat!(MyStates, findall(x->x==stt, MyStates))
                        newValue = true
                        continue
                    end
                    
                elseif !isnothing(oldStt)
                    stt.h = oldStt.h
                    stt.s = oldStt.s
                    stt.p = oldStt.p
                    stt.T = oldStt.T
                    stt.Q = oldStt.Q
                end

                continue
            end
            
            stTemp = nothing
            
            if isnothing(stt.next) || (!isnothing(stt.next) && !(5 in chosen) && size(chosen)[1] >= 2)
                if size(chosen)[1] != 2
                    for j in 1:size(use)[1]
                        if size(chosen)[1] == 2
                             break
                        end
                        for k in (j + 1):size(use)[1]
                            chosen = [use[j], use[k]]
                            break
                    end end
                    if use == [3, 5]
                        Ttop = PropsSI("Tcrit", stt.fluid)
                        Tbot = 274
                        T0 = (Ttop + Tbot) / 2
                        for i in 1:20
                            tempSt = StateProps(stt.fluid, [vars[chosen[1]], values[chosen[1]], "T", T0])
                            if tempSt[4] > values[chosen[2]]
                                Tbot = T0
                                T0 = (Ttop + T0) / 2
                            else
                                Ttop = T0
                                T0 = (T0 + Tbot) / 2
                        end end
                        stTemp = StateProps(stt.fluid, [vars[chosen[1]], values[chosen[1]], "T", T0])
                    elseif use == [3, 4]
                        Ttop = PropsSI("Pcrit", stt.fluid) / 1000
                        Tbot = 0
                        T0 = (Ttop + Tbot) / 2
                        for i in 1:20
                            tempSt = StateProps(stt.fluid, [vars[chosen[1]], values[chosen[1]], "P", T0])
                            if tempSt[3] < values[chosen[2]]
                                Tbot = T0
                                T0 = (Ttop + T0) / 2
                            else
                                Ttop = T0
                                T0 = (T0 + Tbot) / 2
                        end end
                        stTemp = StateProps(stt.fluid, [vars[chosen[1]], values[chosen[1]], "P", T0])
                    else
                        if !isnothing(oldStt)
                            stt.h = oldStt.h
                            stt.s = oldStt.s
                            stt.p = oldStt.p
                            stt.T = oldStt.T
                            stt.Q = oldStt.Q
                        end
                        continue
                    end
                else
                    stTemp = StateProps(stt.fluid, [vars[chosen[1]], values[chosen[1]], vars[chosen[2]], values[chosen[2]]])
                end
                
                if !isnothing(stt.n) && 5 in chosen
                    stt.h = oldStt.h
                    stt.s = oldStt.s
                    stt.p = oldStt.p
                    stt.T = oldStt.T
                    stt.Q = oldStt.Q                
                    if isnothing(stt.previous) || isnothing(stt.previous.h)
                        continue
                    end
                    
                    stt.h = stt.previous.h - stt.n * (stt.previous.h - stTemp[3])
                    resetProp(stt, :(:s))
                    # stt.s = nothing
                    DoAgain = true
                    continue
                end
            else
                if !(1 in use) && !(2 in use)
                    continue
                end
                if stt.next[1].p isa Num
                    continue
                end
                if !(stt.next[1].h isa Num)
                    if stt.next[2] < 1
                        if 1 in use
                            Ttop = PropsSI("Tmax", stt.fluid)
                            Tbot = 274
                            T0 = (Ttop + Tbot) / 2
                            for i in 1:20
                                tempSt = StateProps(stt.fluid, [vars[1], values[1], "T", T0])
                                tempSt2 = StateProps(stt.fluid, ["P", stt.next[1].p, "S", tempSt[4]])
                                if stt.next[1].h > tempSt[3] - stt.next[2] * (tempSt[3] - tempSt2[3])
                                    Tbot = T0
                                    T0 = (Ttop + T0) / 2
                                else
                                    Ttop = T0
                                    T0 = (T0 + Tbot) / 2
                            end end 
                            stTemp = StateProps(stt.fluid, [vars[1], values[1], "T", T0])
                        elseif 2 in use
                            Ttop = PropsSI("Pcrit", stt.fluid) / 1000
                            Tbot = 0
                            T0 = (Ttop + Tbot) / 2
                            count = 0
                            while true
                                count += 1
                                if count > 50
                                    break
                                end
                                tempSt = StateProps(stt.fluid, [vars[2], values[2], "P", T0])
                                tempSt2 = StateProps(stt.fluid, ["P", stt.next[1].p, "S", tempSt[4]])
                                test = tempSt[3] - stt.next[2] * (tempSt[3] - tempSt2[3])
                                if abs(stt.next[1].h - test) < 0.1
                                    break
                                end
                                if stt.next[1].h < test
                                    Tbot = T0
                                    T0 += 100
                                else
                                    T0 = (T0 + Tbot) / 2
                            end end
                            stTemp = StateProps(stt.fluid, [vars[2], values[2], "P", T0])
                        end
                    else
                        if 1 in use
                            Ttop = PropsSI("Tmax", stt.fluid)
                            Tbot = 274
                            T0 = 274
                            for i in 1:20
                                tempSt = StateProps(stt.fluid, [vars[1], values[1], "T", T0])
                                if stt.next[1].h > tempSt[3] + stt.next[2] * 
                                        (stt.next[1].p - tempSt[2]) / (tempSt[6]) #convert problem
                                    Tbot = T0
                                    T0 = (Ttop + T0) / 2
                                else
                                    Ttop = T0
                                    T0 = (T0 + Tbot) / 2
                            end end
                            stTemp = StateProps(stt.fluid, [vars[1], values[1], "T", T0])
                        elseif 2 in use
                            stTemp = StateProps(stt.fluid, [vars[2], values[2], "Q", 0])
                            if abs(stt.next[1].h - (stTemp[3] + stt.next[2] *
                                                    (stt.next[1].p - stTemp[2]) / stTemp[6])) >= 0.5 #convert problem
                                continue
                    end end end
                else                    
                    if 1 in use
                        canCalc = false
                        Eqtemp = nothing                 
                        for i in MyEquations
                            if canCalc
                                continue  
                            end
                            for j in i.vars
                                if j == Expr(:., stt.next[1].name, :(:h))
                                    Eqtemp = Symbolics.solve_for([i.Eq], [eval(j)])[1]
                                    Eqvars = GetVars(Meta.parse(string(Eqtemp)))
                                    if length(Eqvars) == 1
                                        canCalc = true
                                        break
                                    end
                                end 
                            end
                        end              
                        if !canCalc
                            continue  
                        end
                        st_temp = eval(Expr(:., stt.name, :(:h)))
                        tempEq = st_temp - (st_temp - Eqtemp) / stt.next[2] 
                        
                        Ttop = PropsSI("Tmax", stt.fluid)
                        Tbot = StateProps(stt.fluid, [vars[1], values[1], "Q", 1])[1] + 1
                        T0 = (Ttop + Tbot) / 2
                        diff = 10000
                        for i in 1:20
                            tempSt1 = StateProps(stt.fluid, [vars[1], values[1], "T", T0])
                            newH = substitute(tempEq, Dict([eval(Expr(:., stt.name, :(:h))) => tempSt1[3]]))
                            newH = eval(Meta.parse(string(newH)))
                            tempSt2s = StateProps(stt.fluid, ["P", stt.next[1].p, "H", newH])
                            
                            diff = abs(tempSt2s[4] - tempSt1[4])
                            if tempSt2s[4] < tempSt1[4]
                                Tbot = T0
                                T0 = (Ttop + T0) / 2
                            else
                                Ttop = T0
                                T0 = (T0 + Tbot) / 2
                            end
                        end
                        if diff > 0.5
                            continue
                        end
                        stTemp = StateProps(stt.fluid, [vars[1], values[1], "T", T0])                        
                    else
                        continue       
            end end end
    
            stt.T = stTemp[1]
            stt.p = stTemp[2]
            stt.h = stTemp[3]
            stt.s = stTemp[4]
            stt.Q = stTemp[5]
            stt.rho = stTemp[6]
            deleteat!(MyStates, findall(x->x==stt, MyStates))
            newValue = true   
        end
        if DoAgain
            newValue |= FindStates()
        end
        return newValue
    end
    
    function resetProp(state, prop)
        stateName = state.name
        local state2
        if stateName isa Expr
            state2 = copy(stateName)
            for i in 2:size(state2.args)[1]
                state2.args[i] = Expr(:call, :(:), 1, state2.args[i])
            end
            state2 = Expr(:ref, state2.args..., Expr(:call, :(:), 1, 8))
        else
            state2 = Expr(:ref, stateName, Expr(:call, :(:), 1, 8))
        end  
        state3 = Symbol(state2.args[1], :Stts)
        state2.args[1] = state3
        eval(Expr(:macrocall, Symbol("@variables"), :(), state2))
        eval(Expr(:(=), state2.args[1], Expr(:call, :collect, state2.args[1])))
    
        propIndex = Dict(
            :(:T)=>1,
            :(:p)=>2,
            :(:h)=>3,
            :(:s)=>4,
            :(:Q)=>5,
            :(:rho)=>6,
            :(:m)=>7,
            :(:mFraction)=>8
        )[prop]
        
        if stateName isa Expr
            eval(Expr(:(=), Expr(:., state.name, prop), Expr(:ref, state3, stateName.args[2:end]..., propIndex)))
        else
            eval(Expr(:(=), Expr(:., state.name, prop), Expr(:ref, state3, propIndex)))
        end
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

    mutable struct Stt
        T           #1
        p           #2
        h           #3
        s           #4
        Q           #5
        rho         #6
        m           #7
        mFraction   #8
        fluid       
        n           
        previous    
        next        
        blocked     
        cycleInfos  
        name        
        refArray    
    end   

    mutable struct MathEq
        Eq
        vars
        priority
        MathEq() = new()
    end

    function newEq(eq, extras = Any[]) 
        if eq.head == Symbol('=')
            if eq.args[1] isa Expr
                if eq.args[1].args[1] == Symbol("thisComponent")
                    massIn = :(0)
                    massOut = :(0)
                    if string(eq.args[1].args[2])[2:2] in ["Q", "W"]
                        for i in MassParent[end][1]
                            massIn = Expr(:call, :(+), massOut, :($i.m * $i.h))
                        end
                        for i in MassParent[end][2]
                            massOut = Expr(:call, :(+), massOut, :($i.m * $i.h))
                        end
                    else
                        for i in MassParent[end][1]
                            massIn = Expr(:call, :(+), massOut, :($i.h))
                        end
                        for i in MassParent[end][2]
                            massOut = Expr(:call, :(+), massOut, :($i.h))
                        end
                    end
                    
                    tempValue = nothing
                    if string(eq.args[1].args[2])[3:end] == "in"
                        tempValue = Expr(:call, :(-), massOut, massIn)
                    else                    
                        tempValue = Expr(:call, :(-), massIn, massOut)
                    end
                    newEq(:($(eq.args[2]) = $tempValue))
                    push!(CyclesCalcMass, MassParent[end][1][1])
                    return
                elseif eq.args[1].args[1] == Symbol("thisCycle")
                    push!(PropsInputEq, [eq.args[1].args[2], cycleIndex + 1, eq.args[2]])
                    if string(eq.args[1].args[2])[2:2] in ["Q", "W"]
                        push!(CyclesCalcMass, cycleIndex)
                    end
                    return
                end
            end
            for i in eq.args
                manageExpr(i)                
            end
            newEquation = MathEq()
            eq = Expr(:call, :(~), eq.args[1], eq.args[2]) 
            newEquation.Eq = SimplifyEq(eval(eq))
            newEquation.vars = GetVars(Meta.parse(string(newEquation.Eq)))
            push!(MyEquations, newEquation)
        elseif eq.args[1] == :>>
            cycleType = eq.args[3]
            if cycleType isa Expr
                cycleType = cycleType.args[1]
            end
            if cycleType == Symbol("Steam")
                global cycleInfos = 0
            elseif cycleType == Symbol("Gas")
                global cycleInfos = 1
            elseif cycleType == Symbol("Gas_variable_CP")
                global cycleInfos = 2
            else
                print("ERROR")
            end

            if eq.args[2] == Symbol("Refrigeration_Cycle")
                global itsRefrigeration = true
            end

            global cycleIndex += 1

            if eq.args[3] isa Expr
                if eq.args[3].args[2] isa Expr
                    global fluidDefault = String(eq.args[3].args[2].args[2])
                    global cycleInfos = Any[cycleInfos, eq.args[3].args[2].args[3], cycleIndex]
                else
                    global fluidDefault = String(eq.args[3].args[2])
                    global cycleInfos = Any[cycleInfos, -1, cycleIndex]
                end
            else
                if cycleInfos == 0
                    global fluidDefault = "water"
                elseif cycleInfos == 1
                    global fluidDefault = "air"
                end
                global cycleInfos = Any[cycleInfos, -1, cycleIndex]
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
    
    function SimplifyEq(eq::Equation)
        eq = Symbolics.simplify(eq)
        if Symbolics.istree(eq.rhs) && Symbolics.operation(eq.rhs) == /
            eq = Symbolics.arguments(eq.rhs)[2] * eq.lhs ~ Symbolics.arguments(eq.rhs)[2] * eq.rhs
        end
        if Symbolics.istree(eq.lhs) && Symbolics.operation(eq.lhs) == /
            eq = Symbolics.arguments(eq.lhs)[2] * eq.lhs ~ Symbolics.arguments(eq.lhs)[2] * eq.rhs
        end    
        return eq
    end

    function GetVars(eq, vars = [])
        if eq isa Expr 
            if eq.head == Symbol("call")
                for i in eq.args[2:1:end]
                    GetVars(i, vars)
                end
            elseif eq.head == Symbol("block")
                for i in eq.args[2:2:end]
                    GetVars(i, vars)
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
    
    function manageExpr(eq)
        if eq isa Expr 
            if eq.head == Symbol("call")
                for i in eq.args[2:1:end]
                    manageExpr(i)
                end
            elseif eq.head == Symbol("block")
                for i in eq.args[2:2:end]
                    manageExpr(i)
                end
            else
                createSymbolics(eq)
            end    
        elseif eq isa Symbol
            createSymbolics(eq)
        end
    end

    function createSymbolics(var)
        if var isa Expr 
            if var.head == Symbol(".")
                createState(var.args[1])
            elseif var.head == Symbol("ref")  
                createVar(var)                    
            end
            if !(var in AllVars)
                push!(AllVars, var)
            end
        elseif !(var in AllVars)
            push!(AllVars, var)
            createVar(var) 
        end   
    end
    
    function createState(state) 
        if state in [i.name for i in AllStates]
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
        for i in MyStates
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
        # sttClass.fluid = "Water"
        sttClass.blocked = false
        # sttClass.cycleInfos = [0, -1]
        eval(Expr(:(=), state2.args[1], :nothing))
        push!(MyStates, sttClass)
        push!(AllStates, sttClass)
    end

    function createVar(var) 
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
                newSz = size(eval(var.args[1]))
                newSz = [newSz...]
                for i in 1:size(newSz)[1]
                    if newSz[i] < var.args[1+i]
                        newSz[i] = var.args[1+i]
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

    function MassFlow(inStt, outStt, isolate=false)
        push!(MassParent, [inStt, outStt])
        if !isolate
            for i in [inStt..., outStt...]
                push!(fluidEq, [i, cycleInfos, fluidDefault])
        end end
    
        m_total = :($(inStt[1]).m)
        for i in inStt[2:end]
            m_total = Expr(:call, :+, m_total, :($(i).m)) 
            if !(:($(i).m) in AllVars)
                push!(AllVars, :($(i).m))
        end end
        for i in outStt
            if !(:($(i).m) in AllVars)
                push!(AllVars, :($(i).m))
        end end
    
        if size(outStt)[1] > 1
            m_fraction2 = :(1)
            indexProp = size(m_fraction)[1] + 1       
            CreateSymbol(Expr(:ref, :m_fraction, indexProp, size(outStt)[1]))
            for i in 1:(size(outStt)[1] - 1)
                push!(MassEq1, [:($(outStt[i]).m = $(m_total) * m_fraction[$indexProp, $i]), outStt[i], inStt])
                m_fraction2 = Expr(:call, :-, m_fraction2, Expr(:ref, :m_fraction, indexProp, i))
            end
            push!(MassEq1, [:($(last(outStt)).m = $(m_total) * $(m_fraction2)), last(outStt), inStt])
        else
            push!(MassEq1, [:($(last(outStt)).m = $(m_total)), last(outStt), inStt])
    end end

    function SetCycleOrder(stt, MassCopy)
        BreakRecursion = 0
        for i in stt[2]
            for j in MassCoef
                if j[1] == i
                    BreakRecursion += 1
                    break
        end end end
        if BreakRecursion == size(stt[2])[1]
            return
        end
    
        coef = 0
        for i in stt[1]
            notIn = true
            for j in MassCoef
                if j[1] == i
                    notIn = false
                    coef += j[2]
                    break
            end end
            if notIn
                push!(MassCoef, [i, 1])
                coef += 1
        end end
    
        for i in stt[2]
            push!(MassCoef, [i, coef/size(stt[2])[1]])
        end
    
        for i in stt[2]
            for j in MassCopy
                breakFor = false
                for k in j[1]
                    if k == i
                        SetCycleOrder(j, MassCopy)
                        breakFor = true
                        break
                end end
                if breakFor
                    break
    end end end end
    
    function CreateSymbol(var)
        # for i in 2:size(SymbolVar.args)[1]
        #     SymbolVar.args[i] = Expr(:call, :(:), 1, SymbolVar.args[i])
        # end
        # eval(Expr(:macrocall, Symbol("@variables"), :(), SymbolVar))
        # eval(Expr(:(=), SymbolVar.args[1], Expr(:call, :collect, SymbolVar.args[1])))
        var2 = copy(var)    
        var2.args[1] = Symbol(var2.args[1], :Vars)
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

    function ExprHasItem(eq, item)
        if eq == item
            return true
        elseif eq isa Expr
            for i in eq.args
                if ExprHasItem(i, item)
                    return true                
        end end end
        return false
    end

    function ExprSubs(eq, old, new)
        if eq == old
            eq = new
        elseif eq isa Expr
            for i in 1:size(eq.args)[1]
                eq.args[i] = ExprSubs(eq.args[i], old, new)
        end end
        return eq
    end

    function SetupMass()
        MassCopy = deepcopy(MassParent)
        for i in 1:size(MassParent)[1]
            MassParent[i] = [MassParent[i][1]..., MassParent[i][2]...]        
        end
        for i in MassParent
            next = false
            for j in i
                for k in 1:size(CyclesStts)[1]
                    if j in CyclesStts[k]
                        for j2 in i
                            if !(j2 in CyclesStts[k])
                                push!(CyclesStts[k], j2)
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
                push!(CyclesStts, i)
            end
        end
    
        stopFor = true
        while stopFor
            mergeIndex = nothing
            stopFor = false
            for i in 1:size(CyclesStts)[1]
                for j in i + 1:size(CyclesStts)[1]
                    inters = intersect(CyclesStts[i], CyclesStts[j])
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
                copy1 = copy(CyclesStts[mergeIndex[1]])
                copy2 = copy(CyclesStts[mergeIndex[2]])
                deleteat!(CyclesStts, findall(x->x==copy1, CyclesStts))
                deleteat!(CyclesStts, findall(x->x==copy2, CyclesStts))
                for j in mergeIndex[3]
                    deleteat!(copy2, findall(x->x==j, copy2))
                end
                push!(CyclesStts, [copy1..., copy2...])
            end
        end
        
        for i in CyclesStts
            for j in MassCopy
                breakFor = false
                for k in j[1]
                    if k == i[1]
                        SetCycleOrder(j, MassCopy)
                        breakFor = true
                        break
                    end
                end
                if breakFor
                    break
                end
            end
        end
       
        RootStt = Any[]
        for i in CyclesStts
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
        
        cDependencies = Vector{Any}()
    
        for i in closedInteractions
            for j in 1:size(CyclesStts)[1]
                if i[1] in CyclesStts[j]
                    for k in 1:size(CyclesStts)[1]
                        if i[2] in CyclesStts[k]
                            if !([j, k] in cDependencies) && !([k, j] in cDependencies)
                                push!(cDependencies, [j, k])                      
        end end end end end end

        CyclesCalcMassRequest = copy(CyclesCalcMass)
        global CyclesCalcMass = falses(size(CyclesStts)[1])

        for i in CyclesCalcMassRequest
            if i isa Int
                if i == -1
                    global CyclesCalcMass = trues(size(CyclesStts)[1])
                else
                    global CyclesCalcMass[i + 1] = true
                end
            else
                for j in 1:length(CyclesStts)
                    if i in CyclesStts[j]
                        global CyclesCalcMass[j] = true
        end end end end
        
        for i in MyEquations
            if size(i.vars)[1] == 1 &&
            i.vars[1] isa Expr &&
            (i.vars[1].head == :.) &&
            last(i.vars[1].args) == :(:m)
                for k in 1:size(CyclesStts)[1]
                    if i.vars[1].args[1] in CyclesStts[k]
                        CyclesCalcMass[k] = true
                        for w in cDependencies
                            if k in w
                                CyclesCalcMass[w[1]] = true
                                CyclesCalcMass[w[2]] = true                
        end end end end end end
    
        for i in copy(fluidEq)
            if i[3] isa String
                eval(Expr(:(=), :($(i[1]).cycleInfos), i[2]))
                eval(Expr(:(=), :($(i[1]).fluid), i[3]))
                deleteat!(fluidEq, findall(x->x==i, fluidEq))
        end end
        
        setMainMass = Array{Any}(nothing, length(CyclesStts))
        for i in 1:size(CyclesStts)[1]
            values = zeros(2)
            for j in CyclesStts[i]
                evalStt = eval(j)
                if !isnothing(evalStt.fluid)
                    values = [evalStt.cycleInfos, evalStt.fluid]
                    if evalStt.cycleInfos[2] != -1
                        CyclesCalcMass[i] = true
                        setMainMass[i] = evalStt.cycleInfos[2]
                        for w in cDependencies
                            if i in w
                                CyclesCalcMass[w[1]] = true
                                CyclesCalcMass[w[2]] = true
                    end end end
                    break
            end end
            for j in CyclesStts[i]
                evalStt = eval(j)            
                if isnothing(evalStt.fluid) ||
                isnothing(evalStt.cycleInfos)
                    eval(:($(j).cycleInfos = $(values)[1]))
                    eval(:($(j).fluid = $(values)[2]))
        end end end
        
        CyclesMassIndex = Array{Any}(undef, size(CyclesStts)[1])
        removeItem = []
        MassEq3 = []   
        
        for i in 1:size(RootStt)[1]
            if CyclesCalcMass[i]
                indexProp = size(m_Cycle)[1] + 1       
                createVar(Expr(:ref, :m_Cycle, indexProp))
                CyclesMassIndex[i] = indexProp
                equalityMass = Expr(:ref, :m_Cycle, indexProp)
            else
                equalityMass = :(1)
            end
            for j in 1:size(MassEq1)[1]    
                if MassEq1[j][2] == RootStt[i][1] || (
                        size(MassEq1[j][3])[1] == 1 &&
                        MassEq1[j][3][1] == RootStt[i][1] &&
                        !ExprHasItem(MassEq1[j][1], :(m_fraction)))
                    local outVars
                    for j2 in MassEq1
                        if RootStt[i][1] in j2[3]
                            outVars = j2[3]
                            break
                    end end
                    
                    if size(outVars)[1] == 1   
                        # push!(MassEq3, [:($(MassEq1[j][1].args[1]).m), equalityMass])   
                        if length(MassEq1[j][3]) == 1
                            push!(MassEq3, [:($(MassEq1[j][3][1]).m), equalityMass])    
                        end
                        MassEq1[j][1] = :($(MassEq1[j][1].args[1]) = $(equalityMass))           
                        if !isnothing(setMainMass[i])
                            eval(Expr(:(=), equalityMass, setMainMass[i]))                            
                            push!(MassEq3, [equalityMass, setMainMass[i]])                            
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
                if ExprHasItem(MassEq2[i][2], QuoteNode(:m))                
                    for j in MassEq2
                        if ExprHasItem(MassEq2[i][2], j[1])
                            MassEq2[i][2] = ExprSubs(MassEq2[i][2], j[1], j[2])                                   
                            newValue = true
        end end end end end

        for i in 1:size(MassEq2)[1]
            ret = MathEq()
            eq = Expr(:call, :(~), MassEq2[i][1], MassEq2[i][2])
            eq = Symbolics.simplify(SimplifyEq(eval(eq)); expand=true)
            ret.Eq = eq
            ret.vars = Any[]
            ret.vars = GetVars(Meta.parse(string(eq.lhs)))
            # for j in ret.vars:
            #     if '.m' in j:
            #         sol = solve(ret.Eq, eval(j))
            #         if len(sol) > 0:
            #             if setGlobalVar(j, sol[0]) is not None:
            #                 continue
            #             for k in range(len(MyEquations)):
            #                 MyEquations[k].Eq = MyEquations[k].Eq.subs(Symbol(j), sol[0])
            #         break
            ret.priority = false
            push!(BaseEqualities, ret)
        end

        for i in 1:length(MyEquations)
            for j in copy(MyEquations[i].vars)
                if j isa Expr && (j.head == :.) && j.args[end] == QuoteNode(:mFraction)
                    sttTemp = j.args[1]
                    for k in 1:size(CyclesStts)[1]
                        if sttTemp in CyclesStts[k]
                            newProp = copy(j.args[1])
                            newProp.args[1] = Symbol(newProp.args[1], :Stts)
                            newProp = Expr(:ref, newProp.args... , 8)
                            for k in BaseEqualities
                                if k.vars[1].args[1] == j.args[1]
                                    # MyEquations[i].Eq = substitute(MyEquations[i].Eq, Dict([eval(j) => k.Eq.rhs]))
                                    Eq2Expr = Meta.parse(string(MyEquations[i].Eq))
                                    Eq2Expr = ExprSubs(Eq2Expr, newProp, Meta.parse(string(k.Eq.rhs)))
                                    MyEquations[i].vars = GetVars(Eq2Expr)
                                    MyEquations[i].Eq = SimplifyEq(eval(Eq2Expr))

                                    for j2 in MyEquations[i].vars
                                        if j2 isa Expr && j2.args[1] == :m_Cycle
                                            
                                            MyEquations[i].Eq = substitute(MyEquations[i].Eq, Dict([eval(j2) => 1]))
                                            MyEquations[i].vars = GetVars(Meta.parse(string(MyEquations[i].Eq)))
                                            break
                                    end end                                       

                                    
                                    
                                    break
                            end end
                            
                                
                            # if isdefined(CyclesMassIndex, k)
                            #     Eq2Expr.args[2] = Expr(:call, :*, Eq2Expr.args[2], Expr(:ref, :m_Cycle, CyclesMassIndex[k]))
                            # end
    
                            # MyEquations[i].vars = []
    
                            # MyEquations[i].Eq = SimplifyEq(eval(Eq2Expr))
                            # MyEquations[i].vars = GetVars(Meta.parse(string(Eq2Expr)))
                            break
            end end end end
            isaMassEq = false            
            for j in MyEquations[i].vars
                if j isa Expr && j.head == :. && j.args[end] == QuoteNode(:m)
                    for k in BaseEqualities
                        if k.vars[1] == j
                            MyEquations[i].Eq = substitute(MyEquations[i].Eq, Dict([eval(j) => k.Eq.rhs]))      
                            isaMassEq = true                   
                            break
                    end end
            end end
            if isaMassEq
                # MyEquations[i].Eq = Symbolics.simplify(SimplifyEq(MyEquations[i].Eq); expand=true)  
                MyEquations[i].vars = []
                MyEquations[i].vars = GetVars(Meta.parse(string(MyEquations[i].Eq)))
                mCycleTimes = 0
                for j in MyEquations[i].vars
                    if j isa Expr && j.args[1] == :m_Cycle
                        mCycleTimes += 1
                end end
                if mCycleTimes == 1
                    for j in MyEquations[i].vars
                        if j isa Expr && j.args[1] == :m_Cycle
                            try
                                if Symbolics.solve_for([MyEquations[i].Eq], [eval(j)])[1] == 0
                                    MyEquations[i].Eq = substitute(MyEquations[i].Eq, Dict([eval(j) => 1]))
                                    break
                                end
                            catch
                    end end end 
                    MyEquations[i].vars = GetVars(Meta.parse(string(MyEquations[i].Eq)))
                end

                for k in copy(MyEquations[i].vars)
                    if k isa Expr && k.args[1] == :m_fraction
                        changed = false
                        ret = MyEquations[i].Eq.lhs/(m_fraction[k.args[2], k.args[3]]) ~ MyEquations[i].Eq.rhs/(m_fraction[k.args[2], k.args[3]])
                        ret = Symbolics.simplify(ret; simplify_fractions=true)                    
                        if ((Symbolics.istree(ret.lhs) && Symbolics.istree(ret.rhs)) &&
                        (Symbolics.operation(ret.lhs) == /) && (Symbolics.operation(ret.rhs) == /) &&
                        (string(Symbolics.arguments(ret.rhs)[end]) == string(Symbolics.arguments(ret.lhs)[end])))
                            ret = Symbolics.arguments(ret.lhs)[1] ~ Symbolics.arguments(ret.lhs)[2]
                        else
                            changed = true
                            MyEquations[i].Eq = ret
                        end                    
    
                        ret = MyEquations[i].Eq.lhs/(1 - m_fraction[k.args[2], k.args[3]]) ~ MyEquations[i].Eq.rhs/(1 - m_fraction[k.args[2], k.args[3]])
                        ret = Symbolics.simplify(ret; simplify_fractions=true)
                        if ((Symbolics.istree(ret.lhs) && Symbolics.istree(ret.rhs)) &&
                        (Symbolics.operation(ret.lhs) == /) && (Symbolics.operation(ret.rhs) == /) &&
                        (string(Symbolics.arguments(ret.rhs)[end]) == string(Symbolics.arguments(ret.lhs)[end])))
                            ret = Symbolics.arguments(ret.lhs)[1] ~ Symbolics.arguments(ret.lhs)[2]
                        else
                            changed = true
                        end
                        
                        if changed
                            MyEquations[i].Eq = Symbolics.simplify(SimplifyEq(ret); expand=true)
                            MyEquations[i].vars = []
                            MyEquations[i].vars = GetVars(Meta.parse(string(ret)))
                end end end                
            end
        end
    
        for i in fluidEq
            eval(Expr(:(=), :($(i[1]).cycleInfos), eval(i[2])))
            eval(Expr(:(=), :($(i[1]).fluid), eval(i[3])))
        end
    end

    function EnergyBalance(inStt, outStt)
        inEq = :($(inStt[1]).m * $(inStt[1]).h)
        for i in inStt[2:end]
            inEq = Expr(:call, :+, inEq, :($i.m * $i.h))
        end
        outEq = :($(outStt[1]).m * $(outStt[1]).h)
        for i in outStt[2:end]
            outEq = Expr(:call, :+, outEq, :($i.m * $i.h))
        end
        newEq(Expr(:(=), inEq, outEq))
    end

    ##########################################

    function pump(inStt, outStt, n = 100)
        if inStt[1] isa Stt
            inStt = Any[i.name for i in inStt]
            outStt = Any[i.name for i in outStt]
        end
        
        if length(inStt) != length(outStt)
            # SET ERROR
        elseif length(inStt) > 1
            for i in 1:length(inStt)
                pump([inStt[i]], [outStt[i]], n)
            end
            return
        else
            MassFlow(Any[inStt[1]], Any[outStt[1]])
            inStt = inStt[1]
            outStt = outStt[1]
        end
        
        push!(PropsEquations, Any[:Win, 
        :($outStt.m * $outStt.h - $inStt.m * $inStt.h),
        [string("pump: ", string(inStt), " >> ", string(outStt)), inStt]])
        push!(PropsEquations, Any[:win, 
        :($outStt.h - $inStt.h),
        [string("pump: ", string(inStt), " >> ", string(outStt)), inStt]])        
        
        if n == :find
            push!(findVariables, Any[:(($inStt.h - SttTemp_S)/($inStt.h - $outStt.h)),
                eval(inStt), eval(outStt), string("efficiency of [pump: ",
                string(inStt), " >> ", string(outStt),"]"), 1])
            return
        end

        n /= 100
        newEq(:($outStt.s = $inStt.s), [1, 3])
        if n != 1
            eval(Expr(:(=), :($outStt.n), 1/n))
            eval(Expr(:(=), :($outStt.previous), eval(inStt)))
            eval(Expr(:(=), :($inStt.next), [eval(outStt), 1/n]))
        end
    end

    function turbine(inStt, outStt, n = 100)
        if inStt[1] isa Stt
            inStt = Any[i.name for i in inStt]
            outStt = Any[i.name for i in outStt]
        end
        if length(inStt) != length(outStt)
            if length(inStt) == 1 && 1 < length(outStt)
                Wouttemp = :($(inStt[1]).m * $(inStt[1]).h)
                wouttemp= :($(inStt[1]).mFraction * $(inStt[1]).h)
                for i in outStt
                    Wouttemp = Expr(:call, :(-), Wouttemp, :($i.m * $i.h))
                    wouttemp = Expr(:call, :(-), wouttemp, :($i.mFraction * $i.h))
                end
                push!(PropsEquations, Any[:Wout, Wouttemp,
                [string("turbine: ", string(inStt), " >> ", string(outStt)), inStt[1]]])
                push!(PropsEquations, Any[:wout, 
                Expr(:call, :(/), wouttemp, :($(inStt[1]).mFraction)),
                [string("turbine: ", string(inStt), " >> ", string(outStt)), inStt[1]]])
            end
        elseif length(inStt) == 1
            push!(PropsEquations, Any[:Wout, 
            :($(inStt[1]).m * $(inStt[1]).h - $(outStt[1]).m * $(outStt[1]).h),
            [string("turbine: ", string(inStt[1]), " >> ", string(outStt[1])), inStt[1]]])
            push!(PropsEquations, Any[:wout, 
            :($(inStt[1]).h - $(outStt[1]).h),
            [string("turbine: ", string(inStt[1]), " >> ", string(outStt[1])), inStt[1]]])
        end
        if cycleInfos[1] == 0
            if length(inStt) != length(outStt)
                if length(inStt) == 1 && 1 < length(outStt)

                    MassFlow(inStt, outStt)
                    n /= 100

                    for i in outStt
                        indexProp = 0
                        newEq(:($i.s = $(inStt[1]).s), [1, 3])
                        if n != 1
                            eval(Expr(:(=), :($i.n), n))
                            eval(Expr(:(=), :($i.previous), inStt[1]))
                    end end
                    return
                else
                    # println("ERROR")
                end
            elseif length(inStt) > 1
                for i in 1:length(inStt)
                    turbine(Any[inStt[i]], Any[outStt[i]], n)
                end
                return
            else
                MassFlow(Any[inStt[1]], Any[outStt[1]])
                inStt = inStt[1]
                outStt = outStt[1]
            end

            if n == :find
                push!(findVariables, Any[:(($inStt.h - $outStt.h)/($inStt.h - SttTemp_S)),
                 eval(inStt), eval(outStt), string("efficiency of [turbine: ",
                 string(inStt), " >> ", string(outStt),"]"), 1])
            else
                n /= 100

                newEq(:($outStt.s = $inStt.s), [1, 3])
                if n != 1
                    eval(Expr(:(=), :($outStt.n), n))
                    eval(Expr(:(=), :($outStt.previous), eval(inStt)))
                    eval(Expr(:(=), :($inStt.next), [eval(outStt), n]))
                end
            end
        elseif cycleInfos[1] == 1
            MassFlow(inStt, outStt)
            k = props[lowercase(fluidDefault)][4]
            inStt = inStt[1]
            outStt = outStt[1]
            # T2s = T1 * (P2 / P1) ** (k-1)/k
            # T2 = T1 + n * (T2s - T1)
            # T2 = T1 + n * (T1 * (P2 / P1) ** (k-1)/k - T1)
            if n == :find
                push!(findVariables, Any[:(
                    ($outStt.T - $inStt.T) / ($inStt.T * ($outStt.p / $inStt.p)^(($k - 1)/$k) - $inStt.T)),
                 eval(inStt), eval(outStt), string("efficiency of [turbine: ",
                 string(inStt), " >> ", string(outStt),"]"), 1])
                return                
            end

            if n == 100
                newEq(:($outStt.T = $inStt.T * ($outStt.p / $inStt.p)^(($k - 1)/$k)), [1, 3])
            else
                n /= 100
                newEq(:($outStt.T = $inStt.T +($inStt.T * ($outStt.p / $inStt.p)^(($k - 1)/$k) - $inStt.T) * $n), [1, 3])
            end
        else
            MassFlow(inStt, outStt)
            inStt = inStt[1]
            outStt = outStt[1]            
            
            if n == :find
                push!(findVariables, Any[1, eval(inStt), eval(outStt),
                string("efficiency of [turbine: ",
                string(inStt), " >> ", string(outStt),"]"), 1])
                return                
            end

            n /= 100
            if n != 1                
                eval(Expr(:(=), :($outStt.n), :($n)))
                eval(Expr(:(=), :($outStt.previous), eval(inStt)))
                eval(Expr(:(=), :($inStt.next), [eval(outStt), n]))
    end end end
        
    function condenser(inStt, outStt)
        if inStt[1] isa Stt
            inStt = Any[i.name for i in inStt]
            outStt = Any[i.name for i in outStt]
        end
        if length(inStt) != length(outStt)
            MassFlow(inStt, outStt)
            # EnergyBalance(inStt, outStt)
            states = [inStt..., outStt...]
            for i in 1:(length(states) - 1)
                newEq(:($(states[i]).p = $(states[i + 1]).p), [1, 3])
            end
            newEq(:($(states[end]).p = $(states[1]).p), [1, 3])
            for i in outStt
                newEq(:($i.Q = 0), [1, 3])
            end

            Qouttemp = :(0)
            qouttemp = :(0)
            for i in inStt
                Qouttemp = Expr(:call, :(+), Qouttemp, :($i.m * $i.h))
                qouttemp = Expr(:call, :(+), qouttemp, :($i.mFraction * $i.h))
            end       
            push!(PropsEquations, Any[:Qout,
            Expr(:call, :(-), Qouttemp, :($(outStt[1]).m * $(outStt[1]).h)),
            [string("condenser: ", string(inStt), " >> ", string(outStt[1])), inStt[1]]])
            push!(PropsEquations, Any[:qout, 
            Expr(:call, :(-), qouttemp, :($(outStt[1]).h)),
            [string("condenser: ", string(inStt), " >> ", string(outStt[1])), inStt[1]]])  

            return
        elseif length(inStt) > 1
            for i in 1:length(inStt)
                condenser([inStt[i]], [outStt[i]])
            end
            return
        else
            MassFlow([inStt[1]], [outStt[1]])
            inStt = inStt[1]
            outStt = outStt[1]

            push!(PropsEquations, Any[:Qout, 
            :($inStt.m * $inStt.h - $outStt.m * $outStt.h),
            [string("condenser: ", string(inStt), " >> ", string(outStt)), inStt]])
            push!(PropsEquations, Any[:qout, 
            :($inStt.h - $outStt.h),
            [string("condenser: ", string(inStt), " >> ", string(outStt)), inStt]])
        end

        newEq(:($outStt.p = $inStt.p), [1, 3])
        newEq(:($outStt.Q = 0), [1, 3])
    end

    function boiler(inStt, outStt)
        if inStt[1] isa Stt
            inStt = Any[i.name for i in inStt]
            outStt = Any[i.name for i in outStt]
        end
        if length(inStt) != length(outStt)
            # println("ERROR")
        elseif length(inStt) > 1
            for i in 1:length(inStt)
                boiler([inStt[i]], [outStt[i]])
            end
            return
        else
            MassFlow([inStt[1]], [outStt[1]])
            inStt = inStt[1]
            outStt = outStt[1]
        end

        push!(PropsEquations, Any[:Qin, 
        :($outStt.m * $outStt.h - $inStt.m * $inStt.h),
        [string("boiler: ", string(inStt), " >> ", string(outStt)), inStt]])
        push!(PropsEquations, Any[:qin, 
        :($outStt.h - $inStt.h),
        [string("boiler: ", string(inStt), " >> ", string(outStt)), inStt]])

        newEq(:($outStt.p = $inStt.p), [1, 3])
    end

    function evaporator(inStt, outStt)
        if inStt[1] isa Stt
            inStt = Any[i.name for i in inStt]
            outStt = Any[i.name for i in outStt]
        end
        if length(inStt) != length(outStt)
            # println("ERROR")
        elseif length(inStt) > 1
            for i in 1:length(inStt)
                evaporator([inStt[i]], [outStt[i]])
            end
            return
        else
            MassFlow([inStt[1]], [outStt[1]])
            inStt = inStt[1]
            outStt = outStt[1]
        end

        push!(PropsEquations, Any[:Qin, 
        :($outStt.m * $outStt.h - $inStt.m * $inStt.h),
        [string("evaporator: ", string(inStt), " >> ", string(outStt)), inStt]])
        push!(PropsEquations, Any[:qin, 
        :($outStt.h - $inStt.h),
        [string("evaporator: ", string(inStt), " >> ", string(outStt)), inStt]])

        newEq(:($outStt.Q = 1), [1, 3])
        newEq(:($outStt.p = $inStt.p), [1, 3])
    end

    function evaporator_condenser(inStt, outStt)
        if inStt[1] isa Stt
            inStt = Any[i.name for i in inStt]
            outStt = Any[i.name for i in outStt]
        end
        EnergyBalance(inStt, outStt)
        push!(closedInteractions, inStt)
        for i in 1:length(inStt)
            MassFlow([inStt[i]], [outStt[i]], true)
            newEq(:($(outStt[i]).p = $(inStt[i]).p), [1, 3])
        end
        newEq(:($(outStt[1]).Q = 1), [1, 3])
        newEq(:($(outStt[2]).Q = 0), [1, 3])

        push!(Qflex, Any[inStt, outStt,
        string("evaporator_condenser: ", string(inStt), " >> ", string(outStt))])
        push!(qflex, Any[inStt, outStt,
        string("evaporator_condenser: ", string(inStt), " >> ", string(outStt))])
    end

    function expansion_valve(inStt, outStt)
        if inStt[1] isa Stt
            inStt = Any[i.name for i in inStt]
            outStt = Any[i.name for i in outStt]
        end
        if length(inStt) != length(outStt)
            # println("ERROR")
        elseif length(inStt) > 1
            for i in 1:length(inStt)
                expansion_valve([inStt[i]], [outStt[i]])
            end
            return
        else
            MassFlow([inStt[1]], [outStt[1]])
            inStt = inStt[1]
            outStt = outStt[1]
        end
        newEq(:($outStt.h = $inStt.h), [1, 3])      
    end

    function flash_chamber(inStt, outStt)
        if inStt[1] isa Stt
            inStt = Any[i.name for i in inStt]
            outStt = Any[i.name for i in outStt]
        end
        if length(inStt) != length(outStt)
            # println("ERROR")
        elseif length(inStt) > 1
            for i in 1:length(inStt)
                flash_chamber([inStt[i]], [outStt[i]])
            end
            return
        else
            MassFlow([inStt[1]], [outStt[1]])
            inStt = inStt[1]
            outStt = outStt[1]
        end
        newEq(:($outStt.h = $inStt.h), [1, 3])        
    end

    function heater_closed(inStt, outStt)
        inStt = Any[i.name for i in inStt]
        outStt = Any[i.name for i in outStt]
        EnergyBalance(inStt, outStt)
        push!(closedInteractions, inStt)
        for i in 1:length(inStt)
            MassFlow([inStt[i]], [outStt[i]], true)
            newEq(:($(outStt[i]).p = $(inStt[i]).p), [1, 3])
        end
        push!(WhoisTheHeater, Any[inStt, outStt])
        for i in outStt
            eval(Expr(:(=), :($i.blocked), true))
        end
        for i in 1:(length(outStt) - 1)
            newEq(:($(outStt[i]).T = $(outStt[i + 1]).T), [1, 3])
        end
        if length(outStt) > 2
            newEq(:($(outStt[end]).T = $(outStt[1]).T), [1, 3])
    end end

    function heater_open(inStt, outStt)
        inStt = Any[i.name for i in inStt]
        outStt = Any[i.name for i in outStt]
        MassFlow(inStt, outStt)
        EnergyBalance(inStt, outStt)
        states = [inStt..., outStt...]
        for i in 1:(length(states) - 1)
            newEq(:($(states[i]).p = $(states[i + 1]).p), [1, 3])
        end
        if length(states) > 2
            newEq(:($(states[end]).p = $(states[1]).p), [1, 3])
        end
        newEq(:($(outStt[1]).Q = 0), [1, 3])
    end

    function mix(inStt, outStt)
        inStt = Any[i.name for i in inStt]
        outStt = Any[i.name for i in outStt]
        MassFlow(inStt, outStt)
        EnergyBalance(inStt, outStt)
        states = [inStt..., outStt...]
        for i in 1:(length(states) - 1)
            newEq(:($(states[i]).p = $(states[i + 1]).p), [1, 3])
        end
        if length(states) > 2
            newEq(:($(states[end]).p = $(states[1]).p), [1, 3])
    end end

    function div(inStt, outStt)
        inStt = Any[i.name for i in inStt]
        outStt = Any[i.name for i in outStt]
        MassFlow(inStt, outStt)
        states = [inStt..., outStt...]
        for i in 1:(length(states) - 1)
            newEq(:($(states[i]).p = $(states[i + 1]).p), [1, 3])
            newEq(:($(states[i]).h = $(states[i + 1]).h), [1, 3])
        end
        if length(states) > 2
            newEq(:($(states[end]).p = $(states[1]).p), [1, 3])
            newEq(:($(states[end]).h = $(states[1]).h), [1, 3])
    end end

    function process_heater(inStt, outStt)
        inStt = Any[i.name for i in inStt]
        outStt = Any[i.name for i in outStt]
        MassFlow(inStt, outStt)
        states = [inStt..., outStt...]
        for i in 1:(length(states) - 1)
            newEq(:($(states[i]).p = $(states[i + 1]).p), [1, 3])
        end
        if length(states) > 2
            newEq(:($(states[end]).p = $(states[1]).p), [1, 3])   
    end end
    
    function compressor(inStt, outStt, n = 100)
        if inStt[1] isa Stt
            inStt = Any[i.name for i in inStt]
            outStt = Any[i.name for i in outStt]
        end

        push!(PropsEquations, Any[:Win, 
        :($(outStt[1]).m * $(outStt[1]).h - $(inStt[1]).m * $(inStt[1]).h),
        [string("compressor: ", string(inStt[1]), " >> ", string(outStt[1])), (inStt[1])]])
        push!(PropsEquations, Any[:win, 
        :($(outStt[1]).h - $(inStt[1]).h),
        [string("compressor: ", string(inStt[1]), " >> ", string(outStt[1])), (inStt[1])]]) 

        if cycleInfos[1] == 0
            if length(inStt) != length(outStt)
                # println("ERROR")
            elseif length(inStt) > 1
                for i in 1:length(inStt)
                    compressor([inStt[i]], [outStt[i]], n)
                end
                return
            else
                MassFlow([inStt[1]], [outStt[1]])
                inStt = inStt[1]
                outStt = outStt[1]
            end

            if n == :find
                push!(findVariables, Any[:(($inStt.h - SttTemp_S)/($inStt.h - $outStt.h)),
                 eval(inStt), eval(outStt), string("efficiency of [compressor: ",
                  string(inStt), " >> ", string(outStt),"]"), 1])
            else
                n /= 100
                newEq(:($outStt.s = $inStt.s), [1, 3])
                if n != 1
                    eval(Expr(:(=), :($outStt.n), 1/n))
                    eval(Expr(:(=), :($outStt.previous), eval(inStt)))
                    eval(Expr(:(=), :($inStt.next), [eval(outStt), 1/n]))
                end
            end
        elseif cycleInfos[1] == 1
            k = props[lowercase(fluidDefault)][4]
            MassFlow(inStt, outStt)
            #T2s = T1 * (P2 / P1) ** (k-1)/k
            #T2 = T1 + (T2s - T1) / n
            #T2 = T1 + (T1 * (P2 / P1) ** (k-1)/k - T1) / n
            inStt = inStt[1]
            outStt = outStt[1]
            if n == :find
                push!(findVariables, Any[:(
                    ($inStt.T * ($outStt.p / $inStt.p)^(($k - 1)/$k) - $inStt.T)/($outStt.T - $inStt.T)),
                    eval(inStt), eval(outStt), string("efficiency of [compressor: ",
                    string(inStt), " >> ", string(outStt),"]"), 1])
                return                   
            end
            if n == 100
                newEq(:($outStt.T = $inStt.T * ($outStt.p / $inStt.p)^(($k - 1)/$k)), [1, 3])
            else
                n /= 100
                newEq(:($outStt.T = $inStt.T + ($inStt.T * ($outStt.p / $inStt.p)^(($k - 1)/$k) - $inStt.T) / $n), [1, 3])
            end
        else
            MassFlow(inStt, outStt)
            inStt = inStt[1]
            outStt = outStt[1]
            if n == :find
                push!(findVariables, Any[2, eval(inStt), eval(outStt),
                string("efficiency of [compressor: ",
                string(inStt), " >> ", string(outStt),"]"), 1])
                return                
            end

            n /= 100
            if n != 1
                eval(Expr(:(=), :($(outStt).n), 1/n))
                eval(Expr(:(=), :($outStt.previous), eval(inStt)))
                eval(Expr(:(=), :($inStt.next), [eval(outStt), 1/n]))
    end end end

    function combustion_chamber(inStt, outStt)
        inStt = Any[i.name for i in inStt]
        outStt = Any[i.name for i in outStt]
        MassFlow(inStt, outStt)
        inStt = inStt[1]
        outStt = outStt[1]
        newEq(:($outStt.p = $inStt.p), [1, 3])

        push!(Qflex, Any[[inStt], [outStt],
        string("combustion_chamber: ", string(inStt), " >> ", string(outStt))])
        push!(qflex, Any[[inStt], [outStt],
        string("combustion_chamber: ", string(inStt), " >> ", string(outStt))])     
    end

    function heater_exchanger(inStt, outStt, effect = nothing)
        inStt = Any[i.name for i in inStt]
        outStt = Any[i.name for i in outStt]
        push!(closedInteractions, inStt)
        for i in 1:length(inStt)
            MassFlow([inStt[i]], [outStt[i]], true)
            newEq(:($(outStt[i]).p = $(inStt[i]).p), [1, 3])
        end
        
        push!(Qflex, Any[inStt, outStt,
        string("heater_exchanger: ", string(inStt), " >> ", string(outStt))])
        push!(qflex, Any[inStt, outStt,
        string("heater_exchanger: ", string(inStt), " >> ", string(outStt))]) 

        if effect == :find
            EnergyBalance(inStt, outStt)

            indexProp = length(stAux) + 1       
            createState(Expr(:ref, :stAux, indexProp))
            
            push!(fluidEq, [Expr(:ref, :stAux, indexProp), :($(inStt[2]).cycleInfos), :($(inStt[2]).fluid)])
            newEq(:($(Expr(:ref, :stAux, indexProp)).T = $(inStt[1]).T), [1, 3])
            newEq(:($(Expr(:ref, :stAux, indexProp)).p = $(inStt[2]).p), [1, 3])

            push!(findVariables, Any[:(($(outStt[1]).h - $(inStt[1]).h) /
            (($(inStt[2]).h - $(Expr(:ref, :stAux, indexProp)).h) * 
            ($(inStt[2]).m / $(inStt[1]).m))),
            string("effectiveness of [heater_exchanger: ",
            string(inStt), " >> ", string(outStt),"]"), nothing, nothing, 2])
            
            return
        end
    
        if !isnothing(effect) && length(inStt) == 2 && length(outStt) == 2   
            indexProp = length(stAux) + 1       
            createState(Expr(:ref, :stAux, indexProp))
            
            push!(fluidEq, [Expr(:ref, :stAux, indexProp), :($(inStt[2]).cycleInfos), :($(inStt[2]).fluid)])
            newEq(:($(Expr(:ref, :stAux, indexProp)).T = $(inStt[1]).T), [1, 3])
            newEq(:($(Expr(:ref, :stAux, indexProp)).p = $(inStt[2]).p), [1, 3])
    
            effect /= 100
            
            newEq(:($(outStt[1]).h = $(inStt[1]).h + ($(inStt[2]).m / $(inStt[1]).m) * $effect *
            ($(inStt[2]).h - $(Expr(:ref, :stAux, indexProp)).h)))

            newEq(:($(outStt[2]).h = $(inStt[2]).h - $effect *
            ($(inStt[2]).h - $(Expr(:ref, :stAux, indexProp)).h)))
        else
            EnergyBalance(inStt, outStt)
        end
    end

    function separator(inStt, outStt)
        inStt = Any[i.name for i in inStt]
        outStt = Any[i.name for i in outStt]
        MassFlow(inStt, outStt)
        states = [inStt..., outStt...]
        for i in 1:(length(states) - 1)
            newEq(:($(states[i]).p = $(states[i + 1]).p), [1, 3])
        end
        if length(states) > 2
            newEq(:($(states[end]).p = $(states[1]).p), [1, 3])
        end
        if length(outStt) != 2
            # println("ERROR")
        end
        newEq(:($(outStt[1]).Q = 1), [1, 3])
        newEq(:($(outStt[2]).Q = 0), [1, 3])
        newEq(:($(outStt[1]).m = $(inStt[1]).Q * $(inStt[1]).m))
        newEq(:($(outStt[2]).m = $(inStt[1]).m - $(outStt[1]).m))        
    end

    function PrintResultsTxt()
        for i in 1:length(Cycles)
            TitleTxt = string(i,"- ")
            if itsRefrigeration
                TitleTxt = string(TitleTxt, "REFRIGERATION ")
            end
            if Cycles[i].states[1].cycleInfos[1] == 0
                TitleTxt = string(TitleTxt, "STEAM")
            else
                TitleTxt = string(TitleTxt, "GAS")
            end
            TitleTxt = string(TitleTxt, " CYCLE [", Cycles[i].states[1].fluid, "]")

            println("─────────────────────────────────────────────────────────────────────────────────────────────")
            println("                       ──────────────────────────────────────────────\n",
                    "                                     ", TitleTxt ,"\n",
                    "                       ──────────────────────────────────────────────")

            DataStates = Any[]
            for j in Cycles[i].states
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
            pretty_table(alignment=:l, linebreaks=true, DataStates; header=(
                ["State", "T", "P", "h", "s", "x", "ṁ", "Mass-flux"],
                ["Name", "[K]", "[kPa]", "[kJ/kg]", "[kJ/kg.K]", "", "[kg/s]", "fraction"]
                ))

            allValues = Any[[Cycles[i].properties.qin, Cycles[i].properties.Qin], [Cycles[i].properties.qout, Cycles[i].properties.Qout],
             [Cycles[i].properties.win, Cycles[i].properties.Win], [Cycles[i].properties.wout, Cycles[i].properties.Wout]]
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
            pretty_table(alignment=:l, linebreaks=true, body_hlines = [1,2,3,4], tempData; header=["", "Total", "Component", "Value"])
            
            if !isnothing(Cycles[i].properties.n)
                effTxt2 = ""
                effTxt = ""
                if itsRefrigeration
                    effTxt = "Coefficient of performance (COP) = "
                else
                    effTxt2 = " %"
                    effTxt = "Thermal efficiency (n) = "
                end
                
                println("
                ┌───────────────────────────────────────────────────────────────────────────┐
                                    ", effTxt, round(Cycles[i].properties.n, digits=4), effTxt2,"
                └───────────────────────────────────────────────────────────────────────────┘
                ")        
            end
        end
        if length(Cycles) > 1
            println("─────────────────────────────────────────────────────────────────────────────────────────────")
            println("─────────────────────────────────────────────────────────────────────────────────────────────")
            println(
                "                          ┌──────────────────────────────────────────────┐\n",
                "                          │┌────────────────────────────────────────────┐│\n",
                "                          ││             SYSTEM PROPERTIES:             ││\n",
                "                          │└────────────────────────────────────────────┘│\n",
                "                          └──────────────────────────────────────────────┘")
            
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
            pretty_table(alignment=:l, linebreaks=true, body_hlines = [1,2,3,4], tempData; header=["", "Total", "Component", "Value"])
            
            if !isnothing(System.n)
                effTxt = ""
                effTxt2 = ""
                if itsRefrigeration
                    effTxt = "Coefficient of performance (COP) = "
                else
                    effTxt = "Thermal efficiency (n) = "
                    effTxt2 = " %"
                end
                
                println("
                ┌───────────────────────────────────────────────────────────────────────────┐
                        ┌────────────────────────────────────────────────────────┐
                                    ", effTxt, round(System.n, digits=4), effTxt2,"
                        └────────────────────────────────────────────────────────┘
                └───────────────────────────────────────────────────────────────────────────┘
                ")     
            end
        end

        if length(findVariables) > 0
            println("                       ──────────────────────────────────────────────\n",
                    "                               calculated component properties\n",
                    "                       ──────────────────────────────────────────────")
            for i in findVariables
                println()
                if length(i) == 2
                    println(i[2], " = ", round(i[1], digits=4), "%")
                else
                    println(i[4], " = not found")
                end
        end end        
    end

    function TSGraph(cycles)
        p = plot()
        for c in cycles
            flow = [[i[3], i[2]] for i in MassEq1]
            FlowGraph = Any[]
            for i in flow
                for j in i[1]
                    if j in CyclesStts[c]
                        push!(FlowGraph, Any[j, i[2]])
                    end
            end end
    
            states = Cycles[c].states
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
            fluidTemp = Cycles[c].states[1].fluid
    
            if Cycles[c].states[1].cycleInfos[1] == 0 #Steam
    
                AlltRange = Any[Cycles[c].states[1].T, Cycles[c].states[1].T]
                for i in Cycles[c].states
                    if i.T > AlltRange[2]
                        AlltRange[2] = i.T
                    end
                    if i.T < AlltRange[1]
                        AlltRange[1] = i.T
                    end
                end
                sizeRangeT = AlltRange[2] - AlltRange[1]
    
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
    
                ########################################################
    
    
                for i in FlowGraph
                    t = Any[]
                    s = Any[]
                    st1 = eval(i[1])
                    st2 = eval(i[2])
                
                    push!(t, st1.T)
                    push!(s, st1.s)
                
                    if st1.p == st2.p
                        tQ0 = PropsSI("T", "P", st2.p * 1000, "Q", 0, fluidTemp)
                        ttemp = st1.T
                        if abs(ttemp - st2.T) < 0.5
                            push!(t, st2.T)
                            push!(s, st2.s)                    
                        elseif ttemp < st2.T
                            count = 0
                            while count < 250
                                count += 1
                                if ttemp == tQ0 && s[end] != PropsSI("S", "P", st2.p * 1000, "Q", 1, fluidTemp)/1000                    
                                    if st2.T > tQ0
                                        push!(t, tQ0)
                                        push!(s, PropsSI("S", "P", st2.p * 1000, "Q", 1, fluidTemp)/1000)
                                    else
                                        # if st2.Q < 0
                                        #     push!(t, st2.T)
                                        #     push!(s, st2.s)
                                        # end
                                        break
                                    end
                                elseif ttemp < tQ0
                                    ttemp0 = ttemp
                                    TRound = round(Int, (tQ0-ttemp0) / 70)
                                    for j in 1:TRound
                                        tTemp = ttemp0 + j/(TRound+1) * (tQ0-ttemp0)
                                        push!(t, tTemp)
                                        push!(s, PropsSI("S", "P", st2.p * 1000, "T", tTemp, fluidTemp)/1000)
                                    end
                                    push!(t, tQ0)
                                    push!(s, PropsSI("S", "P", st2.p * 1000, "Q", 0, fluidTemp)/1000)
                                    ttemp = tQ0 
                                elseif ttemp >= tQ0
                                    ttemp0 = ttemp
                                    TRound = round(Int, (st2.T-ttemp0) / 10)
                                    for j in 1:TRound
                                        tTemp = ttemp0 + j/TRound * (st2.T-ttemp0)
                                        push!(t, tTemp)
                                        push!(s, PropsSI("S", "P", st2.p * 1000, "T", tTemp, fluidTemp)/1000)
                                    end
                                    break
                                end
                            end
                        elseif ttemp > st2.T
                            count = 0
                            while count < 250
                                count += 1
                                if ttemp == tQ0 && s[end] != PropsSI("S", "P", st2.p * 1000, "Q", 0, fluidTemp)/1000
                                    if st2.T < tQ0
                                        push!(t, tQ0)
                                        push!(s, PropsSI("S", "P", st2.p * 1000, "Q", 0, fluidTemp)/1000)
                                    else
                                        # if abs(st2.T - tQ0) > 0.5
                                        #     push!(t, st2.T)
                                        #     push!(s, st2.s)
                                        # end
                                        push!(t, st2.T)
                                        push!(s, st2.s)
                                        break
                                    end
                                elseif ttemp <= tQ0
                                    ttemp0 = ttemp
                                    TRound = round(Int, (st2.T-ttemp0) / 70)
                                    for j in 1:TRound
                                        tTemp = ttemp0 + j/(TRound+1) * (st2.T-ttemp0)
                                        push!(t, tTemp)
                                        push!(s, PropsSI("S", "P", st2.p * 1000, "T", tTemp, fluidTemp)/1000)
                                    end
                                    break
                                elseif ttemp > tQ0
                                    ttemp0 = ttemp
                                    TRound = round(Int, (tQ0-ttemp0) / 10)
                                    for j in 1:TRound
                                        tTemp = ttemp0 + j/TRound * (tQ0-ttemp0)
                                        push!(t, tTemp)
                                        push!(s, PropsSI("S", "P", st2.p * 1000, "T", tTemp, fluidTemp)/1000)
                                    end
                                    push!(t, tQ0)
                                    push!(s, PropsSI("S", "P", st2.p * 1000, "Q", 1, fluidTemp)/1000)
                                    ttemp = tQ0 
                                end
                            end
                        end        
                    else
                        if abs(st1.h-st2.h) < 1
                            TRound = round(Int, abs(st2.s-st1.s) / 0.005)
                            for j in 1:TRound
                                tTemp = st1.s + j/(TRound+1) * (st2.s-st1.s)
                                push!(s, tTemp)
                                push!(t, PropsSI("T", "H", st2.h * 1000, "S", tTemp * 1000, fluidTemp))
                            end
                        elseif length(cycles) == 1
                            newT = PropsSI("T", "P", st2.p * 1000, "S", st1.s * 1000, fluidTemp)
                            newC = RGBA{Float64}(colors[2].r, colors[2].g, colors[2].b, 0.5)
                            plot!([st1.s, st1.s], [st1.T, newT], lw=1, ls=:dash, color = newC)
                        end
                        push!(t, st2.T)
                        push!(s, st2.s)
                    end
                
                    plot!(s, t, color = colors[2])
                end            
                plot!(legend = false, grid = false,
                xlabel = "s [kJ/kg.K]", ylabel = "T [K]")
    
                
                if length(cycles) == 1
                    pressureRanges = Any[]
                    for i in Cycles[c].states
                        if !(i.p in pressureRanges)
                            push!(pressureRanges, i.p)
                        end
                    end
    
                    for k in pressureRanges
                        tRange = Any[-1, -1]
                        for i in Cycles[c].states
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
                        if PropsSI("Tmax", fluidTemp) < tRange[2] 
                            tRange[2] = PropsSI("Tmax", fluidTemp)
                        end
    
                        t = Any[]
                        s = Any[]
                        tQ01 = PropsSI("T", "P", k * 1000, "Q", 0, fluidTemp)
                        TRound = max(10, round(Int, (tRange[2]-tRange[1]) / 50))
                        checkPoint = false
                        for j in 1:TRound
                            tTemp = tRange[1] + j/(TRound+1) * (tRange[2]-tRange[1])
    
                            if !checkPoint && tTemp >= tQ01
                                checkPoint = true
    
                                push!(t, tQ01)
                                push!(s, PropsSI("S", "P", k * 1000, "Q", 0, fluidTemp)/1000)
    
                                push!(t, tQ01)
                                push!(s, PropsSI("S", "P", k * 1000, "Q", 1, fluidTemp)/1000)
    
                                if tTemp == tQ01
                                    continue
                                end
                            end
                            
                            push!(t, tTemp)
                            push!(s, PropsSI("S", "P", k * 1000, "T", tTemp, fluidTemp)/1000)
                        end
    
                        newC = RGBA{Float64}(colors[2].r, colors[2].g, colors[2].b, 0.4)
                        plot!(s, t, lw=1, color = newC)
                        txtP = string(round(Int, k), " KPa")
                        annotate!(s[end], t[end], text("█"^(length(txtP)÷2+1), :white, :center, :center, 6, rotation = 45))
                        annotate!(s[end], t[end], text(txtP, txtColor, :center, :center, 5, rotation = 45))
                    end            
                end
    
            else #gas
                for i in FlowGraph
                    t = Any[]
                    s = Any[]
                    st1 = eval(i[1])
                    st2 = eval(i[2])
                
                    push!(t, st1.T)
                    push!(s, st1.s)
                    if st1.p == st2.p
                        TRound = round(Int, abs(st2.T-st1.T) / 0.005)
                        for j in 1:TRound
                            tTemp = st1.T + j/(TRound+1) * (st2.T-st1.T)
                            push!(t, tTemp)
                            push!(s, GetGasEntropy(tTemp, st1.p, st1.fluid))
                        end
                    else
                        if length(cycles) == 1
                            # newT = PropsSI("T", "P", st2.p * 1000, "S", st1.s * 1000, fluidTemp)
                            # push!(s, GetGasEntropy(tTemp, k, fluidTemp))
                            R = props[lowercase(fluidTemp)][1]
                            specific_heat = props[lowercase(fluidTemp)][2]
                            # S =  specific_heat * log(T) - R * log(p / 101.325)
                            newT = ℯ^((st1.s - R * log(101.325) + R * log(st2.p)) / specific_heat)
                            newC = RGBA{Float64}(colors[2].r, colors[2].g, colors[2].b, 0.5)
                            plot!([st1.s, st1.s], [st1.T, newT], lw=1, ls=:dash, color = newC)
                        end
                    end
                
                    push!(t, st2.T)
                    push!(s, st2.s)
                    plot!(s, t, color = colors[2])
                end            
                plot!(legend = false, grid = false,
                xlabel = "s [kJ/kg.K]", ylabel = "T [K]")   
                
                if length(cycles) == 1
                    pressureRanges = Any[]
                    for i in Cycles[c].states
                        if !(i.p in pressureRanges)
                            push!(pressureRanges, i.p)
                        end
                    end
    
                    AlltRange = Any[Cycles[c].states[1].T, Cycles[c].states[1].T]
                    for i in Cycles[c].states
                        if i.T > AlltRange[2]
                            AlltRange[2] = i.T
                        end
                        if i.T < AlltRange[1]
                            AlltRange[1] = i.T
                        end
                    end
                    sizeRangeT = AlltRange[2] - AlltRange[1]
    
                    for k in pressureRanges
                        tRange = Any[-1, -1]
                        for i in Cycles[c].states
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
    
                        tRange[2] += sizeRangeT * 0.3
                        tRange[1] -= sizeRangeT * 0.15
    
                        t = Any[]
                        s = Any[]
                        TRound = round(Int, (tRange[2]-tRange[1]) / 50)
                        for j in 1:TRound
                            tTemp = tRange[1] + j/(TRound+1) * (tRange[2]-tRange[1])
                            push!(t, tTemp)
                            push!(s, GetGasEntropy(tTemp, k, fluidTemp))
                        end
    
                        newC = RGBA{Float64}(colors[2].r, colors[2].g, colors[2].b, 0.4)
                        plot!(s, t, lw=1, color = newC)
                        txtP = string(round(Int, k), " KPa")
                        annotate!(s[end], t[end], text("█"^(length(txtP)÷2+1), :white, :center, :center, 6, rotation = 45))
                        annotate!(s[end], t[end], text(txtP, txtColor, :center, :center, 5, rotation = 45))
                    end            
                end
            end
    
        end
        return p
    end
    
    function PrintResults()
        str = Any[]
        for i in 1:length(CycleSolver.Cycles)
            TitleTxt = string(i,"- ")
            if CycleSolver.itsRefrigeration
                TitleTxt = string(TitleTxt, "REFRIGERATION ")
            end
            if CycleSolver.Cycles[i].states[1].cycleInfos[1] == 0
                TitleTxt = string(TitleTxt, "STEAM")
            else
                TitleTxt = string(TitleTxt, "GAS")
            end
            TitleTxt = string(TitleTxt, " CYCLE [", CycleSolver.Cycles[i].states[1].fluid, "]")
    
            TitleTxt = string("<h1 style='display: block; text-align: center; border: 1px solid #666666;",
            "margin: -17px; margin-bottom: 20px; padding: 10px'>", TitleTxt,"</h1>")
            #####################################################
            DataStates = Any[]
            for j in CycleSolver.Cycles[i].states
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
            allValues = Any[[CycleSolver.Cycles[i].properties.qin, CycleSolver.Cycles[i].properties.Qin], [CycleSolver.Cycles[i].properties.qout, CycleSolver.Cycles[i].properties.Qout],
             [CycleSolver.Cycles[i].properties.win, CycleSolver.Cycles[i].properties.Win], [CycleSolver.Cycles[i].properties.wout, CycleSolver.Cycles[i].properties.Wout]]
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
            if !isnothing(CycleSolver.Cycles[i].properties.n)
                effTxt2 = ""
                effTxt = ""
                if CycleSolver.itsRefrigeration
                    effTxt = "Coefficient of performance (COP) = "
                else
                    effTxt2 = " %"
                    effTxt = "Thermal efficiency (n) = "
                end
                nc = string("<h3 style='text-align: center; border: 2px solid #666666; padding: 15px; margin: 10px;'>",
                effTxt, round(CycleSolver.Cycles[i].properties.n, digits=4), effTxt2, "</h3>")                    
            end
    
            #####################################################
            plotHTML = sprint(show, "text/html", TSGraph([i]))
    
            #####################################################
    
            push!(str, string("<div style='display: inline-block; padding: 15px; margin: 20px;
            border: 2px solid #666666;'>\n", TitleTxt,
            "<div style='display: flex; justify-content: space-around;'>", propsTb1, "</div>",
            "<div style='display: flex; justify-content: space-around;
            padding: 10px; margin: 10px;'>", plotHTML, "</div>",
            "<div style=' border: 1px solid;'>",
            "<h3 style='text-align: center;margin: 8px;'>Cycle Properties:</h3>",
            "<div style='display: flex; justify-content: space-around;'>", propsTb2, "</div>",
            nc,
            "</div>",
            "\n</div></br>"))
            
        end
    
        perCycle = ""
        for i in str
            perCycle = string(perCycle, i)
        end
    
    
        if length(CycleSolver.Cycles) > 1        
            allValues = Any[[CycleSolver.System.qin, CycleSolver.System.Qin], [CycleSolver.System.qout, CycleSolver.System.Qout],
            [CycleSolver.System.win, CycleSolver.System.Win], [CycleSolver.System.wout, CycleSolver.System.Wout]]
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
            if !isnothing(CycleSolver.System.n)
                effTxt = ""
                effTxt2 = ""
                if CycleSolver.itsRefrigeration
                    effTxt = "Coefficient of performance (COP) = "
                else
                    effTxt = "Thermal efficiency (n) = "
                    effTxt2 = " %"
                end
                nc = string("<h2 style='text-align: center; border: 3px solid; padding: 15px; margin: 10px;'>",
                effTxt, round(CycleSolver.System.n, digits=4), effTxt2, "</h2>")   
            end
    
            plotHTML = sprint(show, "text/html", TSGraph(collect(1:length(CycleSolver.Cycles))))
    
            perCycle = string(perCycle, 
                        "<div style=\"display: inline-block; padding: 15px; margin: 20px;",
                        "border: 2px solid;\"><h1 style=\"text-align: center;
                        margin: -8px;\">SYSTEM PROPERTIES</h1>",
                        "<div style='display: flex; justify-content: space-around;
                        padding: 10px; margin: 10px;'>", plotHTML, "</div>",
                        "<div style=' border: 1px solid;'>",
                        "<div style='display: flex; justify-content: space-around; margin: 20px;'>",
                        propsTb3,
                        "</div>", nc, "</div>"
                        )
        end
        
        if length(CycleSolver.findVariables) > 0
            componentsTxt = "<h2 style=\"text-align: center;
                        margin: -8px;\">Calculated Component Properties</h2>"
    
            for i in CycleSolver.findVariables
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
end