
#=
Alignment methods. Each method needs
1) Type with fields necessary for algorithm
2) function defining detection algorithm

=#


export AlignMax, AlignFFT


#=
Julia isn't great at getting functions as arguments right now, so this helps the slow downs because of that. Probably will disappear eventually
=#

immutable alignment{Name} end

@generated function call{fn}(::alignment{fn},x::Sorting)
        :($fn(x))
end


#= 
Maximum signal
=#
type AlignMax <: Alignment

end

function align_max(sort::Sorting)
    j=indmax(sort.p_temp[align_range])+window_half
    sort.waveforms[sort.numSpikes][:]=sort.p_temp[j-window_half:j+window_half-1]
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

function align_fft(sort::Sorting)

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

type AlignOsort <: Alignment

end

function align_osort(sort::Sorting)

end
