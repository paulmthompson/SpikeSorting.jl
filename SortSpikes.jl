module SortSpikes

using ExtractSpikes

export onlineCal, onlineSort, offlineSort

function onlineCal(rawSignal::Array{Int64,2},clus::Dict{Int64,Cluster},s::Dict{Int64,SpikeDetection},method="POWER", k=20)
    #The first data collected will be fundamentally different in several ways. Need to determine:
    #Threshold for spike detection
    #Threshold for cluster assignment and merger
    #Cluster templates

    #find the thresholds for each channel
    for i=1:size(rawSignal,2)
        s[i].thresholds=getThres(rawSignal[:,i],method)
        clus[i].Tsm=size(rawSignal,1)*var(rawSignal[:,i]) #this isn't exactly the same as the paper where it is the average of a running standard deviation. I think its okay
    end
 
    #Run a second of data to refine cluster templates, and not caring about recording spikes
    for i=1:size(rawSignal,2)
        prepareDetection(s[i],rawSignal[(k+1):end,i])
        detectSpikes(s[i],clus[i],rawSignal[(k+1):end,i])

        #if new clusters were discovered, get rid of initial noise cluster to skip merger code later on when unnecessary

        #Also, should be able to load clusters from the end of previous session
        if clus[i].numClusters>1
            for j=2:numClusters
                clus[i].clusters[:,j-1]=clus[i].clusters[:,j]
            end
        end
         
    end
    
end

function onlineSort(timeends::Array{Int32,1},rawSignal::Array{Int32,2},clus::Dict{Int64,Cluster},s::Dict{Int64,SpikeDetection},electrode::Dict{Int64,Array{Int64,1}},neuronnum::Dict{Int64,Array{Int64,1}},method="POWER")
 
    for i=1:size(rawSignal,2)

        #Find spikes during this time block, labeled by neuron
        (neurontimes,neuroniden)=detectSpikes(s[i],clus[i],rawSignal[:,i])

        #convert to absolute time stamps with the timeends variable

        #move stuff around if there were mergers of clusters (I guess? maybe do all of that at the end)

        #write to output
        append!(electrode[j],neurontimes)
        append!(neuronnum[j],neuroniden)
 
    end
    
end

function offlineSort()

    
    
end

end
