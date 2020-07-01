
#=
Treeview Functions
=#

#=
Callback
=#
function unit_select_cb(w::Ptr,p1,p2,user_data::Tuple{Single_Channel})

    sc, = user_data
    select_unit(sc)
end

function select_unit(sc::Single_Channel)
    clus=get_cluster_id(sc)

    old_clus=sc.buf.selected_clus

    sc.buf.selected_clus=clus
    if clus>0
        mytol=sc.temp.tol[clus]
        setproperty!(sc.adj_sort, :value, mytol)
    end

    ctx=Gtk.getgc(sc.c3)

    if old_clus>0
        (x1_i,x2_i,y1_i,y2_i)=get_template_dims(sc,old_clus)
        draw_box(x1_i,y1_i,x2_i,y2_i,(0.0,0.0,0.0),2.0,ctx)
        draw_box(x1_i,y1_i,x2_i,y2_i,(1.0,1.0,1.0),1.0,ctx)
    end

    if sc.buf.selected_clus>0
        (x1_f,x2_f,y1_f,y2_f)=get_template_dims(sc,sc.buf.selected_clus)
        draw_box(x1_f,y1_f,x2_f,y2_f,(1.0,0.0,1.0),1.0,ctx)
    end

    nothing
end

function get_cluster_id(sc::Single_Channel)
    selmodel=Gtk.GAccessor.selection(sc.sort_tv)
    iter=Gtk.selected(selmodel)

    myind=parse(Int64,Gtk.get_string_from_iter(TreeModel(sc.sort_list), iter))
end

function update_treeview(sc::Single_Channel)

    for i=length(sc.sort_list):-1:2
        deleteat!(sc.sort_list,i)
    end

    for i=1:sc.total_clus
        push!(sc.sort_list,(i,))
    end

    selmodel=Gtk.GAccessor.selection(sc.sort_tv)
    Gtk.select!(selmodel, Gtk.iter_from_index(sc.sort_list,1))

    nothing
end

function is_selected(store,tv,ind)
    iter=Gtk.iter_from_string_index(store,string(ind))
    selection=Gtk.GAccessor.selection(tv)
    ccall((:gtk_tree_selection_iter_is_selected, Gtk.libgtk),Bool,
    (Ptr{Gtk.GObject}, Ptr{Gtk.GtkTreeIter}),selection, Gtk.mutable(iter))
end
