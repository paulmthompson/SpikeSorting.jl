

###########
Reduction
###########

*********
Overview
*********

Feature spaces from raw signals can often be high dimensional; dimensionality reduction allows the sorting algorithm to only compare a subset of the possible dimensions. This can be useful in terms of speed and accuracy during the subsequent clustering step. The difficulty is that we often do not know the most "discriminatory" dimensions to use in clustering. The methods below outline methods to select dimensions of a given high dimensional feature space to use for later clustering.

Each reduction method needs
1) Type with fields necessary for algorithm
2) function "reduction" to operate on sort with type field defined above
3) any other necessary functions for alignment algorithm

There can also be a "reductionprepare" function for the calibration step if necessary.

All datatypes are members of the abstract type Reduction. They should have default constructors to be initialized as follows:

.. code-block:: julia

	#Create instance of reduction type specifying that no reduction will be used
	myreduction=ReductionNone()

	#Create instance of reduction type specifying to select dimensions based on maximum difference test
	myreduction=ReductionMD()


********
Methods
********
======================
Currently Implemented
======================

-------------
No Reduction
-------------

-------------------
Maximum Difference
-------------------

Reference:

Gibson, Sarah and Judy, Jack W. and Markovi{\'{c}}, Dejan. Technology-aware algorithm design for neural spike detection, feature extraction, and dimensionality reduction. 2010

======================
Partially Implemented
======================

------------------------------
Principle Components Analysis
------------------------------

Refs:

Adamos, Dimitrios A and Kosmidis, Efstratios K and Theophilidis, George. Performance evaluation of PCA-based spike sorting algorithms. 2008.

Jung, Hae Kyung and Choi, Joon Hwan and Kim, Taejeong. Solving alignment problems in neural spike sorting using frequency domain PCA. 2006.

==========
To Do
==========

--------------------
Laplacian eigenmaps
--------------------

Reference:

Chah, E. and Hok, V. and Della-Chiesa, A. and Miller, J J H. and O'Mara, S. M. and Reilly, R. B. Automated spike sorting algorithm based on Laplacian eigenmaps and k-means clustering. 2011.

----------------------------------------------------
Projection Pursuit based on Negentropy maximization
----------------------------------------------------

Reference:

Kim, Kyung Hwan and Kim, Sung June. Method for unsupervised classification of multiunit neural signal recording under low signal-to-noise ratio. 2003.

---------------------------
Shannon mutual information
---------------------------

Reference:

Hulata, Eyal and Segev, Ronen and Ben-Jacob, Eshel. A method for spike sorting and detection based on wavelet packets and Shannon's mutual information. 2002.

----
SVD
----

Reference:

Oliynyk, Andriy and Bonifazzi, Claudio and Montani, Fernando and Fadiga, Luciano. Automatic online spike sorting with singular value decomposition and fuzzy C-mean clustering. 2012.

-----------------
Uniform Sampling
-----------------

Reference:

Karkare, Vaibhav and Gibson, Sarah and Markovic, Dejan. A 130-W, 64-channel neural spike-sorting DSP chip. 2011






