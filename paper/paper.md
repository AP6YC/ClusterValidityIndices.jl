---
title: 'ClusterValidityIndices.jl: Batch and Incremental Metrics for Unsupervised Learning'
tags:
  - Julia
  - CVI
  - ICVI
  - Cluster Validity Indices
  - Cluster Validity Index
  - Incremental Cluster Validity Indices
  - Incremental Cluster Validity Index
  - Neural Networks
  - Machine Learning
  - Clustering
  - Metrics
authors:
  - name: Sasha Petrenko
    orcid: 0000-0003-2442-8901
    affiliation: 1
  - name: Donald C. Wunsch II
    orcid: 0000-0002-9726-9051
    affiliation: 1
affiliations:
  - name: Missouri University of Science and Technology
    index: 1
date: 1 June 2021
bibliography: paper.bib
---

# Summary

ClusterValidityIndices.jl is a Julia package for evaluating the performance of clustering algorithms without the aid of supervised labels.
Cluster Validity Indices (CVI) provide a metric of the over- or under-partitioning of an arbitrary clustering algorithm with only the original data and labels assigned by the clustering algorithm.
Furthermore, there exist formulations of every CVI such that they may run incrementally (i.e. Incremental CVIs, or ICVI), streaming alongside the clustering algorithm and producing the same results as in their batch implementations.
Using a standard interface, each CVI in this package can be run with any clustering algorithm to produce a metric of that algorithm's performance in scenarios where explicit supervised labels do not exist, which is extremely useful in real-world applications where that is often the case.

# Statement of need

CVIs are useful as one of the only methods of determining the performance of a clustering algorithm in the absence of explicit labels [@ARBELAITZ2013243].
Furthermore, ICVIs can measure the performance of clustering algorithms as they are running in a computationally tractable manner, which is incredibly useful in a variety of streaming clustering applications [@brito_da_silva_incremental_2020].

There exist many CVIs in the literature, and their algorithmic and programmatic requirements are often very similar.
Despite their utility in machine learning applications, however, there does not exist to date a unified repository of their implementations in Julia.
Furthermore, new incremental variations of these algorithms are regularly developed in the literature without the ability to update the original implementations.
The purpose of this package is to create a unified framework and repository of CVIs so as to fill the gap left by most metrics in this machine learning problem subset.

## Comparison to Existing Implementations

Many implementations of various CVIs exist as a result of reproducibility efforts in the literature for use by the machine learning research community.
However, each of these implementations vary in degrees of programming accessibility, language, number of implemented CVIs, and incremental variant implementations.
Due to gaps left by the incomplete feature overlap of existing CVI packages, the objective of this package is to make many batch and incremental CVIs available in a fast, free, open-source, and documented repository.

Researchers associated with the CRIStAL Laboratory of the University of Lille, France have implemented a CVI package in the MATLAB programming language for the reproducibility of a survey of CVIs [@cvik-toolbox-GitHub; @CVI_Survey_Garcia].
This repository contains a large variety of CVIs from the literature, though they are lacking their incremental variants.

A variety of CVIs are also implemented in a package for time series clustering in the R statistical computing language [@R_dtwclust].
However, these CVIs are implemented as a submodule of the R package rather than being standalone, impeding their visibility, and incremental variants are also not implemented.

Although each of these CVI projects and the very many and disparate implementations of individual CVIs in the literature combined may implement the majority of CVI algorithms relevant to modern research and engineering, together they lack cohesion in programming language and usage.
Furthermore, though software implementations in the MATLAB programming language are syntactically accessible, this is to the detriment of those in research and industry without a private MATLAB license.
In contrast, the R programming language is open and extremely powerful for research scientists and statisticians yet generally less suited for production environments.

The Julia programming langauge is selected for this open-source CVI package implementation due to its high-level syntactic ease of use and speed of development without comprimising computational efficiency for production environments.
Furthermore, the objective of this package is to contain both batch and incremental implementations of many CVIs with clear documentation and simple usage for research scientists and engineers alike.

# Acknowledgements

This package is developed and maintained with sponsorship by the Applied Computational Intelligence Laboratory (ACIL) of the Missouri University of Science and Technology.
This project is supported by grants from the Army Research Labs Night Vision Electronic Sensors Directorate (NVESD), the DARPA Lifelong Learning Machines (L2M) program, Teledyne Technologies, and the National Science Foundation.
The material, findings, and conclusions here do not necessarily reflect the views of these entities.

# References