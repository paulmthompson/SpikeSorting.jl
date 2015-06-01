module ExtractSpikes

using DSP

export filterSignal, initFilter, detectSpikes, runningStd, getThres

#Hd is an array of transfer function coefficients to filter the signal (default is 300 3000 band pass)

#I think the hardware already does/can do all of the filtering before it gets here

#This runs first and calls detect spikes
function extractSpikes(rawSignal::Array{Int32,1}, Hd::Array{Float64,2},detectionMethod::String)

    #Set default params
  
    #Calculate the to-be-thresholded signal, depending on the method used

    #Compute signal for peak finding, if required.

    #call detectSpikes
    
end

function detectSpikes(rawSignal::Array{Int32,1},k::Int64,thres::Float64)
    
    #could make the threshold input a starting point and continuously update with a running std (can also be calculated from a and b in loop
    
    inds=zeros(Int64,1)
    index=0
    a = 0
    b = 0
    p_temp=zeros(Float64,50)
    
    for i=1:k
        a += rawSignal[i]
        b += rawSignal[i]^2
    end

    c=rawSignal[1]
    d=rawSignal[1]^2

    #probably don't want to actually go all the way to the end since things may be cut off
    for i=(k+1):length(rawSignal)
        
        a += rawSignal[i] - c
        b += rawSignal[i]^2 - d
      
        # equivalent to p = sqrt(1/n * sum( (f(t-i) - f_bar(t))^2))
        p=sqrt((b - a^2/k)/k) #This is an implicit int32 to float64 conversion. probably need to fix this       
        c=rawSignal[i-k+1]
        d=rawSignal[i-k+1]^2

        if index>0
            
            p_temp[50-index+1]=p
            index+=-1
            
            if index==0

                #If no clear peak is found, assign to noise
                
                j=indmax(p_temp)

                #Add peak to index list
                push!(inds,i-50+j)
            end
       
        elseif p>thres
                
            p_temp[1]=p
            index=49
 
        end
                   
    end
    
    return inds
    
end

function getThres(rawSignal::Array{Int32,1},method::String)

    if method=="POWER"

        p=runningPower(rawSignal,20)
        
        #threshold should be 5 * std(power)
        threshold=mean(p)+5*std(p)
        
    elseif method=="SIGNAL"

    elseif method=="TEST"

        threshold=1.0

    end
    
    return threshold
    
end

function runningStd(rawSignal::Array{Int32,1},k::Int64)

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

function runningPower(rawSignal::Array{Int32,1},k::Int64)
    
    #running power
    p=Array(Float64,length(rawSignal)-k)
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
        p[i-k]=sqrt((b - a^2/k)/k)
        c=rawSignal[i-k+1]
        d=rawSignal[i-k+1]^2
        
    end

    return p
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

end
