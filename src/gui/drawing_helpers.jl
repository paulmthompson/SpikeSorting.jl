
function line(ctx,x1,x2,y1,y2)
    move_to(ctx,x1,y1)
    line_to(ctx,x2,y2)
    nothing
end

function add_button_label(button,mylabel)
    b_label=Label(mylabel)
    Gtk.GAccessor.markup(b_label, string("""<span size="x-small">""",mylabel,"</span>"))
    push!(button,b_label)
    show(b_label)
end

function change_button_label(button,mylabel)
    hi=Gtk.GAccessor.child(button)
    Gtk.GAccessor.markup(hi, string("""<span size="x-small">""",mylabel,"</span>"))
end

function draw_box(x1,y1,x2,y2,mycolor,linewidth,ctx)
    move_to(ctx,x1,y1)
    line_to(ctx,x2,y1)
    line_to(ctx,x2,y2)
    line_to(ctx,x1,y2)
    line_to(ctx,x1,y1)
    set_source_rgb(ctx,mycolor[1],mycolor[2],mycolor[3])
    set_line_width(ctx,linewidth)
    stroke(ctx)
    nothing
end
