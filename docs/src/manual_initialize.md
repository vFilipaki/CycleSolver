# Initialize a cycle

The function `newCycle[]` starts a cycle using water as the working fluid and without a known mass flow.

### Cycle fluid change

The change in the working fluid is done in the cycle start command, inserting the new fluid between square brackets at the end of the command.
For example, changing the fluid to R134a: `newCycle[R134a]`.

### Define the main mass flow of the cycle

The definition of the mass flow is also done in the cycle initialization command, right after defining the working fluid of the cycle, inside the square brackets the value to be assigned is inserted after a colon sign. For example, for mass flow of 2.5 Kg/s and water as the working fluid: `newCycle[water: 2.5]`.