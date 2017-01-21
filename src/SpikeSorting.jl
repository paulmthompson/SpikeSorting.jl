module SpikeSorting

using Interpolations, DistributedArrays, Gtk.ShortNames, Cairo, MultivariateStats

export Sorting,Spike,create_multi,output_buffer,benchmark, SortView

include("types.jl")
include("constants.jl")
include("gui.jl")
include("detect.jl")
include("align.jl")
include("feature.jl")
include("reduction.jl")
include("cluster.jl")
include("run.jl")
include("threshold.jl")
include("benchmark.jl")

end
