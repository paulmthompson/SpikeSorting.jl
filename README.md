# SpikeSorting.jl
Online spike sorting methods in Julia

# Introduction

This is a Julia implementation of various spike sorting methods. Our initial goal is to have a system that can perform online sorting of data that is acquired via a Intan RHD2000 acquisition board:

https://github.com/paulmthompson/Intan.jl

Since Osort (http://www.urut.ch/new/serendipity/index.php?/pages/osort.html) was designed with algorithms for real time acquisition, we plan on adapting these methods first. We would like to eventually include other methods of sorting and greater flexibility for other data acquisition methods (and include offline analysis). We use planar arrays and don't have to worry about the same spikes on multiple electrodes, but we could one day add methods to account for this.

# Overview of (Intended) Implementation

Voltages from multi-electrode arrays are read from the Intan to computer in blocks in real time. These blocks (of n samples collected at 20000 Hz) are then fed to the spike sorter. First, a training peroid needs to take place, where things like signal to noise on each electrode are calculated. Then spikes are detected, aligned and sorted according to methods described in the Osort paper: http://www.urut.ch/pdfs/Rutishauser_2006a.pdf

# Current Functionality

* Calibration method can calculate thresholds for spike detection (power) and clustering
* Spikes are detected with a running local energy window that compares to the power threshold
* Candidate spikes are then compared to with existing clusters
* If the distance between the spike and an existing cluster is less than threshold from calibration, the spike is assigned to that cluster, and the cluster shape is updated with a weighted average (95% existing, 5% new spike).
* If the distance is greater than threshold, the spike is assigned to a new cluster
* List of spike timestamps and corresponding cluster index is returned

# TO DO

## Calibration

When data first starts being acquired, there is going to be a lot of action since the waveforms are not defined to start with. I think the adaptive Osort algorithm is great if there is some templates to start with, but might be pretty chaotic if it comes up with all of the waveforms itself. 

Might be good during the calibration period to determine the expected clusters for each channel, and not necessarily with osort methods since this is not "online" collection quite yet.

Also, there should be periodic "recalibration" where the thresholds are recalculated.

## Detection

Only spike detection based on power is implemented right now. Should at least add in support for thresholding the raw waveforms. Maybe try wavelet methods for detection (might be too slow though).

## Alignment

Right now alignment is done with a simple indmax. Need to add a few important steps:
* The paper describes more sophisticated approaches based on whether the peak is up or down.
* Currently no upsampling is used, but should be
* The paper also defines a "noise cluster" and just because a "spike" is detected, doesn't mean it will be assigned to an existing cluster or new one. Need to account for this.

## Sorting

Algorithm runs, but lots of stuff needs to be added.
* The clusters need to be compared with one another and if they are below a threshold, they should be merged together. Spikes that were assigned to one of the clusters (which would now be the same as another cluster) should be re-labeled
* The paper discusses how the success of the algorithm is based on accurate alignment, and that methods that are invariant to translation could provide improvements. Need to look into this.
* The paper also discusses how synchronous spikes were be categorized as unique clusters, rather than linear combinations of 2 already known clusters. This could be addressed (but maybe not in real time).

## User Interface
* The GUI for something like this is difficult because it needs to be super fast to provide real-time updating of plots while not slowing down the data that will be continuously streaming in. I don't know what the best solution Julia has for this at the moment.
* Whatever the UI looks like, it needs to have a pipeline that allows for supervised sorting. If the unsupervised algorithm does a crappy job, there needs to be a way to either have control over changing the mean waveform, or doing some totally supervised spike sorting, and essentially turning the automated algorithm off on that channel.
