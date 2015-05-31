module ExtractSpikes

using DSP

export filterSignal, initFilter, detectSpikes, runningStd, getThres

#Hd is an array of transfer function coefficients to filter the signal (default is 300 3000 band pass)

#I think the hardware already does/can do all of the filtering before it gets here

#This runs first and calls detect spikes
function extractSpikes(rawSignal::Array{Float64,1}, Hd::Array{Float64,2},detectionMethod::String)

    #Set default params
  
    #Calculate the to-be-thresholded signal, depending on the method used

    #Compute signal for peak finding, if required.

    #call detectSpikes
    
end

function detectSpikes(rawSignal::Array{Float64,1},k::Int64,thres::Float64)

    inds=zeros(Int64,1)

    rstd=std(rawSignal)
    #power setup
    a = 0.0
    b = 0.0
    
    for i=1:k
        a += rawSignal[i]
        b += rawSignal[i]^2
    end

    c=rawSignal[1]
    d=rawSignal[1]^2

    for i=(k+1):length(rawSignal)
        
        a += rawSignal[i] - c
        b += rawSignal[i]^2 - d

        p = sqrt((b - a^2/k)/k)

        c=rawSignal[i-k+1]
        d=rawSignal[i-k+1]^2

        if p > thres
            push!(inds,i)
        end

        println(p)
        
    end
    
    return inds
    
end

function getThres(rawSignal::Array{Float64,1},method::String)

    if method=="POWER"

        #threshold should be 5 * std(power)
        threshold=1.0
    elseif method=="SIGNAL"

    end
    
    return threshold
    
end


function runningStd(rawSignal::Array{Float64,1},k::Int64)


    #running std of fixed width
    rstd=Array(Float64,length(rawSignal)-k)
    a = 0.0
    b = 0.0
    for i=1:k
        a += rawSignal[i]
        b += rawSignal[i]^2
    end

    c=rawSignal[1]
    d=rawSignal[1]^2
    
    for i=(k+1):length(rawSignal)
        
        a += rawSignal[i] - c
        b += rawSignal[i]^2 - d
        rstd[i-k]=sqrt(k*b - a^2)/k
        c=rawSignal[i-k+1]
        d=rawSignal[i-k+1]^2
        
    end

    return rstd
    
end



function runningAverage(rawSignal, windowSize, mode=1)
       
    if mode==1
        runMean = [mean(rawSignal[1:i]) for i=1:length(rawSignal)]
    else
        runMean = filtfilt(ones(Float64,windowSize)./windowSize,1,rawSignal)
    end

    return runMean
                    
end

function filterSignal(rawSignal::Array{Float64,1}, Hd::Array{Float64,2})

    filtered=filtfilt(Hd[:,1],Hd[:,2],rawSignal)
    return filtered
    
end

function initFilter(Fs=20000,passband=[300, 3000])

    response_type = Bandpass(passband[1], passband[2]; fs=Fs)
    proto_type = Butterworth(4)

    myfilter=convert(PolynomialRatio,digitalfilter(response_type,proto_type))

    b=coefb(myfilter)
    a=coefa(myfilter)

    Hd=hcat(b,a)
    
    return Hd
    

end

function MTEO(rawSignal, ks)

    tmp=zeros(Float64,length(ks),lenght(rawSignal))

    for i=1:length(ks)
        tmp[i,:] = runningTEO(rawSignal, ks[i])
        v = var(tmp[i,:])

        #apply the window
        #win = hamming( 4*ks(i)+1, 'symmetric')
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
