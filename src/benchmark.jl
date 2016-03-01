



function benchmark(dataset::Array{Int64,1},truth::Array{Array{Int64,1},1},s::Sorting,cal_length=15.0, sample_rate=20000)

    #Benchmark data should have first column as voltage time series
    #Every additional columnn should be 1's and 0's corresponding a particular neuron firing
    
    #Calibrate

    (buf,nums)=output_buffer(1);

    cal_samples=round(Int,sample_rate*cal_length)
    v=zeros(Int64,div(cal_samples,2),1)

    #Threshold calibration for first half of calibration time
    v[:,1]=dataset[1:size(v,1),1]
    cal!(s,v,buf,nums,0)

    #Clustering / DM calibration for second half of calibration time
    v[:,1]=dataset[(size(v,1)+1):(2*size(v,1)),1]
    cal!(s,v,buf,nums,2)

    #Sort

    spikes=Array(Array{Int64,1},0)
    v=zeros(Int64,sample_rate,1)
    num_clusters=0
    
    for i=cal_samples+1:div(sample_rate,20):(round(Int64,length(dataset)/sample_rate)*sample_rate-sample_rate)

        v[:,1]=dataset[i:(i+sample_rate-1),1]
        onlinesort!(s,v,buf,nums)

        for k=1:nums[1]
            if buf[k,1].id>num_clusters
                num_clusters=buf[k,1].id
                push!(spikes,zeros(Int64,0))
            end
            push!(spikes[buf[k,1].id],buf[k,1].inds[1]+i+25)
            buf[k,1]=Spike()
        end
        nums[1]=0
    end

    #ISI violations

    #Accuracy due to overlap, clustering, and detection phases
    corrmat=accuracy_bench(dataset,spikes,truth,cal_length,sample_rate)

    #speed calculations

    (spikes,corrmat)
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

function accuracy_bench(dataset::Array{Int64,1},spikes::Array{Array{Int64,1},1},truth::Array{Array{Int64,1},1},cal_length::Float64, sample_rate::Int64)

    #first go through detected spikes to classify as false positives or true positives
    #then go through ground truth to look for false negatives

    #need to figure out what cluster corresponds to what neuron
    corrmat=zeros(Float64,length(truth),length(spikes))

    data_s=zeros(Int64,length(dataset))
    data_t=zeros(Int64,length(dataset))

    for i=1:length(spikes)

        data_s[:]=0
        for k in spikes[i]
            if k+25<length(dataset)
                data_s[k-25:k+25]=1
            end
        end
        
        for j=1:length(truth)
            data_t[:]=0
            for k in truth[j]
                if k+25<length(dataset)
                    data_t[k-25:k+25]=1
                end
            end

            test=data_s+data_t

            l=1
            while l<length(test)-1
                if test[l]>1
                    l+=1
                    forward=true
                    while forward
                        if test[l]>1
                            test[l]=0
                            l+=1
                        else
                            forward=false
                        end
                    end
                end
                l+=1
            end

            corrmat[j,i]=sum(test.>1)/length(truth[j])*100.0
        end
    end
    
    #=
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
    win=25
    for i=1:length(electrode) #loop through all detected spikes
        if assignedd[neuronnum[i]]==0 #if this cluster doesn't even exist, FP
            FP_C+=1
        else
            found=false
            for j=(electrode[i]-win):(electrode[i]+win)
                if dataset[j,assignedd[neuronnum[i]]]==1 #found
                    TP+=1
                    found=true
                    dataset[j,assigned[neuronnum[i]]]=-1
                    break
                end
            end
            if found==false #If no TP, determine if FP is from overlap or clustering
                totalspikes=sum(abs(dataset[(electrode[i]-win):(electrode[i]+win),2:end]))
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
                overlap=sum(abs(dataset[(i-win):(i+win),2:end]))
                if overlap>1
                    FN_O+=1
                else
                    FN_C+=1
                end
            else
            end
        end
    end
    =#
  corrmat
end

#ISI violation calculation
function ISI_violations(electrode::Array{Int64,1},neuronnum::Array{Int64,1},numspikes::Int64)

end


#Speed / neuron

#parallel vs not parallel
