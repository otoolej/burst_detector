%-------------------------------------------------------------------------------
% env: estimate median of envelope (using Hilbert transform) over a 2-second epoch
%
% Syntax: t_stat=env(x,Fs)
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
%     t_stat=env(x,Fs);
%
%     figure(1); clf; 
%     t=(0:N-1)./Fs;
%     plotyy(t,x,t,t_stat); 
%     xlabel('time (seconds)');

% John M. O' Toole, University College Cork
% Started: 18-06-2015
%
% last update: Time-stamp: <2015-06-25 17:47:32 (otoolej)>
%-------------------------------------------------------------------------------
function t_stat=env(x,Fs)
if(nargin<2), error('need signal and sampling frequency as I/P args.'); end


N=length(x);

% for short-time analysis:
EPOCH_SIZE=1;   % epoch size in seconds
OVERLAP=75;     % in percentage
[L_hop,L_epoch,win_epoch]=epoch_window(OVERLAP,EPOCH_SIZE,'rect',Fs);
N_epochs=floor( (N-L_epoch)/L_hop );
if(N_epochs<1) N_epochs=1; end
nw=0:L_epoch-1;



%---------------------------------------------------------------------
% 2. compute the envelope for the whole signal
%---------------------------------------------------------------------
x=abs( hilbert(x) );

%---------------------------------------------------------------------
% 3. break-up into the epochs
%---------------------------------------------------------------------
z_all=zeros(1,N); win_summed=zeros(1,N);
kshift=floor( L_epoch/(2*L_hop) );
N_epochs_plus=N_epochs+kshift;
ev=zeros(1,N_epochs_plus);
for k=1:N_epochs
    nf=mod(nw+(k-1)*L_hop,N);
    x_epoch=x(nf+1);

    ev(k+kshift)=median(x_epoch);

    z_all(nf+1)=z_all(nf+1) + (ones(1,L_epoch)*ev(k+kshift));
    win_summed(nf+1)=win_summed(nf+1)+ones(1,L_epoch);            
end
t_stat=z_all./win_summed;        
