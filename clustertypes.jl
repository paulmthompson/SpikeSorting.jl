
export Cluster

type Cluster
    #These fields represent data that needs to be stored over the experiment about waveforms that have been determined
    clusters::Array{Float64,2}
    clusterWeight::Array{Int64,1}
    numClusters::Int64
    Tsm::Float64
end

function Cluster()   
    Cluster(hcat(rand(Float64,50,1),zeros(Float64,50,4)),zeros(Int64,5),1,1.0)  
end

function Cluster(n::Int64)
    Cluster(hcat(rand(Float64,n,1),zeros(Float64,n,4)),zeros(Int64,5),1,1.0)
end
