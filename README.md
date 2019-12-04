# Backtest v3
Further evolution of ["Magic formula" backtest](https://github.com/Tim-K-DFW/vultures_ruby), short only, added 3rd factor, added sector constraints, parametrized factor weights


#### Business case

Assess potential on the short side and add several enhancements.

#### Key features (diffs vs v2)

- short-only
- added third factor
- added user's ability to allocate factor weights
- added user's ability to allocate portfolio weights between industry sectors.

#### Design/code aspects (diffs vs v2)

- more work and discoveries on best ways to preprocess and store input data at higher frequencies
- switch from CLI inputs to YAML files for parameter specification.
