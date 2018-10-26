module SpikeSorting

using Interpolations, DistributedArrays, Gtk.ShortNames, Cairo, MultivariateStats

export Sorting,Spike,create_multi,output_buffer,benchmark, SortView

include("types.jl")
include("constants.jl")
include("cluster.jl")
include("gui/gui_types.jl")
include("gui/template_cluster.jl")
include("gui/cluster_treeview.jl")
include("gui/multi_dim_view.jl")
include("gui/single_channel.jl")
include("gui/drawing_helpers.jl")
include("gui/isi_canvas.jl")
include("gui/offline_gui.jl")
include("detect.jl")
include("align.jl")
include("feature.jl")
include("reduction.jl")
include("run.jl")
include("threshold.jl")
include("benchmark.jl")

end
