
#=
These types should contain the fields necessary for the corresponding detection method
=#


export DetectPower

abstract SpikeDetection



type DetectPower <: SpikeDetection
    a::Int64
    b::Int64
    c::Int64
    p_temp::Array{Float64,1}
    thres::Float64
end

function DetectPower()
    DetectPower(0,0,0,zeros(Float64,50),1.0)
end

function DetectPower(n::Int64)
    DetectPower(0,0,0,zeros(Float64,n),1.0)
end
