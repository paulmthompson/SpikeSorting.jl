
#=
Clustering methods. Each method needs
1) Type with fields necessary for algorithm
2) function "cluster" to operate on sort with type field defined above
3) any other necessary functions for clustering algorithm

=#

export ClusterOSort, ClusterManual

#=
OSort

Rutishauser 2006
=#

type ClusterOSort <: Cluster
    clusters::Array{Float64,2}
    clusterWeight::Array{Int64,1}
    numClusters::Int64
    Tsm::Float64
end

function ClusterOSort()   
    ClusterOSort(hcat(rand(Float64,50,1),zeros(Float64,50,4)),zeros(Int64,5),1,1.0)  
end

function ClusterOSort(n::Int64)
    ClusterOSort(hcat(rand(Float64,n,1),zeros(Float64,n,4)),zeros(Int64,5),1,1.0)
end

function cluster{S,C<:ClusterOSort,A,F}(sort::Sorting{S,C,A,F})
   
    x=getdist(sort)
    
    #add new cluster or assign to old
    if x==0
        sort.c.numClusters+=1
        sort.c.clusters[:,sort.c.numClusters]=sort.features[:]
        sort.c.clusterWeight[sort.c.numClusters]=1   
        sort.neuronnum[sort.numSpikes]=sort.c.numClusters
    else       
        if sort.c.clusterWeight[x]<20
            sort.c.clusterWeight[x]+=1
            for i=1:size(sort.c.clusters,1)
                sort.c.clusters[i,x]=(sort.c.clusterWeight[x]-1)/sort.c.clusterWeight[x]*sort.c.clusters[i,x]+1/sort.c.clusterWeight[x].*sort.features[i]
            end
        else
            for i=1:size(sort.c.clusters,1)
                sort.c.clusters[i,x]=.95.*sort.c.clusters[i,x]+.05.*sort.features[i]
            end
        end
        sort.neuronnum[sort.numSpikes]=x       
    end

    if sort.c.numClusters>1
        merged=findmerge!(sort)
    end
end

function getdist(sort::Sorting)
    
    dist=Array(Float64,sort.c.numClusters)
    for i=1:sort.c.numClusters
        dist[i]=norm(sort.features-sort.c.clusters[:,i])
    end

    ind=indmin(dist)

    if dist[ind]<sort.c.Tsm
        return ind
    else
        return 0
    end
    
end

function findmerge!(sort::Sorting)
    #if two clusters are below threshold distance away, merge them

    skip=0
    merger=0

    for i=1:sort.c.numClusters-1
        
        if i==skip
            continue
        end
        
        for j=(i+1):sort.c.numClusters
                dist=norm(sort.c.clusters[:,i]-sort.c.clusters[:,j])
            if dist<sort.c.Tsm
                for k=1:size(sort.c.clusters[:,i],1)
                    sort.c.clusters[k,i]=(sort.c.clusters[k,i]+sort.c.clusters[k,j])/2
                end
                sort.c.numClusters-=1
                skip=j
                merger=i
            end
        end
    end

    if skip!=0

        for i=skip:sort.c.numClusters+1
            sort.c.clusters[:,i]=sort.c.clusters[:,i+1]
        end
    end

    [skip,merger]
    
end

#=
CLASSIT
=#

type attribute
    S::Float64
    SS::Float64
end

type node
    n::Int64 #count
    a::Array{attribute,1} #attributes
    
    c::Array{node,1} #children
    p::node #parent 
end

function runningstd(N::node,x::Array{Float64,1}) #change to sum of squares

    for i=1:length(N.a)
        std=sqrt((1/(n-1))*(SS-(S^2/n)))

        if std<acuity
            std=acuity
        end
    end    
end

function getstdchild(N::node,x::Array{Float64,1},ind::Int64)

    stdmat=zeros(Float64,length(N.a))
    
    for i=1:length(N.a)
        M_new=N.a[i].M_old+(x[i]-N.c[ind].a[i].M_old)/N.c[ind].n
        S_new=N.a[i].S_new+(x[i]-N.c.[ind].a[i].M_old)*(x[i]-M_new)
        stdmat[i]=sqrt(S_new/(N.c[ind].n-1))

        if stdmat[i]<acuity
            stdmat[i]=acuity
        end
    end
  
end


function cobweb(N::node, x::Array{Float64,1})
    if length(N.c)==0 #If leaf
        if
        end
    else

        #add I to each child and get CUs
        S=zeros(Float64,length(N.c))
        for i=1:length(N.c)
            getstdchild(N,x,i)
            
        end
        
        #add I as new singleton child and get CU
        for i=1:(length(N.c)+1)
            getstdchild(N,
        

        #merge best and second best CUs from 1 and add I to merged result

        #promote children of best child to be children of P, and add instance

        if
        end
        
    end
end

function calcCU(probs::Array{Float64,1},stdmat::Array{Float64,2},numclasses::Int64)

    CU=0.0

    for i=1:numclasses
    
        CU += probs[i]*sum(1/stdmat[:,i])
    end
    
    CU=CU/numclasses
    
end
    

#=
ECOWEB
=#

#=
Manual Detection - Window Discriminators
=#

type ClusterManual <: Cluster
    clusters::Array{Float64,2}
    numClusters::Int64
    win::Array{Float64,2}
end

function ClusterManual()   
    ClusterOSort(zeros(Float64,5),0,zeros(Float64,4,5))  
end

function cluster{S,C<:ClusterManual,A,F}(sort::Sorting{S,C,A,F})

    for i=1:sort.numClusters
        
        A1=(win[3,i]-win[4,i])/(win[1,i]-win[2,i])
        b1=win[3,i]-A1*win[1,i]
        
        A2=(sort.waveforms[win[1,i],sort.numSpikes]-sort.waveforms[win[2,i],sort.numSpikes])/(win[1,i]-win[2,i])
        b2=sort.waveforms[win[1,i],sort.numSpikes]-A2*win[1,i]

        Xa=(b2 - b1) / (A1 - A2)

        if Xa>win[1,i] &&  Xa<win[2,i]
            sort.neuronnum[sort.numSpikes]=i
            sort.numSpikes+=1
            break
        else

        end   
    end      
end
