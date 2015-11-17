
###########
Detection
###########

*********
Overview
*********

Voltage samples will be compared to some threshold value to determine if spiking has occured. Different methods of detection can be defined by declaring 1) a Type that is the data structure for the algorithm, 2) a function "detect" that implements the algorithm 3) a function "threshold" to determine the threshold for comparison during the training period.

Often methods will need to be initialized during a calibration period, such as calculating the running sum of the last n samples in power detection. These initialization procedures are defined in "detectprepare" functions.

All datatypes are members of the abstract type Detect. They should have default constructors to be initialized as follows:

.. code-block:: julia

	#Create instance of power detection for use in sorting
	mypowerdetection=DetectPower()

	#Create instance of median absolute value threshold detection for use in sorting
	mymedian=DetectSignal()


********
Methods
********

======================
Currently Implemented
======================

-----------------
Median Threshold
-----------------

Each timepoint is compared to a threshold, where the threshold is generated as some multiple of the formula below:

.. math:: \sigma_n = median \left\{ \frac{|x|}{.6745} \right\}

Usually the threshold is set as 4 sigma.

.. code-block:: julia

	type DetectSignal <: Detect
	end

Reference:

Quiroga, R Quian and Nadasdy, Z. and Ben-Shaul, Y. Unsupervised spike detection and sorting with wavelets and superparamagnetic clustering. 2004

--------------------------------
Nonlinear Energy Operator (NEO)
--------------------------------

Also known as Teager energy operator (TEO). The NEO is calculated at each time point based on the current, future and past sample and compared to a threshold.

.. math:: \psi [x(n)] = x^2(n) - x(n+1) x(n-1)

.. code-block:: julia 

	type DetectNEO <: Detect
	end

References:

Mukhopadhyay S and Ray G C. A new interpretation of nonlinear energy operator and its efficacy in spike detection. 1998

Choi, Joon Hwan and Jung, Hae Kyung and Kim, Taejeong. A new action potential detector using the MTEO and its effects on spike sorting systems at low signal-to-noise ratios. 2006.

-------
Power
-------

This method looks at the local energy built up over n samples, where by default n=20.

.. math:: P(t) = \left\{ \frac{1}{n} \sum_{i=1}^n (f(t-i) - \bar{f}(t))^2 \right\}^{1/2}
.. math:: \bar{f}(t) = \frac{1}{n} \sum_{i=1}^n f(t-i)

Some value of power is chosen as a threshold.

.. code-block:: julia

	type DetectPower <: Detect
    		a::Int64 #sum of last n samples
    		b::Int64 #sum of squares of last n samples
    		c::Int64 #value of sample at t-n
	end

Reference:

Kim and Kim, "Neural spike sorting under nearly 0-dB signal-to-noise ratio using nonlinear energy operator and artificial neural-network classifier," 2002

======================
Partially Implemented
======================

----------------------------------------------------------
Wavelet - Multiscale Correlation of Wavelet Coefficients
----------------------------------------------------------

References:

Yang, Chenhui and Olson, Byron and Si, Jennie. A multiscale correlation of wavelet coefficients approach to spike detection. 2011

Yuan, Yuan and Yang, Chenhui and Si, Jennie. The M-Sorter: an automatic and robust spike detection and classification system. 2012.

Yang, Chenhui and Yuan, Yuan and Si, Jennie. Robust spike classification based on frequency domain neural waveform features. 2013

==========
To Do
==========

-------------------------------
Amplitude detection - Multiple
-------------------------------

Reference:

Kamboh, Awais M. and Mason, Andrew J. Computationally efficient neural feature extraction for spike sorting in implantable high-density recording systems. 2013

-------------------------------------------
Nonlinear Energy Operator - smoothed (SNEO)
-------------------------------------------

Reference:

Azami, Hamed and Sanei, Saeid. Spike detection approaches for noisy neuronal data: Assessment and comparison. 2014.

-----------------------------------------------
Normalised cumulative energy difference (NCED)
-----------------------------------------------

Reference:

Mtetwa, Nhamoinesu and Smith, Leslie S. Smoothing and thresholding in neuronal spike detection. 2006.

----------
Summation
----------

Reference:

Mtetwa, Nhamoinesu and Smith, Leslie S. Smoothing and thresholding in neuronal spike detection. 2006.

---------------------------------------
Wavelet - Continuous Wavelet Transform
---------------------------------------

References:

Nenadic, Zoran and Burdick, Joel W. Spike detection using the continuous wavelet transform. 2005.

Benitez, Raul and Nenadic, Zoran. Robust unsupervised detection of action potentials with probabilistic models. 2008.

---------------------------------------
Wavelet - Stationary Wavelet Transform
---------------------------------------

Reference:

Kim, Kyung Hwan and Kim, Sung June. A wavelet-based method for action potential detection from extracellular neural signal recording with low signal-to-noise ratio. 2003.

-------------------------------
Wavelet - Wavelet Footprints
-------------------------------

Reference:

Kwon, and Oweiss. Wavelet footprints for detection and sorting of extracellular neural action potentials. 2011

Kwon, Ki Yong and Eldawlatly, Seif and Oweiss, Karim. NeuroQuest: a comprehensive analysis tool for extracellular neural ensemble recordings. 2012


