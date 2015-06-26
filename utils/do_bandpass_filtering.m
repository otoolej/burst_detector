%-------------------------------------------------------------------------------
% do_bandpass_filtering: zero-phase bandpass filter according to [1]
%
% Syntax: x=do_bandpass_filtering(x,Fs,LP_fc,HP_fc)
%
% Inputs: 
%     x     - signal (size 1 x N)
%     Fs    - sampling frequency (Hz)
%     LP_fc - low-pass cut-off (in Hz)
%     HP_fc - high-pass cut-off (in Hz)
%
% Outputs: 
%     x - filtered signal
%
% Example:
%       N=512; x=randn(1,N); Fs=64;
%       y=do_bandpass_filtering(x,Fs,0.5,10);
%     
%       figure(1); clf; hold all;
%       t=(1:N)./Fs;
%       plot(t,x); plot(t,y,'linewidth',2); 
%       xlabel('time (seconds)');
% 
%
% [1] Palmu, K., Stevenson, N., Wikström, S., Hellström-Westas, L., 
% Vanhatalo, S., & Palva, J. M. (2010). Optimization of an NLEO-based 
% algorithm for automated detection of spontaneous activity transients 
% in early preterm EEG. Physiological measurement, 31(11), N85–93.


% John M. O' Toole, University College Cork
% Started: 18-06-2015
%
% last update: Time-stamp: <2015-06-25 15:11:17 (otoolej)>
%-------------------------------------------------------------------------------
function x=do_bandpass_filtering(x,Fs,HP_fc,LP_fc)
HP_order=1;
LP_order=6;

[b,a]=butter(HP_order,HP_fc/(Fs/2),'high');    
x=filtfilt(b,a,x);

[b,a]=ellip(LP_order,3,50,LP_fc/(Fs/2));
x=filtfilt(b,a,x);


