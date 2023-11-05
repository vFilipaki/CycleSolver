# Results visualization

After the cycle's programming is performed within the macro `@solve`, the results can be presented through tables and graphs by calling the `PrintResults()` function.

### Visualization properties

For a better visualization of the system's graph, it's possible to add some attributes in its generation, modifications to the `PrintResults()` function, which is composed of two optional attributes: `PrintResults(graphs=1, showStateNames=true, multiplyEntropyByMass=false)`. 

* `graphs`: Defines which graphs will be displayed according to the number entered:
    1. Shows T-s graph.
    2. Shows P-h graph.
    3. Shows T-s and P-h graphs.


* `showStateNames`: Defines if the names of the states appeared in the generated T-s graphs.


* `multiplyEntropyByMass`: Defines if the cycle entropies will be multiplied by their mass flow.

### Access to properties

To access the resources for analyzing and manipulating data related to thermodynamic cycles, you can use the `CycleSolver.SystemCycles` command to obtain the list of cycles.

Each cycle has specific thermodynamic properties that can be accessed. For example, to obtain the thermodynamic properties of the cycle at index 1, simply use `CycleSolver.SystemCycles[1].thermoProperties`. Within these properties, you can access information such as the heat transfer into the cycle, represented by `CycleSolver.SystemCycles[1].thermoProperties.qin`, and the cycle efficiency, accessed with `CycleSolver.SystemCycles[1].thermoProperties.n`.

Furthermore, each cycle is composed of a series of thermodynamic states. To view the list of states in the cycle at index 1, the command `CycleSolver.SystemCycles[1].states` is used.

To access the specific properties of each state, in addition to the syntax presented earlier, it is also possible to obtain the properties with the command `CycleSolver.st1`, which provides access to the properties of the state identified as `st1`. To view the enthalpy of this state, simply use `CycleSolver.st1.h`.

It is important to note that if there is more than one cycle, in addition to the individual properties of each cycle, there will also be properties related to the system of cycles as a whole. These properties can be accessed through the command `CycleSolver.System`. The heat transfer into the system can be viewed with `CycleSolver.System.qin`, while the system efficiency is obtained through `CycleSolver.System.n`.

### Energy/Mass Imbalance and Entropy Generation

To visualize the Energy/Mass Imbalance and Entropy Generation, the `PrintImbalance function` is used, which displays these properties for each component and for the system. To access these properties through code, you can use the variable `CycleSolve.SystemImbalanceAndEntropyGeneration`, which is a list with three values, representing respectively, the Energy Imbalance, Mass Imbalance, and Entropy Generation.