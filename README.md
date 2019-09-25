# phylostan: phylogenetic inference using Stan

## Introduction

*phylostan* is a tool written in python for inferring phylogenetic trees from nucleotide datasets. 
It generates a variety of phylogenetic models using the Stan language.
 Through the pystan library, *phylostan* has access to Stan's variational inference and sampling (NUTS and HMC) engines.
The program has been described and its performance evaluated in a [preprint](https://doi.org/10.1101/702944). The data and scripts used to generate the results can be found [here](examples/README.md).

## Features
Phylogenetic model components:
- Nucleotide substitution models: JC69, HKY, GTR
- Rate heterogeneity: discretized Weibull distribution and general discrete distribution
- Tree without clock constraint with uniform prior on topology
- Time tree:
  - Homochronous sequences: same sampling date
  - Heterochronous sequences: sequences sampled at different time points
 - Molecular clocks:
   - Strict
   - [Autocorrelated](https://doi.org/10.1093/oxfordjournals.molbev.a025892)
   - [Uncorrelated](https://dx.doi.org/10.1371%2Fjournal.pbio.0040088): log-normal hierarchical prior
 - Coalescent models:
   - Constant population size
   - [Skyride](https://doi.org/10.1093/molbev/msn090)
   - [Skygrid](https://doi.org/10.1093/molbev/mss265)

Algorithms provided by Stan:
- Variational inference:
  - Mean-field distribution
  - Full-rank distribution
- No U-Turn Sampler ([NUTS](https://arxiv.org/abs/1111.4246))
- Hamiltonian Monte Carlo (HMC)

## Prerequisites

| Program/Library    | Version | Description |
|----------- | --------| -- |
| python | Tested on python 2.7, 3.5, 3.6, 3.7           | |
| [pystan](https://pystan.readthedocs.io/)    | >=2.19 | API for [Stan](https://mc-stan.org) |
| [dendropy](https://www.dendropy.org)      |   | Library for manipulating trees and alignments|
| numpy   | >=1.7    | |


## You can install phylostan using pip
```bash
pip install phylostan
```

## You can also run it locally
```bash
python -m phylostan.phylostan <COMMAND>
```
where `<COMMAND>` is either the *build* or *run* command.

## Command-line usage

*phylostan* is decomposed into two sub-commands:
- *build*: creates a Stan file: a text file containing the model.
- *run*: runs a Stan file with the data.

These two steps are separated so the user can edit the Stan model. The main reason would be to modify the priors.

To get some help about the *build* or *run* commands:
```bash
phylostan build --help
phylostan run --help
```

## Quickstart

We are going to use the `fluA.fa` alignment and `fluA.tree` tree files. This dataset contains 69 influenza A virus haemagglutinin nucleotide sequences isolated between 1981 and 1998.  

First, a Stan script needs to be generated using the *build* command:
```bash
cd examples/fluA
phylostan build -s fluA-GTR-W4.stan  -m HKY -C 4 \
 --heterochronous --estimate_rate --clock strict --coalescent constant
```

This command is going to create a Stan file `fluA-GTR-W4.stan` with the following model:
- Hasegawa, Kishino and Yano (HKY) nucleotide substitution model
- Rate heterogeneity with 4 rate categories using the Weibull distribution
- Assumes that sequences were sampled are different time points (heterochronous)
- Constant effective population size
- The substitution rate will be estimated

In the second step we compile and run the script with our data
```bash
phylostan run -s fluA-GTR-W4.stan  -m HKY -C 4 \
 --heterochronous --estimate_rate --clock strict --coalescent constant \
 -i fluA.fa -t fluA.tree -o fluA -q meanfield
```

The *run* command requires the data (tree and alignment) and an output parameter.
It also needs the parameters that were provided to the *build* command.
The output will consists of 4 files:
- `fluA`: this file is the output file of Stan. It contains the samples drawn from the variational distribution (or MCMC samples).
- `fluA.diag`: this file is also generated by Stan and it contains some information such as the ELBO at each iteration.
- `fluA.trees`: this file is a nexus file containing trees. It can be opened with a program such as [FigTree](https://github.com/rambaut/figtree) or summarized using *treeannotator* from [BEAST](https://beast.community/treeannotator) or [BEAST2](https://www.beast2.org/treeannotator/).
- `fluA-GTR-W4.pkl`: the Stan script is compiled into this binary file. This file can be reused automatically by *phylostan* unless it must be recompiled, then the option `--compile` can be used.

At the end of the run, *phylostan* will print on the screen the mean and 95% credibility interval of the parameters of interest:
```
Weibull (shape) mean: 0.488 95% CI: (0.383,0.616)
Strict clock (rate) mean: 0.00499 95% CI: (0.00432,0.00577)
Constant population size (theta) mean: 4.03 95% CI: (3.14,5.05)
HKY (kappa) mean: 5.58 95% CI: (4.37 7.039)
Root height mean: 18.96 95% CI: (18.36 19.74)
```
In this example we have used a mean-field distribution (`-q meanfield`) to approximate the posterior using variational inference.
The Stan model is already compiled so we can run the NUTS algorithm without re-generating the script file, simply issue the command:
```bash
phylostan run -s fluA-GTR-W4.stan  -m HKY -C 4 \
 --heterochronous --estimate_rate --clock strict --coalescent constant \
 -i fluA.fa -t fluA.tree -o fluA -a nuts
```

The NUTS algorithm is much slower (and more accurate) than variational inference so it should be used on a small dataset.

## Reference
Mathieu Fourment and Aaron E. Darling. Evaluating probabilistic programming and fast variational Bayesian inference in phylogenetics. _bioRxiv_. doi: [10.1101/702944](https://doi.org/10.1101/702944). 