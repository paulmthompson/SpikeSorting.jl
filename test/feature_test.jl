module Feature_Test

using SpikeSorting

if VERSION > v"0.7-"
    using Test
else
    using Base.Test
end


d=DetectNeg()
cluster=ClusterOSort();
align=AlignMax();
reduce=ReductionNone();
thres=ThresholdMeanN();
num_channels=1;

(buf,nums)=output_buffer(num_channels);

function make_voltage(num_channels)

    v=rand(1:1000, 1000, num_channels);
    count = 1
    for i=525:550
        v[i,1] = v[i,1] + count
        count = count + 10
    end
    for i=551:775
        v[i,1]+=1
        count -= 10
    end
    v
end

v=make_voltage(num_channels)
#=
Time
=#

f=FeatureTime()
s1=create_multi(d,cluster,align,f,reduce,thres,num_channels);

cal!(s1,v,buf,nums,0)
cal!(s1,v,buf,nums,1)
cal!(s1,v,buf,nums,2)
onlinesort!(s1,v,buf,nums)



#=
Discrete Derivatives
=#
#=
f=FeatureDD()
s1=create_multi(d,cluster,align,f,reduce,thres,num_channels);

cal!(s1,v,buf,nums,0)
cal!(s1,v,buf,nums,1)
cal!(s1,v,buf,nums,2)
onlinesort!(s1,v,buf,nums)


=#
#=
Curvature
=#
#=
f=FeatureCurv()
s1=create_multi(d,cluster,align,f,reduce,thres,num_channels);

cal!(s1,v,buf,nums,0)
cal!(s1,v,buf,nums,1)
cal!(s1,v,buf,nums,2)
onlinesort!(s1,v,buf,nums)

facts() do

end
=#
end
