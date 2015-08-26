# SpikeSorting.jl
Online spike sorting methods in Julia

# Introduction

This is a Julia implementation of various spike sorting methods. Our big picture goal is to have a system that can perform online sorting of data that is acquired via a Intan RHD2000 acquisition board:

https://github.com/paulmthompson/Intan.jl

In addition, we are trying to put many existing online algorithms, or potential online algorithms, into one place, and optimize them for speed.

# Required Modules

* DistributedArrays - https://github.com/JuliaParallel/DistributedArrays.jl
* Winston - https://github.com/nolta/Winston.jl
* Gtk - https://github.com/JuliaLang/Gtk.jl
* OnlineStats - https://github.com/joshday/OnlineStats.jl
* Interpolations - https://github.com/tlycken/Interpolations.jl

# Current Functionality and TODO

## Program Structure

Rather than copying arrays so frequently, and storing separate spike waveforms, should be using unitranges and arrayviews. Probably can scrap entire spike waveforms matrix altogether (yay!)

May also be better to bring the rawSignal out of the data structure and rather have a 2D shared array. that contains all of the neural data

## Calibration

- [x] thresholds for power detection
- [x] templates from rawsignal waveforms
- [x] thresholds for raw signal detection
- [x] threshold for NEO
- [ ] power normalization for MCWC
- [ ] Need to add a periodic "recalibration" where the thresholds are recalculated (probably at the end of each analysis block).

## Detection

- [x] Power Thresholding 
- [x] Raw Signal Threshold (as in Quiroga 2004)
- [x] Nonlinear Energy Operator (Choi et al 2006)
- [ ] Continuous Wavelet Transform (Nenadic et al 2005)
- [x] Multiscale Correlation of Wavelet Coefficients (Yang et al 2011)
- [ ] Stationary Wavelet Transform (Brychta et 2007)

## Alignment

- [x] maximum index
- [ ] alignment accounting for shape (as in OSort)
- [x] Upsampling via fft 
- [ ] upsampling via cubic splines
- [ ] center of mass (as in Sahani 1999 dissertation)

## Overlap

- [ ] Continuous Basis Pursuit (Ekanadham et al 2014)
- [ ] Sequential Bayesian inference (Haga et at 2013)

## Feature Extraction:
- [x] PCA
- [ ] Wavelet packet decomposition (Hulata et al 2002)
- [ ] Classification algorithm based on frequency domain features (Yang et al 2013)

## Clustering:

### Connectivity Models
- [ ] BIRCH
- [ ] CLASSIT

### Centroid Models
- [ ] Hierachical Adaptive Means (Paraskevopoulou et al 2014)
- [x] OSort (Rutishauser et al 2006)

### Distribution Models
- [ ] Time varying Dirichlet process (Gasthaus et al 2009)

### Density Models
- [ ] DenStream

Notes: 
There are many different clustering methods. For a totally unsupervised, online implementation, the number of clusters needs to be determined automatically. The clusters should be able to adapt over time to compensate for things like electrode drift. Also, the clustering algorithm should have a sense of an "outlier." 

## User Interface

- [ ] Real time plotting of at least some channels of interest
- [ ] Supervised sorting interface (probably via window discriminators)

Notes:
* After trying several plotting options, I think I'm settled on Gtk + Winston for this. Keeping things in Julia and C seems to allow for pretty decent speed.
* Whatever the UI looks like, it needs to have a pipeline that allows for supervised sorting. If the unsupervised algorithm does a crappy job, there needs to be a way to either have control over changing the mean waveform, or doing some totally supervised spike sorting, and essentially turning the automated algorithm off on that channel.

## Parallel Processing

- [x] Convert basic user type into Distributed Array for sorting across processors
- [ ] Add option to push data to cloud for sorting

## Offline analysis

* All of the online methods can be adapted to run on offline data. This would be very useful for testing purposes.
