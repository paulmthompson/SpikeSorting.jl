

#=
Dimensionality Reduction methods. Each method needs
1) Type with fields necessary for algorithm
2) function "reduction" to operate on sort with type field defined above
3) any other necessary functions for alignment algorithm
=#

export ReductionNone, ReductionMD

function reductionprepare{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R})
    nothing
end

#=
No Dimensionality Reduction
=#
type ReductionNone <: Reduction
end
    
#=
Maximum Difference
=#
type ReductionMD <: Reduction
end

#=
Lilliefor's Test
=#
type ReductionLT <: Reduction
end

#=
Hartigan's Dip
=#
type ReductionHD <: Reduction
end

#=
Uniform Sampling
=#
type ReductionUS <: Reduction
end
