
export make_offline_gui

function make_offline_gui(s)

    grid = Grid()

    frame_hold=Frame("Spike")
    grid[1,1]=frame_hold
    vbox_hold=Grid()
    push!(frame_hold,vbox_hold)

    button_pause=ToggleButton()
    add_button_label(button_pause,"Pause")
    vbox_hold[2,2]=button_pause

    button_clear=Button()
    add_button_label(button_clear,"Refresh")
    vbox_hold[1,2]=button_clear

    button_restore=Button()
    add_button_label(button_restore,"Restore")
    vbox_hold[3,2]=button_restore

    button_rb=Array(RadioButton,3)
    button_rb[1]=RadioButton(active=true)
    button_rb[2]=RadioButton(button_rb[1])
    button_rb[3]=RadioButton(button_rb[2])

    vbox_hold[1,3]=button_rb[1]
    Gtk.GAccessor.mode(button_rb[1],false)
    add_button_label(button_rb[1],"RubberBand")
    vbox_hold[2,3]=button_rb[2]
    Gtk.GAccessor.mode(button_rb[2],false)
    add_button_label(button_rb[2],"Draw")
    vbox_hold[3,3]=button_rb[3]
    Gtk.GAccessor.mode(button_rb[3],false)
    add_button_label(button_rb[3],"Selection")


    c_grid=Grid()

    c2 = Canvas()
    @guarded draw(c2) do widget
        ctx = Gtk.getgc(c2)
        SpikeSorting.clear_c2(c2,1)
    end

    show(c2)
    c_grid[1,1]=c2
    setproperty!(c2,:hexpand,true)
    setproperty!(c2,:vexpand,true)

    c3=Canvas(-1,200)
    @guarded draw(c3) do widget
        ctx = Gtk.getgc(c3)
        clear_c3(c3,1)
    end
    show(c3)
    c_grid[1,2]=c3
    setproperty!(c3,:hexpand,true)

    grid[2,2]=c_grid

    sortview_handles = SpikeSorting.sort_gui(s[1].s.win+1)

    win = Window(grid,"SpikeSorting.jl") |> showall

    sleep(5.0)

    sc_widgets=Single_Channel(c2,c3,Gtk.getgc(c2),copy(Gtk.getgc(c2)),false,RubberBand(Vec2(0.0,0.0),Vec2(0.0,0.0),
    Vec2(0.0,0.0),[Vec2(0.0,0.0)],false,0),1,falses(500),falses(500),false,false,button_pause,button_rb,
    1,(0.0,0.0),false,width(Gtk.getgc(c2)),height(Gtk.getgc(c2)),s[1].s.win,1.0,0.0,sortview_handles.buf,
    0.0,0.0,ClusterTemplate(convert(Int64,s[1].s.win)),0,1,false)

    id = signal_connect(canvas_press_win,c2,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(sc_widgets,))
    id = signal_connect(pause_cb,button_pause,"toggled",Void,(),false,(sc_widgets,))
    id = signal_connect(canvas_release_template,c2,"button-release-event",Void,(Ptr{Gtk.GdkEventButton},),false,(sortview_handles.buf,sc_widgets))
    id = signal_connect(win_resize_cb, win, "size-allocate",Void,(Ptr{Gtk.GdkRectangle},),false,(sc_widgets,))
    (win,sc_widgets)
end

function offline_loop(win,sc,sorting,buf,nums)

    while true

        if sc.show_thres
            SpikeSorting.plot_thres(sc)
        end
        if sc.rb_active
            SpikeSorting.draw_rb(sc)
        end

        reveal(sc.c2)
        reveal(sc.c3)

        sleep(0.01)
    end

end
