#=
Threshold methods

Running thresholds

=#

export ThresholdMeanP, ThresholdMeanN

#running median


#running mean

mutable struct ThresholdMeanP <: Threshold
    m_k::Float64
    k::Int64
    m_l::Float64
    s_k::Float64
    s_l::Float64
    mean::Float64
    stds::Float64
end

ThresholdMeanP()=ThresholdMeanP(0.0,1,0.0,0.0,0.0,0.0,3.0)

ThresholdMeanP(stds::Float64)=ThresholdMeanP(0.0,1,0.0,0.0,0.0,0.0,stds)

function threshold(t::ThresholdMeanP,sort::Sorting,v,i)

    sort.t.k+=1

    sort.t.m_k=sort.t.m_l+(v[i,sort.id]-sort.t.m_l)/sort.t.k
    sort.t.s_k=sort.t.s_l+(v[i,sort.id]-sort.t.m_l)*(v[i,sort.id]-sort.t.m_k)

    myvar=sort.t.s_k/(sort.t.k-1)

    sort.t.mean+=v[i,sort.id]
    mymean=sort.t.mean/sort.t.k

    sort.thres=mymean+sort.t.stds*sqrt(myvar)

    sort.t.m_l=sort.t.m_k
    sort.t.s_l=sort.t.s_k

    nothing
end

mutable struct ThresholdMeanN <: Threshold
    m_k::Float64
    k::Int64
    m_l::Float64
    s_k::Float64
    s_l::Float64
    mean::Float64
    stds::Float64
end

ThresholdMeanN()=ThresholdMeanN(0.0,1,0.0,0.0,0.0,0.0,3.0)

ThresholdMeanN(stds::Float64)=ThresholdMeanN(0.0,1,0.0,0.0,0.0,0.0,stds)

function threshold(t::ThresholdMeanN,sort::Sorting,v,i)

    sort.t.k+=1

    sort.t.m_k=sort.t.m_l+(v[i,sort.id]-sort.t.m_l)/sort.t.k
    sort.t.s_k=sort.t.s_l+(v[i,sort.id]-sort.t.m_l)*(v[i,sort.id]-sort.t.m_k)

    myvar=sort.t.s_k/(sort.t.k-1)

    sort.t.mean+=v[i,sort.id]
    mymean=sort.t.mean/sort.t.k

    sort.thres=mymean-sort.t.stds*sqrt(myvar)

    sort.t.m_l=sort.t.m_k
    sort.t.s_l=sort.t.s_k

    nothing
end
