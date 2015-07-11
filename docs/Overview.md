# Introduction

This toolbox is a development environment for online spike sorting of raw voltage traces. Spike sorting methods are designed by combining modular 1) detection, 2) alignment, 3) feature extraction, and 4) clustering stages. These modules have been constructed from algorithms described in the literature, optimized for speed, and designed such the outputs of one stage are compatible with any of the implementations of the following stage.

# Implementation

The main data structure, Sorting, is a composite type, that contains all of the variables necessary for detection, alignment, feature extraction and clustering, as well as all of the variables to hold the detected waveforms, spike times, and those necessary for transitioning from one block of signal into another. Because different algorithms in each stage require different storage for calculations, every algorithm will define its own type. For example:

type DetectPower <: Detect
	a::Int64
	b::Int64
	c::Int64
end

type FeatureTime <: Feature
end

Each of these types will inherit from one of four abstract types: Detect, Align, Feature, or Cluster. Therefore, when an instance of Sorting is created, it will be described by a unique combination of 4 concrete types that each derive from a corresponding abstract types. For example

s=Sorting(DetectPower(),ClusterOSort(),AlignMax(),FeatureTime())

The toolbox takes advantage of Julia's multiple dispatch to automatically select the appropriate algorithms for detection, alignment, feature extraction and clustering based on the types characterizing each instance of Sorting.


