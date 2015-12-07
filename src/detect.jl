
#=
Detection methods. Each method needs
1) Type with fields necessary for algorithm
2) function "detect" to operate on sort with type field defined above
3) function "threshold" to operate on sort with type field defined above
4) any other necessary functions for detection algorithm

A method may also need a "detectprepare" function to use in its first iteration if the detection method uses a sliding window that depends on previous iterations (see power for an example)
=#

export DetectPower, DetectSignal, DetectNEO, DetectMCWC

function detectprepare{D,C,A,F,R}(sort::Sorting{D,C,A,F,R},v::AbstractArray{Int64,2})
end

#=
Power

Rutishauser et al 2006
=#
type DetectPower <: Detect
    a::Int64
    b::Int64
    c::Int64
end

function DetectPower()
    DetectPower(0,0,0)
end

function detect{D<:DetectPower,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R}, i::Int64,v::AbstractArray{Int64,2})
    
    @inbounds sort.d.a += v[i,sort.id] - sort.d.c
    @inbounds sort.d.b += v[i,sort.id]^2 - sort.d.c^2   

    if i>=power_win
        @inbounds sort.d.c=v[i-power_win0,sort.id]
    else
        @inbounds sort.d.c=sort.sigend[i+sigend_length-power_win0]
    end

    # equivalent to p = sqrt(1/n * sum( (f(t-i) - f_bar(t))^2))
    sqrt((sort.d.b - (sort.d.a^2/power_win))/power_win)
    
end

function threshold{D<:DetectPower,C,A,F,R}(sort::Sorting{D,C,A,F,R},v::AbstractArray{Int64,2})
    
    p=Array(Float64,size(v,1)-power_win)
    a = 0
    b = 0
    for i=1:power_win
        a += v[i,sort.id]
        b += v[i,sort.id]^2
    end

    c = v[1,sort.id]
    
    for i=power_win1:(size(v,1)-1)
        
        a += v[i,sort.id] - c
        b += v[i,sort.id]^2 - c^2
        p[i-power_win]=sqrt((b - a^2/power_win)/power_win)
        c = v[i-power_win0,sort.id]
        
    end

    sort.thres=mean(p)+5*std(p)

    nothing

end

function detectprepare{D<:DetectPower,C,A,F,R}(sort::Sorting{D,C,A,F,R},v::AbstractArray{Int64,2})
    
    sort.d.a=0
    sort.d.b=0
    
    for i=1:power_win
        sort.d.a += v[i,sort.id]
        sort.d.b += v[i,sort.id]^2
    end

    sort.d.c=v[1,sort.id]

    for i=power_win1:sigend_length
        sort.d.a += v[i,sort.id] - sort.d.c
        sort.d.b += v[i,sort.id]^2 - sort.d.c^2
        sort.d.c = v[i-power_win+1,sort.id]
    end

    nothing

end

#=
Raw Signal

Quiroga et al 2004
=#

type DetectSignal <: Detect
end

function detect{D<:DetectSignal,C,A,F,R}(sort::Sorting{D,C,A,F,R},i::Int64)

    abs(sort.rawSignal[i])
    
end

function threshold{D<:DetectSignal,C,A,F,R}(sort::Sorting{D,C,A,F,R})

    sort.thres=4*median(abs(sort.rawSignal)/.6745)

    nothing
    
end

#=
Nonlinear Energy Operator

Choi et al 2006
=#

type DetectNEO <: Detect
end

function detect{D<:DetectNEO,C,A,F,R}(sort::Sorting{D,C,A,F,R},i::Int64)

    if i==length(sort.rawSignal)
        #Will do spike detection next iteration due to edging
        psi=0
    elseif i>1
        psi=sort.rawSignal[i]^2 - sort.rawSignal[i+1] * sort.rawSignal[i-1]
    else

        #perform calculation for end of last step and this one, and return the larger
        psi1=sort.sigend[end]^2 - sort.rawSignal[i] * sort.sigend[end-1]
        psi2=sort.rawSignal[i]^2 - sort.rawSignal[i+1] * sort.sigend[end]

        if psi1>psi2
            return psi1
        else
            return psi2
        end

    end

    psi
    
end

function threshold{D<:DetectNEO,C,A,F,R}(sort::Sorting{D,C,A,F,R})

    psi=zeros(Int64,signal_length-1)
    
    for i=2:signal_length-1
        psi[i]=sort.rawSignal[i]^2 - sort.rawSignal[i+1] * sort.rawSignal[i-1]
    end

    sort.thres=3*mean(psi)

    nothing
    
end

#=
Continuous Wavelet Transform

Nenadic et al 2005, Benitez et al 2008
=#

#=
Discrete Wavelet Transform

Kim and Kim 2003
=#

#=
Nonparametric Detection

Song et al 2006
=#

#=
Smoothed Nonlinear Energy Operator

Azami et al 2014
=#

type DetectSNEO <: Detect
end

function detect{D<:DetectSNEO,C,A,F,R}(sort::Sorting{D,C,A,F,R},i::Int64)

    if i==length(sort.rawSignal)
        #Will do spike detection next iteration due to edging
        psi=0
    elseif i>20
        
    elseif i>1
        psi=sort.rawSignal[i]^2 - sort.rawSignal[i+1] * sort.rawSignal[i-1]
    else

        #perform calculation for end of last step and this one, and return the larger
        psi1=sort.sigend[end]^2 - sort.rawSignal[i] * sort.sigend[end-1]
        psi2=sort.rawSignal[i]^2 - sort.rawSignal[i+1] * sort.sigend[end]

        if psi1>psi2
            return psi1
        else
            return psi2
        end

    end

    psi   
end

function threshold{D<:DetectSNEO,C,A,F,R}(sort::Sorting{D,C,A,F,R})

    nothing   
end

#=
Multiscale Correlation of Wavelet Coefficients

Yang et al 2011
=#

type DetectMCWC <: Detect
    Tx::Array{Float64,1}
    rs::Array{Float64,1}
end

function DetectMCWC()
    DetectMCWC(zeros(Float64,11),zeros(Float64,10))
end

function detect{D<:DetectMCWC,C<:Cluster,A<:Align,F<:Feature,R<:Reduction}(sort::Sorting{D,C,A,F,R}, i::Int64)

    p=0.0
    
    #calculate wavelet coefficients
    if i<=bigJ
        sort.d.Tx[:]=coiflets_scaled*[sort.sigend[(end-bigJ+i+1):end];sort.rawSignal[1:i]]    
    else        
        sort.d.Tx[:]=coiflets_scaled*sort.rawSignal[(i-bigJ+1):i]
    end
    
    for j=1:11
        sort.d.Tx[j] *= onesquarea[j]
    end
   
    #Correlation of wavelet coefficients
    for j=1:10
        sort.d.rs[j] = sort.d.Tx[j]*sort.d.Tx[j+1]
    end

    #Since I'm using a rolling window, I do this a little differently
    #maybe pre calculate the power to normalize?
    for j=1:10
        if sort.d.Tx[j]^2 < abs(sort.d.rs[j])
            p=2.0
            break
        end
    end

    for j=1:11
        sort.d.Tx[j]=0.0
    end
        
    p
    
end

function threshold{D<:DetectMCWC,C,A,F,R}(sort::Sorting{D,C,A,F,R})
    sort.thres=1.0
    nothing
end

#=

=#


