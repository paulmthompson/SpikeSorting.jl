
#=
Detection methods. Each method needs
1) function for  detection algorithm
2) function for threshold calculation
=#

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
function detect_power(sort::Sorting, i::Int64, k=20)
    
    sort.s.a += sort.rawSignal[i] - sort.s.c
    sort.s.b += sort.rawSignal[i]^2 - sort.s.c^2   

    if i>19
        sort.s.c=sort.rawSignal[i-k+1]
    else
        sort.s.c=sort.s.sigend[i+56]
    end

    # equivalent to p = sqrt(1/n * sum( (f(t-i) - f_bar(t))^2))
    sqrt((sort.s.b - (sort.s.a^2/k))/k)
    
end

function threshold_power(sort::Sorting, k=20)
    
    #running power
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

    mean(p)+5*std(p)

end

#=
Raw Signal

Quiroga et al 2004
=#
function detect_signal(sort::Sorting,i::Int64)

    abs(sort.rawSignal[i])
    
end

function threshold_signal(sort::Sorting)

    median(abs(sort.rawSignal))/.6745
    
end


#=
Nonlinear Energy Operator

Choi et al 2006
=#
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

    3*mean(psi)
    
end

#=
Continuous Wavelet Transform

Nenadic et al 2005
=#
