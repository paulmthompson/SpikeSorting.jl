# SpikeSorting.jl
Online spike sorting methods in Julia

# Introduction

This is a Julia implementation of various spike sorting methods. Our initial goal is to have a system that can perform online sorting of data that is acquired via a Intan RHD2000 acquisition board:

https://github.com/paulmthompson/Intan.jl

Since Osort (http://www.urut.ch/new/serendipity/index.php?/pages/osort.html) was designed with algorithms for real time acquisition, we plan on adapting these methods first. Would like to later include other methods of sorting and greater flexibility for other data acquisition methods other than Intan (including offline analysis). We use planar arrays and don't have to worry about the same spikes on multiple electrodes, but could one day add methods to account for this.

# Overview of (Intended) Implementation

Voltages from multi-electrode arrays are read from the Intan to computer in blocks in real time. These blocks (of n samples collected at 20000 Hz) are then fed to the spike sorter. First, a training peroid needs to take place, where things like signal to noise on each electrode are calculated. Then spikes are detected, aligned and sorted according to methods described in Osort.  

# Current Functionality

* Basically none (hopefully up and running summer 2015!)
* Thresholding methods for raw waveforms and power are almost complete.

# TO DO

## Calibration

* Need to determine thresholds for later spike detection. 

## Detection

* Raw signal thresholding
* Extract spikes from index of threshold crossing

## Alignment

* Upsample spikes
* Center spikes

## Sorting

* Implement Osort algorithm
