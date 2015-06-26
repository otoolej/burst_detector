%-------------------------------------------------------------------------------
% rel_spec_power: relative spectral power of frequency band
%
% Syntax: t_stat=rel_spec_power(x,Fs,freq_band,total_freq_band)
%
% Inputs: 
%     x               - 1-channel of EEG data (size 1 x N)
%     Fs              - sampling frequency (in Hz, must be ≥64 Hz)
%     freq_band       - frequency band
%     total_freq_band - bandwidth of signal signal 
%
% Outputs: 
%     t_stat - feature generated from x (size 1 x N)
%
% Example:
%     N=5000; Fs=64; 
%     x=gen_impulsive_noise(N).*10;
%     total_freq_band=[0.5 30];
%     freq_band=[3 8];
%
%     t_stat=rel_spec_power(x,Fs,freq_band,total_freq_band);
%
%     figure(1); clf; 
%     t=(0:N-1)./Fs;
%     plotyy(t,x,t,t_stat); 
%     xlabel('time (seconds)');

% John M. O' Toole, University College Cork
% Started: 18-06-2015
%
% last update: Time-stamp: <2015-06-25 17:48:02 (otoolej)>
%-------------------------------------------------------------------------------
function t_stat=rel_spec_power(x,Fs,freq_band,total_freq_band)
if(nargin<2), error('need signal and sampling frequency as I/P args.'); end
if(nargin<3 || isempty(freq_band)), freq_band=[0.5 3]; end
if(nargin<4 || isempty(total_freq_band)), total_freq_band=[0.5 30]; end

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


%---------------------------------------------------------------------
% generate short-time FT on all data:
%---------------------------------------------------------------------
K_stft=zeros(N_epochs,L_epoch);
for k=1:N_epochs
    nf=mod(nw+(k-1)*L_hop,N);
    
    K_stft(k,:)=x(nf+1).*win_epoch';
end
S_stft=abs(fft(K_stft.',Nfreq)).^2;
S_stft=S_stft';

f_scale=(Nfreq/Fs);
itotal_bandpass=ceil(total_freq_band(1)*f_scale):floor(total_freq_band(2)*f_scale);


ibandpass=ceil(freq_band(1)*f_scale):floor(freq_band(2)*f_scale);        
%---------------------------------------------------------------------
% 2. break-up into the epochs
%---------------------------------------------------------------------
z_all=zeros(1,N); win_summed=zeros(1,N);
kshift=floor( L_epoch/(2*L_hop) );
N_epochs_plus=N_epochs+kshift;
tv_spec_energ=zeros(1,N_epochs_plus);
for k=1:N_epochs
    tv_spec_energ(k+kshift)=sum( S_stft(k,ibandpass).' )./sum( S_stft(k,itotal_bandpass).' );

    nf=mod(nw+(k-1)*L_hop,N);

    z_all(nf+1)=z_all(nf+1) + (ones(1,L_epoch)*tv_spec_energ(k+kshift));
    win_summed(nf+1)=win_summed(nf+1)+ones(1,L_epoch);            
end
t_stat=z_all./win_summed;
