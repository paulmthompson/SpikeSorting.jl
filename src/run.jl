
#=
Main loops for spike sorting

=#


function firstrun{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R},v::Array{Int64,2})
    
    #detection initialization
    detectprepare(sort,v)
    threshold(sort,v)
    
    sort.sigend[:]=v[1:75,sort.id]

    maincal(sort,v,76)

    return sort
    
end

function firstrun_par{T<:Sorting}(s::DArray{T,1,Array{T,1}})
    map!(firstrun,s)
    nothing
end

function cal{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R},v::Array{Int64,2})
    
    maincal(sort,v)    

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

function onlinesort{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R},v::Array{Int64,2})
    main(sort,v)    
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

function main{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R},v::Array{Int64,2})

    for i=1:size(v,1)

        p=detect(sort,i,v)
        
        #continue collecting spike information if there was a recent spike
        if sort.index>0
            
            sort.p_temp[sort.index]=v[i,sort.id]
            sort.index+=1

            #If end of spike window is reached, continue spike detection
            if sort.index==101

                align(sort)

                #overlap detection? (probably need to do this in the time domain)
                
                feature(sort)
                    
                cluster(sort,v)

                #Spike time stamp
                sort.numSpikes+=1        
                sort.index=0
                  
            end

        elseif p>sort.thres
            
            if i<=window
                sort.p_temp[1:(window-i+1)]=sort.sigend[end-(window-i):end]
                sort.p_temp[(window-i):window]=v[1:i-1,sort.id]  
            else
                sort.p_temp[1:window]=v[i-window:i-1,sort.id]
            end

            sort.p_temp[window+1]=v[i,sort.id]
            sort.index=window+2
        end
    end
                   
    sort.sigend[:]=v[(end-sigend_length+1):end,sort.id]

    nothing
    
end

#=
Main calibration loop
=#

function maincal{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R},v::Array{Int64,2},start=1)

    for i=start:size(v,1)

        p=detect(sort,i,v)
        
        #continue collecting spike information if there was a recent spike
        if sort.index>0
            
            sort.p_temp[sort.index]=v[i,sort.id]
            sort.index+=1

            #If end of spike window is reached, continue spike detection
            if sort.index==101

                align(sort)

                featureprepare(sort)
                
                reductionprepare(sort,v)

                sort.index=0
                           
            end

        elseif p>sort.thres
            
            if i<=window
                sort.p_temp[1:(window-i+1)]=sort.sigend[end-(window-i):end]
                sort.p_temp[(window-i):window]=v[1:i-1,sort.id]  
            else
                sort.p_temp[1:window]=v[i-window:i-1,sort.id]
            end

            sort.p_temp[window+1]=v[i,sort.id]
            sort.index=window+2
        end
    end
                   
    sort.sigend[:]=v[(end-sigend_length+1):end,sort.id]

    nothing

end

