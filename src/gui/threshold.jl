function thres_show_cb(widget::Ptr,user_data::Tuple{SpikeSorting.Single_Channel})

    sc, = user_data
    mywidget = convert(CheckButton, widget)
    sc.show_thres=getproperty(mywidget,:active,Bool)
    sc.old_thres=getproperty(sc.adj_thres,:value,Int)
    sc.thres=getproperty(sc.adj_thres,:value,Int)

    nothing
end

function thres_cb(widget::Ptr,user_data::Tuple{SpikeSorting.Single_Channel})

    sc,  = user_data

    mythres=getproperty(sc.adj_thres,:value,Int)
    setproperty!(sc.thres_widgets.sb,:label,string(mythres))
    sc.thres_changed=true

    nothing
end

function gain_check_cb(widget::Ptr,user_data::Tuple{SpikeSorting.Single_Channel})

    sc, = user_data

    mygain=getproperty(sc.gain_widgets.multiply,:active,Bool)

    if mygain
        Gtk.GAccessor.increments(sc.gain_widgets.gainbox,10,10)
    else
        Gtk.GAccessor.increments(sc.gain_widgets.gainbox,1,1)
    end

    nothing
end

function sb2_cb(widget::Ptr,user_data::Tuple{Single_Channel})

    sc, = user_data

    mygain=getproperty(sc.gain_widgets.all,:active,Bool)

    gainval=getproperty(sc.gain_widgets.gainbox,:value,Int)
    mythres=getproperty(sc.adj_thres,:value,Int)

    if mygain==true
    else
    end

    han.sc.s = -1.*gainval/1000

    han.sc.thres_changed=true

    nothing
end
