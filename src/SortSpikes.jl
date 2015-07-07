module SortSpikes


abstract SpikeDetection
abstract Alignment
abstract Cluster

type Sorting{S<:SpikeDetection, C<:Cluster, A<:Alignment}
    s::S
    c::C
    a::A
    rawSignal::Array{Int64,1}
    electrode::Array{Int64,1}
    neuronnum::Array{Int64,1}
    numSpikes::Int64
    waveforms::Array{SharedArray,1}
    sigend::Array{Int64,1}
    index::Int64
    p_temp::Array{Int64,1}
end

include("constants.jl")
include("detect.jl")
include("align.jl")
include("cluster.jl")

#using Winston, Gtk.ShortNames
#include("gui.jl")           

function Sorting()
    Sorting(DetectPower(),ClusterOSort(),AlignMax(),
            zeros(Int64,signal_length),zeros(Int64,500), zeros(Int64,500),2,
            [convert(SharedArray,zeros(Int64,window)) for j=1:10], 
            zeros(Int64,75),0,zeros(Int64,window*2))
end

function Sorting(s::SpikeDetection,c::Cluster,a::Alignment)

    #Need to make this do different things based on selection choices

    if typeof(a)==AlignFFT
        
        Sorting(s,c,a,
                zeros(Int64,signal_length),zeros(Int64,500),zeros(Int64,500),2,
                [convert(SharedArray,zeros(Int64,a.M*window)) for j=1:10], 
                zeros(Int64,75),0,zeros(Int64,window*2))
    else
        Sorting(s,c,a,
                zeros(Int64,signal_length),zeros(Int64,500),zeros(Int64,500),2,
                [convert(SharedArray,zeros(Int64,window)) for j=1:10], 
                zeros(Int64,75),0,zeros(Int64,window*2))
    end
    
end
    
export Sorting, onlinecal, onlinesort, offlinesort

function onlinecal(sort::Sorting,method="POWER")
    
    prepare(sort)
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

function onlinesort(sort::Sorting,method="POWER")
 
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

function detectspikes(sort::Sorting,start=1)

    #Threshold comparator, should be same type as threshold
    p=0.0

    for i=start:signal_length

        #Calculate theshold comparator
        p=detect(sort,i)
        
        #continue collecting spike information if there was a recent spike
        if sort.index>0
            
            sort.p_temp[sort.index]=sort.rawSignal[i]
            sort.index+=1

            #If end of spike window is reached, continue spike detection
            if sort.index==101

                align(sort)

                #overlap detection?
                    
                cluster(sort)

                #Spike time stamp
                sort.electrode[sort.numSpikes]=i #need adjust this based on alignment
         
                sort.index=0
                  
            end

        elseif p>sort.s.thres
            
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
    
end


end
