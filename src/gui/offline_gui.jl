
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

    button_rb=ToggleButton()
    add_button_label(button_rb,"RubberBand")
    vbox_hold[1,3]=button_rb
    Gtk.GAccessor.active(button_rb,true)

    button_draw=ToggleButton()
    add_button_label(button_draw,"Draw")
    vbox_hold[2,3]=button_draw

    button_selection=ToggleButton()
    add_button_label(button_selection,"Selection")
    vbox_hold[3,3]=button_selection

    c_grid=Grid()
    
    c2 = Canvas()
    @guarded draw(c2) do widget
        ctx = getgc(c2)
        SpikeSorting.clear_c2(c2,1)
    end

    show(c2)
    c_grid[1,1]=c2
    setproperty!(c2,:hexpand,true)
    setproperty!(c2,:vexpand,true)

    c3=Canvas(-1,200)     
    @guarded draw(c3) do widget
        ctx = getgc(c3)
        clear_c3(c3,1)
    end
    show(c3)
    c_grid[1,2]=c3
    setproperty!(c3,:hexpand,true)

    grid[2,2]=c_grid

    sortview_handles = SpikeSorting.sort_gui(s[1].s.win+1)

    win = Window(grid,"SpikeSorting.jl") |> showall
    
    sleep(5.0)

    sc_widgets=Single_Channel(c2,c3,getgc(c2),copy(getgc(c2)),false,RubberBand(Vec2(0.0,0.0),Vec2(0.0,0.0),Vec2(0.0,0.0),[Vec2(0.0,0.0)],false,0),1,falses(500),falses(500),false,false,button_pause,button_rb,button_draw,button_selection,(0.0,0.0),false,width(getgc(c2)),height(getgc(c2)),s[1].s.win,1.0,0.0,sortview_handles.buf,0.0,0.0)

    
    win
end
