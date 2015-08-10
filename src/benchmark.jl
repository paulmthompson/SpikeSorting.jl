



function benchmark{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(dataset::Array{Int64,2},sort::Sorting{D,C,A,F,R})

    #Benchmark data should have first column as voltage time series
    #Every additional columnn should be 1's and 0's corresponding a particular neuron firing

    cal_length=30 # seconds
    sample_rate=20000 #hertz
    
    #Calibrate
    counter=1
    while counter<cal_length*sample_rate
        sort.rawSignal[:]=dataset[counter:(counter+sample_rate-1),1]
        if counter==1
            firstrun(sort)
        else
            cal(sort)
        end
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
    accuracy_bench(electrode,neuronnum,dataset,cal_length*sample_rate)
           
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

function accuracy_bench(electrode::Array{Int64,1},neuronnum::Array{Int64,1},dataset::Array{Int64,2},start::Int64)
    #this is much harder than i expected it to be. maybe i'm not thinking this through right

    #clustering miss
    # How to determine which cluster corresponds to which neuron?
    # FP - assigned to cluster when there is no corresponding spike in that window
    # FN - did not assign spike to cluster when there was a spike
    
    win_real=Array(Int64,0)
    win_detect=Array(Int64,0)

    next=1

    for i=start:(start+div(overlap_win,2)-1)
        next=update_spikes(neuronnum,win_detect,spike_present,win_real,next,i)
    end
    
    #each neuron has a total number of spikes
    #algorithm will have true positive for each of those neurons or FN/FP for one of the reasons below
    overlap_win=50
    i=start+overlap_win/2
    
    for i=(start+div(overlap_win,2)):(size(dataset,1)-overlap_win)
    
        if spike_present[1]==1
            
            if length(win_detect)<length(win_real) #more spikes than what is detected in window
                if length(win_real)==1
                    #false negative due to threshold
                else
                    #false negative due to overlap
                end  
            elseif length(win_detect)>length(win_real) #more spikes detected than actually exist
                #false positive due to detection
            else #number of spikes that exist equals number that have been detected
                if length(win_detect)==0 #no spikes present, detected correctly
                else
                    #determine if spike was clustered correctly
                    #don't want to duplicate for others in the window
                end
            end
        end
        
        next=update_spikes(neuronnum,win_detect,spike_present,win_real,next,i)
        
    end
   
end

function update_spikes(neuronnum::Array{Int64,1},win_detect::Array{Int64,1},spike_present::Array{Int64,1},win_real::Array{Int64,1},next::Int64,i::Int64)
    
    if neuronnum[next]==i
        push!(win_detect,25)
        push!(spike_present,25)
        next+=1
    end

    for j=2:size(dataset,2)
        if dataset[i,j]==1
            push!(win_real,25)
            push!(spike_present,25)
        end
    end

    win_detect=win_detect-1
    win_real=win_real-1
    spike_present=spike_present-1

    if win_detect[1]<-25
        shift!(win_detect)
    end

    for j in win_real
        if j<-25
            shift!(win_real)
        end
    end

    for j in spike_present
        if j<1
            shift!(spike_present)
        end
    end

    next
    
end

#ISI violation calculation

#Generate benchmark dataset

#Speed / neuron

#parallel vs not parallel
