module Feature_Test

using FactCheck,SpikeSorting

d=DetectSignal()
cluster=ClusterOSort();
align=AlignMax();
reduce=ReductionNone();
thres=ThresholdMean();
num_channels=1;

(buf,nums)=output_buffer(num_channels);
v=rand(1:1000, 1000, num_channels);
count=1.0
for i=525:550
    v[i,1]+=count
    count+=10
end
for i=551:775
    v[i,1]+=1
    count-=10
end
#=
Time
=#

f=FeatureTime()
s1=create_multi(d,cluster,align,f,reduce,thres,num_channels);

cal!(s1,v,buf,nums,0)
cal!(s1,v,buf,nums,1)
cal!(s1,v,buf,nums,2)
onlinesort!(s1,v,buf,nums)

facts() do

end

#=
Discrete Derivatives
=#

f=FeatureDD()
s1=create_multi(d,cluster,align,f,reduce,thres,num_channels);

cal!(s1,v,buf,nums,0)
cal!(s1,v,buf,nums,1)
cal!(s1,v,buf,nums,2)
onlinesort!(s1,v,buf,nums)

facts() do

end

#=
Curvature
=#

f=FeatureCurv()
s1=create_multi(d,cluster,align,f,reduce,thres,num_channels);

cal!(s1,v,buf,nums,0)
cal!(s1,v,buf,nums,1)
cal!(s1,v,buf,nums,2)
onlinesort!(s1,v,buf,nums)

facts() do

end

end
