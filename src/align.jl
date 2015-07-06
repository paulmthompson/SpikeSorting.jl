
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
    M::Int64
    x_int::Array{Complex{Float64},1}
    fout::Array{Complex{Float64},1}
    upsamp::Array{Float64,1}
    align_range::UnitRange{Int64}
end

function AlignFFT(M::Int64)
    
    AlignFFT(M,zeros(Complex{Float64},M*2*window),
             zeros(Complex{Float64},2*window),zeros(Float64,M*2*window),
             (window_half*M+1):((window+window_half)*M))
    
end

function align_fft(sort::Sorting)
    
    sort.a.fout[:]=fft(sort.p_temp)
    
    sort.a.x_int[1:window]=sort.a.fout[1:window]
    sort.a.x_int[window+1]=sort.a.fout[window+1]/2
    sort.a.x_int[(window+2):(sort.a.M*2*window-window)]=zeros(Complex{Float64},2*sort.a.M*window-2*window-1)
    sort.a.x_int[sort.a.M*2*window-window+1]=sort.a.fout[window+1]/2    
    sort.a.x_int[(sort.a.M*2*window-window+2):end]=sort.a.fout[(window+2):end]
    
    ifft!(sort.a.x_int)
    sort.a.upsamp[:]=sort.a.M.*real(sort.a.x_int)
    
    j=indmax(sort.a.upsamp[sort.a.align_range])+sort.a.M*window_half
    sort.waveforms[sort.numSpikes][:]=convert(Array{Int64,1},round(sort.a.upsamp[j-sort.a.M*window_half:j+sort.a.M*window_half-1]))
    
end

#=
FFT upsampling + temporal order of peaks

Rutishauser 2006
=#

type AlignOsort <: Alignment

end

function align_osort(sort::Sorting)

end

