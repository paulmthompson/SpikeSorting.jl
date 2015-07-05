
#=
Clustering methods. Each method needs
1) Type with fields necessary for algorithm
2) function defining detection algorithm

=#


export OSort 

#=
Julia isn't great at getting functions as arguments right now, so this helps the slow downs because of that. Probably will disappear eventually
=#

immutable clustering{Name} end

@generated function call{fn}(::clustering{fn},x::Sorting,y::Int64)
        :($fn(x,y))
end

#=
OSort

Rutishauser 2006
=#

type OSort <: Cluster
    clusters::Array{Float64,2}
    clusterWeight::Array{Int64,1}
    numClusters::Int64
    Tsm::Float64
end

function OSort()   
    OSort(hcat(rand(Float64,50,1),zeros(Float64,50,4)),zeros(Int64,5),1,1.0)  
end

function OSort(n::Int64)
    OSort(hcat(rand(Float64,n,1),zeros(Float64,n,4)),zeros(Int64,5),1,1.0)
end
