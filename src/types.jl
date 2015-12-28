
export Algorithm

abstract Algorithm

abstract Detect <: Algorithm
abstract Align <:Algorithm
abstract Cluster <:Algorithm
abstract Feature <:Algorithm
abstract Reduction <:Algorithm
abstract Threshold <:Algorithm

#Data Structure to store range of a spike and cluster ID
immutable Spike
    inds::UnitRange{Int64}
    id::Int64
end

function Spike()
    Spike(0:0,0) 
end

function output_buffer(channels::Int64,par=false)

    nums=zeros(Int64,channels)
    
    if par==false
        buf=Spike[Spike() for i=1:100,j=1:channels]
    else
        buf=convert(SharedArray{Spike,2},Spike[Spike() for i=1:100,j=1:channels])
        nums=convert(SharedArray{Int64,1},nums)
    end

    (buf,nums)
    
end

type Sorting{D<:Detect,C<:Cluster,A<:Align,F<:Feature,R<:Reduction,T<:Threshold}
    d::D
    c::C
    a::A
    f::F
    r::R
    t::T
    id::Int64
    sigend::Array{Int64,1}
    index::Int64
    p_temp::Array{Float64,1}
    features::Array{Float64,1}
    fullfeature::Array{Float64,1}
    dims::Array{Int64,1}
    thres::Float64
    waveform::Array{Float64,1}
end

function Sorting(d::Detect,c::Cluster,a::Align,f::Feature,r::Reduction,t::Threshold)

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
    f=typeof(f)(wavelength,reducedims)
    c=typeof(c)(reducedims)
    Sorting(d,c,a,f,r,t,
            1,zeros(Int64,window+window_half),0,
            zeros(Float64,window*2),zeros(Float64,reducedims),zeros(Float64,fulllength),
            collect(1:reducedims),1.0,zeros(Float64,wavelength))   
end

function create_multi(d::Detect,c::Cluster,a::Align,f::Feature,r::Reduction,t::Threshold,num::Int64)
    
    st=Array(Sorting{typeof(d),typeof(c),typeof(a),typeof(f),typeof(r),typeof(t)},num)

    for i=1:num
        st[i]=Sorting(typeof(d)(),typeof(c)(),typeof(a)(),typeof(f)(),typeof(r)(),typeof(t)())
        st[i].id=i
    end

    st
    
end
    
function create_multi(d::Detect,c::Cluster,a::Align,f::Feature,r::Reduction,t::Threshold,num::Int64,cores::UnitRange{Int64})
        
    st=create_multi(d,c,a,f,r,t,num)

    st=distribute(st,procs=collect(cores))
    
end
