
type FeaturePlot
    xmin::Float64
    ymin::Float64
    xscale::Float64
    yscale::Float64
    xc_i::Float64
end

FeaturePlot()=FeaturePlot(0.0,0.0,1.0,1.0,1.0)

type Buffer
    count::Int64
    ind::Int64
    spikes::Array{Int16,2}
    clus::Array{UInt8,1}
    mask::Array{Bool,1}
    selected_clus::UInt8
    replot::Bool
    selected::Array{Bool,1}
    c_changed::Bool
end

Buffer(wave_points)=Buffer(500,1,zeros(Int16,wave_points,500),zeros(UInt8,500),trues(500),1,false,falses(500),false)

type SortView
    win::Gtk.GtkWindowLeaf

    c::Gtk.GtkCanvasLeaf

    b1::Gtk.GtkButtonLeaf

    features::Dict{String,Array{Float64,1}}

    pca::PCA{Float64}
    pca_calced::Bool

    n_col::Int64
    n_row::Int64

    popup_axis::Gtk.GtkMenuLeaf

    selected_plot::Int64

    axes::Array{Bool,2}
    axes_name::Array{String,2}

    col_sb::Gtk.GtkSpinButtonLeaf

    plots::Array{FeaturePlot,1}

    h::Float64
    w::Float64

    buf::Buffer 
end
