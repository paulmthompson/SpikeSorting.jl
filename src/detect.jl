
#=
Detection methods. Each method needs
1) Type with fields necessary for algorithm
2) function defining detection algorithm
3) function for threshold calculation

A method may also need a "prepare" function to use in its first iteration if the detection method uses a sliding window that depends on previous iterations (see power for an example)
=#

export DetectPower

#=
Julia isn't great at getting functions as arguments right now, so this helps the slow downs because of that. Probably will disappear eventually
=#

immutable detection{Name} end

@generated function call{fn}(::detection{fn},x::Sorting,y::Int64)
        :($fn(x,y))
end

#=
Power

Rutishauser et al 2006
=#
type DetectPower <: SpikeDetection
    a::Int64
    b::Int64
    c::Int64
    thres::Float64
end

function DetectPower()
    DetectPower(0,0,0,1.0)
end

function detect_power(sort::Sorting, i::Int64, k=20)
    
    sort.s.a += sort.rawSignal[i] - sort.s.c
    sort.s.b += sort.rawSignal[i]^2 - sort.s.c^2   

    if i>19
        sort.s.c=sort.rawSignal[i-k+1]
    else
        sort.s.c=sort.sigend[i+56]
    end

    # equivalent to p = sqrt(1/n * sum( (f(t-i) - f_bar(t))^2))
    sqrt((sort.s.b - (sort.s.a^2/k))/k)
    
end

function threshold_power(sort::Sorting, k=20)
    
    p=Array(Float64,size(sort.rawSignal,1)-k)
    a = 0
    b = 0
    for i=1:k
        a += sort.rawSignal[i]
        b += sort.rawSignal[i]^2
    end

    c = sort.rawSignal[1]
    
    for i=(k+1):(size(sort.rawSignal,1)-1)
        
        a += sort.rawSignal[i] - c
        b += sort.rawSignal[i]^2 - c^2
        p[i-k]=sqrt((b - a^2/k)/k)
        c = sort.rawSignal[i-k+1]
        
    end

    sort.s.thres=mean(p)+5*std(p)

end

function prepare_power(sort::Sorting,k=20)
    
    sort.s.a=0
    sort.s.b=0
    
    for i=1:k
        sort.s.a += sort.rawSignal[i]
        sort.s.b += sort.rawSignal[i]^2
    end

    sort.s.c=sort.rawSignal[1]

    for i=(k+1):75
        sort.s.a += sort.rawSignal[i] - sort.s.c
        sort.s.b += sort.rawSignal[i]^2 - sort.s.c^2
        sort.s.c = sort.rawSignal[i-k+1]
    end

end

#=
Raw Signal

Quiroga et al 2004
=#

type DetectSignal <: SpikeDetection
    thres::Float64
end

function DetectSignal()
    DetectSignal(1.0)
end

function detect_signal(sort::Sorting,i::Int64)

    abs(sort.rawSignal[i])
    
end

function threshold_signal(sort::Sorting)

    sort.s.thres=median(abs(sort.rawSignal))/.6745
    
end

#=
Nonlinear Energy Operator

Choi et al 2006
=#

type DetectNEO <: SpikeDetection
    thres::Float64
end

function DetectNEO()
    DetectNEO(1.0)
end

function detect_neo(sort::Sorting,i::Int64)

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

function threshold_neo(sort::Sorting)

    psi=zeros(Int64,length(sort.rawSignal)-1)
    
    for i=2:length(sort.rawSignal)-1
        psi[i]=sort.rawSignal[i]^2 - sort.rawSignal[i+1] * sort.rawSignal[i-1]
    end

    sort.s.thres=3*mean(psi)
    
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

type DetectMCWC <: SpikeDetection
    Tx::Array{Float64,1}
    rs::Array{Float64,1}
    thres::Float64
end

function DetectMCWC()
    DetectMCWC(zeros(Float64,11),zeros(Float64,10),1.0)
end

function detect_mcwc(sort::Sorting, i::Int64)

    p=0.0
    
    #calculate wavelet coefficients
    for j=1:11
        for k=1:20 #J = 20
            sort.s.Tx[j] += sort.RawSignal[i-20+k] * psi[21-k,j]
        end
        sort.s.Tx[j] = sort.s.Tx[j] * 1/sqrt(wave_a[j])
    end

    #Correlation of wavelet coefficients
    for j=1:10
        sort.s.rs[j] *= sort.s.Tx[j+1]
    end

    #Find highest ratio
    tempp=0.0
    for j=1:10
        tempp=abs(sort.s.rs[j]/sort.s.Tx[j])
        if tempp>p
            p=tempp
        end
    end
    
    p
    
end

