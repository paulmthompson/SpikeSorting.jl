
#=
Alignment methods. Each method needs
1) Type with fields necessary for algorithm
2) function "align" to operate on sort with type field defined above
3) any other necessary functions for alignment algorithm
=#

export AlignMax, AlignMin

#= 
Maximum signal
=#
type AlignMax <: Align
end

function align(a::AlignMax, sort::Sorting)
    mymax=sort.p_temp[sort.s.win2]
    sort.cent=sort.s.win2
    @inbounds for i=(sort.s.win2+1):sort.s.s_end
        if sort.p_temp[i]>mymax
            sort.cent=i+1
            mymax=sort.p_temp[i]
        end
    end
    nothing
end

mysize(align::AlignMax,win)=win

#=
Minimum signal
=#
type AlignMin <: Align
end

function align(a::AlignMin,sort::Sorting)
    mymin=sort.p_temp[sort.s.win2]
    sort.cent=sort.s.win2
    @inbounds for i=(sort.s.win2+1):sort.s.s_end
        if sort.p_temp[i]<mymin
            sort.cent=i+1
            mymin=sort.p_temp[i]
        end
    end
    nothing
end

mysize(align::AlignMin,win)=win

#=
Maximum Magnitude
=#

#=
FFT upsampling
=#

#=
type AlignFFT <: Align
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

function align(a::AlignFFT, sort::Sorting)
    
    sort.a.fout[:]=fft(sort.p_temp)
    
    sort.a.x_int[1:window]=sort.a.fout[1:window]
    sort.a.x_int[window+1]=sort.a.fout[window+1]/2
    sort.a.x_int[(window+2):(sort.a.M*2*window-window)]=zeros(Complex{Float64},2*sort.a.M*window-2*window-1)
    sort.a.x_int[sort.a.M*2*window-window+1]=sort.a.fout[window+1]/2    
    sort.a.x_int[(sort.a.M*2*window-window+2):end]=sort.a.fout[(window+2):end]
    
    ifft!(sort.a.x_int)
    sort.a.upsamp[:]=sort.a.M.*real(sort.a.x_int)
    
    j=indmax(sort.a.upsamp[sort.a.align_range])+sort.a.M*window_half
    sort.waveform=view(sort.a.upsamp,j-sort.a.M*window_half:j+sort.a.M*window_half-1)
    
    return j-window_half:j+window_half-1
end

mysize(align::AlignFFT)=window*align.M
=#
#=
FFT upsampling + temporal order of peaks

Rutishauser 2006
=#
#=
type AlignOsort <: Align

end

function align(a::AlignOsort, sort::Sorting)

end


function mysize(align::AlignOsort)
    window*align.M
end
=#
