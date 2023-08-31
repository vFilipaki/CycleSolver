# Brayton Cycle

!!! note "Cycle data"
    > ![](./assets/ex4.png) 

    !!! ukw "Known properties"
        - Air is used as working fluid;
        - Pressure at the compressor inlet 100 kPa;
        - Temperature at the compressor inlet 20 °C;
        - Pressure ratio equal to 7;
        - Temperature at the turbine inlet 500 °C;
        - The turbine and compressor have an isentropic efficiency of 90%.


!!! compat "Input code"
    ```julia
    CycleSolver.@solve begin
            st2.p / st1.p = 7
            st1.T = 20 + 273
            st1.p = 100
            st3.T = 500 + 273  
            newCycle[Air] 
                compressor(st1, st2, 90)
                combustion_chamber(st2, st3)
                turbine(st3, st4, 90)
                combustion_chamber(st4, st1)
    end

    CycleSolver.PrintResults()
    ```

