
module Detect_test

using SpikeSorting, FactCheck

cluster=ClusterOSort();
align=AlignMax();
feature=FeatureTime();
reduce=ReductionNone();
thres=ThresholdMeanN();
num_channels=1;

(buf,nums)=output_buffer(num_channels);
v=rand(1:1000, 1000, num_channels);

#=
Power

Rutishauser et al 2006
=#
#=
d=DetectPower()
s1=create_multi(d,cluster,align,feature,reduce,thres,num_channels);

cal!(s1,v,buf,nums,0)
cal!(s1,v,buf,nums,1)
cal!(s1,v,buf,nums,2)
onlinesort!(s1,v,buf,nums);

facts() do

    @fact s1[1].d.a --> less_than(s1[1].d.b)
    @fact s1[1].d.a --> greater_than(s1[1].d.c)
end
=#

#=
Raw Signal

=#

d=DetectNeg()
s1=create_multi(d,cluster,align,feature,reduce,thres,num_channels);

cal!(s1,v,buf,nums,0)
cal!(s1,v,buf,nums,1)
cal!(s1,v,buf,nums,2)
onlinesort!(s1,v,buf,nums);

end
