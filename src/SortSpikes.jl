module SortSpikes

#using Winston, Gtk.ShortNames,
using OnlineStats

abstract SpikeDetection
abstract Alignment
abstract Cluster
abstract Feature

type Sorting{S<:SpikeDetection,C<:Cluster,A<:Alignment,F<:Feature}
    s::S
    c::C
    a::A
    f::F
    rawSignal::Array{Int64,1}
    electrode::Array{Int64,1}
    neuronnum::Array{Int64,1}
    numSpikes::Int64
    waveforms::Array{Array{Float64,1},1}
    sigend::Array{Int64,1}
    index::Int64
    p_temp::Array{Int64,1}
    features::Array{Float64,1}
    thres::Float64
end

include("constants.jl")
include("detect.jl")
include("align.jl")
include("feature.jl")
include("cluster.jl")

#include("gui.jl")           

function Sorting(s::SpikeDetection,c::Cluster,a::Alignment,f::Feature)

    #determine size of alignment output
    wavelength=mysize(a)

    #determine feature size
    featurelength=mysize(f,wavelength)

    c=typeof(c)(featurelength)
      
    Sorting(s,c,a,f,
            zeros(Int64,signal_length),zeros(Int64,500),zeros(Int64,500),2,
            [zeros(Float64,wavelength) for j=1:10], 
            zeros(Int64,window+window_half),0,zeros(Int64,window*2),zeros(Float64,featurelength),1.0)   
end
    
export Sorting, onlinecal, onlinesort

function onlinecal(sort::Sorting)
    
    prepare(sort)
    threshold(sort)
    sort.c.Tsm=50*var(sort.rawSignal)
    sort.sigend[:]=sort.rawSignal[1:75]
    detectspikes(sort,76)
    
    #if new clusters were discovered, get rid of initial noise cluster to skip merger code later on when unnecessary
    #might want to change this later
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

    return sort
end

function onlinesort{S<:SpikeDetection,C<:Cluster,A<:Alignment,F<:Feature}(sort::Sorting{S,C,A,F})
 
    detectspikes(sort)

    #convert to absolute time stamps with the timeends variable

    #move stuff around if there were mergers of clusters (I guess? maybe do all of that at the end)

    #write to output  
    
    return sort
    
end

function offlinesort()
end

#=
Main processing loop for length of raw signal
=#

function detectspikes{S<:SpikeDetection,C<:Cluster,A<:Alignment,F<:Feature}(sort::Sorting{S,C,A,F},start=1)

    for i=start:signal_length

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

                #add spike cluster identifier to dummy first waveform shared array
                sort.waveforms[1][sort.numSpikes]=sort.neuronnum[sort.numSpikes]    
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


end
