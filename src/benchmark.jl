



function benchmark{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(dataset::Array{Int64,2},sort::Sorting{D,C,A,F,R})

    #Benchmark data should have first column as voltage time series
    #Every additional columnn should be 1's and 0's corresponding a particular neuron firing

    cal_length=30 # seconds
    sample_rate=20000 #hertz
    
    #Calibrate

    sort.rawSignal[:]=dataset[1:sample_rate,1]
    firstrun(sort)
    
    counter=sample_rate
    while counter<cal_length*sample_rate
        sort.rawSignal[:]=dataset[counter:(counter+sample_rate-1),1]
        cal(sort)
        counter+=sample_rate
    end

    electrode=zeros(Int64,1)
    neuronnum=zeros(Int64,1)
    elapsedtime=zeros(Int64,1)
    
    while (counter+sample_rate-1)<length(dataset)
        sort.rawSignal[:]=dataset[counter:(counter+sample_rate-1),1]

        tic()
        main(sort)
        push!(elapsedtime,tocq())

        append!(electrode,sort.electrode[1:sort.numSpikes]+counter)
        append!(neuronnum,sort.neuronnum[1:sort.numSpikes]+counter)

    end
    
    #ISI violations

    #Accuracy due to overlap, clustering, and detection phases
    accuracy_bench(electrode,neuronnum,dataset,cal_length*sample_rate,sort.numSpikes)

    #speed calculations
           
end

function benchmark_all(dataset::Array{Int64,2},newstep::Algorithm)

    masterlist=Array(Any,5)

    steps=subtypes(Algorithm)

    for i=1:length(masterlist)        
        if steps[i]!=super(newstep)
            masterlist[i]=subtypes(mystep)
        else
            masterlist[i]=newstep
        end                  
    end

    
end

function accuracy_bench(electrode::Array{Int64,1},neuronnum::Array{Int64,1},dataset::Array{Int64,2},start::Int64,numspikes::Int64)

    #first go through detected spikes to classify as false positives or true positives
    #then go through ground truth to look for false negatives

    #need to figure out what cluster corresponds to what neuron
    myzeros=zeros(Float64,size(dataset,1))
    corrmat=zeros(Float64,size(dataset,2)-1,numspikes)
    
    for i=1:numspikes
        inds=electrode[neuronnum.==i]
        myzeros[inds]=1
        for j=2:size(dataset,2)
            corrmat[j-1,i]=cor(myzeros,dataset[start:end,j])
        end
        myzeros[inds]=0.0
    end

    myinds=(0,0)
    assignedd=zeros(Int64,numspikes) #zero indicates it doesn't correspond to anything
    assigneds=falses(size(dataset,2)-1)
    count=1

    
    if (size(dataset,2)-1)>=numspikes #fewer neurons (or equal) detected than actually exist
        while count <= numspikes
            myinds=ind2sub(size(corrmat),indmax(corrmat))
            if assignedd[myinds[2]]==0 & assigneds[myinds[1]]==false
                assignedd[myinds[2]]=myinds[1]
                assigneds[myinds[1]]=true
                count+=1
            end
            corrmat[myinds[1],myinds[2]]=0.0
        end
  
    elseif numspikes>(size(dataset,2)-1) #more neurons detected than actually exist
        while count < size(dataset,2)
            myinds=ind2sub(size(corrmat),indmax(corrmat))
            if assignedd[myinds[2]]==0 & assigneds[myinds[1]]==false
                assignedd[myinds[2]]=myinds[1]
                assigneds[myinds[1]]=true
                count+=1
            end
            corrmat[myinds[1],myinds[2]]=0.0
        end
    end

    TP=0
    FP_C=0
    FP_O=0
    FN_T=0
    FN_O=0
    #1 yet undetected
    #-1 detected
    win=50
    for i=1:length(electrode) #loop through all detected spikes
        if assignedd[neuronnum[i]]==0 #if this cluster doesn't even exist, FP
            FP_C+=1
        else
            found=false
            for j=(electrode[i]-div(win,2)):(electrode[i]+div(win,2))
                if dataset[j,assignedd[neuronnum[i]]]!=1 #found
                    TP+=1
                    found=true
                    dataset[j,assigned[neuronnum[i]]]=-1
                    break
                end
            end
            if found==false #If no TP, determine if FP is from overlap or clustering
                totalspikes=sum(abs(dataset[(electrode[i]-div(win,2)):(electrode[i]+div(win,2)),2:end]))
                if totalspikes>1
                    FP_O+=1
                else
                    FP_C+=1
                end
            else
            end            
        end 
    end

    #Determine FN in real spikes that were not detected
    for i=start:(size(dataset,1)-win)
        for j=2:(size(dataset,2))
            if dataset[i,j]==1 #missed spike
                overlap=sum(abs(dataset[(i-div(win,2)):(i+div(win,2)),2:end]))
                if overlap>1
                    FN_O+=1
                else
                    FN_C+=1
                end
            else
            end
        end
    end
  
end


#ISI violation calculation

#Generate benchmark dataset

#Speed / neuron

#parallel vs not parallel
