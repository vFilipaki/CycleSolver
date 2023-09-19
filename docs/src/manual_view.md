# Results visualization

After the cycle's programming is performed within the macro `@solve`, the results can be presented through tables and graphs by calling the `PrintResults()` function.

### Visualization properties

For a better visualization of the system's graph, it's possible to add some attributes in its generation, modifications to the `PrintResults()` function, which is composed of two optional attributes: `PrintResults(showStateNames=true, multiplyEntropyByMass=false)`. 

* `showStateNames`: Defines if the names of the states appeared in the generated T-s graphs.

* `multiplyEntropyByMass`: Defines if the cycle entropies will be multiplied by their mass flow.