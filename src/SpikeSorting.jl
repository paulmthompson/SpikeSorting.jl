module SpikeSorting

using Interpolations, DistributedArrays, Gtk.ShortNames, Cairo, MultivariateStats

export Sorting,Spike,create_multi,output_buffer,benchmark, SortView

include("types.jl")
include("constants.jl")
include("gui/gui_types.jl")
include("gui/multi_dim_view.jl")
include("detect.jl")
include("align.jl")
include("feature.jl")
include("reduction.jl")
include("cluster.jl")
include("run.jl")
include("threshold.jl")
include("benchmark.jl")

end
