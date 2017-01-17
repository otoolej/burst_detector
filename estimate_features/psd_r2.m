%-------------------------------------------------------------------------------
% psd_r2: error of linear regression fit to log-log PSD
%
% Syntax: t_stat=psd_r2(x,Fs,freq_band)
%
% Inputs: 
%     x         - 1-channel of EEG data (size 1 x N)
%     Fs        - sampling frequency (in Hz, must be ≥64 Hz)
%     freq_band - frequency band in which to assess regression fit
%
% Outputs: 
%     t_stat - feature generated from x (size 1 x N)
%
% Example:
%     N=5000; Fs=64; 
%     x=gen_impulsive_noise(N).*10;
%
%     t_stat=psd_r2(x,Fs,[3 8]);
%
%     figure(1); clf; 
%     t=(0:N-1)./Fs;
%     plotyy(t,x,t,t_stat); 
%     xlabel('time (seconds)');

% John M. O' Toole, University College Cork
% Started: 17-06-2015
%
% last update: Time-stamp: <2017-01-17 17:11:10 (otoolej)>
%-------------------------------------------------------------------------------
function t_stat=psd_r2(x,Fs,freq_band)
if(nargin<2), error('need signal and sampling frequency as I/P args.'); end
if(nargin<3 || isempty(freq_band)), freq_band=[0.5 3]; end

% FFT length:
Nfreq=2048;


N=length(x);

% for short-time analysis:
EPOCH_SIZE=2; 
OVERLAP=75; % in percentage
[L_hop,L_epoch,win_epoch]=epoch_window(OVERLAP,EPOCH_SIZE,'hamm',Fs);
N_epochs=floor( (N-L_epoch)/L_hop );
if(N_epochs<1) N_epochs=1; end
nw=0:L_epoch-1;

freq=linspace(0,Fs/2,Nfreq);
irange=find( freq<freq_band(2) & freq>freq_band(1) );
freq_db=10*log10(freq(irange));


%---------------------------------------------------------------------
% 3. break-up into the epochs
%---------------------------------------------------------------------
z_all=zeros(1,N); win_summed=zeros(1,N);
for k=1:N_epochs
    nf=mod(nw+(k-1)*L_hop,N);
    x_epoch=x(nf+1).*win_epoch.';

    X=abs(fft(x_epoch,Nfreq));
    pxx_db=20*log10( X(irange) );
    
    [~,R2]=lin_regress(freq_db,pxx_db);

    z_all(nf+1)=z_all(nf+1) + (ones(1,L_epoch)*R2);
    win_summed(nf+1)=win_summed(nf+1)+ones(1,L_epoch);      
end

t_stat=z_all./win_summed;


        

function [c,r2]=lin_regress(x,y)
%---------------------------------------------------------------------
% linear regression
%---------------------------------------------------------------------
N=length(y);

% $$$ c=polyfit(x,y,1);
c=fast_polyfit(x,y);


y_fit=c(1)*x + c(2);
y_residuals=y-y_fit;

r2=1-(sum( y_residuals.^2 ))./( (N-1).*var(y) );



function c=fast_polyfit(x1,y1)
%---------------------------------------------------------------------
% faster implementation (but no sanity checking) than polyfit.m 
%
% (from
% https://uk.mathworks.com/matlabcentral/answers/41652-speed-comparison-between-polyfit-and-a-y)
%---------------------------------------------------------------------
c=[ones(length(x1),1) ,reshape(x1,length(x1),1)] \ reshape(y1,length(y1),1);
c=fliplr(c');
