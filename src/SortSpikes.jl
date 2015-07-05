module SortSpikes


abstract SpikeDetection
abstract Alignment

include("clustertypes.jl")

type Sorting{S<:SpikeDetection, A<:Alignment}
    s::S
    c::Cluster
    a::A
    rawSignal::Array{Int,1}
    electrode::Array{Int,1}
    neuronnum::Array{Int,1}
    numSpikes::Int64
    waveforms::Array{SharedArray,1}
    sigend::Array{Int64,1}
    index::Int64
end

include("detectmethods.jl")
include("alignmethods.jl")
include("extractspikes.jl")

#using Winston, Gtk.ShortNames
#include("gui.jl")

export Sorting, onlinecal, onlinesort, offlinesort

function onlinecal(sort::Sorting,method="POWER")
    
    if method=="POWER"
        
        sort.s.thres=getthres(sort,method)
        detectionmethod=detection{:detect_power}()

        prepare_power(sort)
        
    elseif method=="SIGNAL"

        sort.s.thres=getthres(sort,method)
        detectionmethod=detection{:detect_signal}()
        
    elseif method=="NEO"

        sort.s.thres=getthres(sort,method)
        detectionmethod=detection{:detect_neo}()
        
    end

    sort.c.Tsm=50*var(sort.rawSignal)
    sort.sigend[:]=sort.rawSignal[1:75]
    detectspikes(sort,detectionmethod, 76)
    
    #if new clusters were discovered, get rid of initial noise cluster to skip merger code later on when unnecessary
    #might want to change this later
    if sort.c.numClusters>1
        for j=2:sort.c.numClusters
            sort.c.clusters[:,j-1]=sort.c.clusters[:,j]
            sort.c.clusters[:,j]=zeros(Float64,size(sort.c.clusters[:,j]))
            sort.c.clusterWeight[j-1]=sort.c.clusterWeight[j]
            sort.c.clusterWeight[j]=0
         end
         sort.c.numClusters-=1
    end

    sort.electrode=zeros(size(sort.electrode))
    sort.neuronnum=zeros(size(sort.electrode))
    sort.numSpikes=2

    return sort
end

function onlinesort(sort::Sorting,method="POWER")
 
    #Find spikes during this time block, labeled by neuron

    if method=="POWER"
             
        detect_power1=detection{:detect_power}()
        detectspikes(sort,detect_power1)       

    elseif method=="SIGNAL"

        detect_signal1=detection{:detect_signal}()
        detectspikes(sort,detect_signal)
        
    elseif method=="NEO"

        detect_neo1=detection{:detect_neo}()
        detectspikes(sort,detect_neo1)

    elseif method=="MANUAL"

        detectspikes(sort, manualdetection)

    end

    #convert to absolute time stamps with the timeends variable

    #move stuff around if there were mergers of clusters (I guess? maybe do all of that at the end)

    #write to output  
    
    return sort
    
end

function offlinesort()

    
end


end
