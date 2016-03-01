
export Algorithm

abstract Algorithm

abstract Detect <: Algorithm
abstract Align <:Algorithm
abstract Cluster <:Algorithm
abstract Feature <:Algorithm
abstract Reduction <:Algorithm
abstract Threshold <:Algorithm

abstract Sorting

#Data Structure to store range of a spike and cluster ID
immutable Spike
    inds::UnitRange{Int64}
    id::Int64
end

Spike()=Spike(0:0,0) 

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

global sorting_num = 1

function MakeSorting()
end

function gen_sorting(D::Detect,C::Cluster,A::Align,F::Feature,R::Reduction,T::Threshold)

    global sorting_num
    
    @eval begin
        type $(symbol("Sorting_$sorting_num")) <: Sorting
            d::($(typeof(D)))
            c::($(typeof(C)))
            a::($(typeof(A)))
            f::($(typeof(F)))
            r::($(typeof(R)))
            t::($(typeof(T)))
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

        function MakeSorting(D::($(typeof(D))),C::($(typeof(C))),A::($(typeof(A))),F::($(typeof(F))),R::($(typeof(R))),T::($(typeof(T))))
    
            #determine size of alignment output
            wavelength=mysize(A)

            #determine feature size
            fulllength=mysize(F,wavelength)

            if typeof(R)==ReductionNone
                reducedims=fulllength
            else
                R=typeof(R)(fulllength,R.mydims)
                reducedims=R.mydims
            end
            F=typeof(F)(wavelength,reducedims)
            C=typeof(C)(reducedims)
            $(symbol("Sorting_$sorting_num"))(D,C,A,F,R,T,
                    1,zeros(Int64,window+window_half),0,
                    zeros(Float64,window*2),zeros(Float64,reducedims),zeros(Float64,fulllength),
                    collect(1:reducedims),1.0,zeros(Float64,wavelength))   
        end

    end

    sorting_num+=1
    nothing
end

function create_multi(d::Detect,c::Cluster,a::Align,f::Feature,r::Reduction,t::Threshold,num::Int64)

    if method_exists(MakeSorting,(typeof(d),typeof(c),typeof(a),typeof(f),typeof(r),typeof(t)))
    else
        gen_sorting(d,c,a,f,r,t)
    end
    
    st=Array(typeof(MakeSorting(d,c,a,f,r,t)),num)

    for i=1:num
        st[i]=MakeSorting(d,c,a,f,r,t)
        st[i].id=i
    end

    st  
end
    
function create_multi(d::Detect,c::Cluster,a::Align,f::Feature,r::Reduction,t::Threshold,num::Int64,cores::UnitRange{Int64})
        
    st=create_multi(d,c,a,f,r,t,num)
    st=distribute(st,procs=collect(cores)) 
end
