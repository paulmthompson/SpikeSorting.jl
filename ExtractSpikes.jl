
module ExtractSpikes

using DSP

#This runs first and calls detect spikes
function extractSpikes

    #Set default params


    #Calculate running mean


    #

end

function detectSpikes

end


function runningAverage(rawSignal, windowSize, mode=1)
       
    if mode==1
        runMean = [mean(rawSignal[1:i]) for i=1:windowSize]
    else
        runMean = filtfilt(ones(Float64,windowSize)./windowSize,1,rawSignal)
    end

    return runMean
                    
end

function MTEO(rawSignal, ks)

    tmp=zeros(Float64,length(ks),lenght(rawSignal))

    for i=1:length(ks)
        tmp[i,:] = runningTEO(rawSignal, ks[i])
        v = var(tmp[i,:])

        #apply the window
        win = hamming( 4*ks(i)+1, 'symmetric')
        tmp[i,:] = filter( win,1,tmp[i,:]) ./ v

    end

    return sum(tmp)

end



function runningTEO(rawSignal,k=1)

    out=similar(rawSignal)
    for i=1:length(rawSignal)
        #out = rawSignal[i]^2 - [rawSignal(1+k:end) repmat(0,1,k)].*[repmat(0,1,k) rawSignal(1:end-k)]
        out[i] = rawSignal[i]^2 - rawSignal[i-1]*rawSignal[i+1]
    end
    
    return out
    
end

end
