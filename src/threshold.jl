#=
Threshold methods

Running thresholds

=#

export ThresholdMean

#running median


#running mean

type ThresholdMean <: Threshold
    m_k::Float64
    k::Int64
    m_l::Float64
    s_k::Float64
    s_l::Float64
    mean::Float64
end

function ThresholdMean()
    ThresholdMean(0.0,1,0.0,0.0,0.0,0.0)
end

function threshold{D,C,A,F,R,T<:ThresholdMean}(sort::Sorting{D,C,A,F,R,T},p::Float64)

    sort.t.k+=1
    
    sort.t.m_k=sort.t.m_l+(p-sort.t.m_l)/sort.t.k
    sort.t.s_k=sort.t.s_l+(p-sort.t.m_l)*(p-sort.t.m_k)

    myvar=sort.t.s_k/(sort.t.k-1)

    sort.t.mean+=p
    mymean=sort.t.mean/sort.t.mean

    sort.thres=mymean+4*sqrt(myvar)

    sort.t.m_l=sort.t.m_k
    sort.t.s_l=sort.t.s_k
    
    nothing
end


