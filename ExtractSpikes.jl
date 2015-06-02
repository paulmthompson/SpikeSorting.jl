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

function detectSpikes(rawSignal::Array{Int32,1},thres::Float64,Tsm::Float64,clusters::Array{Float64,2},clusterWeight::Array{Int64,1},n=20000,k=20)
    
    #could make the threshold input a starting point and continuously update with a running std (can also be calculated from a and b in loop
    
    index=0
    a = 0
    b = 0
    p_temp=zeros(Float64,size(clusters,1))
    inds=zeros(Int64,1)
    spikes=zeros(Int64,1)
    
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
            
            p_temp[index]=p
            index-=1
            
            if index==0

                #If clear peak is found
                if true

                    #alignment (power based)
                    j=indmax(p_temp)

                    x=assignSpike!(rawSignal[i-j-25:1:i-j+24],clusters,clusterWeight,Tsm)
            
                    #Spike time stamp
                    push!(spikes,x)
                    push!(inds,i-j)

                else
                    #If no clear peak, assign to noise
                    
                end
                  
            end
       
        elseif p>thres
                
            p_temp[50]=p
            index=49
 
        end
                   
    end
    
    return (inds,spikes)
    
end

function assignSpike!(signal,clusters,clusterWeight,Tsm)

    #Will return cluster for assignment or 0 indicating did not cross threshold
    x=getDist(signal,clusters,Tsm)

    #add new cluster or assign to old
    if x==0

        clusters=hcat(clusters,signal)
        push!(clusterWeight,1)
        
        #Assign to new cluster
        out=size(clusters,2)

    else
        
        #average with cluster waveform
        if clusterWeight[x]<20
            clusterWeight[x]+=1
            clusters[:,x]=(clusterWeight[x]-1)/clusterWeight[x]*clusters[:,x]+1/clusterWeight[x]*signal
            
        else
            
            clusters[:,x]=.95.*clusters[:,x]+.05.*signal

        end

        out=x
        
    end

    return out

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

function getDist(signal::Array{Int32,1},clusters::Array{Float64,2},Tsm::Float64)

    dist=Array(Float64,size(clusters,2))
    for i=1:size(clusters,2)
        dist[i]=norm(signal-clusters[:,i])
    end

    ind=indmin(dist)

    if dist[ind]<Tsm
        return ind
    else
        return 0
    end
    
end

function findMerge!(clusters::Array{Float64,2},Tsm::Float64)
    #if two clusters are close to each other, merge them together and assign spikes from both to one new cluster

    for i=1:size(clusters,2)
        for j=i:size(clusters,2)
            if j!=i
                dist=norm(clusters[:,i]-clusters[:,j])
                if dist<Tsm
                    
                    
            end
        end
    end
    
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
