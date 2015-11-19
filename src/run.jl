
function firstrun{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R})
    
    #detection initialization
    detectprepare(sort)
    threshold(sort)
    
    sort.sigend[:]=sort.rawSignal[1:75]

    maincal(sort,76)

    return sort
    
end

function firstrun_par{T<:Sorting}(s::DArray{T,1,Array{T,1}})
    map!(firstrun,s)
    nothing
end

function cal{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R})
    
    maincal(sort)    

    #reset things we would normally return
    #Need to reset waveforms
    sort.neuronnum=zeros(size(sort.neuronnum))
    sort.numSpikes=2

    return sort
end

function cal_par{T<:Sorting}(s::DArray{T,1,Array{T,1}})    
    map!(cal,s)
    nothing
end

function onlinesort{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R})
    main(sort)    
    return sort  
end

function onlinesort_par{T<:Sorting}(s::DArray{T,1,Array{T,1}})
    map!(onlinesort,s)
    nothing
end

function offlinesort()
end

#=
Main processing loop for length of raw signal
=#

function main{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R})

    for i=1:signal_length

        p=detect(sort,i)
        
        #continue collecting spike information if there was a recent spike
        if sort.index>0
            
            sort.p_temp[sort.index]=sort.rawSignal[i]
            sort.index+=1

            #If end of spike window is reached, continue spike detection
            if sort.index==101

                align(sort)

                #overlap detection? (probably need to do this in the time domain)
                
                feature(sort)
                    
                cluster(sort)

                #Spike time stamp
                sort.numSpikes+=1        
                sort.index=0
                  
            end

        elseif p>sort.thres
            
            if i<=window
                sort.p_temp[1:(window-i+1)]=sort.sigend[end-(window-i):end]
                sort.p_temp[(window-i):window]=sort.rawSignal[1:i-1]  
            else
                sort.p_temp[1:window]=sort.rawSignal[i-window:i-1]
            end

            sort.p_temp[window+1]=sort.rawSignal[i]
            sort.index=window+2
        end
    end
                   
    sort.sigend[:]=sort.rawSignal[(end-sigend_length+1):end]

    nothing
    
end

#=
Main calibration loop
=#

function maincal{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R},start=1)

    for i=start:signal_length

        p=detect(sort,i)
        
        #continue collecting spike information if there was a recent spike
        if sort.index>0
            
            sort.p_temp[sort.index]=sort.rawSignal[i]
            sort.index+=1

            #If end of spike window is reached, continue spike detection
            if sort.index==101

                align(sort)

                featureprepare(sort)
                
                reductionprepare(sort)

                sort.index=0
                           
            end

        elseif p>sort.thres
            
            if i<=window
                sort.p_temp[1:(window-i+1)]=sort.sigend[end-(window-i):end]
                sort.p_temp[(window-i):window]=sort.rawSignal[1:i-1]  
            else
                sort.p_temp[1:window]=sort.rawSignal[i-window:i-1]
            end

            sort.p_temp[window+1]=sort.rawSignal[i]
            sort.index=window+2
        end
    end
                   
    sort.sigend[:]=sort.rawSignal[(end-sigend_length+1):end]

    nothing

end

