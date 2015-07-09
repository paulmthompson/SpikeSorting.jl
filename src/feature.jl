
#=
Feature extraction methods. Each method needs
1) Type with fields necessary for algorithm
2) function "feature" to operate on sort with type field defined above
3) any other necessary functions for extraction algorithm

=#

export FeatureTime, FeaturePCA

#=
Temporal Waveform
=#

type FeatureTime <: Feature
    
end

function feature{S,C,A,F<:FeatureTime}(sort::Sorting{S,C,A,F})
    sort.features[:]=sort.waveforms[sort.numSpikes][:]
    nothing
end

function mysize(feature::FeatureTime,wavelength::Int64)
    wavelength
end

#=
online PCA
=#

type FeaturePCA <: Feature
    oPCA::OnlineStats.OnlinePCA
end

function FeaturePCA()
    FeaturePCA(OnlineStats.OnlinePCA(window,4))
end

function FeaturePCA(win::Int64,dims::Int64)
    FeaturePCA(OnlineStats.OnlinePCA(win,dims))
end

function feature{S,C,A,F<:FeaturePCA}(sort::Sorting{S,C,A,F})
    a=convert(Array{Float64,1},collect(sort.waveforms[sort.numSpikes][:])) #Need to make this not suck
    OnlineStats.update!(sort.f.oPCA,a)
    sort.features[:]=sort.f.oPCA.V*sort.waveforms[sort.numSpikes]
end

function mysize(feature::FeaturePCA,wavelength::Int64)
    feature.oPCA.k
end

#=
Wavelet
=#

type FeatureWavelet <: Feature
end

function feature{S,C,A,F<:FeatureWavelet}(sort::Sorting{S,C,A,F})
end


