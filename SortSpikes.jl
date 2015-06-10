module SortSpikes

using ExtractSpikes

export onlineCal, onlineSort, offlineSort, onlineCal_par

function onlineCal(rawSignal::Array{Int64,2},clus::Array{Any,1},s::Array{Any,1},method="POWER")
    #The first data collected will be fundamentally different in several ways. Need to determine:
    #Threshold for spike detection
    #Threshold for cluster assignment and merger
    #Cluster templates

    #find the thresholds for each channel
    for i=1:size(rawSignal,2)
        s[i].thres=getThres(rawSignal,method,i)
        
        #Threshold is supposed to be the average standard deviation of all of the spiking events. Don't have any of those to start
        clus[i].Tsm=50*var(rawSignal[:,i]) 
    end

    #Run a second of data to refine cluster templates, and not caring about recording spikes
    #Also, should be able to load clusters from the end of previous session
    for i=1:size(rawSignal,2)
        prepareCal(s[i],rawSignal,i)
        detectSpikes(s[i],clus[i],rawSignal,i,21)

        #if new clusters were discovered, get rid of initial noise cluster to skip merger code later on when unnecessary
        #might want to change this later
        if clus[i].numClusters>1
            for j=2:clus[i].numClusters
                clus[i].clusters[:,j-1]=clus[i].clusters[:,j]
                clus[i].clusters[:,j]=zeros(Float64,size(clus[i].clusters[:,j]))
                clus[i].clusterWeight[j-1]=clus[i].clusterWeight[j]
                clus[i].clusterWeight[j]=0
            end
            clus[i].numClusters-=1
        end 
         
    end

end

function onlineCal_par(rawSignal::Array{Int64,2},clus::Array{Any,1},s::Array{Any,1},thisproc::Int,totalproc::Int, method="POWER")
    #The first data collected will be fundamentally different in several ways. Need to determine:
    #Threshold for spike detection
    #Threshold for cluster assignment and merger
    #Cluster templates

    
    iter=convert(Int,size(rawSignal,2)*(thisproc-1)/totalproc+1):convert(Int,size(rawSignal,2)*thisproc/totalproc)
    ind=1
    #find the thresholds for each channel
    for i in iter
        s[ind].thres=getThres(rawSignal,method,i)
        
        #Threshold is supposed to be the average standard deviation of all of the spiking events. Don't have any of those to start
        clus[ind].Tsm=50*var(rawSignal[:,i])

        ind+=1
    end

    ind=1
    #Run a second of data to refine cluster templates, and not caring about recording spikes
    #Also, should be able to load clusters from the end of previous session
    for i in iter
        prepareCal(s[ind],rawSignal,i)
        detectSpikes(s[ind],clus[ind],rawSignal,i,21)

        #if new clusters were discovered, get rid of initial noise cluster to skip merger code later on when unnecessary
        #might want to change this later
        if clus[ind].numClusters>1
            for j=2:clus[ind].numClusters
                clus[ind].clusters[:,j-1]=clus[ind].clusters[:,j]
                clus[ind].clusters[:,j]=zeros(Float64,size(clus[ind].clusters[:,j]))
                clus[ind].clusterWeight[j-1]=clus[ind].clusterWeight[j]
                clus[ind].clusterWeight[j]=0
            end
            clus[ind].numClusters-=1
        end 

        ind+=1
        
    end

end

function onlineSort(timeends::Array{Int,1},rawSignal::Array{Int64,2},clus::Array{Any,1},s::Array{Any,1},electrode::Array{Any,1},neuronnum::Array{Any,1},method="POWER")
 
    for i=1:size(rawSignal,2)

        #Find spikes during this time block, labeled by neuron
        (neurontimes,neuroniden)=detectSpikes(s[i],clus[i],rawSignal,i)

        #convert to absolute time stamps with the timeends variable

        #move stuff around if there were mergers of clusters (I guess? maybe do all of that at the end)

        #write to output
        append!(electrode[i],neurontimes)
        append!(neuronnum[i],neuroniden)
 
    end
    
end

function offlineSort()

    
end

end
