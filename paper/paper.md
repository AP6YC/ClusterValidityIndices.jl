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

ClusterValidityIndices.jl is a Julia package for evaluating the performance the performance of clustering algorithms without the aid of supervised labels.
Cluster Validity Indices (CVI) provide a metric of the over- or under-partitioning of an arbitrary clustering algorithm with only the original data and labels assigned by the clustering algorithm.
Furthermore, there exist formulations of every CVI such that they may run incrementally (i.e. Incremental CVIs, or ICVI),streaming alongside the clustering algorithm and producing the same results as in their batch implementations.
Using a standard interface, each CVI in this package can be run with any clustering algorithm to produce a metric of that algorithm's performance in scenarios where explicit supervised labels do not exist, which is extremely useful in real-world applications where that is often the case.

# Statement of need

CVIs are useful as one of the only methods of determining the performance of a clustering algorithm in the absence of explicit labels.
Furthermore, ICVIs can measure the performance of clustering algorithms as they are running in a computationally tractable manner, which is incredibly useful in a variety of streaming clustering applications [@brito_da_silva_incremental_2020].

There exist many CVIs in the literature, and their algorithmic and programmatic requirements are often very similar.
Despite their utility in machine learning applications, however, there does not exist to date a unified repository of their implementations in Julia.
Furthermore, new incremental variations of these algorithms are regularly developed in the literature without the ability to update the original implementations.
The purpose of this package is to create a unified framework and repository of CVIs so as to fill the gap left by most metrics in this machine learning problem subset.

# Acknowledgements

This package is developed and maintained with sponsorship by the Applied Computational Intelligence Laboratory (ACIL) of the Missouri University of Science and Technology.
This project is supported by grants from the Army Research Labs Night Vision Electronic Sensors Directorate (NVESD), the DARPA Lifelong Learning Machines (L2M) program, Teledyne Technologies, and the National Science Foundation.
The material, findings, and conclusions here do not necessarily reflect the views of these entities.

# References