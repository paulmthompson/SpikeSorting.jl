
#=
Alignment methods. Each method should take a length of signal and return the center
=#

#=
Julia isn't great at getting functions as arguments right now, so this helps the slow downs because of that. Probably will disappear eventually
=#
immutable alignment{Name} end

@generated function call{fn}(::alignment{fn},x::Sorting,y::Int64)
        :($fn(x,y))
end


#= 
Maximum index
=#

function align_max(sort::Sorting, i::Int64)

end


#=
FFT upsampling
=#

function align_fft(sort::Sorting, i::Int64)

    #provide input a, x_int and output c as arguments
    a=rand(100)
    M=2
    N=length(a)
    x_int=zeros(Complex{Float64},M*N)

    b=fft(a)

    x_int[1:50]=b[1:50]
    x_int[51]=b[51]/2
    x_int[52:150]=zeros(Complex{Float64},99)
    x_int[151]=b[51]/2    
    x_int[152:200]=b[52:100]
    
    ifft!(x_int)
    c[:]=M.*real(x_int)

end


#=
FFT upsampling + temporal order of peaks

Rutishauser 2006
=#

function align_osort(sort::Sorting, i::Int64)

end
