module SortSpikes

#using Winston, Gtk.ShortNames
using OnlineStats, Interpolations, DistributedArrays

abstract Detect
abstract Align
abstract Cluster
abstract Feature
abstract Reduction

type Sorting{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}
    d::D
    c::C
    a::A
    f::F
    r::R
    rawSignal::Array{Int64,1}
    sigend::Array{Int64,1}
    index::Int64
    p_temp::Array{Int64,1}
    numSpikes::Int64
    features::Array{Float64,1}
    fullfeature::Array{Float64,1}
    dims::Array{Int64,1}
    thres::Float64
    electrode::Array{Int64,1}
    neuronnum::Array{Int64,1}
    waveforms::Array{Float64,2}
end

include("constants.jl")
include("detect.jl")
include("align.jl")
include("feature.jl")
include("reduction.jl")
include("cluster.jl")

#include("gui.jl")           

function Sorting(d::Detect,c::Cluster,a::Align,f::Feature,r::Reduction)

    #determine size of alignment output
    wavelength=mysize(a)

    #determine feature size
    fulllength=mysize(f,wavelength)

    if typeof(r)==ReductionNone
        reducedims=fulllength
    else
        r=typeof(r)(fulllength,r.mydims)
        reducedims=r.mydims
    end
    c=typeof(c)(reducedims)
    Sorting(d,c,a,f,r,
            zeros(Int64,signal_length),zeros(Int64,window+window_half),0,
            zeros(Int64,window*2),2,zeros(Float64,reducedims),zeros(Float64,fulllength),
            collect(1:reducedims),1.0,zeros(Int64,100),zeros(Int64,100),
            zeros(Float64,wavelength,100))   
end
    
export Sorting, firstrun, firstrun_par,cal,cal_par,onlinesort,onlinesort_par

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
    sort.electrode=zeros(size(sort.electrode))
    sort.neuronnum=zeros(size(sort.electrode))
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

                feature(sort)
                
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

end
