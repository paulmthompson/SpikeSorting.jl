
#Delete clusters
function b1_cb_template(widgetptr::Ptr,user_data::Tuple{Single_Channel})

    sc, = user_data
    clus=sc.buf.selected_clus

    if (clus<1) #do nothing if zeroth cluster selected
    else
        delete_cluster(sc.temp,clus)
        deleteat!(sc.sort_list,sc.total_clus+1)
        sc.total_clus -= 1
        sc.buf.selected_clus = 0
        selmodel=Gtk.GAccessor.selection(sc.sort_tv)
        Gtk.select!(selmodel, Gtk.iter_from_index(sc.sort_list,1))
        sc.buf.c_changed=true
    end
    nothing
end

function delete_cluster(c::ClusterTemplate,n)

    for i=1:size(c.templates,1)
        c.templates[i,n] = 0.0
        c.sig_max[i,n] = 0.0
        c.sig_min[i,n] = 0.0
    end

    c.tol[n]=0.0

    if n == c.num
        c.num -= 1
    else
        for i=n:(c.num-1)
            for j=1:size(c.templates,1)
                c.templates[j,i]=c.templates[j,i+1]
                c.sig_max[j,i]=c.sig_max[j,i+1]
                c.sig_min[j,i]=c.sig_min[j,i+1]
            end
            c.tol[i]=c.tol[i+1]
        end
        c.num -= 1
    end

    nothing
end

#Add Unit
function b2_cb_template(widget::Ptr,user_data::Tuple{Single_Channel})

    sc, = user_data

    #Add total number of units and go to that unit
    sc.total_clus += 1
    sc.temp.num += 1

    sc.buf.selected_clus = sc.total_clus
    push!(sc.sort_list,(sc.total_clus,))

    selmodel=Gtk.GAccessor.selection(sc.sort_tv)
    Gtk.select!(selmodel, Gtk.iter_from_index(sc.sort_list, sc.total_clus+1))

    nothing
end

function b3_cb_template(widget::Ptr,user_data::Tuple{Single_Channel,SortView})

    sc, sortview_widgets = user_data

    mybutton = convert(Button, widget)

    if sc.pause
        Gtk.GAccessor.active(sc.pause_button,false)
    end

    if !sc.hold
        clear_c2(sc.c2,sc.spike)
        sc.ctx2=Gtk.getgc(sc.c2)
        sc.ctx2s=copy(sc.ctx2)
        sc.buf.ind=1
        sc.buf.count=1
        sc.hold=true
        sc.pause=false
        change_button_label(mybutton,"Stop Collection")
    else

        Gtk.GAccessor.active(sc.pause_button,true)
        change_button_label(mybutton,"Collect Templates")

        if sc.buf.count==size(sc.buf.spikes,2)
            sc.buf.ind=sc.buf.count
        end

        if visible(sortview_widgets.win)
            recalc_features(sortview_widgets)
            replot_sort(sortview_widgets)
        end
    end

    nothing
end

function b4_cb_template(widgetptr::Ptr,user_data::Tuple{Single_Channel})

    sc, = user_data
    widget = convert(ToggleButton, widgetptr)

    #Untoggle
    if !getproperty(widget,:active,Bool)
        sc.buf.replot=true
    else
        #Toggling, so draw template
        if sc.pause
            draw_template_bounds(sc)
        end
    end

    nothing
end

function draw_template_bounds(sc::Single_Channel)

    ctx = sc.ctx2
    clus=sc.buf.selected_clus

     if clus>0
            s=sc.s
            o=sc.o

            Cairo.translate(ctx,0.0,sc.h2/2)
            Gtk.scale(ctx,sc.w2/sc.wave_points,s)

            move_to(ctx,1.0,sc.temp.templates[1,clus]+(sc.temp.sig_max[1,clus]*sc.temp.tol[clus])-o)

            for i=2:size(sc.temp.templates,1)
                y=sc.temp.templates[i,clus]+(sc.temp.sig_max[i,clus]*sc.temp.tol[clus])-o
                line_to(ctx,i,y)
            end

            y=sc.temp.templates[end,clus]-(sc.temp.sig_min[end,clus]*sc.temp.tol[clus])-o

            line_to(ctx,size(sc.temp.templates,1),y)

            for i=(size(sc.temp.templates,1)-1):-1:1
                y=sc.temp.templates[i,clus]-(sc.temp.sig_min[i,clus]*sc.temp.tol[clus])-o
                line_to(ctx,i,y)
            end

            close_path(ctx)

            select_color(ctx,clus+1)
            set_line_width(ctx,3.0)
            stroke_preserve(ctx)

            select_color(ctx,clus+1,.5)
            fill(ctx)
        end

    identity_matrix(ctx)
end

function check_cb_template(widget::Ptr,user_data::Tuple{Single_Channel})

    sc, = user_data

    mycheck=convert(CheckButton,widget)

    if getproperty(mycheck,:active,Bool)
        sc.sort_cb=true
    else
        sc.sort_cb=false
    end

    if sc.sort_cb
        draw_templates(sc)
    end

    nothing
end

function draw_templates(sc::Single_Channel)

    ctx = sc.ctx2s
    mywidth=width(ctx)
    myheight=height(ctx)

    s=sc.s
    o=sc.o

    Cairo.translate(ctx,0.0,myheight/2)
    Gtk.scale(ctx,mywidth/sc.wave_points,s)

    for clus=1:sc.total_clus

        move_to(ctx,1.0,(sc.temp.templates[1,clus])-o)

        for i=2:size(sc.temp.sig_max,1)
            y=sc.temp.templates[i,clus]-o
            line_to(ctx,i,y)
        end

        select_color(ctx,clus+1)
        set_line_width(ctx,3.0)
        stroke(ctx)
    end
    identity_matrix(ctx)
    nothing
end

function get_template_dims(sc::Single_Channel,clus)

    ctx=Gtk.getgc(sc.c3)
    mywidth=width(ctx)

    total_clus = max(sc.total_clus+1,5)

    xbounds=linspace(0.0,mywidth,total_clus+1)

    (xbounds[clus],xbounds[clus+1],0.0,130.0)
end

#=
Calculates the mean and bounds for a collection of spikes that
1) are not hidden by the mask vector
2) meet some condition

examples of this condition could be whether the spikes are contained within a rubberband, or if they are part of a certain cluster already
=#
function make_cluster(input::Array{T,2},mask,count,condition) where T

    hits=0
    mymean=zeros(Float64,size(input,1)-1)
    mysum=zeros(Int64,size(input,1)-1)
    mybounds=zeros(Float64,size(input,1)-1,2)

    for i=1:count
        if (condition[i])&&(mask[i])
            hits+=1
            for ii=1:length(mymean)
                mysum[ii] += input[ii,i]
                if hits==1
                    mybounds[ii,1]=input[ii,i]
                    mybounds[ii,2]=input[ii,i]
                else
                    if input[ii,i]>mybounds[ii,1]
                        mybounds[ii,1]=input[ii,i]
                    end
                    if input[ii,i]<mybounds[ii,2]
                        mybounds[ii,2]=input[ii,i]
                    end
                end
            end
        end
    end

    if hits==0
        hits=1
    end

    for i=1:length(mymean)
        mymean[i] = mysum[i]/hits
        mybounds[i,2] = abs(mymean[i]-mybounds[i,2])
        mybounds[i,1] = abs(mybounds[i,1] - mymean[i])
    end

    (mymean,mybounds)
end

function change_cluster(c::ClusterTemplate,mymean::Array{Float64,1},mystd::Array{Float64,2},n)

    for i=1:length(mymean)
        c.templates[i,n] = mymean[i]
        c.sig_max[i,n] = mystd[i,1]
        c.sig_min[i,n] = mystd[i,2]
    end

    nothing
end


function template_cluster(sc::Single_Channel,clus,mymean::Array{Float64,1},mymin::Array{Float64,1},mymax::Array{Float64,1},tol::Float64)

    @inbounds for i=1:sc.buf.ind

        mymisses=0
        for j=1:length(mymean)
            if (sc.buf.spikes[j,i]<(mymean[j]-(mymin[j]*tol)))|(sc.buf.spikes[j,i]>(mymean[j]+(mymax[j]*tol)))
                mymisses+=1
                if mymisses>1
                    break
                end
            end
        end
        if mymisses<1 #If passes template matching, set as unit
            sc.buf.clus[i]=clus
        elseif sc.buf.clus[i]==clus #If did not pass, but was previously, set to noise cluster
            sc.buf.clus[i]=0
        end
    end

    nothing
end

function send_clus(s::Array{T,1},sc::Single_Channel) where T<:Sorting
    s[sc.spike].c=deepcopy(sc.temp)
    nothing
end

function send_clus(s::DArray{T,1,Array{T,1}},sc::Single_Channel) where T<:Sorting
    (nn,mycore)=get_thres_id(s,sc.spike)
    remotecall_wait(((x,tt,num)->localpart(x)[num].c=tt),mycore,s,sc.temp,nn)
    nothing
end
