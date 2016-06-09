
#=
Constants needed for various methods
=#

#Detection Power

const power_win=20
const power_win1=power_win+1
const power_win0=power_win-1

#Wavelets
#=
const coiflets_five=[0.00021208083980379827
0.00035858968789573785
-0.0021782363581090178
-0.004159358781386048
0.010131117519849788
0.023408156785839195
-0.02816802897093635
-0.09192001055969624
0.05204316317624377
0.4215662066908515
-0.7742896036529562
0.4379916261718371
0.06203596396290357
-0.10557420870333893
-0.0412892087501817
0.03268357426711183
0.01976177894257264
-0.009164231162481846
-0.006764185448053083
0.0024333732126576722
0.0016628637020130838
-0.0006381313430451114
-0.00030225958181306315
0.00014054114970203437
4.134043227251251e-05
-2.1315026809955787e-05
-3.7346551751414047e-06
2.0637618513646814e-06
1.6744288576823017e-07
-9.517657273819165e-08
0.0
0.0
0.0
0.0
0.0
0.0
0.0
0.0
0.0
0.0
];

#=
Multiscale Correlation of Wavelet Coefficients

Yang et al 2011
=#

const bigJ=20

const wave_a=collect(0.5:.1:1.5);

#This is REAL ugly, and edges aren't very good. Also code isn't very Julian


const coiflets_scaled=zeros(Float64,length(wave_a),bigJ)

coif_intp=interpolate(coiflets_five,BSpline(Quadratic(Line())),OnCell())
interpvec=collect(1:.1:40)
coif_up=Float64[coif_intp[i] for i in interpvec]

for i=1:length(wave_a)
    t=collect(1:bigJ)./wave_a[i]
    for j=1:bigJ
        coiflets_scaled[i,j]=coif_up[indmin(abs(interpvec-t[j]))]       
    end
end

const onesquarea=Float64[1/sqrt(wave_a[i]) for i=1:11]
=#
#=
CLASSIT clustering algorithm
=#

const acuity=1.0 / sqrt(2.0 * pi) #Probably adjust this based on variance

const cob_cutoff=0.2

#=
Discrete Derivatives - Maximum Difference Test
=#

const DD_inds=[1; 3; 7]
