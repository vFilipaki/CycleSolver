# Cycle structure

After initialization, the structure of the cycle is created, using named functions based on the components they represent and the input state of the component being informed in the first parameter of the function and the output state being informed in the second parameter.

> ### List of components:
> - pump(inState, outState, optionalEfficiency)
> - turbine(inState, outState, optionalEfficiency)
> - condenser(inState, outState)
> - boiler(inState, outState)
> - evaporator(inState, outState)
> - evaporator_condenser(inState, outState)
> - expansion_valve(inState, outState)
> - flash_chamber(inState, outState)
> - heater_closed(inState, outState)
> - heater_open(inState, outState)
> - mix(inState, outState)
> - div(inState, outState)
> - process_heater(inState, outState)
> - compressor(inState, outState, optionalEfficiency)
> - combustion_chamber(inState, outState)
> - heater_exchanger(inState, outState, optionalEffectiveness, optionalHigherCapacityRate)
> - separator(inState, outState)
> - generic_component(inState, outState, optionalThermoProperties)

### Components with more than one input or output state

For the definition that the component has multiple input or output states, the states are inserted into a list, which will be the input or output parameter of the component. For example a mix with two input states, `st1` and `st2`, and an output state `st3`: `mix([st1, st2], st3)`.

### Efficiency and effectiveness

In order to include the efficiency and effectiveness of the components in the cycle schedule, the percentage value is defined in the third parameter of the component function, after defining the input and output states. For example, a turbine with input and output states, `st1` and `st2`, and isentropic efficiency of 90%: `turbine(st1, st2, 90)`.

### Heater Exchanger

In the `heater_exchanger`, there is also a fourth parameter that refers to the stream with the highest thermal capacity. If this information is known, it can be entered into this parameter, with a value of 1 for the stream that occupies the first index of the input and output parameters, and a value of 2 for the one that occupies the second index. If the stream with the highest thermal capacity is unknown, then leave the field blank.

### Generic Component

In the `generic component`, a component is created that simply connects the input and output states, and the relationships between these states and the thermodynamic properties of the component must be described manually.

The relationships between the states are established through equations that equate the properties of the states. Meanwhile, the thermodynamic properties are inputted in the third parameter of the component as a list of macros, where these macros represent equations. The following example illustrates the configuration of a `generic component`:

```julia
st1.p = st2.p
generic_component(st1, st2,[
    :(qin = st2.h - st1.h),
    :(Qin = st2.m * (st2.h - st1.h))
])
```


