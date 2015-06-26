%-------------------------------------------------------------------------------
% gen_impulsive_noise: impulsive noise model, inspired from [1] 
%
% Syntax: x=gen_impulsive_noise(N)
%
% Inputs: 
%     N - length of signal to generate
%
% Outputs: 
%     x - impulsive noise signal (size 1 x N)
%
% Example:
%     
%
% [1] Saeed V. Vaseghi, Advanced Digital Signal Processing and Noise Reduction, Second
% Edition, John Wiley & Sons Ltd, 2000.


% John M. O' Toole, University College Cork
% Started: 25-06-2015
%
% last update: Time-stamp: <2015-06-25 15:49:29 (otoolej)>
%-------------------------------------------------------------------------------
function x=gen_impulsive_noise(N)

x=zeros(1,N);

% a. impulse location:
x(unique(randi(N,1,floor(N/20))))=1;

% b. amplitude modulation on the impulses:
x=x.*randn(1,N);

% c. add some white Gaussian noise and low-pass filter:
x=x + randn(1,N)./20;
x=conv(x,hamming(21),'same');

% e. again, add white Gaussian noise
x=x+randn(1,N)./5;
