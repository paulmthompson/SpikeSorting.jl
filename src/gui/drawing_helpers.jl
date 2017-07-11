
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
