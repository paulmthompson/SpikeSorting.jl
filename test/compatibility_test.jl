module Compatibility_test

using SpikeSorting, FactCheck

num_channels=1;

(buf,nums)=output_buffer(num_channels);
v=rand(1:1000, 1000, num_channels);

detects=subtypes(SpikeSorting.Detect)
aligns=subtypes(SpikeSorting.Align)
features=subtypes(SpikeSorting.Feature)
reduces=subtypes(SpikeSorting.Reduction)
clusters=subtypes(SpikeSorting.Cluster)
thresholds=subtypes(SpikeSorting.Threshold)

for d in detects
    for a in aligns
        for f in features
            for r in reduces
                for c in clusters
                    for t in thresholds
                        
                        s1=create_multi(d(),c(),a(),f(),r(),t(),num_channels)

                        cal!(s1,v,buf,nums,0)
                        cal!(s1,v,buf,nums,1)
                        cal!(s1,v,buf,nums,2)
                        onlinesort!(s1,v,buf,nums)

                        facts() do
                            @fact s1[1].sigend --> v[end-74:end,1]
                        end
                        
                    end
                end
            end
        end
    end
end


end
