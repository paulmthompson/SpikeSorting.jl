
#=
Detection methods. Each method needs
1) Type with fields necessary for algorithm
2) function "detect" to operate on sort with type field defined above
3) function "threshold" to operate on sort with type field defined above
4) any other necessary functions for detection algorithm

A method may also need a "prepare" function to use in its first iteration if the detection method uses a sliding window that depends on previous iterations (see power for an example)
=#

export DetectPower, DetectSignal, DetectNEO, DetectMCWC

function prepare{S,C,A,F}(sort::Sorting{S,C,A,F})
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

function detect{S<:DetectPower,C<:Cluster,A<:Align,F<:Feature}(sort::Sorting{S,C,A,F}, i::Int64)
    
    sort.s.a += sort.rawSignal[i] - sort.s.c
    sort.s.b += sort.rawSignal[i]^2 - sort.s.c^2   

    if i>=power_win
        sort.s.c=sort.rawSignal[i-power_win0]
    else
        sort.s.c=sort.sigend[i+sigend_length-power_win0]
    end

    # equivalent to p = sqrt(1/n * sum( (f(t-i) - f_bar(t))^2))
    sqrt((sort.s.b - (sort.s.a^2/power_win))/power_win)
    
end

function threshold{S<:DetectPower,C,A,F}(sort::Sorting{S,C,A,F})
    
    p=Array(Float64,signal_length-power_win)
    a = 0
    b = 0
    for i=1:power_win
        a += sort.rawSignal[i]
        b += sort.rawSignal[i]^2
    end

    c = sort.rawSignal[1]
    
    for i=power_win1:(signal_length-1)
        
        a += sort.rawSignal[i] - c
        b += sort.rawSignal[i]^2 - c^2
        p[i-power_win]=sqrt((b - a^2/power_win)/power_win)
        c = sort.rawSignal[i-power_win0]
        
    end

    sort.thres=mean(p)+5*std(p)

    nothing

end

function prepare{S<:DetectPower,C,A,F}(sort::Sorting{S,C,A,F})
    
    sort.s.a=0
    sort.s.b=0
    
    for i=1:power_win
        sort.s.a += sort.rawSignal[i]
        sort.s.b += sort.rawSignal[i]^2
    end

    sort.s.c=sort.rawSignal[1]

    for i=power_win1:sigend_length
        sort.s.a += sort.rawSignal[i] - sort.s.c
        sort.s.b += sort.rawSignal[i]^2 - sort.s.c^2
        sort.s.c = sort.rawSignal[i-power_win+1]
    end

    nothing

end

#=
Raw Signal

Quiroga et al 2004
=#

type DetectSignal <: Detect
end

function detect{S<:DetectSignal,C,A,F}(sort::Sorting{S,C,A,F},i::Int64)

    abs(sort.rawSignal[i])
    
end

function threshold{S<:DetectSignal,C,A,F}(sort::Sorting{S,C,A,F})

    sort.thres=median(abs(sort.rawSignal))/.6745

    nothing
    
end

#=
Nonlinear Energy Operator

Choi et al 2006
=#

type DetectNEO <: Detect
end

function detect{S<:DetectNEO,C,A,F}(sort::Sorting{S,C,A,F},i::Int64)

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

function threshold{S<:DetectNEO,C,A,F}(sort::Sorting{S,C,A,F})

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

function detect{S<:DetectMCWC,C<:Cluster,A<:Align,F<:Feature}(sort::Sorting{S,C,A,F}, i::Int64)

    p=0.0

    #calculate wavelet coefficients
    if i<=bigJ
        sort.s.Tx[:]=coiflets_scaled*[sort.sigend[(end-bigJ+i+1):end];sort.rawSignal[1:i]]    
    else        
        sort.s.Tx[:]=coiflets_scaled*sort.rawSignal[(i-bigJ+1):i]
    end
    
    for j=1:11
        sort.s.Tx[j] *= onesquarea[j]
    end
   
    #Correlation of wavelet coefficients
    for j=1:10
        sort.s.rs[j] = sort.s.Tx[j]*sort.s.Tx[j+1]
    end

    #Find highest ratio
    tempp=0.0
    for j=1:10
        tempp=abs(sort.s.rs[j]/sort.s.Tx[j])
        if tempp>p
            p=tempp
        end
    end

    for j=1:11
        sort.s.Tx[j]=0.0
    end
        
    p
    
end

function threshold{S<:DetectMCWC,C,A,F}(sort::Sorting{S,C,A,F})
    sort.thres=1.0
    nothing
end
