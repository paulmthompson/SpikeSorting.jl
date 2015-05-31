module SortSpikes

using ExtractSpikes

function onlineCal(rawSignal::Array{Int32,2},method="POWER")
#Before running 

    
    thresholds=Array(Int32, size(rawSignal,2))
    
    #find the threshold for each channel, depending on method
    for i=1:size(rawSignal,2)
        thresholds[i]=getThres(rawSignal[:,i],method)
    end
    
    return thresholds
    
end

function onlineSort(timeends::Array{Int32,1},rawSignal::Array{Int32,2},thresholds::Array{Int32,1})

    
    
end

function offlineSort()


    
end





end
