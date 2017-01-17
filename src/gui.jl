
type SortView
    win::Gtk.GtkWindowLeaf

    c::Gtk.GtkCanvasLeaf

    b1::Gtk.GtkButtonLeaf

    spike_buf::Array{Int16,2}
    buf_count::Int64
    buf_clus::Array{Int64,1}

    features::Array{Float64,3}

    pca::PCA{Float64}
    pca_calced::Bool

    n_col::Int64
    n_row::Int64

    popup_axis::Gtk.GtkMenuLeaf

    selected_plot::Int64
    selected_axis::Int64 #1 = x ; 2 = y 

    axes::Array{Bool,2}
    axes_name::Array{String,2}

    col_sb::Gtk.GtkSpinButtonLeaf
    
    
end




function sort_gui()

    grid = @Grid()

    c_sort = @Canvas()

    @guarded draw(c_sort) do widget
        ctx = getgc(c_sort)
        set_source_rgb(ctx,0.0,0.0,0.0)
        paint(ctx)
    end
    show(c_sort)
    grid[1,2]=c_sort
    setproperty!(c_sort,:hexpand,true)
    setproperty!(c_sort,:vexpand,true)

    panel_grid = @Grid()
    grid[2,2] = panel_grid
    
    b1 = @Button("Plot")

    panel_grid[1,1]=b1

    clusteropts = @MenuItem("_Cluster")
    clustermenu = @Menu(clusteropts)
    cluster_km = @MenuItem("K means")
    push!(clustermenu,cluster_km)
    cluster_dbscan = @MenuItem("DBSCAN")
    push!(clustermenu,cluster_dbscan)

    mb = @MenuBar()
    push!(mb, clusteropts)
    grid[1,1]=mb

    col_sb=@SpinButton(1:3)
    panel_grid[1,3]=col_sb

    #Event
    popup_axis = @Menu()

    popup_pca1=@MenuItem("PCA1")
    push!(popup_axis,popup_pca1)
    popup_pca2=@MenuItem("PCA2")
    push!(popup_axis,popup_pca2)

    showall(popup_axis)


    win = @Window(grid,"Sort View") |> showall
    
    handles = SortView(win,c_sort,b1,zeros(Int16,500,49),500,zeros(Int64,500),zeros(Float64,500,2,10),fit(PCA,rand(Float64,10,10)),false,1,1,popup_axis,1,1,falses(10,2),["Non" for i=1:20,j=1:2],col_sb)

    signal_connect(b1_cb,b1,"clicked",Void,(),false,(handles,))
    signal_connect(col_sb_cb,col_sb,"value-changed",Void,(),false,(handles,))

    signal_connect(canvas_press,c_sort,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,))

    signal_connect(popup_pca1_cb,popup_pca1,"activate",Void,(),false,(handles,))
    signal_connect(popup_pca2_cb,popup_pca2,"activate",Void,(),false,(handles,))

    handles
end

function b1_cb(widget::Ptr,user_data::Tuple{SortView})

    han, = user_data

    replot_sort(han)

    nothing
end

function col_sb_cb(widget::Ptr,user_data::Tuple{SortView})

    han, = user_data

    han.n_col=getproperty(han.col_sb,:value,Int)

    replot_sort(han)

    nothing
end

popup_pca1_cb(widget::Ptr,han::Tuple{SortView})=pca_calc(han[1],1)
popup_pca2_cb(widget::Ptr,han::Tuple{SortView})=pca_calc(han[1],2)

function pca_calc(han::SortView,num::Int64)

    if !han.pca_calced
        han.pca = fit(PCA,convert(Array{Float64,2},han.spike_buf))
        han.pca_calced
    end

    han.features[:,han.selected_axis,han.selected_plot] = han.pca.proj[:,num]' * han.spike_buf

    han.axes[han.selected_plot,han.selected_axis]=true
    han.axes_name[han.selected_plot,han.selected_axis]=string("PCA-",num)

    replot_sort(han)

    nothing
end

function name_axis(han::SortView,myname)

end

function canvas_press(widget::Ptr,param_tuple,user_data::Tuple{SortView})

    han, = user_data

    event = unsafe_load(param_tuple)

    ctx=getgc(han.c)

    inaxis = get_axis_bounds(han,event.x,event.y)

    if event.button==1

    elseif event.button==3

        if inaxis
            popup(han.popup_axis,event)
        end
        
    end
        
    nothing
end

function get_axis_bounds(han::SortView,x,y)

    ctx=getgc(han.c)
    myheight=height(ctx)
    mywidth=width(ctx)

    xbounds=linspace(0.0,mywidth,han.n_col+1)
    ybounds=linspace(0.0,myheight,han.n_row+1)

    count=1
    inaxis=false
    for xx=1:length(xbounds)-1, yy=2:length(ybounds)
        if (x<xbounds[xx]+50.0)&(x>xbounds[xx])
            han.selected_plot=count
            han.selected_axis=2
            inaxis=true
            break
        elseif (y>ybounds[yy]-50.0)&(y<ybounds[yy])
            han.selected_plot=count
            han.selected_axis=1
            inaxis=true
            break
        end
        count+=1
    end

    inaxis
end

function replot_sort(han::SortView)

    ctx=getgc(han.c)
    set_source_rgb(ctx,0.0,0.0,0.0)
    paint(ctx)
    mywidth=width(ctx)
    myheight=height(ctx)
    
    if han.axes[han.selected_plot,1]&han.axes[han.selected_plot,2]
              
        xmin=minimum(han.features[:,1,han.selected_plot])
        ymin=minimum(han.features[:,2,han.selected_plot])
        xscale=maximum(han.features[:,1,han.selected_plot])-xmin
        yscale=maximum(han.features[:,2,han.selected_plot])-ymin

        Cairo.translate(ctx,50+mywidth/(han.n_col)*(han.selected_plot-1),20+myheight/(han.n_row)*(han.selected_plot-1))
        Cairo.scale(ctx,(mywidth/(han.n_col)-70)/xscale,(myheight/(han.n_row)-50)/yscale)

        for ii=1:(maximum(han.buf_clus)+1)
            for i=1:size(han.features,1)
                if (han.buf_clus[i]+1 == ii)
                    move_to(ctx,han.features[i,1,han.selected_plot]-xmin,han.features[i,2,han.selected_plot]-ymin)
                    line_to(ctx,han.features[i,1,han.selected_plot]+10.0-xmin,han.features[i,2,han.selected_plot]+10.0-ymin)
                end
            end
            mselect_color(ctx,ii)
            stroke(ctx)
        end

        midentity_matrix(ctx)

        set_source_rgb(ctx,1.0,1.0,1.0)
        move_to(ctx,mywidth/(han.n_col*2)+mywidth/(han.n_col)*(han.selected_plot-1),myheight-10.0)
        show_text(ctx,han.axes_name[han.selected_plot,1])

        move_to(ctx,10.0+mywidth/han.n_col*(han.selected_plot-1),myheight/2)
        rotate(ctx,-pi/2)
        show_text(ctx,han.axes_name[han.selected_plot,2])

        midentity_matrix(ctx)  
    end

    reveal(han.c)
    
    nothing
end

midentity_matrix(ctx)=ccall((:cairo_identity_matrix,Cairo._jl_libcairo),Void, (Ptr{Void},), ctx.ptr)

function mselect_color(ctx,clus,alpha=1.0)

    if clus==1
        set_source_rgba(ctx,1.0,1.0,1.0,alpha) # white
    elseif clus==2
        set_source_rgba(ctx,1.0,1.0,0.0,alpha) #Yellow
    elseif clus==3
        set_source_rgba(ctx,0.0,1.0,0.0,alpha) #Green
    elseif clus==4
        set_source_rgba(ctx,0.0,0.0,1.0,alpha) #Blue
    elseif clus==5
        set_source_rgba(ctx,1.0,0.0,0.0,alpha) #Red
    else
        set_source_rgba(ctx,1.0,1.0,0.0,alpha)
    end
    
    nothing
end
