
#=
Clustering methods. Each method needs
1) Type with fields necessary for algorithm
2) function "cluster" to operate on sort with type field defined above
3) any other necessary functions for clustering algorithm

=#

export ClusterOSort

function clusterprepare(c::Cluster, sort::Sorting)   
end

#=
OSort

Rutishauser 2006
=#

type ClusterOSort <: Cluster
    clusters::Array{Float64,2}
    clusterWeight::Array{Int64,1}
    numClusters::Int64
    Tsm::Float64
    m_k::Float64
    k::Int64
    m_l::Float64
    s_k::Float64
    s_l::Float64
end

function ClusterOSort()   
    ClusterOSort(zeros(Float64,50,5),zeros(Int64,5),0,1.0,0.0,1,0.0,0.0,0.0)  
end

function ClusterOSort(n::Int64)
    ClusterOSort(zeros(Float64,n,5),zeros(Int64,5),0,1.0,0.0,1,0.0,0.0,0.0)
end

function cluster(c::ClusterOSort,sort::Sorting)
   
    x=getdist(sort)

    id=0
    
    #add new cluster or assign to old
    if x==0
        sort.c.numClusters+=1
        sort.c.clusters[:,sort.c.numClusters]=sort.features[:]
        sort.c.clusterWeight[sort.c.numClusters]=1   
        id=sort.c.numClusters
    else       
        if sort.c.clusterWeight[x]<20
            sort.c.clusterWeight[x]+=1
            for i=1:size(sort.c.clusters,1)
                sort.c.clusters[i,x]=(sort.c.clusterWeight[x]-1)/sort.c.clusterWeight[x]*sort.c.clusters[i,x]+1/sort.c.clusterWeight[x].*sort.features[i]
            end
        else
            for i=1:size(sort.c.clusters,1)
                sort.c.clusters[i,x]=.95.*sort.c.clusters[i,x]+.05.*sort.features[i]
            end
        end
        id=x       
    end

    if sort.c.numClusters>1
        merged=findmerge!(sort)
    end
    id
end

function getdist(sort::Sorting)
    
    dist=Array(Float64,sort.c.numClusters)
    for i=1:sort.c.numClusters
        dist[i]=norm(sort.features-sort.c.clusters[:,i])^2
    end
    if sort.c.numClusters<1
        return 0
    else 
        ind=indmin(dist)
        if dist[ind]<sort.c.Tsm
            return ind
        else
            return 0
        end
    end
  
end

function findmerge!(sort::Sorting)
    #if two clusters are below threshold distance away, merge them

    skip=0
    merger=0

    for i=1:sort.c.numClusters-1
        
        if i==skip
            continue
        end
        
        for j=(i+1):sort.c.numClusters
                dist=norm(sort.c.clusters[:,i]-sort.c.clusters[:,j])^2
            if dist<sort.c.Tsm
                for k=1:size(sort.c.clusters[:,i],1)
                    sort.c.clusters[k,i]=(sort.c.clusters[k,i]+sort.c.clusters[k,j])/2
                end
                sort.c.numClusters-=1
                skip=j
                merger=i
            end
        end
    end

    if skip!=0

        for i=skip:sort.c.numClusters+1
            sort.c.clusters[:,i]=sort.c.clusters[:,i+1]
        end
    end

    [skip,merger]
    
end

function clusterprepare(c::ClusterOSort,sort::Sorting,p::Int64)

    sort.c.k+=1
    
    sort.c.m_k=sort.c.m_l+(p-sort.c.m_l)/sort.c.k
    sort.c.s_k=sort.c.s_l+(p-sort.c.m_l)*(p-sort.c.m_k)

    myvar=sort.c.s_k/(sort.c.k-1)


    sort.c.Tsm=(myvar)*50

    sort.c.m_l=sort.c.m_k
    sort.c.s_l=sort.c.s_k
   
    nothing
end


#=
CLASSIT
=#

type attribute
    S::Float64
    SS::Float64
    std::Float64
end

type node
    n::Int64 #count
    a::Array{attribute,1} #attributes
    instdsum::Float64   
    c::Array{node,1} #children
    proc::Bool
end

function node(x::Array{Float64,1})
    
    a=[attribute(x[i],x[i]^2,acuity) for i=1:length(x)]
    instdsum=0.0
    for i=1:length(x)
        instdsum+=1/a[i].std
    end

    node(1,a,instdsum,Array(node,0),false) 
end

function node(N1::node,N2::node)
    a=Array(attribute,length(N1.a))
    instdsum=0.0
    prior=N1.n+N2.n
    a=[attribute(N1.a[i].S+N2.a[i].S,N1.a[i].SS+N2.a[i].SS,0.0) for i=1:length(N1.a)]
    for j=1:length(N1.a)  
        a[j].std=sqrt((1/(prior))*((a[j].SS+x[j]^2)-((a[j].S+x[j])^2/(prior+1))))
        if a[j].std<acuity
            a[j].std=acuity
        end
        instdsum+=1/a[j].std
    end
    node(prior,a,instdsum,[N1;N2],false)    
end

type ClusterClassit <: Cluster
    clustree::node
end

function ClusterClassit()
    ClusterClassit(node(zeros(Float64,3)))
end

function ClusterClassit(N::Int64)
    ClusterClassit(node(zeros(Float64,N)))
end

function cluster(c::ClusterClassit,sort::Sorting)
    x=sort.features[:]
    cobweb(sort.c.clustree,x)
end

function updatestd(N::node,x::Array{Float64,1},ind::Int64)

    stdmat=0.0
    
    for j=1:length(N.a)
        
        std=sqrt((1/(N.c[ind].n))*((N.c[ind].a[j].SS+x[j]^2)-((N.c[ind].a[j].S+x[j])^2/(N.c[ind].n+1))))
        if std<acuity
            std=acuity
        end

        stdmat+=1/std
    end

    stdmat
    
end

function parentstd(N::node,x::Array{Float64,1})

    N.instdsum=0.0
    
    for j=1:length(N.a)
        N.a[j].S=N.a[j].S+x[j]
        N.a[j].SS=N.a[j].SS+x[j]^2
        N.a[j].std=sqrt((1/(N.n-1))*((N.a[j].SS)-((N.a[j].S)^2/(N.n))))
        if N.a[j].std<acuity
            N.a[j].std=acuity
        end

        N.instdsum+=1/N.a[j].std
    end

    nothing
end

function cob_incorp(N::node,ind::Int64,stdmat::Float64)
    
    CU=0.0

    for i=1:length(N.c)
        if i==ind
            CU += (N.c[i].n+1)/N.n*stdmat
        else
            CU += (N.c[i].n)/N.n*N.c[i].instdsum
        end
    end
    
    CU=CU/length(N.c)
end

function cob_create(N::node)
    CU=0.0

    for i=1:length(N.c)
        CU += (N.c[i].n/N.n)*N.c[i].instdsum       
    end

    CU += 1/N.n*sum([1/acuity for i=1:length(N.a)])
    
    CU=CU/(length(N.c)+1)
end

function cob_merge(N::node,best1ind::Int64,best2ind::Int64,x::Array{Float64,1})

    CU=0.0
    count=0

    for i=1:length(N.c)
           if (i==best1ind | i==best2ind) & count==0
               stdmat=0.0
               prior=N.c[best1ind].n+N.c[best2ind].n
               for j=1:length(N.a)
                   SS=N.c[best1ind].a[j].SS+N.c[best2ind].a[j].SS
                   S=N.c[best1ind].a[j].S+N.c[best2ind].a[j].S   
                   std=sqrt((1/(prior))*((SS+x[j]^2)-((S+x[j])^2/(prior+1))))
                   if std<acuity
                       std=acuity
                   end

                   stdmat+=1/std
               end
               CU += (prior+1)/N.n*stdmat
               count=1
           else
            CU += (N.c[i].n)/N.n*N.c[i].instdsum
           end
    end
    
    CU=CU/(length(N.c)-1)
    
end

function cob_split(N::node,best1ind::Int64)
    CU=0.0

    for i=1:length(N.c)
        if i==best1ind
            for j=1:length(N.c[i].c)
                CU += (N.c[i].c[j].n)/N.n*N.c[i].c[j].instdsum
            end
        else
            CU += (N.c[i].n)/N.n*N.c[i].instdsum
        end
    end
    
    CU=CU/(length(N.c)+length(N.c[best1ind].c))
end
           
function cobweb(N::node, x::Array{Float64,1})
     
    if length(N.c)==0 #If leaf
     
        CU=0.0
        instdsum=0.0
        for i=1:length(N.a)
            std=sqrt((1/(N.n))*((N.a[i].SS+x[i]^2)-((N.a[i].S+x[i])^2/(N.n+1))))
            if std<acuity
                std=acuity
            end
            instdsum+=1/std
        end
        
        CU=(1/N.n*1/acuity+N.n/(N.n+1)*N.instdsum - instdsum)/2

        if CU<cob_cutoff
            
        else
            N.proc=false
            newnode1=node(x)
            newnode2=deepcopy(N)
            push!(N.c,newnode1)
            push!(N.c,newnode2)
        end
        N.n+=1
        parentstd(N,x)                 
    else

        if N.proc==false
            N.n+=1
            parentstd(N,x)
        end
        
        bestoverallind=0
        bestoverall=0.0
        
        #add I to each child and get CUs
        best1=0.0
        best1ind=0
        best2=0.0
        best2ind=0
        for i=1:length(N.c)
            stdmat=updatestd(N,x,i)
            S1=cob_incorp(N,i,stdmat)
            if S1>best2
                if S1>best1
                    best1=S1
                    best1ind=i
                else
                    best2=S1
                    best2ind=i
                end
            end            
        end
        bestoverallind=1
        bestoverall=best1
        
        #add I as new singleton child and get CU
        S2=cob_create(N)
        if S2>bestoverall
            bestoverallind=2
            bestoverall=S2
        end
                
        #merge best and second best CUs from 1 and add I to merged result
        if length(N.c)>2
            S3=cob_merge(N,best1ind,best2ind,x)
            if S3>bestoverall
                bestoverallind=3
                bestoverall=S3
            end 
        end
        
        #promote children of best child to be children of P, and add instance
        if length(N.c[best1ind].c)>0
            S4=cob_split(N,best1ind)
            if S4>bestoverall
                bestoverallind=4
                bestoverall=S4
            end
        end
              
        if bestoverallind==1
            N.proc=false
            cobweb(N.c[best1ind],x) #go down tree at best index
        elseif bestoverallind==2
            N.proc=false
            newnode=node(x)
            push!(N.c,newnode)       
        elseif bestoverallind==3
            newnode=node(N.c[best1ind],N.c[best2ind])
            deleteat!(N.c,best1ind)
            if best1ind>best2ind
                deleteat!(N.c,best2ind)
            else
                deleteat!(N.c,best2ind-1)
            end
            push!(N.c,newnode)
            N.c[end].proc=true
            cobweb(N.c[end],x)
        elseif bestoverallind==4
            append!(N.c,N.c[best1ind].c)
            deleteat!(N.c,best1ind)
            N.proc=true
            cobweb(N,x)
        end
        
    end

    return true
end

#=
Manual Detection - Window Discriminators
=#

type ClusterManual <: Cluster
    clusters::Array{Float64,2}
    numClusters::Int64
    win::Array{Float64,2}
end

function ClusterManual()   
    ClusterOSort(zeros(Float64,5),0,zeros(Float64,4,5))  
end

function cluster(c::ClusterManual, sort::Sorting)

    for i=1:sort.numClusters
        
        A1=(win[3,i]-win[4,i])/(win[1,i]-win[2,i])
        b1=win[3,i]-A1*win[1,i]
        
        A2=(sort.waveform[win[1,i]]-sort.waveform[win[2,i]])/(win[1,i]-win[2,i])
        b2=sort.waveform[win[1,i]]-A2*win[1,i]

        Xa=(b2 - b1) / (A1 - A2)

        if Xa>win[1,i] &&  Xa<win[2,i]
            sort.neuronnum[sort.numSpikes]=i
            sort.numSpikes+=1
            break
        else

        end   
    end      
end
