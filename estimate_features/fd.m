%-------------------------------------------------------------------------------
% fd: Higuichi method to estimate the fractal dimension [1]
%
% Syntax: t_stat=fd(x,Fs)
%
% Inputs: 
%     x      - 1-channel of EEG data (size 1 x N)
%     Fs     - sampling frequency (in Hz, must be ≥64 Hz)
%
% Outputs: 
%     t_stat - feature generated from x (size 1 x N)
%
% Example:
%     N=5000; Fs=64; 
%     x=gen_impulsive_noise(N).*10;
%
%     t_stat=fd(x,Fs);
%
%     figure(1); clf; 
%     t=(0:N-1)./Fs;
%     plotyy(t,x,t,t_stat); 
%     xlabel('time (seconds)');
%
%
% [1] T. Higuchi, “Approach to an irregular time series on the basis of 
% the fractal theory,” Phys. D Nonlinear Phenom., vol. 31, pp. 277–283, 
% 1988.


% John M. O' Toole, University College Cork
% Started: 18-06-2015
%
% last update: Time-stamp: <2015-06-25 17:47:39 (otoolej)>
%-------------------------------------------------------------------------------
function t_stat=fd(x,Fs)
if(nargin<2), error('need signal and sampling frequency as I/P args.'); end


N=length(x);

%---------------------------------------------------------------------
% 1. bandpass filter the signal 
%---------------------------------------------------------------------
LP_fc=0.5;  HP_fc=30;
x=do_bandpass_filtering(x,Fs,LP_fc,HP_fc);


%---------------------------------------------------------------------
% 2. generate derivate (using forward-finite difference)
%---------------------------------------------------------------------
EPOCH_SIZE=1; 
OVERLAP=75; % in percentage
% for short-time analysis:
[L_hop,L_epoch,win_epoch]=epoch_window(OVERLAP,EPOCH_SIZE,'rect',Fs);
N_epochs=floor( (N-L_epoch)/L_hop );
if(N_epochs<1) N_epochs=1; end
nw=0:L_epoch-1;

z_all=zeros(1,N); win_summed=zeros(1,N);
for k=1:N_epochs
    nf=mod(nw+(k-1)*L_hop,N);
    x_epoch=x(nf+1);

    fd=fd_higuchi(x_epoch,6);
    fd=-fd;
    
    z_all(nf+1)=z_all(nf+1) + (ones(1,L_epoch)*fd);
    win_summed(nf+1)=win_summed(nf+1)+ones(1,L_epoch);            
end
t_stat=z_all./win_summed;





function FD=fd_higuchi(x,kmax)
%---------------------------------------------------------------------
% estimate fractal dimension using the Higuchi approach
%---------------------------------------------------------------------
N=length(x);

DBplot=0;

if(nargin<2 || isempty(kmax)), kmax=floor(N/10); end

FD=[]; L=[];


% what values of k to compute?
ik=1; k_all=[]; knew=0;
while( knew<kmax )
    if(ik<=4)
        knew=ik;
    else
        knew=floor(2^((ik+5)/4));
    end
    if(knew<=kmax)
        k_all=[k_all knew];
    end
    ik=ik+1;
end


%---------------------------------------------------------------------
% curve length for each vector:
%---------------------------------------------------------------------
inext=1; L_avg=zeros(1,length(k_all));
for k=k_all
    
    L=zeros(1,k);
    for m=1:k
        ik=1:floor( (N-m)/k );
        scale_factor=(N-1)/(floor( (N-m)/k )*k);
        
        L(m)=sum( abs( x(m+ik.*k) - x(m+(ik-1).*k) ) )*(scale_factor/k);
        
    end

    L_avg(inext)=mean(L);
    inext=inext+1;    
end

x1=log2(k_all); y1=log2(L_avg);
c=polyfit(x1,y1,1);
FD=-c(1);

if(nargout>1)
    y_fit=c(1)*x1 + c(2);
    y_residuals=y1-y_fit;

    r2=1-(sum( y_residuals.^2 ))./( (N-1).*var(y1) );
end

