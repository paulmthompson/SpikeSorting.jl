
#=
Feature extraction methods. Each method needs
1) Type with fields necessary for algorithm
2) function "feature" to operate on sort with type field defined above
3) any other necessary functions for extraction algorithm

=#

export FeatureTime

featureprepare(f::Feature,sort::Sorting)=nothing

#=
Temporal Waveform
=#

type FeatureTime <: Feature 
end

FeatureTime(M::Int64,N::Int64)=FeatureTime()

function feature(f::FeatureTime,sort::Sorting)
    sort.features=sub(sort.waveform,sort.dims)
    nothing
end

mysize(feature::FeatureTime,wavelength::Int64)=wavelength

#=
online PCA


type FeaturePCA <: Feature
    oPCA::OnlineStats.OnlinePCA
end

function FeaturePCA()
    FeaturePCA(OnlineStats.OnlinePCA(window,4))
end

function FeaturePCA(win::Int64,dims::Int64)
    FeaturePCA(OnlineStats.OnlinePCA(win,dims))
end


function feature{D<:Detect,C<:Cluster,A<:Align,F<:FeaturePCA,R<:Reduction}(sort::Sorting{D,C,A,F,R})
    OnlineStats.update!(sort.f.oPCA,sort.waveforms[:,sort.numSpikes])
    sort.features[:]=sort.f.oPCA.V*sort.waveforms[:,sort.numSpikes]
    nothing
end

function mysize(feature::FeaturePCA,wavelength::Int64)
    feature.oPCA.k
end

=#

#=
Wavelet
=#
#=
type FeatureWPD <: Feature
end

function FeatureWPD(M::Int64,N::Int64)
    FeatureWPD()
end

function feature(f::FeatureWPD,sort::Sorting)
    #a=2^i where i = 1:L and L=log2(N) where N is signal length

end

function mysize(feature::FeatureWPD,wavelength::Int64)
end
=#

#=
Integral Transform

Zviagintsev et al 2006
=#
#=
type FeatureIT <: Feature
    N1::Int64
    N2::Int64
    wavemean::Float64
    itr::Int64
    tbeta::Int64
    talpha::Int64
end

FeatureIT()=FeatureIT(0,0,0.0,0,0,0)

FeatureIT(M::Int64,N::Int64)=FeatureIT()

function feature(f::FeatureIT,sort::Sorting)
    
    sort.features[:]=zeros(Float64,length(sort.features))
    for i=sort.f.talpha:(sort.f.talpha+sort.f.N1)
        sort.features[1]+=sort.waveforms[i,sort.numSpikes]
    end
    sort.features[1]=sort.features[1]/sort.f.N1

    for i=sort.f.tbeta:(sort.f.tbeta+sort.f.N2)
        sort.features[2]+=sort.waveforms[i,sort.numSpikes]
    end
    sort.features[2]=sort.features[2]/sort.f.N2
    
    nothing
end

mysize(feature::FeatureIT,wavelength::Int64)=2

function featureprepare(f::FeatureIT,sort::Sorting)

    sort.f.wavemean=mean(sort.waveforms[:,sort.numSpikes])
    tempN1=0
    tempN2=0
    thisval=0
    lastval=0
    N1=0
    N2=0
    talpha=0
    talphat=0
    tbeta=0
    tbetat=0
    
    for i=1:size(sort.waveforms,1)

        thisval=sign(sort.waveforms[i,sort.numSpikes]-sort.f.wavemean)
        if thisval==lastval
            if thisval==1
                tempN2+=1
                if tempN2>N2
                    N2=tempN2
                    tbeta=tbetat
                end
            else
                tempN1+=1
                if tempN1>N1
                    N1=tempN1
                    talpha=talphat
                end
            end  
        else
            if thisval==1
                tempN2=1
                tbetat=i
            else
                tempN1=1
                talphat=i
            end            
        end
        lastval=thisval
    end

    if sort.f.itr==0
        sort.f.N1=N1
        sort.f.N2=N2
        sort.f.talpha=talpha
        sort.f.tbeta=tbeta
    else
        sort.f.N1=round((sort.f.itr/(sort.f.itr+1))*sort.f.N1+(1/(sort.f.itr+1))*N1)
        sort.f.N2=round((sort.f.itr/(sort.f.itr+1))*sort.f.N2+(1/(sort.f.itr+1))*N2)
        sort.f.talpha=round((sort.f.itr/(sort.f.itr+1))*sort.f.talpha+(1/(sort.f.itr+1))*talpha)
        sort.f.tbeta=round((sort.f.itr/(sort.f.itr+1))*sort.f.tbeta+(1/(sort.f.itr+1))*tbeta)
    end

    if sort.f.N1+sort.f.talpha>size(sort.waveforms,1)
        sort.f.N1=size(sort.waveforms,1)-sort.f.talpha-1
    end
    if sort.f.N2+sort.f.tbeta>size(sort.waveforms,1)
        sort.f.N2=size(sort.waveforms,1)-sort.f.tbeta-1
    end
    

    sort.f.itr+=1
    
    nothing
    
end
=#
#=
Discrete Derivatives
=#
#=
type FeatureDD <: Feature
    inds::Array{Int64,2}
end

FeatureDD()=FeatureDD(ones(Int64,10,2))

FeatureDD(M::Int64,N::Int64)=FeatureDD(ones(Int64,N,2))

function feature(f::FeatureDD,sort::Sorting)
    for i=1:length(sort.dims)
        sort.features[i]=sort.waveform[sort.f.inds[i,2]]-sort.waveform[sort.f.inds[i,2]-sort.f.inds[i,1]]
    end     
    nothing
end

function mysize(feature::FeatureDD,wavelength::Int64)
    sizeN=0
    for i=1:length(DD_inds)
        sizeN+=wavelength-DD_inds[i]
    end
    sizeN
end

function featureprepare(f::FeatureDD,sort::Sorting)
    counter=1
    counterdim=1
    for i in DD_inds
        for j=(i+1):size(sort.waveform,1)
            sort.fullfeature[counter]=sort.waveform[j]-sort.waveform[j-i]
            if counter==sort.dims[counterdim]
                sort.f.inds[counterdim,1]=i
                sort.f.inds[counterdim,2]=j
                counterdim+=1
            end
            counter+=1
        end
    end

    sort.features[:]=sort.fullfeature[sort.dims]
    nothing      
end
=#
#=
#=
Curvature
=#
#=
type FeatureCurv <: Feature
end

FeatureCurv(M::Int64,N::Int64)=FeatureCurv()

function feature(f::FeatureCurv,sort::Sorting)
    V1=0.0
    V2=0.0

    for i in sort.dims
        V1=sort.waveform[i]-sort.waveform[i-1]
        V2=sort.waveform[i+1]-2*sort.waveform[i]+sort.waveform[i-1]
        sort.feature[i-1]=V2/(1+V1^2)^1.5
    end
    
    nothing
end

mysize(feature::FeatureCurv,wavelength::Int64)=wavelength-2

function featureprepare(f::FeatureCurv,sort::Sorting)
    V1=0.0
    V2=0.0

    for i=2:size(sort.waveform,1)-1
        V1=sort.waveform[i]-sort.waveform[i-1]
        V2=sort.waveform[i+1]-2*sort.waveform[i]+sort.waveform[i-1]
        sort.fullfeature[i-1]=V2/(1+V1^2)^1.5
    end
    
    nothing
end
=#
=#
