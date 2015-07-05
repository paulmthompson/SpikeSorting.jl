module SortSpikes


abstract SpikeDetection
abstract Alignment
abstract Cluster

type Sorting{S<:SpikeDetection, C<:Cluster, A<:Alignment}
    s::S
    c::C
    a::A
    rawSignal::Array{Int,1}
    electrode::Array{Int,1}
    neuronnum::Array{Int,1}
    numSpikes::Int64
    waveforms::Array{SharedArray,1}
    sigend::Array{Int64,1}
    index::Int64
end

include("constants.jl")
include("detect.jl")
include("align.jl")
include("cluster.jl")
include("extractspikes.jl")

#using Winston, Gtk.ShortNames
#include("gui.jl")

export Sorting, onlinecal, onlinesort, offlinesort

function onlinecal(sort::Sorting,method="POWER")
    
    if method=="POWER"
        
        threshold_power(sort)
        detectionmethod=detection{:detect_power}()
        prepare_power(sort)
        
    elseif method=="SIGNAL"

        threshold_signal(sort)
        detectionmethod=detection{:detect_signal}()
        
    elseif method=="NEO"

        threshold_neo(sort)
        detectionmethod=detection{:detect_neo}()
        
    end

    sort.c.Tsm=50*var(sort.rawSignal)
    sort.sigend[:]=sort.rawSignal[1:75]
    detectspikes(sort,detectionmethod, 76)
    
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

    sort.electrode=zeros(size(sort.electrode))
    sort.neuronnum=zeros(size(sort.electrode))
    sort.numSpikes=2

    return sort
end

function onlinesort(sort::Sorting,method="POWER")
 
    #Find spikes during this time block, labeled by neuron

    if method=="POWER"
             
        detect_power1=detection{:detect_power}()
        detectspikes(sort,detect_power1)       

    elseif method=="SIGNAL"

        detect_signal1=detection{:detect_signal}()
        detectspikes(sort,detect_signal)
        
    elseif method=="NEO"

        detect_neo1=detection{:detect_neo}()
        detectspikes(sort,detect_neo1)

    elseif method=="MANUAL"

        detectspikes(sort, manualdetection)

    end

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

function detectspikes(sort::Sorting,func::detection,start=1,k=20)

    #Threshold comparator, should be same type as threshold
    p=0.0

    for i=start:length(sort.rawSignal)

        #Calculate theshold comparator
        p=func(sort,i)
        
        #continue collecting spike information if there was a recent spike
        if sort.index>0
            
            sort.s.p_temp[sort.index]=p
            sort.index-=1

            #If end of spike window is reached, continue spike detection
            if sort.index==0

                #If clear peak is found
                if true

                    #alignment (power based)
                    j=indmax(sort.s.p_temp)

                    #overlap detection
                    
                    #50 time stamp (2.5 ms) window
                    assignspike!(sort,i,j)
                    
                else
                    #If no clear peak, assign to noise
                    
                end

                #reset temp matrix
                sort.s.p_temp[:]=zeros(Float64,size(sort.s.p_temp))
                  
            end

        elseif p>sort.s.thres
                
            sort.s.p_temp[50]=p
            sort.index=49
 
        end
                   
    end

    sort.sigend[:]=sort.rawSignal[(end-74):end]
    
end


end
