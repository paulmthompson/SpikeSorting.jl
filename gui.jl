
export get_context, plotline, wipeout

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
