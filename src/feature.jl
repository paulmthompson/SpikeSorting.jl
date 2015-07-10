
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

function feature{S<:Detect,C<:Cluster,A<:Align,F<:FeatureTime}(sort::Sorting{S,C,A,F})
    sort.features[:]=sort.waveforms[:,sort.numSpikes]
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

function feature{S<:Detect,C<:Cluster,A<:Align,F<:FeaturePCA}(sort::Sorting{S,C,A,F})
    OnlineStats.update!(sort.f.oPCA,sort.waveforms[:,sort.numSpikes])
    sort.features[:]=sort.f.oPCA.V*sort.waveforms[:,sort.numSpikes]
    nothing
end

function mysize(feature::FeaturePCA,wavelength::Int64)
    feature.oPCA.k
end

#=
Wavelet
=#

type FeatureWPD <: Feature
end

function feature{S<:Detect,C<:Cluster,A<:Align,F<:FeatureWPD}(sort::Sorting{S,C,A,F})
    #a=2^i where i = 1:L and L=log2(N) where N is signal length

end

function mysize(feature::FeatureWPD,wavelength::Int64)
    feature.oPCA.k
end
