module ExtractSpikes

export detectSpikes, getThres, SpikeDetection, prepareCal, Cluster

type SpikeDetection
    #These are needed to so that when the next chunk of real time data is to be processed, it preserved all of the processing information collected from the last chunk
    #If it was in the middle of capturing the shape of a spike, it will be able to faithfully continue
    a::Int64
    b::Int64
    c::Int64
    index::Int64
    sigend::Array{Int64,1}
    p_temp::Array{Float64,1}
    s_temp::Array{Int64,1}
    thres::Float64
end

function SpikeDetection()
    return SpikeDetection(0,0,0,0,zeros(Int64,75),zeros(Float64,50),zeros(Int64,1),1.0)
end

function SpikeDetection(n::Int64,k::Int64)
    return SpikeDetection(0,0,0,0,zeros(Int64,k),zeros(Float64,n),zeros(Int64,1),1.0)
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

function prepareCal(s::SpikeDetection,rawSignal::Array{Int64,2},num,k=20)

    for i=1:k
        s.a += rawSignal[i,num]
        s.b += rawSignal[i,num]^2
    end

    s.c=rawSignal[1,num]
    
    s.sigend=rawSignal[1:75,num]
      
end

function detectSpikes(s::SpikeDetection,clus::Cluster,rawSignal::Array{Int64,2},num::Int64,start=1,k=20)

    spikes=zeros(Int64,1)
    inds=zeros(Int64,1)
    
    for i=start:size(rawSignal,1)
        
        s.a += rawSignal[i,num] - s.c
        s.b += rawSignal[i,num]^2 - s.c^2   

        # equivalent to p = sqrt(1/n * sum( (f(t-i) - f_bar(t))^2))
        p=sqrt((s.b - s.a^2/k)/k) #This is an implicit int64 to float64 conversion. probably need to fix this

        if i>20
            s.c=rawSignal[i-k+1,num]
        else
            s.c=s.sigend[i+55]
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
                    x=assignSpike!(rawSignal,clus,s,num,i,j)
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

                #reset temp matrix
                s.p_temp=zeros(Float64,size(s.p_temp))
                  
            end
       
        elseif p>s.thres
                
            s.p_temp[50]=p
            s.index=49
 
        end
                   
    end

    s.sigend=rawSignal[(end-(50+25)+1):end,num]

    return (spikes,inds)
       
end

function assignSpike!(rawSignal::Array{Int64,2},clus::Cluster,s::SpikeDetection,num::Int64,mytime::Int64,ind::Int64,window=25)

    #If a spike was still being analyzed from 
    if mytime<window
        if ind>mytime+window
            signal=s.sigend[length(s.sigend)-ind-window:length(s.sigend)-ind+window-1]
        else
            signal=[s.sigend[length(s.sigend)-ind-window:end],rawSignal[1:window-(ind-mytime)-1,num]]
        end   
            x=getDist(signal,clus)
    else        
        #Will return cluster for assignment or 0 indicating did not cross threshold
        myrange=mytime-ind-window:mytime-ind+window-1
        x=getDist(rawSignal,clus,num,myrange)
    end
    
    #add new cluster or assign to old
    if x==0

        clus.clusters[:,clus.numClusters+1]=rawSignal[myrange,num]
        clus.clusterWeight[clus.numClusters+1]=1

        clus.numClusters+=1
        #Assign to new cluster
        out=clus.numClusters

    else
        
        #average with cluster waveform
        if clus.clusterWeight[x]<20
            clus.clusterWeight[x]+=1
            clus.clusters[:,x]=(clus.clusterWeight[x]-1)/clus.clusterWeight[x]*clus.clusters[:,x]+1/clus.clusterWeight[x]*rawSignal[myrange,num]
            
        else
            
           clus.clusters[:,x]=.95.*clus.clusters[:,x]+.05.*rawSignal[myrange,num]

        end

        out=x
        
    end

    return out

end


function getThres(rawSignal::Array{Int64,2},method::String,num::Int64)

    if method=="POWER"
        
        #threshold should be 5 * std(power)
        threshold=runningPower(rawSignal,20,num)
        
    elseif method=="SIGNAL"

        threshold=1.0

    elseif method=="TEST"

        threshold=1.0

    end
    
    return threshold
    
end

function getDist(rawSignal::Array{Int64,2},clus::Cluster,num::Int64,range::UnitRange{Int64})

    dist=Array(Float64,clus.numClusters)
    for i=1:clus.numClusters
        dist[i]=norm(rawSignal[range,num]-clus.clusters[:,i])
    end

    #Need to account for no clusters at beginning
    ind=indmin(dist)

    if dist[ind]<clus.Tsm
        return ind
    else
        return 0
    end
    
end

function getDist(rawSignal::Array{Int64,1},clus)
    
    dist=Array(Float64,clus.numClusters)
    for i=1:clus.numClusters
        dist[i]=norm(rawSignal-clus.clusters[:,i])
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
                for k=1:size(clus.clusters[:,i],1)
                    clus.clusters[k,i]=(clus.clusters[k,i]+clus.clusters[k,j])/2
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

function runningPower(rawSignal::Array{Int64,2},k::Int64,num::Int64)
    
    #running power
    p=Array(Float64,size(rawSignal,1)-k)
    a = 0
    b = 0
    for i=1:k
        a += rawSignal[i,num]
        b += rawSignal[i,num]^2
    end

    c = rawSignal[1,num]
    
    for i=(k+1):(size(rawSignal,1)-1)
        
        a += rawSignal[i,num] - c
        b += rawSignal[i,num]^2 - c^2
        p[i-k]=sqrt((b - a^2/k)/k)
        c = rawSignal[i-k+1,num]
        
    end

    thres=mean(p)+5*std(p)
    
    return thres

end

end
