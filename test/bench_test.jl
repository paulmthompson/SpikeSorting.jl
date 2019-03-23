
module Bench_test

using SpikeSorting, JLD

if VERSION > v"0.7-"
    using Test
else
    using Base.Test
end

a=load(string(dirname(Base.source_path()),"/data/spikes2.jld"))
time_stamps=a["time_stamps"]
fv=a["fv"]

detect=DetectNeg()
cluster=ClusterOSort(100,50)
align=AlignMin()
feature=FeatureTime()
reduce=ReductionNone()
thres=ThresholdMeanN(2.0)
s1=create_multi(detect,cluster,align,feature,reduce,thres,1)

ss=SpikeSorting.benchmark(fv,time_stamps,s1[1],180.0,20000)

detected_spikes=sum([length(ss[1][i]) for i=1:length(ss[1])])
tpfp=ss[3]+sum(ss[4])
tpfn=ss[3]+sum(ss[5])



    @test detected_spikes == tpfp
    @test sum(ss[2]) == tpfn



ss2=SpikeSorting.benchmark(fv,time_stamps,s1[1],60.0,20000)

detected_spikes2=sum([length(ss2[1][i]) for i=1:length(ss2[1])])
tpfp2=ss2[3]+sum(ss2[4])
tpfn2=ss2[3]+sum(ss2[5])



    @test detected_spikes2 == tpfp2
    @test sum(ss2[2]) == tpfn2
    @test detected_spikes < less_than(detected_spikes2)


end
