

#=
Dimensionality Reduction methods. Each method needs
1) Type with fields necessary for algorithm
2) function "reduction" to operate on sort with type field defined above
3) any other necessary functions for alignment algorithm
=#

export ReductionNone, ReductionMD

function reductionprepare(r::Reduction,sort::Sorting)
    nothing
end

#=
No Dimensionality Reduction
=#
type ReductionNone <: Reduction
end
    
#=
Maximum Difference

Gibson et al 2010
=#
type ReductionMD <: Reduction
    mydims::Int64
    maximum_difference::Array{Int64,1}
    local_difference::Array{Float64,1}
    spike_old::Array{Float64,1}
    Dc::Array{Int64,1}
end

ReductionMD(dims::Int64)=ReductionMD(10,dims)

ReductionMD(N::Int64,dims::Int64)=ReductionMD(dims,zeros(Int64,N),zeros(Float64,N),zeros(Float64,N),zeros(Int64,dims))

function reductionprepare(r::ReductionMD,sort::Sorting)

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

    for i in max3ind
        for j=1:length(sort.r.Dc)
            if maximum_difference[max3ind[i]]>sort.r.Dc[j]
                if max3ind[i] != sort.dims[j]                
                    sort.dims[j]=max3ind[i]
                end
                sort.r.Dc[j]=maximum_difference[max3ind[i]]
                break
            end
        end
    end   
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
