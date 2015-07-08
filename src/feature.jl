
#=
Feature extraction methods. Each method needs
1) Type with fields necessary for algorithm
2) function "feature" to operate on sort with type field defined above
3) any other necessary functions for extraction algorithm

=#

export FeatureTime

#=
Temporal Waveform
=#

type FeatureTime <: Feature
    
end

function feature{S,C,A,F<:FeatureTime}(sort::Sorting{S,C,A,F})
    sort.features[:]=sort.waveforms[sort.numSpikes][:]
    nothing
end

type FeaturePCA <: Feature

end

type FeatureWavelet <: Feature

end

