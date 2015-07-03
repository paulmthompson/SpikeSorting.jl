module SortSpikes

using ExtractSpikes, Winston, Gtk.ShortNames

export onlineCal, onlineSort, offlineSort, onlineCal_par, get_context, plotline, wipeout

#Should define types here

function onlineCal(sort::Sorting,method="POWER")
    #The first data collected will be different in several ways. Need to determine:
    #Threshold for spike detection
    #Threshold for cluster assignment and merger
    #Cluster templates

    if method=="POWER"
        #find the thresholds for each channel
        sort.s.thres=getThres(sort,method)
        
        #Threshold is supposed to be the average standard deviation of all of the spiking events. Don't have any of those to start
        sort.c.Tsm=50*var(sort.rawSignal) 
        #Run a second of data to refine cluster templates, and not caring about recording spikes
        #Also, should be able to load clusters from the end of previous session
        prepareCal(sort)
        
        PowerDetection1=Detection{:PowerDetection}()
        detectSpikes(sort,PowerDetection1, 76)
    end

    #if new clusters were discovered, get rid of initial noise cluster to skip merger code later on when unnecessary
    #might want to change this later
    if sort.c.numClusters>1
        for j=2:sort.c.numClusters
            sort.c.clusters[:,j-1]=sort.c.clusters[:,j]
            sort.c.clusters[:,j]=zeros(Float64,size(sort.c.clusters[:,j]))
            sort.c.clusterWeight[j-1]=sort.c.clusterWeight[j]
            sort.c.clusterWeight[j]=0
         end
         sort.c.numClusters-=1
    end

    sort.electrode=zeros(size(sort.electrode))
    sort.neuronnum=zeros(size(sort.electrode))
    sort.numSpikes=2

    return sort
end

function onlineSort(sort::Sorting,method="POWER")
 
    #Find spikes during this time block, labeled by neuron

    if method=="POWER"
             
        PowerDetection1=Detection{:PowerDetection}()
        detectSpikes(sort,PowerDetection1)       

    elseif method=="SIGNAL"

        detectSpikes(sort,SignalDetection)
        
    elseif method=="NEO"

        detectSpikes(sort,NEODetection)

    elseif method=="MANUAL"

        detectSpikes(sort, ManualDetection)

    end

    #convert to absolute time stamps with the timeends variable

    #move stuff around if there were mergers of clusters (I guess? maybe do all of that at the end)

    #write to output  
    
    return sort
    
end

function offlineSort()

    
end

function get_context(c::Gtk.Canvas, pc::Winston.PlotContainer)
    device = Winston.CairoRenderer(Gtk.cairo_surface(c))
    ext_bbox = Winston.boundingbox(device)
    Winston._get_context(device, ext_bbox, pc)
end

function make2(self::Winston.Curve, context::Winston.PlotContext)
    x, y = Winston.project(context.geom, self.x, self.y)
    y = context.draw.ctx.surface.height - y
    Winston.GroupPainter(Winston.getattr(self,:style), Winston.PathPainter(x,y))
end

function plotline(i::Int64,c::Array{Gtk.Canvas,1},cu::Array{Winston.Curve,1},a::Array{Winston.PlotContext,1})

    d=make2(cu[i],a[i])

    Winston.paint(d,a[i].paintc)
    
end

function wipeout(context::Winston.PlotContext,M=50,N=50)
    
    imgdata = reshape([ 0x00ffffff for i in 0:(M^2-1) ], (M, M))
    img = Winston.Image((1, M), (1, N), round(UInt32,imgdata))
    
    a = Winston.project(context.geom, Winston.Point(img.x, img.y))
    b = Winston.project(context.geom, Winston.Point(img.x+img.w, img.y+img.h))
    bbox = Winston.BoundingBox(a, b)
    bbox2=Winston.BoundingBox(bbox.xmin,bbox.xmax,
    context.draw.ctx.surface.height - bbox.ymax,context.draw.ctx.surface.height - bbox.ymin)
    Winston.GroupPainter(Winston.getattr(img,:style), Winston.ImagePainter(img.img, bbox2))
    
end

end
