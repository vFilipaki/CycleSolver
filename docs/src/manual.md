# Manual


## Define known properties

To define properties that are already known to the system, you must specify the state and symbol of the known property, following the table below.

> | Property thermodynamics        | Unit                 | Symbol of attributes of the state    |
> | :---             | ---:                 | :---:                   |
> | Temperature      | K                    | .T                      |
> | Pressure         | kPa                  | .p                      |
> | Enthalpy         | kJ/kg                | .h                      |
> | Entropy          | kJ/kg.K              | .s                      |
> | Quality          |                      | .Q                      |
> | Density          | kg/m^3               | .rho                    |
> | Mass flow        | kg/s                 | .m                      |

Based on this, to assign the properties, the name of the state is concatenated with the symbol of the known attribute, followed by the equal sign and the value to be assigned, taking into account the units of each property.

## Initialize a cycle

The function `newCycle[]` starts a cycle using water as the working fluid and without a known mass flow.

#### Cycle fluid change

The change in the working fluid is done in the cycle start command, inserting the new fluid between square brackets at the end of the command.
For example, changing the fluid to R134a: `newCycle[R134a]`.

#### Define the main mass flow of the cycle

The definition of the mass flow is also done in the cycle initialization command, right after defining the working fluid of the cycle, inside the square brackets the value to be assigned is inserted after a colon sign. For example, for mass flow of 2.5 Kg/s and water as the working fluid: `newCycle[water: 2.5]`.

## Cycle structure

After initialization, the structure of the cycle is created, using named functions based on the components they represent and the input state of the component being informed in the first parameter of the function and the output state being informed in the second parameter.

> #### List of components:
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
> - heater_exchanger(inState, outState, optionalEffectiveness)
> - separator(inState, outState)

#### Components with more than one input or output state

For the definition that the component has multiple input or output states, the states are inserted into a list, which will be the input or output parameter of the component. For example a mix with two input states, st1 and st2, and an output state st3: `mix([st1, st2], st3)`.

#### Efficiency and effectiveness

In order to include the efficiency and effectiveness of the components in the cycle schedule, the percentage value is defined in the third parameter of the component function, after defining the input and output states. For example, a turbine with input and output states, st1 and st2, and isentropic efficiency of 90%: `turbine(st1, st2, 90)`.