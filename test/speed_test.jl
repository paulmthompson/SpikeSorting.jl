

module Speed_test

using SpikeSorting, JLD, BenchmarkTools

a=load(string(dirname(Base.source_path()),"/data/spikes2.jld"))
time_stamps=a["time_stamps"]
fv=a["fv"]

cluster=ClusterTemplate();
align=AlignMin();
feature=FeatureTime();
reduce=ReductionNone();
thres=ThresholdMeanN();
num_channels=1;

(buf,nums)=output_buffer(num_channels);

s1=create_multi(d,cluster,align,feature,reduce,thres,num_channels);

cal!(s1,fv,buf,nums,0)
cal!(s1,fv,buf,nums,1)
cal!(s1,fv,buf,nums,2)
onlinesort!(s1,fv,buf,nums);

@time onlinesort!(s1,fv,buf,nums);








end