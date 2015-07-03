module SortSpikes

include("detecttypes.jl")
include("clustertypes.jl")

type Sorting
    s::SpikeDetection
    c::Cluster
    rawSignal::Array{Int,1}
    electrode::Array{Int,1}
    neuronnum::Array{Int,1}
    numSpikes::Int
    waveforms::Array{SharedArray,1}
end

include("detectmethods.jl")
include("extractspikes.jl")

#using Winston, Gtk.ShortNames
#include("gui.jl")

export Sorting, onlinecal, onlinesort, offlinesort

function onlinecal(sort::Sorting,method="POWER")
    
    if method=="POWER"
        
        sort.s.thres=getthres(sort,method)
        
        #Threshold is supposed to be the average standard deviation of all of the spiking events. Don't have any of those to start
        sort.c.Tsm=50*var(sort.rawSignal) 
        #Run a second of data to refine cluster templates, and not caring about recording spikes
        #Also, should be able to load clusters from the end of previous session
        preparecal(sort)
        
        powerdetection1=detection{:powerdetection}()
        detectspikes(sort,powerdetection1, 76)
    end

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
             
        powerdetection1=detection{:powerdetection}()
        detectspikes(sort,powerdetection1)       

    elseif method=="SIGNAL"

        detectspikes(sort,signaldetection)
        
    elseif method=="NEO"

        detectspikes(sort,neodetection)

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
