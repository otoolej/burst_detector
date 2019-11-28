%-------------------------------------------------------------------------------
% edo: Envelope--derivative operator (a frequency-weighted energy measure). 
%      Assumes sampling frequency is 256 Hz, if not then resamples.
%
% Defined as the envelope (using Hilbert transform) of the derivative of signal (using
% central-finite difference), see [1] for details.
%
% Including band-pass filtering on the signal (0.5--10 Hz) and a moving-average smoothing
% (window of 1 second) of the output to keep similarity to the NLEO in [2]
%
%
% Syntax: t_stat=edo(x,Fs)
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
%     t_stat=edo(x,Fs);
%
%     figure(1); clf; 
%     t=(0:N-1)./Fs;
%     plotyy(t,x,t,t_stat); 
%     xlabel('time (seconds)');
%
%
% [1] J.M. O' Toole and N.J. Stevenson, “Assessing instantaneous energy in the EEG: a
% non-negative, frequency-weighted energy operator”, In Engineering in Medicine and
% Biology Society (EMBC), 2014 36th Annual International Conference of the IEEE,
% pp. 3288-3291. IEEE, 2014.
%
% [2] Palmu, K., Stevenson, N., Wikström, S., Hellström-Westas, L., Vanhatalo, S., &
% Palva, J. M. (2010). “Optimization of an NLEO-based algorithm for automated detection of
% spontaneous activity transients in early preterm EEG”. Physiological measurement, 31(11),
% N85–93.


% John M. O' Toole, University College Cork
% Started: 18-06-2015
%
% last update: Time-stamp: <2019-11-28 17:19:08 (otoolej)>
%-------------------------------------------------------------------------------
function t_stat=edo(x,Fs)
if(nargin<2), error('need signal and sampling frequency as I/P args.'); end


%---------------------------------------------------------------------
% 0. re-sample to Fs=256 as EDO amplitude is proportional to 
%    sampling frequency
%---------------------------------------------------------------------
N_x = length(x);
Fs_new=256;
Fs_orig=[];
if(Fs~=Fs_new);
    Fs_orig=Fs;
    x=resample(x,Fs_new,Fs_orig);
    Fs=Fs_new;
end



%---------------------------------------------------------------------
% 1. bandpass filter the signal 
%---------------------------------------------------------------------
LP_fc=0.5;  HP_fc=10; 
x=do_bandpass_filtering(x,Fs,LP_fc,HP_fc);


%---------------------------------------------------------------------
% 2. envelope--derivative operator:
%---------------------------------------------------------------------
Nstart=length(x);
if(rem(length(x),2)~=0), x=[x 0]; end
N=length(x); Nh=ceil(N/2);

% a. hilbert transform:
k=0:N-1;
H=-j.*sign(Nh-k).*sign(k);
h=ifft( fft(x).*H );
% to keep octave happy:
h=real(h);

% b. magnitude squared of derivative (using CFD):
nl=2:N-1;
xx=zeros(1,N);

xx(nl)=(x(nl+1).^2 + x(nl-1).^2 + h(nl+1).^2 + h(nl-1).^2)./4 - ...
       (x(nl+1).*x(nl-1) + h(nl+1).*h(nl-1))./2;

x_env_der=xx(3:end-2);
x_env_der=[0 0 xx(3:end-2) 0 0];


x_env_der=x_env_der(1:Nstart);


%---------------------------------------------------------------------
% 3. smooth with window
%---------------------------------------------------------------------
WIN_LENGTH=1*Fs; 
x_filt=moving_avg_fil(x_env_der,floor(WIN_LENGTH));


% zero pad the end:
L=length(x_filt);
x_env_der(1:L)=x_filt;
x_env_der((L+1):end)=0;


%---------------------------------------------------------------------
% 4. downsample
%---------------------------------------------------------------------
if(~isempty(Fs_orig))
    x_env_der=resample(x_env_der,Fs_orig,Fs_new);
    % resampling may introduce very small negative values:
    x_env_der(x_env_der<0)=0;
end

if(length(x_env_der) ~= N_x)
    x_env_der = x_env_der(1:N_x);
end

t_stat=x_env_der;



function y=moving_avg_fil(x,win_length)
%---------------------------------------------------------------------
% moving average filter
%---------------------------------------------------------------------
N=length(x);
y=zeros(N,1);
Lh=floor(win_length/2);

y_tmp=filter(ones(1,win_length),win_length,x);

n=(Lh+1):(N-Lh);
y(n)=y_tmp(n);
