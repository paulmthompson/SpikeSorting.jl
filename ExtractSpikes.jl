module ExtractSpikes

export detectSpikes, getThres, SpikeDetection, prepareCal, Cluster, Sorting, PowerDetection, SignalDetection, NEODetection

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

type Sorting
    s::SpikeDetection
    c::Cluster
    rawSignal::Array{Int,1}
    electrode::Array{Int,1}
    neuronnum::Array{Int,1}
    numSpikes::Int
    waveforms::Array{Int,2}
end

function prepareCal(sort::Sorting,k=20)

    for i=1:k
        sort.s.a += sort.rawSignal[i]
        sort.s.b += sort.rawSignal[i]^2
    end

    sort.s.c=sort.rawSignal[1]

    for i=(k+1):75
        sort.s.a += sort.rawSignal[i] - sort.s.c
        sort.s.b += sort.rawSignal[i]^2 - sort.s.c^2
        sort.s.c = sort.rawSignal[i-k+1]

    end
    
    sort.s.sigend=sort.rawSignal[1:75]
      
end

function detectSpikes(sort::Sorting,func::Function,start=1,k=20)
   
    for i=start:length(sort.rawSignal)

        #Calculate theshold comparator
        #This is WAY slower. thought the extra function call would add a little overhead, but not an order of magnitude. need to figure out why
        #p=func(sort,i)

        sort.s.a += sort.rawSignal[i] - sort.s.c
        sort.s.b += sort.rawSignal[i]^2 - sort.s.c^2   

        # equivalent to p = sqrt(1/n * sum( (f(t-i) - f_bar(t))^2))
        p=sqrt((sort.s.b - (sort.s.a^2)/k)/k)

        if i>20
            sort.s.c=sort.rawSignal[i-k+1]
        else
            sort.s.c=sort.s.sigend[i+55]
        end

        #continue collecting spike information if there was a recent spike
        if sort.s.index>0
            
            sort.s.p_temp[sort.s.index]=p
            sort.s.index-=1

            #If end of spike window is reached, continue spike detection
            if sort.s.index==0

                #If clear peak is found
                if true

                    #alignment (power based)
                    j=indmax(sort.s.p_temp)

                    #50 time stamp (2.5 ms) window
                    assignSpike!(sort,i,j)
                    
                else
                    #If no clear peak, assign to noise
                    
                end

                #reset temp matrix
                sort.s.p_temp=zeros(Float64,size(sort.s.p_temp))
                  
            end

        #check if there was a threshold crossing
        elseif p>sort.s.thres
                
            sort.s.p_temp[50]=p
            sort.s.index=49
 
        end
                   
    end

    sort.s.sigend=sort.rawSignal[(end-76):end]
    
end

function PowerDetection(sort::Sorting, i::Int,k=20)
    
    sort.s.a += sort.rawSignal[i] - sort.s.c
    sort.s.b += sort.rawSignal[i]^2 - sort.s.c^2   

    # equivalent to p = sqrt(1/n * sum( (f(t-i) - f_bar(t))^2))
    p=sqrt((sort.s.b - (sort.s.a^2/k))/k)

    if i>20
        sort.s.c=sort.rawSignal[i-k+1]
    else
        sort.s.c=sort.s.sigend[i+55]
    end

    return p
    
end

function SignalDetection(sort::Sorting,i::Int)

    return sort.rawSignal[i]
    
end

function NEODetection(sort::Sorting,i::Int)

    if i==length(sort.rawSignal)
        #GOTO onlineSort?
        psi=0
    elseif i>1
        psi=sort.rawSignal[i]^2 - sort.rawSignal[i+1] * sort.rawSignal[i-1]
    else
        psi=sort.rawSignal[i]^2 - sort.rawSignal[i+1] * sort.sigend[end]

    end

    return psi
    
end

function assignSpike!(sort::Sorting,mytime::Int64,ind::Int64,window=25)
   
    #If a spike was still being analyzed from 
    if mytime<window
        if ind>mytime+window
            sort.waveforms[:,sort.numSpikes]=sort.s.sigend[length(sort.s.sigend)-ind-window:length(sort.s.sigend)-ind+window-1]
        else
            sort.waveforms[:,sort.numSpikes]=[sort.s.sigend[length(sort.s.sigend)-ind-window:end],sort.rawSignal[1:window-(ind-mytime)-1]]
        end   
            x=getDist(sort)
    else        
        #Will return cluster for assignment or 0 indicating did not cross threshold
        sort.waveforms[:,sort.numSpikes]=sort.rawSignal[mytime-ind-window:mytime-ind+window-1]
        x=getDist(sort)
    end
    
    #add new cluster or assign to old
    if x==0

        sort.c.clusters[:,sort.c.numClusters+1]=sort.waveforms[:,sort.numSpikes]
        sort.c.clusterWeight[sort.c.numClusters+1]=1

        sort.c.numClusters+=1
        #Assign to new cluster
        sort.neuronnum[sort.numSpikes]=sort.c.numClusters

    else
        
        #average with cluster waveform
        if sort.c.clusterWeight[x]<20
            sort.c.clusterWeight[x]+=1
            sort.c.clusters[:,x]=(sort.c.clusterWeight[x]-1)/sort.c.clusterWeight[x]*sort.c.clusters[:,x]+1/sort.c.clusterWeight[x]*sort.waveforms[:,sort.numSpikes]
            
        else
            
           sort.c.clusters[:,x]=.95.*sort.c.clusters[:,x]+.05.*sort.waveforms[:,sort.numSpikes]

        end

        sort.neuronnum[sort.numSpikes]=x
        
    end

    #Spike time stamp
    sort.electrode[sort.numSpikes]=mytime-ind
    sort.numSpikes+=1

    if sort.c.numClusters>1
        merged=findMerge!(sort)
    end

end


function getThres(sort::Sorting,method::ASCIIString)

    if method=="POWER"
        
        #threshold should be 5 * std(power)
        threshold=runningPower(sort,20)
        
    elseif method=="SIGNAL"

        #from Quian Quiroga et al 2004
        threshold=median(abs(sort.rawSignal))/.6745

    elseif method=="NEO"

        threshold=runningNEO(sort)

    elseif method=="TEST"

        threshold=1.0

    end
    
    return threshold
    
end

function getDist(sort::Sorting)
    
    dist=Array(Float64,sort.c.numClusters)
    for i=1:sort.c.numClusters
        dist[i]=norm(sort.waveforms[:,sort.numSpikes]-sort.c.clusters[:,i])
    end

    #Need to account for no clusters at beginning
    ind=indmin(dist)

    if dist[ind]<sort.c.Tsm
        return ind
    else
        return 0
    end
    
end

function findMerge!(sort::Sorting)
    #if two clusters are below threshold distance away, merge them

    skip=0
    merger=0

    for i=1:sort.c.numClusters-1
        
        if i==skip
            continue
        end
        
        for j=(i+1):sort.c.numClusters
                dist=norm(sort.c.clusters[:,i]-sort.c.clusters[:,j])
            if dist<sort.c.Tsm
                for k=1:size(sort.c.clusters[:,i],1)
                    sort.c.clusters[k,i]=(sort.c.clusters[k,i]+sort.c.clusters[k,j])/2
                end
                sort.c.numClusters-=1
                skip=j
                merger=i
            end
        end
    end

    if skip!=0

        for i=skip:sort.c.numClusters+1
            sort.c.clusters[:,i]=sort.c.clusters[:,i+1]
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

function runningPower(sort::Sorting,k::Int64)
    
    #running power
    p=Array(Float64,size(sort.rawSignal,1)-k)
    a = 0
    b = 0
    for i=1:k
        a += sort.rawSignal[i]
        b += sort.rawSignal[i]^2
    end

    c = sort.rawSignal[1]
    
    for i=(k+1):(size(sort.rawSignal,1)-1)
        
        a += sort.rawSignal[i] - c
        b += sort.rawSignal[i]^2 - c^2
        p[i-k]=sqrt((b - a^2/k)/k)
        c = sort.rawSignal[i-k+1]
        
    end

    thres=mean(p)+5*std(p)
    
    return thres

end

function runningNEO(sort::Sorting)

    psi=zeros(Int,length(sort.rawSignal)-1)
    
    for i=2:length(sort.rawSignal)-1
        psi[i]=sort.rawSignal[i]^2 - sort.rawSignal[i+1] * sort.rawSignal[i-1]
    end

    thres=3*mean(psi)

    return thres
    
end


end
