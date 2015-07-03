

function detectspikes(sort::Sorting,func::detection,start=1,k=20)

    #Threshold comparator
    p=0.0

    for i=start:length(sort.rawSignal)

        #Calculate theshold comparator
        p=func(sort,i)
        
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
                    assignspike!(sort,i,j)
                    
                else
                    #If no clear peak, assign to noise
                    
                end

                #reset temp matrix
                sort.s.p_temp[:]=zeros(Float64,size(sort.s.p_temp))
                  
            end

        elseif p>sort.s.thres
                
            sort.s.p_temp[50]=p
            sort.s.index=49
 
        end
                   
    end

    sort.s.sigend[:]=sort.rawSignal[(end-74):end]
    
end


function assignspike!(sort::Sorting,mytime::Int64,ind::Int64,window=25)
   
    #If a spike was still being analyzed from 
    if mytime<window
        if ind>mytime+window
            sort.waveforms[sort.numSpikes][:]=sort.s.sigend[length(sort.s.sigend)-ind-window:length(sort.s.sigend)-ind+window-1]
        else
            sort.waveforms[sort.numSpikes][:]=[sort.s.sigend[length(sort.s.sigend)-ind-window:end],sort.rawSignal[1:window-(ind-mytime)-1]]
        end   
            x=getdist(sort)
    else        
        #Will return cluster for assignment or 0 indicating did not cross threshold
        sort.waveforms[sort.numSpikes][:]=sort.rawSignal[mytime-ind-window:mytime-ind+window-1]
        x=getdist(sort)
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
            sort.c.clusters[:,x]=(sort.c.clusterWeight[x]-1)/sort.c.clusterWeight[x]*sort.c.clusters[:,x]+1/sort.c.clusterWeight[x]*sort.waveforms[sort.numSpikes][:]
            
        else
            
           sort.c.clusters[:,x]=.95.*sort.c.clusters[:,x]+.05.*sort.waveforms[sort.numSpikes][:]

        end

        sort.neuronnum[sort.numSpikes]=x
        
    end

    #Spike time stamp
    sort.electrode[sort.numSpikes]=mytime-ind

    #add spike cluster identifier to dummy first waveform shared array
    sort.waveforms[1][sort.numSpikes]=sort.neuronnum[sort.numSpikes]
    
    sort.numSpikes+=1


    if sort.c.numClusters>1
        merged=findmerge!(sort)
    end

end


function getthres(sort::Sorting,method::ASCIIString)

    #Change this to function call being passed
    if method=="POWER"
        
        threshold=threshold_power(sort)
        
    elseif method=="SIGNAL"

        threshold=threshold_signal(sort)

    elseif method=="NEO"

        threshold=threshold_neo(sort)

    end
    
    threshold
    
end

function getdist(sort::Sorting)
    
    dist=Array(Float64,sort.c.numClusters)
    for i=1:sort.c.numClusters
        dist[i]=norm(sort.waveforms[sort.numSpikes][:]-sort.c.clusters[:,i])
    end

    #Need to account for no clusters at beginning
    ind=indmin(dist)

    if dist[ind]<sort.c.Tsm
        return ind
    else
        return 0
    end
    
end

function findmerge!(sort::Sorting)
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

    [skip,merger]
    
end

