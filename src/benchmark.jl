



function benchmark(dataset::D,truth::Array{Array{Int64,1},1},s::Sorting,cal_length=15.0, sample_rate=20000) where D

    (buf,nums)=output_buffer(1)

    #Calibrate

    cal_samples=round(Int,sample_rate*cal_length)
    v=zeros(eltype(dataset),div(cal_samples,2),1)

    #Threshold calibration for first half of calibration time
    v[:,1]=dataset[1:size(v,1),1]
    cal!(s,v,buf,nums,0)

    #Clustering / DM calibration for second half of calibration time
    v[:,1]=dataset[(size(v,1)+1):(2*size(v,1)),1]
    cal!(s,v,buf,nums,2)

    iter=div(sample_rate,20)
    spikes=[Array{Int64,1}() for i=0:0]
    v=zeros(eltype(dataset),iter,1)
    num_clusters=0

    for i=cal_samples+1:iter:(round(Int64,length(dataset)/sample_rate)*sample_rate-sample_rate)

        v[:,1]=dataset[i:(i+iter-1),1]
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
    (spike_totals,TP,myFP,myFN)=accuracy_bench(dataset,spikes,truth,cal_length,sample_rate)

    #speed calculations

    (spikes,spike_totals,TP,myFP,myFN)
end

#=
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
=#

function accuracy_bench(dataset::D,spikes::Array{Array{Int64,1},1},truth::Array{Array{Int64,1},1},cal_length::Float64, sample_rate::Int64) where D

    #first go through detected spikes to classify as false positives or true positives
    #then go through ground truth to look for false negatives

    #need to figure out what cluster corresponds to what neuron
    corrmat=zeros(Float64,length(truth),length(spikes))

    cal_samples=round(Int,sample_rate*cal_length)
    data_s=zeros(eltype(dataset),length(dataset))
    data_t=zeros(eltype(dataset),length(dataset))

    for i=1:length(spikes)

        data_s[:]=0
        for k in spikes[i]
            if k+25<length(dataset)
                if k>cal_samples
                    data_s[k-25:k+25]=1
                end
            end
        end

        for j=1:length(truth)
            data_t[:]=0
            spike_num=0
            for k in truth[j]
                if k+25<length(dataset)
                    if k>cal_samples
                        data_t[k-25:k+25]=1
                        spike_num+=1
                    end
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
            corrmat[j,i]=sum(test.>1)/spike_num*100.0
        end
    end

    assignedd=zeros(Int64,length(spikes)) #zero indicates it doesn't correspond to anything
    assigneds=falses(length(truth))
    count=1

    overlaps=zeros(Int64,length(dataset))
    spike_totals=zeros(Int64,length(truth))

    for i=1:length(truth)
        for k in truth[i]
            if k+25<length(dataset)
                if k>cal_samples
                    overlaps[k-25:k+25]+=1
                    spike_totals[i]+=1
                end
            end
        end
    end

    mytotals=zeros(Int64,length(dataset))
    for i=1:length(truth)
        for k in truth[i]
            if k+25<length(dataset)
                if k>cal_samples
                    mytotals[k]+=2^i
                end
            end
        end
    end

    if length(truth)>=length(spikes) #fewer neurons (or equal) detected than actually exist
        while count <= length(spikes)
            myinds=ind2sub(size(corrmat),indmax(corrmat))

            assignedd[myinds[2]]=myinds[1]
            assigneds[myinds[1]]=true
            count+=1

            corrmat[myinds[1],:]=0.0
            corrmat[:,myinds[2]]=0.0
        end

    else #more neurons detected than actually exist
        while count <= length(truth)
            myinds=ind2sub(size(corrmat),indmax(corrmat))

            assignedd[myinds[2]]=myinds[1]
            assigneds[myinds[1]]=true
            count+=1

            corrmat[myinds[1],:]=0.0
            corrmat[:,myinds[2]]=0.0
        end
    end

    TP=0
    FP_C=0
    FP_O=0
    FP_N=0
    FN_T=0
    FN_O=0
    #1 yet undetected
    #-1 detected
    tol=10

    missed=[zeros(Int64,0) for i=1:length(truth)]

    for i=1:length(spikes)
        if assignedd[i]==0
            FP_C+=sum(spikes[i].>cal_samples)
        else
            data_t[:]=0
            for k in truth[assignedd[i]]
                if k+tol<length(dataset)
                    if k>cal_samples
                        data_t[k]=k
                    end
                end
            end
            for j=1:length(spikes[i])
                found=false
                for k=(spikes[i][j]-tol):(spikes[i][j]+tol)
                    if data_t[k]>0 #found
                        TP+=1
                        found=true
                        mytotals[k] -= 2^assignedd[i]
                        break
                    end
                end
                if found==false
                    ov=false
                    clus=false
                    fn=false
                    for k=(spikes[i][j]-tol):(spikes[i][j]+tol)
                        if overlaps[k]>1
                            ov=true
                        elseif mytotals[k]>0
                            mytotals[k]=0
                            clus=true
                        end
                    end
                    if ov==true
                        FP_O+=1
                    elseif clus==true
                        FP_C+=1
                    else
                        FP_N+=1
                    end
                end
            end
        end
    end

    #find missed spikes
    for i=1:length(truth)
        for j in truth[i]
            if j>cal_samples
                md=digits(mytotals[j],2)
                if length(md)>i
                    if md[i+1]==1
                        push!(missed[i],j)
                    end
                end
            end
        end
    end

    for i=1:length(missed)
        for j=1:length(missed[i])
            ov=false
            for k=(missed[i][j]-tol):(missed[i][j]+tol)
                if overlaps[k]>1
                    ov=true
                    break
                end
            end
            if ov==true
                FN_O+=1
            else
                FN_T+=1
            end
        end
    end

    println("Spike totals: ", spike_totals)
    println("False Positive Total: ", FP_C+FP_O+FP_N)
    println("False Positive Clustering: ", FP_C)
    println("False Positive Overlap: ", FP_O)
    println("False Positive Noise: ", FP_N)
    println("True Positive: ", TP)
    println("Total False Negative: ", FN_O+FN_T)
    println("False Negative Overlap: ", FN_O)
    println("False Negative Threshold: ", FN_T)

myFP=[FP_C,FP_O,FP_N]
myFN=[FN_O,FN_T]

    (spike_totals,TP,myFP,myFN)
end

#ISI violation calculation
#=
function ISI_violations()

end
=#

#Speed / neuron

#parallel vs not parallel
