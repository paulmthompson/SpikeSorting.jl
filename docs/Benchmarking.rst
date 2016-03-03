
#############
Benchmarking
#############

*********
Overview
*********

The SpikeSorting.jl package provides several ways to calculate objective metrics of a method's performance. Given "gold standard" data, most likely in the form of simulations, the quality metrics of spike sorting performance as outlined here:

http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3123734/

can be calculated. Briefly, we determine the correctly classified spikes (true positives), as well as erroneously identified spikes (false positives) and spikes which are not identified (false negatives). False positives are further divided into false positives that are attributable to 1) overlap of potentials from different neurons in the same window of time, 2) clustering a spike from one neuron as another neuron and 3) classifying noise as a spike. Additionally, false negatives are either attributed to 1) an error in the detection step (e.g. too high of a threshold) or 2)  an error due to overlap of multiple potentials from different neurons.

The total number of detected spikes will be equal to the sum of the true positives and false positives.

The total number of "gold standard" spikes will be equal to the sum of the true positives and false negatives.

****************************
Calculating Quality Metrics
****************************

Quality metrics are calculated with 
1) an array of arrays of time stamps marking when neurons fire in the gold standard data set 
2) an array of voltage vs time of the gold standard signal
3) an instance of the sorting method of interest

Example code is as follows:

.. code-block:: julia

	#time_stamps is the Array of arrays of neuron firing times
	#fv is the array of voltage vs time of extracellular signal
	
	detect=DetectPower()
	cluster=ClusterOSort(100,50)
	align=AlignMin()
	feature=FeatureTime()
	reduce=ReductionNone()
	thres=ThresholdMean(2.0)
	s1=create_multi(detect,cluster,align,feature,reduce,thres,1)

	cal_time=180.0 #calibration time in seconds
	sr=20000 #sample rate

	ss=SpikeSorting.benchmark(fv,time_stamps,s1[1],cal_time,sr)


The benchmark function will print the quality metrics as well as return the following tuple:

1) detected spike times
2) array with each integer indicating the total number of true spikes for a neuron
3) total number of true positives
4) array of the false positives due to clustering, overlap and noise
5) array of false negatives due to overlap and detection

*******************************************
Optimizing sorting method based on results
*******************************************

Coming soon!

***************
Under the hood
***************

============================
Matching clusters to neurons
============================

========================
Attributing to overlap
========================





