
#=
Main functions for spike sorting

=#

export cal!,onlinesort!

#Single Channel
function cal!{T}(sort::Sorting,v::T,spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1},firstrun=0)

    if firstrun==2 #General Calibration
        maincal(sort,v,spikes,ns)
    elseif firstrun==1 #After first run, but still need threshold
        threscal(sort,v,spikes,ns)
    else #Very first run
        detectprepare(sort.d,sort,v)
        sort.sigend[:]=v[1:length(sort.sigend),sort.id]
        threscal(sort,v,spikes,ns,length(sort.sigend)+1)
    end
    
    nothing
end

#Multi-channel - Single Core
function cal!{T<:Sorting,V}(s::Array{T,1},v::V,spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1},firstrun=0)

    for i=1:length(s)
        cal!(s[i],v,spikes,ns,firstrun)
    end
    nothing
end

#Multi-channel - Multi-Core
function cal!{T<:Sorting,V}(s::DArray{T,1,Array{T,1}},v::V,spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1},firstrun=0)
    @sync for p=1:length(s.pids)

	@spawnat s.pids[p] begin
		for i in s.indexes[p][1]
		    cal!(s[i],v,spikes,ns,firstrun)
		end
	end   
    end
    nothing
end

#Single channel
function onlinesort!{V}(sort::Sorting,v::V,spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1})
    main(sort,v,spikes,ns)    
    nothing
end

#Multi-channel - Single Core
function onlinesort!{T<:Sorting,V}(s::Array{T,1},v::V,spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1})
    for i=1:length(s)
        onlinesort!(s[i],v,spikes,ns)
    end
    nothing
end

#Multi-channel - multi-core
function onlinesort!{T<:Sorting,V}(s::DArray{T,1,Array{T,1}},v::V,spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1})
    @sync for p=1:length(s.pids)

	@spawnat s.pids[p] begin
		for i in s.indexes[p][1]
		    onlinesort!(s[i],v,spikes,ns)
		end
	end   
    end
    nothing
end

#=
Main processing loop for length of raw signal
=#

function main{V}(sort::Sorting,v::V,spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1})

    for i=1:size(v,1)

        p=detect(sort.d,sort,i,v)
        
        #continue collecting spike information if there was a recent spike
        if sort.index>0
            
            @inbounds sort.p_temp[sort.index]=v[i,sort.id]
            sort.index+=1

            #If end of spike window is reached, continue spike detection
            if sort.index==length(sort.p_temp)+1

                ind=align(sort.a,sort)

                #overlap detection? (probably need to do this in the time domain)
                
                feature(sort.f,sort)

                id=cluster(sort.c,sort)

                #Spike time stamp
                @inbounds ns[sort.id]+=1    
                @inbounds spikes[ns[sort.id],sort.id]=Spike((ind+i-(length(sort.sigend)+sort.win)):(ind+i-length(sort.sigend)),id)   
                sort.index=0
                  
            end

        elseif p>sort.thres
            
            if i<=sort.win
                @inbounds sort.p_temp[1:(sort.win-i+1)]=sort.sigend[end-(sort.win-i):end]
                @inbounds sort.p_temp[(sort.win-i+2):sort.win]=v[1:i-1,sort.id]  
            else
                @inbounds sort.p_temp[1:sort.win]=v[i-sort.win:i-1,sort.id]
            end

            @inbounds sort.p_temp[sort.win+1]=v[i,sort.id]
            sort.index=sort.win+2
        end
    end
                   
    @inbounds sort.sigend[:]=v[(end-length(sort.sigend)+1):end,sort.id]

    nothing  
end

#=
Main calibration loop
=#

function maincal{V}(sort::Sorting,v::V,spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1},start=1)

    for i=start:size(v,1)

        p=detect(sort.d,sort,i,v)

        @inbounds clusterprepare(sort.c,sort,v[i,sort.id])
        
        #continue collecting spike information if there was a recent spike
        if sort.index>0
            
            @inbounds sort.p_temp[sort.index]=v[i,sort.id]
            sort.index+=1

            #If end of spike window is reached, continue spike detection
            if sort.index==length(sort.p_temp)+1

                align(sort.a,sort)

                featureprepare(sort.f,sort)
                
                reductionprepare(sort.r,sort)

                sort.index=0
                           
            end

        elseif p>sort.thres
            
            if i<=sort.win
                sort.p_temp[1:(sort.win-i+1)]=sort.sigend[end-(sort.win-i):end]
                sort.p_temp[(sort.win-i+2):sort.win]=v[1:i-1,sort.id]  
            else
                sort.p_temp[1:sort.win]=v[(i-sort.win):(i-1),sort.id]
            end

            sort.p_temp[sort.win+1]=v[i,sort.id]
            sort.index=sort.win+2
        end
    end
                   
    @inbounds sort.sigend[:]=v[(end-length(sort.sigend)+1):end,sort.id]

    nothing
end

#=
Threshold calibration loop
=#

function threscal{V}(sort::Sorting,v::V,spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1},start=1)

    for i=start:size(v,1)
        p=detect(sort.d,sort,i,v)
        threshold(sort.t,sort,p)            
    end
                   
    sort.sigend[:]=v[(end-length(sort.sigend)+1):end,sort.id]

    nothing
end
