# SpikeSorting.jl
Online spike sorting methods in Julia

# Introduction

This is a Julia implementation of various spike sorting methods. Our initial goal is to have a system that can perform online sorting of data that is acquired via a Intan RHD2000 acquisition board:

https://github.com/paulmthompson/Intan.jl

Since Osort (http://www.urut.ch/new/serendipity/index.php?/pages/osort.html) was designed with algorithms for real time acquisition, we plan on adapting these methods first. We would like to eventually include other methods of sorting and greater flexibility for other data acquisition methods (and include offline analysis). We use planar arrays and don't have to worry about the same spikes on multiple electrodes, but we could one day add methods to account for this.

# Overview of (Intended) Implementation

Voltages from multi-electrode arrays are read from the Intan to computer in blocks in real time. These blocks (of n samples collected at 20000 Hz) are then fed to the spike sorter. First, a training peroid needs to take place, where things like signal to noise on each electrode are calculated. Then spikes are detected, aligned and sorted according to methods described in the Osort paper: http://www.urut.ch/pdfs/Rutishauser_2006a.pdf

# Current Functionality

* Calibration method calculates thresholds for detection and clustering, and also finds spike templates for that block of data
* Spikes are detected with a running local energy window that compares to the power threshold
* Candidate spikes are then compared to with existing clusters
* If the distance between the spike and an existing cluster is less than threshold from calibration, the spike is assigned to that cluster, and the cluster shape is updated with a weighted average (95% existing, 5% new spike).
* If the distance is greater than threshold, the spike is assigned to a new cluster
* After each new spike is found, the clusters are compared to one another to see if any are below threshold distance away from one another. If they are, the clusters are merged.
* List of spike timestamps and corresponding cluster index is returned

# TO DO

## Calibration

Need to add a periodic "recalibration" where the thresholds are recalculated (probably at the end of each analysis block).

## Detection

Only spike detection based on power is implemented right now. Should at least add in support for thresholding the raw waveforms. Maybe try wavelet methods for detection (might be too slow though).

## Alignment

Right now alignment is done with a simple indmax. Need to add a few important steps:
* The paper describes more sophisticated approaches based on whether the peak is up or down.
* Currently no upsampling is used, but should be
* The paper also defines a "noise cluster" and just because a "spike" is detected, doesn't mean it will be assigned to an existing cluster or new one. Need to account for this.

## Sorting

Algorithm runs, but lots of stuff needs to be added.
* The paper discusses how the success of the algorithm is based on accurate alignment, and that methods that are invariant to translation could provide improvements. Need to look into this.
* The paper also discusses how synchronous spikes were be categorized as unique clusters, rather than linear combinations of 2 already known clusters. This could be addressed (but maybe not in real time).

## User Interface
* I tried matplotlib, and it was just okay. Would like to try PyCall to pyqtgraph now to see if it is indeed faster.
* Whatever the UI looks like, it needs to have a pipeline that allows for supervised sorting. If the unsupervised algorithm does a crappy job, there needs to be a way to either have control over changing the mean waveform, or doing some totally supervised spike sorting, and essentially turning the automated algorithm off on that channel.

## Parallel Processing
* I was able to make a parallel method for the calibration step where basically every core was doing its own thing with a portion of the data. This seemed to work. It would be nicer to somehow use a distributed array (which I didn't have success with) to easily bring the data together when necessary and otherwise have a method perform an algorithm on just its section of the distributed array.
* For now, I'm happy saying that the proof of concept worked, and with it taking ~.5 ms to sort each channel right now, it isn't a high priority to get the parallel working for the normal setup.

## Offline analysis
* All of the online methods can be adapted to run on offline data. This would be very useful for testing purposes.
