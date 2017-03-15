
#=
Main functions for spike sorting

=#

export cal!,onlinesort!

#Single Channel
function cal!(sort::Sorting,v,spikes,ns,firstrun=0)

    if firstrun==2 #General Calibration
        maincal(sort,v,spikes,ns)
    elseif firstrun==1 #After first run, but still need threshold
        threscal(sort,v,spikes,ns)
    else #Very first run
        detectprepare(sort.d,sort,v)
        for i=1:sort.s.s_end
            sort.sigend[i]=v[i,sort.id]
        end
        threscal(sort,v,spikes,ns,sort.s.s_end+1)
    end
    
    nothing
end

#Multi-channel - Single Core
function cal!{T<:Sorting}(s::Array{T,1},v,spikes,ns,firstrun=0)

    for i=1:length(s)
        cal!(s[i],v,spikes,ns,firstrun)
    end
    nothing
end

#Multi-channel - Multi-Core
function cal!{T<:Sorting}(s::DArray{T,1,Array{T,1}},v,spikes,ns,firstrun=0)

    @sync begin
        for p in procs(s)
            @async remotecall_wait((ss)->cal!(localpart(ss),v,spikes,ns),p,s)
        end
    end
    nothing
end

#Single channel
function onlinesort!(sort::Sorting,v,spikes,ns)
    main(sort,v,spikes,ns)    
    nothing
end

#Multi-channel - Single Core
function onlinesort!{T<:Sorting}(s::Array{T,1},v,spikes,ns)
    @inbounds for i=1:length(s)
        onlinesort!(s[i],v,spikes,ns)
    end
    nothing
end

#Multi-channel - multi-core
function onlinesort!{T<:Sorting}(s::DArray{T,1,Array{T,1}},v,spikes,ns)
    @sync begin
        for p in procs(s)
            @async remotecall_wait((ss)->onlinesort!(localpart(ss),v,spikes,ns),p,s)
        end
    end
    nothing
end

#=
Main processing loop for length of raw signal
=#

function main(sort::Sorting,v,spikes,ns)

    for i=1:size(v,1)

        p=detect(sort.d,sort,i,v)
        
        #continue collecting spike information if there was a recent spike
        if sort.index>0
            
            @inbounds sort.p_temp[sort.index]=v[i,sort.id]
            sort.index+=1

            #If end of spike window is reached, continue spike detection
            if sort.index==length(sort.p_temp)+1

                align(sort.a,sort)

                #overlap detection? (probably need to do this in the time domain)
                
                feature(sort.f,sort)

                id=cluster(sort.c,sort)

                #Spike time stamp
                @inbounds ns[sort.id]+=1    
                @inbounds spikes[ns[sort.id],sort.id]=Spike((sort.cent+i-(sort.s.s_end+sort.s.win)):(sort.cent+i-sort.s.s_end),id)
                sort.index=0               
            end

        elseif p
            
            if i<=sort.s.win
                @inbounds for j=1:(sort.s.win-i+1)
                    sort.p_temp[j]=sort.sigend[sort.s.s_end-(sort.s.win-i)+j-1]
                end
                count=1
                @inbounds for j=(sort.s.win-i+2):sort.s.win
                    sort.p_temp[j]=v[count,sort.id]
                    count+=1
                end
            else
                @inbounds for j=1:sort.s.win
                    sort.p_temp[j]=v[i-sort.s.win+j-1]
                end
            end

            @inbounds sort.p_temp[sort.s.win+1]=v[i,sort.id]
            sort.index=sort.s.win+2
        end
    end

    @inbounds for j=1:sort.s.s_end
        sort.sigend[j]=v[size(v,1)-sort.s.s_end+j,sort.id]
    end

    nothing  
end

#=
Main calibration loop
=#

function maincal(sort::Sorting,v,spikes,ns,start=1)

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

        elseif p
            
            if i<=sort.s.win
                @inbounds for j=1:(sort.s.win-i+1)
                    sort.p_temp[j]=sort.sigend[sort.s.s_end-(sort.s.win-i)+j-1]
                end
                count=1
                @inbounds for j=(sort.s.win-i+2):sort.s.win
                    sort.p_temp[j]=v[count,sort.id]
                    count+=1
                end
            else
                @inbounds for j=1:sort.s.win
                    sort.p_temp[j]=v[i-sort.s.win+j-1]
                end
            end

            @inbounds sort.p_temp[sort.s.win+1]=v[i,sort.id]
            sort.index=sort.s.win+2
        end
    end
                   
    @inbounds for j=1:sort.s.s_end
        sort.sigend[j]=v[size(v,1)-sort.s.s_end+j,sort.id]
    end

    nothing
end

#=
Threshold calibration loop
=#

function threscal(sort::Sorting,v,spikes,ns,start=1)

    for i=start:size(v,1)
        threshold(sort.t,sort,v,i)            
    end
                   
    @inbounds for j=1:sort.s.s_end
        sort.sigend[j]=v[size(v,1)-sort.s.s_end+j,sort.id]
    end

    nothing
end
