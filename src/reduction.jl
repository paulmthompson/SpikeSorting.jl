

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
    mydims::Int64
    maximum_difference::Array{Int64,1}
    local_difference::Array{Float64,1}
    spike_old::Array{Float64,1}
    D::Array{Int64,1}
    Dc::Array{Int64,1}
end

function ReductionMD(dims::Int64)
    ReductionMD(dims,zeros(Int64,10),zeros(Float64,10),zeros(Float64,10),zeros(Int64,dims),zeros(Int64,dims))
end

function ReductionMD(N::Int64,dims::Int64)    
    ReductionMD(dims,zeros(Int64,N),zeros(Float64,N),zeros(Float64,N),zeros(Int64,dims),zeros(Int64,dims))
end

function reductionprepare{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:ReductionMD}(sort::Sorting{D,C,A,F,R})

    max3ind=zeros(Int64,3)
    for i=1:length(sort.fullfeature)
        sort.r.local_difference[i]=abs(sort.r.spike_old[i]-sort.fullfeature[i])

        if sort.r.local_difference[i]>max3ind[1]
            if sort.r.local_difference[i]>max3ind[2]
                if sort.f.local_difference[i]>max3ind[3]
                    max3ind[1]=max3ind[2]
                    max3ind[2]=max3ind[3]
                    max3ind[3]=i
                end
                max3ind[1]=max3ind[2]
                max3ind[2]=i
            end
            max3ind[1]=i
        end
    end

    sort.r.maximum_difference[max3ind]+=1
    sort.r.spike_old[:]=sort.fullfeature[:]

    #Need to fix this so there are no duplicates
    for i=1:3
        (mymin,myindex)=findmin(sort.f.Dc)
        if sort.r.maximum_difference[max3ind[i]]>mymin
            if max3ind[i]!=sort.r.D[myindex]
                sort.r.Dc[myindex]=sort.r.maximum_difference[max3ind[i]]
                sort.r.D[myindex]=max3ind[i]
            end     
        end
    end

    #sort.dims = 
  
    nothing

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
