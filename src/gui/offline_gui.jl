
export make_offline_gui

type Analog_Viewer
    c::Gtk.GtkCanvasLeaf
    slider::Gtk.GtkScaleLeaf
    adj::Gtk.GtkAdjustmentLeaf
    pos::Int64
    changed::Bool
end

type Offline_GUI
    win::Gtk.GtkWindowLeaf
    sc::Single_Channel
    sortview::SortView
    v::Array{Int16,1} #Should be anything
    av::Analog_Viewer
end

function make_offline_gui(s)

    grid = Grid()

    vbox1_2=Grid()

    frame1_2=Frame("Gain")
    vbox1_2[1,2]=frame1_2
    vbox1_2_1=Grid()
    push!(frame1_2,vbox1_2_1)

    sb2=SpinButton(1:1000)
    setproperty!(sb2,:value,1)
    vbox1_2_1[1,1]=sb2

    gain_checkbox=CheckButton()
    add_button_label(gain_checkbox," x 10")
    vbox1_2_1[2,1]=gain_checkbox

    button_gain = CheckButton()
    add_button_label(button_gain,"All Channels")
    setproperty!(button_gain,:active,false)
    vbox1_2_1[1,2]=button_gain


    #THRESHOLD
    frame1_3=Frame("Threshold")
    vbox1_2[1,3]=frame1_3
    vbox1_3_1=Box(:v)
    push!(frame1_3,vbox1_3_1)

    #sb=SpinButton(-300:300)
    #setproperty!(sb,:value,0)
    sb=Label("0")
    push!(vbox1_3_1,sb)

    button_thres_all = CheckButton()
    add_button_label(button_thres_all,"All Channels")
    setproperty!(button_thres_all,:active,false)
    push!(vbox1_3_1,button_thres_all)

    button_thres = CheckButton()
    add_button_label(button_thres,"Show")
    setproperty!(button_thres,:active,false)
    push!(vbox1_3_1,button_thres)


    frame_hold=Frame("Spike")
    #grid[1,1]=frame_hold
    vbox1_2[1,4]=frame_hold
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


    #CLUSTER
    frame1_4=Frame("Clustering")

    vbox1_3_2=Grid()
    push!(frame1_4,vbox1_3_2)

    button_sort1 = Button()
    button_sort2 = Button()
    button_sort3 = Button()

    button_sort4 = ToggleButton()
    button_sort5 = Button()

    check_sort1 = CheckButton()

    slider_sort = Scale(false, 0.0, 2.0,.02)
    adj_sort = Adjustment(slider_sort)
    setproperty!(adj_sort,:value,1.0)
    slider_sort_label=Label("Slider Label")

    sort_list=ListStore(Int32)
    push!(sort_list,(0,))
    sort_tv=TreeView(TreeModel(sort_list))
    sort_r1=CellRendererText()
    sort_c1=TreeViewColumn("Cluster",sort_r1, Dict([("text",0)]))
    Gtk.GAccessor.activate_on_single_click(sort_tv,1)

    push!(sort_tv,sort_c1)

    vbox1_3_2[1,3] = button_sort1
    vbox1_3_2[1,4] = button_sort2
    vbox1_3_2[1,5] = button_sort3
    vbox1_3_2[1,6] = button_sort4
    vbox1_3_2[1,7] = check_sort1
    #vbox1_3_2[1,7]=button_sort5
    vbox1_3_2[1,8] = slider_sort
    vbox1_3_2[1,9] = slider_sort_label

    myscroll=ScrolledWindow()
    Gtk.GAccessor.min_content_height(myscroll,150)
    Gtk.GAccessor.min_content_width(myscroll,100)
    push!(myscroll,sort_tv)
    vbox1_3_2[1,10]=myscroll
    vbox1_3_2[1,11]=Canvas(180,10)

    vbox1_2[1,5]=frame1_4 |> showall

    #COLUMN 2 - Threshold slider
    vbox_slider=Box(:v)
    thres_slider = Scale(true, -300,300,1)
    adj_thres = Adjustment(thres_slider)
    setproperty!(adj_thres,:value,0)

    c_thres=Canvas(10,200)
    setproperty!(c_thres,:vexpand,false)

    Gtk.GAccessor.inverted(thres_slider,true)
    Gtk.GAccessor.draw_value(thres_slider,false)

    setproperty!(thres_slider,:vexpand,true)
    push!(vbox_slider,thres_slider)
    push!(vbox_slider,c_thres)

    c_grid=Grid()

    c2 = Canvas()
    @guarded draw(c2) do widget
        ctx = Gtk.getgc(c2)
        clear_c2(c2,1)
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

    grid[2,2]=vbox1_2
    grid[3,2]=vbox_slider
    grid[4,2]=c_grid

    c_analog=Canvas(-1,200)
    grid[4,3]=c_analog
    analog_slider = Scale(false, 1,30000,1)
    adj_analog = Adjustment(analog_slider)
    setproperty!(adj_analog,:value,1)
    grid[4,4]=analog_slider

    analog_handles = Analog_Viewer(c_analog,analog_slider,adj_analog,1,false)

    sortview_handles = SpikeSorting.sort_gui(s[1].s.win+1)

    win = Window(grid,"SpikeSorting.jl") |> showall

    sleep(5.0)

    thres_widgets=Thres_Widgets(sb,thres_slider,adj_thres,button_thres_all,button_thres)
    gain_widgets=Gain_Widgets(sb2,gain_checkbox,button_gain)

    sc_widgets=Single_Channel(c2,c3,Gtk.getgc(c2),copy(Gtk.getgc(c2)),false,RubberBand(Vec2(0.0,0.0),Vec2(0.0,0.0),
    Vec2(0.0,0.0),[Vec2(0.0,0.0)],false,0),1,falses(500),falses(500),false,false,button_pause,button_rb,
    1,(0.0,0.0),false,width(Gtk.getgc(c2)),height(Gtk.getgc(c2)),s[1].s.win,1.0,0.0,sortview_handles.buf,
    0.0,0.0,ClusterTemplate(convert(Int64,s[1].s.win)),0,1,false,sort_list,sort_tv,adj_sort,adj_thres,thres_slider,false,
    thres_widgets,gain_widgets)

    id = signal_connect(canvas_press_win,c2,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(sc_widgets,))

    #=
    Pause, Restore, and Clear Callbacks
    =#
    id = signal_connect(pause_cb,button_pause,"toggled",Void,(),false,(sc_widgets,))
    id = signal_connect(clear_button_cb,button_clear,"clicked",Void,(),false,(sc_widgets,))
    id = signal_connect(restore_button_cb,button_restore,"clicked",Void,(),false,(sc_widgets,))


    id = signal_connect(canvas_release_template,c2,"button-release-event",Void,(Ptr{Gtk.GdkEventButton},),false,(sortview_handles.buf,sc_widgets))
    id = signal_connect(win_resize_cb, win, "size-allocate",Void,(Ptr{Gtk.GdkRectangle},),false,(sc_widgets,))

    id = signal_connect(b1_cb_template,button_sort1,"clicked",Void,(),false,(sc_widgets,))
    add_button_label(button_sort1,"Delete Unit")

    id = signal_connect(b2_cb_template,button_sort2,"clicked",Void,(),false,(sc_widgets,))
    add_button_label(button_sort2,"Add Unit")

    id = signal_connect(b3_cb_template,button_sort3,"clicked",Void,(),false,(sc_widgets,sortview_handles))
    add_button_label(button_sort3,"Collect Templates")

    id = signal_connect(b4_cb_template,button_sort4,"clicked",Void,(),false,(sc_widgets,))
    add_button_label(button_sort4,"Show Template Bounds")

    setproperty!(check_sort1,:label,"Show Template")
    id = signal_connect(check_cb_template,check_sort1,"clicked",Void,(),false,(sc_widgets,))

    setproperty!(slider_sort_label,:label,"Tolerance")

    id = signal_connect(unit_select_cb,sort_tv, "row-activated", Void, (Ptr{Gtk.GtkTreePath},Ptr{Gtk.GtkTreeViewColumn}), false, (sc_widgets,))
    id = signal_connect(canvas_press_win,c2,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(sc_widgets,))

    #=
    ISI canvas callbacks
    =#
    id = signal_connect(c3_press_win,c3,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(sc_widgets,))

    #=
    Threshold callbacks
    =#

    id = signal_connect(thres_cb,thres_slider,"value-changed",Void,(),false,(sc_widgets,))
    id = signal_connect(thres_show_cb,button_thres,"clicked",Void,(),false,(sc_widgets,))

    #=
    Gain Callbacks
    =#

    id = signal_connect(sb2_cb,sb2, "value-changed",Void,(),false,(sc_widgets,))
    id = signal_connect(gain_check_cb,gain_checkbox, "clicked", Void,(),false,(sc_widgets,))

    v=round.(Int16,100.*rand(60000)-50.0)

    myoffline = Offline_GUI(win,sc_widgets,sortview_handles,v,analog_handles)

    #=
    Analog Callbacks
    =#

    id = signal_connect(analog_slider_cb,analog_slider,"value-changed",Void,(),false,(myoffline,))
    id = signal_connect(analog_gain_cb, sb2, "value-changed",Void,(),false,(myoffline,))

    myoffline
end

function offline_loop(han,sorting,buf,nums)

    while true

        if han.sc.buf.c_changed

            clus = han.sc.buf.selected_clus

            if clus>0

                #Find Cluster characteristics from selected waveforms
                (mymean,mystd)=make_cluster(han.sc.buf.spikes,han.sc.buf.mask,han.sc.buf.ind,.!han.sc.buf.selected)

                #Apply cluster characteristics to handles cluster
                change_cluster(han.sc.temp,mymean,mystd,clus)
                setproperty!(han.sc.adj_sort, :value, 1.0)

                if (han.sc.buf.count>0)&(han.sc.pause)
                    template_cluster(han.sc,clus,mymean,mystd[:,2],mystd[:,1],1.0)
                end

            end

            #Send cluster information to sorting
            send_clus(sorting,han.sc)
            han.sc.buf.c_changed=false
        end
        if han.sc.buf.replot
            replot_all_spikes(han.sc)
            if visible(han.sortview.win)
                if !han.sc.pause

                else
                    #Refresh Screen
                    SpikeSorting.replot_sort(han.sortview)
                end
            end
            han.sc.buf.replot=false
        end
        if han.sc.thres_changed
            offline_thres_changed(han.sc,sorting)
        end
        if han.sc.show_thres
            SpikeSorting.plot_thres(han.sc)
        end
        if han.sc.rb_active
            SpikeSorting.draw_rb(han.sc)
        end
        if han.av.changed
            replot_analog(han)
        end

        reveal(han.sc.c2)
        reveal(han.sc.c3)

        sleep(0.01)
    end

end

function offline_thres_changed(sc,s)

    mythres=getproperty(sc.adj_thres,:value,Int)
    sc.thres=mythres

    #update sorting
    if (getproperty(sc.thres_widgets.all,:active,Bool))|(getproperty(sc.gain_widgets.all,:active,Bool))
        for i=1:length(s)
            s[i].thres=-1*sc.thres/sc.s #This isn't right, need a scale thing
        end
    else
        s[sc.spike].thres = -1 * sc.thres / sc.s
    end

    sc.thres_changed=false

    nothing
end

function analog_slider_cb(widget::Ptr,user_data::Tuple{Offline_GUI})

    han, = user_data

    han.av.pos = getproperty(han.av.adj,:value,Int)

    han.av.changed = true

    nothing
end

function analog_gain_cb(widget::Ptr,user_data::Tuple{Offline_GUI})

    han, = user_data

    han.av.changed = true

    nothing
end

function replot_analog(han)
    ctx = Gtk.getgc(han.av.c)

    set_source_rgb(ctx,0.0,0.0,0.0)
    paint(ctx)

    h=height(ctx)
    w=width(ctx)

    gain = han.sc.s

    set_source_rgb(ctx,1.0,1.0,1.0)
    move_to(ctx,1.0,h/2+han.v[han.av.pos]*gain)
    for i=2:round(Int64,w)
        line_to(ctx,i,h/2+han.v[han.av.pos+i-1]*gain)
    end
    stroke(ctx)

    reveal(han.av.c)

    han.av.changed = false
    nothing
end
