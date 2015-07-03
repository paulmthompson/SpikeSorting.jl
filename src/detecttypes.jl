
#=
This type will store the variables needed for each detection method
=#


export SpikeDetection

type SpikeDetection
    a::Int64
    b::Int64
    c::Int64
    index::Int64
    sigend::Array{Int64,1}
    p_temp::Array{Float64,1}
    s_temp::Array{Int64,1}
    thres::Float64
end

function SpikeDetection()
    SpikeDetection(0,0,0,0,zeros(Int64,75),zeros(Float64,50),zeros(Int64,1),1.0)
end

function SpikeDetection(n::Int64,k::Int64)
    SpikeDetection(0,0,0,0,zeros(Int64,k),zeros(Float64,n),zeros(Int64,1),1.0)
end
