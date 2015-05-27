
module ExtractSpikes

using DSP

function extractSpikes

    #Set default params


    #Calculate running mean


    #

end



function runningAverage(rawSignal, windowSize, mode=1)
       
    if mode==1
        runMean = [mean(rawSignal[1:i]) for i=1:windowSize]
    else
        runMean = filtfilt(ones(Float64,windowSize)./windowSize,1,rawSignal)
    end

    return runMean
                    
end


end
