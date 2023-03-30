
# SpikeSorting.jl

This is a collection of spike sorting methods in Julia that were made to be used with my online acquisition system Intan.jl https://github.com/paulmthompson/Intan.jl. Each component of the spike sorting process (detection, aligning, feature detection, dimensionality reduction, and clustering) is intended to work independently, so that you can mix and match different parts of different algorithms. 

# How I actually use this

Right now, I only use this with online electrophysiology as a component of Intan.jl. I do NOT actually use this stand alone for offline sorting (although I'd love to if it was put together enough for that). 

# Partially implemented components

1) Manual Offline Sorting
I moved pretty much all of the GUI elements for visualization of spikes from Intan.jl to this package; consequently, it shouldn't be *too* much additional effort to put together a GUI for offline sorting. 

2) Automatic Offline Sorting
Any of the sorint pipelines could be applied to voltage traces, but I expect it wouldn't work very well compared to modern methods. I only do acute single channel recordings, so the methods I have developed are biased toward those types of recordings with one channel and high SNR (e.g. Template matching). I have NOT implemented any types of cross channel (e.g silicon probe or tetrode) sorting methods. Because I use this online, I have also not used any methods that look at all of the data from an experimental session to develop features. 

3) Algorithm Profiling
I coded in the benchmarking methods from https://www.ncbi.nlm.nih.gov/pubmed/21677152, but have never actually used them. 


# Installation

using Pkg
Pkg.add(url="https://github.com/paulmthompson/SpikeSorting.jl.git")

# Documentation

http://spikesortingjl.readthedocs.org/en/latest/

