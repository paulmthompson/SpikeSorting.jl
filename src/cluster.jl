
#=
Clustering methods. Each method needs
1) Type with fields necessary for algorithm
2) function(s) defining detection algorithm

=#

export ClusterOSort, ClusterManual

#=
Julia isn't great at getting functions as arguments right now, so this helps the slow downs because of that. Probably will disappear eventually
=#

immutable clustering{Name} end

@generated function call{fn}(::clustering{fn},x::Sorting)
        :($fn(x))
end

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


function cluster_osort(sort::Sorting)
   
    x=getdist(sort)
    
    #add new cluster or assign to old
    if x==0
        sort.c.numClusters+=1
        sort.c.clusters[:,sort.c.numClusters]=sort.waveforms[:,sort.numSpikes]
        sort.c.clusterWeight[sort.c.numClusters]=1   
        sort.neuronnum[sort.numSpikes]=sort.c.numClusters
    else       
        if sort.c.clusterWeight[x]<20
            sort.c.clusterWeight[x]+=1
            sort.c.clusters[:,x]=(sort.c.clusterWeight[x]-1)/sort.c.clusterWeight[x]*sort.c.clusters[:,x]+1/sort.c.clusterWeight[x]*sort.waveforms[sort.numSpikes][:]            
        else            
           sort.c.clusters[:,x]=.95.*sort.c.clusters[:,x]+.05.*sort.waveforms[sort.numSpikes][:]
        end
        sort.neuronnum[sort.numSpikes]=x       
    end

    #add spike cluster identifier to dummy first waveform shared array
    sort.waveforms[1][sort.numSpikes]=sort.neuronnum[sort.numSpikes]    
    sort.numSpikes+=1
    if sort.c.numClusters>1
        merged=findmerge!(sort)
    end
end

function getdist(sort::Sorting)
    
    dist=Array(Float64,sort.c.numClusters)
    for i=1:sort.c.numClusters
        dist[i]=norm(sort.waveforms[sort.numSpikes][:]-sort.c.clusters[:,i])
    end

    #Need to account for no clusters at beginning
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

function cluster_manualwindow(sort::Sorting)

    for i=1:sort.numClusters
        
        A1=(win[3,i]-win[4,i])/(win[1,i]-win[2,i])
        b1=win[3,i]-A1*win[1,i]
        
        A2=(sort.waveforms[win[1,i],sort.numSpikes]-sort.waveforms[win[2,i],sort.numSpikes])/(win[1,i]-win[2,i])
        b2=sort.waveforms[win[1,i],sort.numSpikes]-A2*win[1,i]

        Xa=(b2 - b1) / (A1 - A2)

        if Xa>win[1,i] &&  Xa<win[2,i]
            sort.waveforms[1][sort.numSpikes]=sort.neuronnum[sort.numSpikes]    
            sort.numSpikes+=1
            break
        else

        end   
    end      
end
