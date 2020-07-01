
function clear_c3(c3,num)

    ctx = Gtk.getgc(c3)

    set_source_rgb(ctx,0.0,0.0,0.0)
    paint(ctx)

    nothing
end

function c3_press_win(widget::Ptr,param_tuple,user_data::Tuple{Single_Channel})

    sc, = user_data
    event = unsafe_load(param_tuple)

    if event.button == 1 #left click captures window
        check_c3_click(sc,event.x,event.y)
    elseif event.button == 3 #right click refreshes window
    end
    nothing
end

function check_c3_click(sc::Single_Channel,x,y)

    ctx=Gtk.getgc(sc.c3)
    mywidth=width(ctx)

    total_clus = max(sc.total_clus+1,5)

    xbounds=linspace(0.0,mywidth,total_clus+1)

    count=1
    inmulti=false
    if y<130
        for j=2:length(xbounds)
            if (x<xbounds[j])
                inmulti=true
                break
            end
            count+=1
        end
    end
    if (inmulti)&(count<sc.total_clus+1)
        selmodel=Gtk.GAccessor.selection(sc.sort_tv)
        Gtk.select!(selmodel, Gtk.iter_from_index(sc.sort_list,count+1))
        select_unit(sc)
    end
    nothing
end
