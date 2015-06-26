%-------------------------------------------------------------------------------
% if_: instantaneous frequency (IF) estimate using the central finite 
%      difference method
%
% Syntax: t_stat=if_(x,Fs,freq_band)
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
%     t_stat=if_(x,Fs);
%
%     figure(1); clf; 
%     t=(0:N-1)./Fs;
%     plotyy(t,x,t,t_stat); 
%     xlabel('time (seconds)');

% John M. O' Toole, University College Cork
% Started: 17-06-2015
%
% last update: Time-stamp: <2015-06-25 17:47:46 (otoolej)>
%-------------------------------------------------------------------------------
function t_stat=if_(x,Fs,freq_band)
if(nargin<2), error('need signal and sampling frequency as I/P args.'); end
if(nargin<3 || isempty(freq_band)), freq_band=[0.5 3]; end


N=length(x);

% for short-time analysis:
EPOCH_SIZE=2; 
OVERLAP=75; % in percentage
[L_hop,L_epoch]=epoch_window(OVERLAP,EPOCH_SIZE,'rect',Fs);
N_epochs=floor( (N-L_epoch)/L_hop );
if(N_epochs<1) N_epochs=1; end
nw=0:L_epoch-1;


%---------------------------------------------------------------------
% 1. estimate IF
%---------------------------------------------------------------------
est_IF=estimate_IF(x,Fs);


% bind within frequency bands:
est_IF( est_IF>freq_band(2) )=freq_band(2);
est_IF( est_IF<freq_band(1) )=freq_band(1);            

% normalized between 0 and 1 (need when combining features):
est_IF=(est_IF - freq_band(1))./(freq_band(2) - freq_band(1));

% invert:
est_IF=1-est_IF;
      

%---------------------------------------------------------------------
% 2. break-up into the epochs
%---------------------------------------------------------------------
z_all=zeros(1,N); win_summed=zeros(1,N);
for k=1:N_epochs
    nf=mod(nw+(k-1)*L_hop,N);
    x_epoch=est_IF(nf+1);

    ev=median(x_epoch);

    z_all(nf+1)=z_all(nf+1) + (ones(1,L_epoch)*ev);
    win_summed(nf+1)=win_summed(nf+1)+ones(1,L_epoch);            
end
t_stat=z_all./win_summed;

        





function if_anal=estimate_IF(z,Fs)
%---------------------------------------------------------------------
% estimate IF using central finite difference method and Hilbert 
% transform
%---------------------------------------------------------------------
if(nargin<2 || isempty(Fs)), Fs=1; end


if( isreal(z) ) z=hilbert(z); end
N=length(z);

MF=2*pi;
SCALE=Fs/(4*pi);

if_anal=zeros(N,1);
n=1:N-2;

% Use CFD method:
z_arg_diff=(angle(z(n+2))-angle(z(n)));  
if_anal(n+1)=mod(MF+z_arg_diff, MF).*SCALE;

