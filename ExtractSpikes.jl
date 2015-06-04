module ExtractSpikes

export detectSpikes, getThres, SpikeDetection, prepareDetection, Cluster

type SpikeDetection
    #These are needed to so that when the next chunk of real time data is to be processed, it preserved all of the processing information collected from the last chunk
    #If it was in the middle of capturing the shape of a spike, it will be able to faithfully continue
    a::Int64
    b::Int64
    c::Int64
    index::Int64
    sigend::Array{Int64,1}
    p_temp::Array{Float64,1}
    thres::Float64
end

function SpikeDetection()
    return SpikeDetection(0,0,0,0,zeros(Int64,20),zeros(Float64,50),1.0)
end

function SpikeDetection(n::Int64,k::Int64)
    return SpikeDetection(0,0,0,0,zeros(Int64,k),zeros(Float64,n),1.0)
end

type Cluster
    #These fields represent data that needs to be stored over the experiment about waveforms that have been determined
    clusters::Array{Float64,2}
    clusterWeight::Array{Int64,1}
    numClusters::Int64
    Tsm::Float64
end

function Cluster()
    
    return Cluster(hcat(rand(Float64,50,1),zeros(Float64,50,4)),zeros(Int64,5),1,1.0)
    
end

function Cluster(n::Int64)
    Cluster(hcat(rand(Float64,n,1),zeros(Float64,n,4)),zeros(Int64,5),1,1.0)
    return 
end

function prepareDetection(s::SpikeDetection,rawSignal::Array{Int64,1},k=20)

    for i=1:k
        s.a += rawSignal[i]
        s.b += rawSignal[i]^2
    end

    s.c=rawSignal[1]
    
    s.sigend=rawSignal[1:20]
      
end

function detectSpikes(s::SpikeDetection,clus::Cluster,rawSignal::Array{Int64,1},k=20)

    spikes=zeros(Int64,1)
    inds=zeros(Int64,1)
    
    for i=1:length(rawSignal)
        
        s.a += rawSignal[i] - s.c
        s.b += rawSignal[i]^2 - s.c^2   

        # equivalent to p = sqrt(1/n * sum( (f(t-i) - f_bar(t))^2))
        p=sqrt((s.b - s.a^2/k)/k) #This is an implicit int64 to float64 conversion. probably need to fix this

        if i>20
            s.c=rawSignal[i-k+1]
        else
            s.c=s.sigend[i]
        end
        
        if s.index>0
            
            s.p_temp[s.index]=p
            s.index-=1
            
            if s.index==0

                #If clear peak is found
                if true

                    #alignment (power based)
                    j=indmax(s.p_temp)

                    #50 time stamp (2.5 ms) window
                    x=assignSpike!(rawSignal[i-j-25:1:i-j+24],clus)
                    
                    #Spike time stamp
                    #Maybe preallocation of a large array is better here?
                    push!(spikes,x)
                    push!(inds,i-j)

                    if clus.numClusters>1
                        merged=findMerge!(clus)
                    end
                    
                else
                    #If no clear peak, assign to noise
                    
                end
                  
            end
       
        elseif p>s.thres
                
            s.p_temp[50]=p
            s.index=49
 
        end
                   
    end

    s.sigend=rawSignal[(end-k+1):end]

    return (spikes,inds)
       
end

function assignSpike!(signal::Array{Int64,1},clus::Cluster)

    #Will return cluster for assignment or 0 indicating did not cross threshold
    x=getDist(signal,clus)

    #add new cluster or assign to old
    if x==0

        clus.clusters[:,clus.numClusters+1]=signal
        clus.clusterWeight[clus.numClusters+1]=1

        clus.numClusters+=1
        #Assign to new cluster
        out=clus.numClusters

    else
        
        #average with cluster waveform
        if clus.clusterWeight[x]<20
            clus.clusterWeight[x]+=1
            clus.clusters[:,x]=(clus.clusterWeight[x]-1)/clus.clusterWeight[x]*clus.clusters[:,x]+1/clus.clusterWeight[x]*signal
            
        else
            
           clus.clusters[:,x]=.95.*clus.clusters[:,x]+.05.*signal

        end

        out=x
        
    end

    return out

end


function getThres(rawSignal::Array{Int64,1},method::String)

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

function getDist(signal::Array{Int64,1},clus::Cluster)

    dist=Array(Float64,clus.numClusters)
    for i=1:clus.numClusters
        dist[i]=norm(signal-clus.clusters[:,i])
    end

    #Need to account for no clusters at beginning
    ind=indmin(dist)

    if dist[ind]<clus.Tsm
        return ind
    else
        return 0
    end
    
end

function findMerge!(clus::Cluster)
    #if two clusters are below threshold distance away, merge them

    skip=0
    merger=0

    for i=1:clus.numClusters-1
        
        if i==skip
            continue
        end
        
        for j=(i+1):clus.numClusters
                dist=norm(clus.clusters[:,i]-clus.clusters[:,j])
            if dist<clus.Tsm
                for k=1:size(clusters[:,i],1)
                    clus.clusters[k,i]=(clus.clusters[k,i]+clusters[k,j])/2
                end
                clus.numClusters-=1
                skip=j
                merger=i
            end
        end
    end

    if skip!=0

        for i=skip:clus.numClusters+1
            clus.clusters[:,i]=clus.clusters[:,i+1]
        end
    end

    return [skip,merger]
    
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

end
