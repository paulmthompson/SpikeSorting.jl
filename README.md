# SpikeSorting.jl
Online spike sorting methods in Julia

# Documentation

http://spikesortingjl.readthedocs.org/en/latest/

# Introduction

This is a Julia implementation of various spike sorting methods. Our big picture goal is to have a system that can perform online sorting of data that is acquired via a Intan RHD2000 acquisition board:

https://github.com/paulmthompson/Intan.jl

In addition, we are trying to put many existing online algorithms, or potential online algorithms, into one place, and optimize them for speed.

# Current Functionality and TODO

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
