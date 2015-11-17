
################
Getting Started
################

SpikeSorting.jl is a Julia implementation of many spike sorting algorithms for neural electrophysiology data. The goal of this project is to design a framework which allows for easy use in 1) real time applications, 2) large scale cluster computing and 3) benchmarking multiple methods against one another. The Julia Language keeps the syntax readible while also allowing for near C performance.

*********
Overview
*********

The process of "spike sorting" takes an analog, extracellular voltage trace, and determines what components of the signal correpond to electrical activity from nearby neurons. A general workflow for spike sorting would be to 1) detect canidate spikes 2) align candidate spikes 3) extract meaningful features from this signal 4) reduce the dimensionality from a high dimensional feature space to those dimensions which are most meaningful for discrimination and 5) clustering spikes with similar features.

SpikeSorting.jl employs this modular framework, such that one method in a step is compatible with most other existing methods in previous or subsequent steps. 

================
Data Structures
================

The primary data structure is the Sorting type, which contains the variables necessary for individual methods in the spike sorting workflow outlined above, as well as variables common to all of the methods. An instance of sorting is initialized by providing the desired method for each step in the workflow. For instance:

.. code-block:: julia

	detection=DetectPower() #Power-based spike detection
	alignment=AlignMax()	#Align candidate spikes by their maximum voltage
	feature=FeatureTime()	#Chose time varying voltage signal as feature
	reduction=Reduction()	#Use all time points for clustering steps
	cluster=ClusterOSort()	#OSort style clustering (compare clusters with candidate spikes by euclidean distance)

	mysort=Sorting(detection,cluster,alignment,feature,reduction)

In the example above, the detection container of type DetectPower will store all of the necessary variables for power-style detection to take place. Because of the modularity, these data containers can be relatively simple, as is the case with power detection:

.. code-block:: julia

	type DetectPower <: Detect
    		a::Int64
    		b::Int64
    		c::Int64
	end


=========
Workflow
=========

Most algorithms require some period of calibration, such as determining the appropriate threshold for detection, or the most discriminatory features to use for clustering. Therefore, some portion of data will need to be used for training. In real time acquisition, this would be the first data collected. For post hoc analysis, this would be some, or all of the data, and then the full dataset can be used after.

==========
Methods
==========

Unlike Python or C++, Julia does have object oriented programming; instead multiple dispatch can be used to call unique implementions of a method for different data types. 

************
Parallelism
************

If multiple channels of extracellular recordings are collected simultaneously, and these channels are sufficiently far apart, as is common with multi-electrode arrays, then the spike sorting of each channel could be considered "embarassingly parallel" whereby the sorting of one channel has no impact on another. Right now, SpikeSorting.jl is designed around this principle and can create a Distributed Array of multiple Sorting instances. In this way, each core of a computer or cluster "owns" all of the data in a collection of Sorting instances, and can quickly and independent process channels without message passing back and forth

===============
Implementation
===============

**********************
Real-Time Application
**********************



