
#=
Alignment methods. Each method needs
1) Type with fields necessary for algorithm
2) function defining detection algorithm

=#


export AlignFFT


#=
Julia isn't great at getting functions as arguments right now, so this helps the slow downs because of that. Probably will disappear eventually
=#

immutable alignment{Name} end

@generated function call{fn}(::alignment{fn},x::Sorting,y::Int64)
        :($fn(x,y))
end


#= 
Maximum signal
=#
type AlignMax

end

function align_max(sort::Sorting, i::Int64)

    
    
end

#=
Maximum power
=#
type AlignPower

end

function align_power(sort::Sorting, i::Int64)

end



#=
FFT upsampling
=#

type AlignFFT <: Alignment
    N::Int64
    Nhalf::Int64
    M::Int64
    x_int::Array{Complex{Float64},1}
    fout::Array{Complex{Float64},1}
    upsamp::Array{Float64,1}
end

function AlignFFT(M::Int64,N::Int64)
    AlignFFT(N,div(N,2),M,zeros(Complex{Float64},M*N),zeros(Complex{Float64},N),zeros(Float64,M*N))
end

function align_fft(sort::Sorting, i::Int64)

    sort.a.fout[:]=fft(sort.p_temp) #change input

    sort.a.x_int[1:sort.a.Nhalf]=sort.a.fout[1:sort.a.Nhalf]
    sort.a.x_int[sort.a.Nhalf+1]=sort.a.fout[sort.a.Nhalf+1]/2
    sort.a.x_int[(sort.a.Nhalf+2):(sort.a.M*sort.a.N-sort.a.Nhalf)]=zeros(Complex{Float64},sort.a.N-1)
    sort.a.x_int[sort.a.M*sort.a.N-sort.a.Nhalf+1]=sort.a.fout[sort.a.Nhalf+1]/2    
    sort.a.x_int[(M*N-Nhalf+2):end]=sort.a.fout[(sort.a.Nhalf+2):end]
    
    ifft!(sort.a.x_int)
    sort.a.upsamp[:]=sort.a.M.*real(sort.a.x_int)


    
end


#=
FFT upsampling + temporal order of peaks

Rutishauser 2006
=#

function align_osort(sort::Sorting, i::Int64)

end
