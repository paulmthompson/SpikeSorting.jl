module SpikeSorting

using Interpolations, DistributedArrays, ArrayViews

export Sorting,Spike,create_multi,output_buffer,benchmark

include("types.jl")
include("constants.jl")
include("detect.jl")
include("align.jl")
include("feature.jl")
include("reduction.jl")
include("cluster.jl")
include("run.jl")
include("threshold.jl")
include("benchmark.jl")

end
