
###########
Alignment
###########

*********
Overview
*********

When a candidate spike is detected, it is usually because some metric computed from the running voltage signal crossed a threshold. Consequently, a piece of the voltage signal surrounding that threshold event is sectioned out and passed to the alignment step for subsequent analysis. Background noise and other factors may not cause the same part of an extracellular potential to generate the threshold crossing event each time: as a result just taking a window around threshold crossing may make the time varying voltage pattern of a given spike forward or backward shifted compared to a previous spike from the same neuron. This can be problematic from feature extraction steps, which may not be immune to phase shifts such as this. Therefore, it can be important to apply an alignment meature to every candidate spike that is detected.

Each alignment method needs
1) Type with fields necessary for algorithm
2) function "align" to operate on sort with type field defined above
3) any other necessary functions for alignment algorithm

All datatypes are members of the abstract type Align. They should have default constructors to be initialized as follows:

.. code-block:: julia

	myalign=AlignMax() #align based on the signal with the higest voltage

	myalign=AlignFFT() #upsample the signal with an FFT, then perform alignment based on the maximum


********
Methods
********
======================
Currently Implemented
======================

---------------
Maximum Index
---------------

-------------------
Upsampling via fft
-------------------

======================
Partially Implemented
======================

==========
To Do
==========

-----------------------------
Upsampling via cubic splines
-----------------------------

----------------
Center of mass
----------------


