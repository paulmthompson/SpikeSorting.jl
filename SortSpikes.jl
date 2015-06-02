module SortSpikes

using ExtractSpikes

export onlineCal, onlineSort, offlineSort

function onlineCal(rawSignal::Array{Int32,2},method="POWER")
    #Before running, collect a few seconds worth of data to find the noise of each channel
    
    #Use these measurements to determine threshold for spike detection
    #Also determine threshold for cluster merging

    #rawSignal should have a column of voltage for each electrode
    
    thresholds=Array(Int32, size(rawSignal,2))
    Tsm=Array(Float64,size(rawSignal,2))
    
    #find the threshold for each channel, depending on method
    for i=1:size(rawSignal,2)
        thresholds[i]=getThres(rawSignal[:,i],method)
        Tsm[i]=size(rawSignal,1)*std(rawSignal[:,i])
    end
    
    return (thresholds,Tsm)
    
end

function onlineSort(timeends::Array{Int32,1},rawSignal::Array{Int32,2},thresholds::Array{Float64,1})
 
    for i=1:size(rawSignal,2)
        
        #detect spikes using power threshold crossing
        #finds the index of the power peak in the 2.5 ms following a threshold crossing
        inds=detectSpikes(rawSignal,20,thresholds[i])

        #sorting
        
        
        #Need to account for the ends of the data which probably can't be analyzed correctly because they are cut off.

    end
    

end

function offlineSort()

    
    
end





end
