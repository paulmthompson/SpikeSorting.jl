module SortSpikes

#using Winston, Gtk.ShortNames
using OnlineStats, Interpolations

abstract Detect
abstract Align
abstract Cluster
abstract Feature

type Sorting{D<:Detect,C<:Cluster,A<:Align,F<:Feature}
    d::D
    c::C
    a::A
    f::F
    rawSignal::Array{Int64,1}
    sigend::Array{Int64,1}
    index::Int64
    p_temp::Array{Int64,1}
    numSpikes::Int64
    features::Array{Float64,1}
    thres::Float64
    electrode::Array{Int64,1}
    neuronnum::Array{Int64,1}
    waveforms::Array{Float64,2}
end

include("constants.jl")
include("detect.jl")
include("align.jl")
include("feature.jl")
include("cluster.jl")

#include("gui.jl")           

function Sorting(d::Detect,c::Cluster,a::Align,f::Feature)

    #determine size of alignment output
    wavelength=mysize(a)

    #determine feature size
    featurelength=mysize(f,wavelength)

    f=typeof(f)(wavelength)
    c=typeof(c)(featurelength)
      
    Sorting(d,c,a,f,
            zeros(Int64,signal_length),zeros(Int64,window+window_half),0,
            zeros(Int64,window*2),2,zeros(Float64,featurelength),1.0,
            zeros(Int64,100),zeros(Int64,100),zeros(Float64,wavelength,100))   
end
    
export Sorting, firstrun, onlinecal, onlinesort

function firstrun{D<:Detect,C<:Cluster,A<:Align,F<:Feature}(sort::Sorting{D,C,A,F})
    
    #detection initialization
    detectprepare(sort)
    threshold(sort)
    
    sort.sigend[:]=sort.rawSignal[1:75]

    maincal(sort,76)

    return sort
    
end

function onlinecal{D<:Detect,C<:Cluster,A<:Align,F<:Feature}(sort::Sorting{D,C,A,F})
    
    maincal(sort)
    
    #if new clusters were discovered, get rid of initial noise cluster to skip merger code later on when unnecessary
    #might want to change this later
    #=
    if sort.c.numClusters>1
        for j=2:sort.c.numClusters
            sort.c.clusters[:,j-1]=sort.c.clusters[:,j]
            sort.c.clusters[:,j]=zeros(Float64,size(sort.c.clusters[:,j]))
            sort.c.clusterWeight[j-1]=sort.c.clusterWeight[j]
            sort.c.clusterWeight[j]=0
         end
         sort.c.numClusters-=1
    end

    #reset things we would normally return
    sort.electrode=zeros(size(sort.electrode))
    sort.neuronnum=zeros(size(sort.electrode))
    sort.numSpikes=2
    =#
    return sort
end

function onlinesort{D<:Detect,C<:Cluster,A<:Align,F<:Feature}(sort::Sorting{D,C,A,F})
    main(sort)    
    return sort  
end

function offlinesort()
end

#=
Main processing loop for length of raw signal
=#

function main{D<:Detect,C<:Cluster,A<:Align,F<:Feature}(sort::Sorting{D,C,A,F})

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
                sort.electrode[sort.numSpikes]=i #need adjust this based on alignment
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

function maincal{D<:Detect,C<:Cluster,A<:Align,F<:Feature}(sort::Sorting{D,C,A,F},start=1)

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

end
