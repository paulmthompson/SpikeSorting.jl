module SortSpikes

using ExtractSpikes

export onlineCal, onlineSort, offlineSort, onlineCal_par

function onlineCal(sort::Sorting,method="POWER")
    #The first data collected will be different in several ways. Need to determine:
    #Threshold for spike detection
    #Threshold for cluster assignment and merger
    #Cluster templates

    #find the thresholds for each channel

    sort.s.thres=getThres(sort,method)
        
    #Threshold is supposed to be the average standard deviation of all of the spiking events. Don't have any of those to start
     sort.c.Tsm=50*var(sort.rawSignal) 

    #Run a second of data to refine cluster templates, and not caring about recording spikes
    #Also, should be able to load clusters from the end of previous session
    prepareCal(sort)
    detectSpikes(sort,21)

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

function onlineSort(sort::Sorting,method="POWER")
 
    #Find spikes during this time block, labeled by neuron
    detectSpikes(sort)

    #convert to absolute time stamps with the timeends variable

    #move stuff around if there were mergers of clusters (I guess? maybe do all of that at the end)

    #write to output  
    
    return sort
    
end

function offlineSort()

    
end

end
