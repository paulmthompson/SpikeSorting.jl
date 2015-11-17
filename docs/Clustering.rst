
###########
Clustering
###########

*********
Overview
*********

The final step of spike sorting is determining if the possiblely reduced signal represented in some feature space belows to an extracellular potential, and if so to which neuron it belongs. In offline analysis, the number of possible clusters can be determined by examining all of the data; in realtime recordings, the number of clusters needs to be determined on the fly or during a calibration period.

Each clustering method needs
1) Type with fields necessary for algorithm
2) function "cluster" to operate on sort with type field defined above
3) any other necessary functions for clustering algorithm

If the clustering step needs to perform a different function during the calibration period, it can be defined in a "clusterprepare" method.

All datatypes are members of the abstract type Cluster. They should have default constructors to be initialized as follows:

.. code-block:: julia

	mycluster=ClusterOSort() #Assign a candidate spike to a cluster based on the euclidean distance between the spike and the mean of the cluster

********
Methods
********
======================
Currently Implemented
======================

-----------------------------------
OSort / Hierachical Adaptive Means
-----------------------------------

References:

Rutishauser, Ueli and Schuman, Erin M. and Mamelak, Adam N. Online detection and sorting of extracellularly recorded action potentials in human medial temporal lobe recordings, in vivo. 2006.

Paraskevopoulou, Sivylla E. and Wu, Di and Eftekhar, Amir and Constandinou, Timothy G. Hierarchical Adaptive Means (HAM) clustering for hardware-efficient, unsupervised and real-time spike sorting. 2014. 

======================
Partially Implemented
======================

-----------
CLASSIT
-----------

Reference:

Gennari, John H and Langley, Pat and Fisher, Doug. Models of incremental concept formation. 1989.

==========
To Do
==========

------
BIRCH
------

Reference:

Zhang, T. and Ramakrishnan, R. and Livny, M. BIRCH: An Efficient Data Clustering Method for Very Large Databases. 1996.

-------
DBSCAN
-------

Reference:

Haga, Tatsuya and Fukayama, Osamu and Takayama, Yuzo and Hoshino, Takayuki and Mabuchi, Kunihiko. Efficient sequential Bayesian inference method for real-time detection and sorting of overlapped neural spikes. 2013.

-----------------------
Mahalanobis Clustering
-----------------------

References:

Kamboh, Awais M. and Mason, Andrew J. Computationally efficient neural feature extraction for spike sorting in implantable high-density recording systems. 2013.

Aik, Lim Eng, Choon, Tan Wee. An Incremental clustering algorithm based on Mahalanobis distance. 2014.

-------------------------------
Time varying dirichlet process
-------------------------------

Reference:

Gasthaus, Jan and Wood, Frank and Gorur, Dilan and Teh, Yee W. Dependent dirichlet process spike sorting. 2009.

