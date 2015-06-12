# SpikeSorting.jl
Online spike sorting methods in Julia

# Introduction

This is a Julia implementation of various spike sorting methods. Our initial goal is to have a system that can perform online sorting of data that is acquired via a Intan RHD2000 acquisition board:

https://github.com/paulmthompson/Intan.jl

Since Osort (http://www.urut.ch/new/serendipity/index.php?/pages/osort.html) was designed with algorithms for real time acquisition, we plan on adapting these methods first. We would like to eventually include other methods of sorting and greater flexibility for other data acquisition methods (and include offline analysis). We use planar arrays and don't have to worry about the same spikes on multiple electrodes, but we could one day add methods to account for this.

# Required Modules

* DistributedArrays - https://github.com/JuliaParallel/DistributedArrays.jl

# Overview of (Intended) Implementation

Voltages from multi-electrode arrays are read from the Intan to computer in blocks in real time. These blocks (of n samples collected at ~20000 Hz) are then fed to the spike sorter. First, a training period needs to take place, where things like signal to noise on each electrode are calculated. Then spikes are detected, aligned and sorted according to one set of several optional methods, most of which are described in the Osort paper: http://www.urut.ch/pdfs/Rutishauser_2006a.pdf

# Current Functionality and TODO

## Calibration

- [x] thresholds for power detection
- [x] templates from rawsignal waveforms
- [x] thresholds for raw signal detection
- [x] threshold for NEO
- [ ] template for wavelet coefficients
- [ ] Need to add a periodic "recalibration" where the thresholds are recalculated (probably at the end of each analysis block).

## Detection

- [x] Power Thresholding 
- [ ] Raw Signal Threshold (as in Quiroga 2004)
- [ ] Nonlinear Energy Operator
- [ ] Continuous Wavelet Transform
- [ ] Stationary Wavelet Transform

## Alignment

- [x] maximum index
- [ ] alignment accounting for shape (as in OSort)
- [ ] Upsampling via fft
- [ ] upsampling via cubic splines
- [ ] Option to assign to "noise cluster" rather than spikes
- [ ] center of mass (as in Sahani 1999 dissertation)

## Sorting

Feature Extraction:
- [ ] Multiscale correlation of wavelet coefficients (Yang 2011, M-sorter)
- [ ] PCA
- [ ] Wavelet packet decomposition (as in Bestel 2012)

Clustering:
- [x] Online new cluster creation (OSort)
- [x] Centroid to template comparison (OSort and lots of others)
- [x] Similar cluster merging via centroid (OSort)
- [ ] 2 Moment (centroid and correlation) template comparison (M-sorter and others)

## User Interface

- [ ] Real time plotting of at least some channels of interest
- [ ] Supervised sorting interface (probably via window discriminators)

Notes:
* I tried matplotlib, and it was just okay. Would like to try PyCall to pyqtgraph now to see if it is indeed faster.
* Whatever the UI looks like, it needs to have a pipeline that allows for supervised sorting. If the unsupervised algorithm does a crappy job, there needs to be a way to either have control over changing the mean waveform, or doing some totally supervised spike sorting, and essentially turning the automated algorithm off on that channel.

## Parallel Processing

- [x] Convert basic user type into Distributed Array for sorting across processors
- [ ] Add option to push data to cloud for sorting

## Offline analysis

* All of the online methods can be adapted to run on offline data. This would be very useful for testing purposes.
