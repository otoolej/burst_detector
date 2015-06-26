%-------------------------------------------------------------------------------
% gen_features: generate feature set for signal x
%
% Syntax: [t_stat]=gen_features(x,Fs,feat_set)
%
% Inputs: 
%     x        - 1-channel of EEG data (size 1 x N)
%     Fs       - sampling frequency (in Hz, must be ≥64 Hz)
%     feat_set - feature set ('FEATURE_SET_FINAL' in bd_parameters.m, size 1 x P)
%
% Outputs: 
%     t_stat   - features estimated from input signal x (size P x N)
%
% Example:
%     N=5000; Fs=64; 
%     x=gen_impulsive_noise(N).*10;
%
%     t_stat=gen_features(x,Fs);
% 
%     figure(1); clf; 
%     t=(0:N-1)./Fs;
%     hax(1)=subplot(211);
%     plot(t,t_stat'); ylim([-5,5]);
%     hax(2)=subplot(212); 
%     plot(t,x);
%     linkaxes(hax,'x');
%     xlabel('time (seconds)');


% John M. O' Toole, University College Cork
% Started: 17-06-2015
%
% last update: Time-stamp: <2015-06-26 10:06:21 (otoolej)>
%-------------------------------------------------------------------------------
function [t_stat]=gen_features(x,Fs,feat_set)
if(nargin<2), error('input arguments should include x and Fs.'); end
if(nargin<3 || isempty(feat_set)), feat_set=[]; end


N=length(x);


%---------------------------------------------------------------------
% 0. set parameters
%---------------------------------------------------------------------
bd_parameters;

% do log-transform for these features :
FEAT_LOG_TRANSFORM={'edo','envelope','spec-power' };


% feature set
if(isempty(feat_set))
    feat_set=FEATURE_SET_FINAL;
end
N_feats=length(feat_set);

t_stat=NaN(N_feats,N);

% for missing data, insert 0's when generating the features
% and then, afterwards, replace with NaNs.
inans=find(isnan(x));
x(inans)=0;


%---------------------------------------------------------------------
% 1. do band-pass filtering first
%---------------------------------------------------------------------
filter_bands={[0 1 0 0 0], [0 0 1 0 0], [0 0 0 1 0], [0 0 0 0 1]};
x_filt=[];
for n=1:length(filter_bands)
    if( any(cellfun(@(x) isequal(filter_bands{n},x), {feat_set.params})) )
        x_filt{n}=filt_b(x,Fs,FBANDS(n+1,2),FBANDS(n+1,1),L_FILTER_ORDER);
    else
        x_filt{n}=[];
    end
end




% 1. iterate over all features:
for n=1:N_feats
    
    y=[];
    if(~isempty(feat_set(n).params))
        ifilt=find(cellfun(@(x) isequal(FEATURE_SET_FINAL(n).params,x), filter_bands));
        y=x_filt{ifilt};
    end
    
    %---------------------------------------------------------------------
    % 2. calculate features
    %---------------------------------------------------------------------
    switch feat_set(n).name
      case {'spec-power'}
        %---------------------------------------------------------------------
        % relative spectral power
        %---------------------------------------------------------------------
        p=find(feat_set(n).params);
        t_stat(n,:)=rel_spec_power(x,Fs,FBANDS(p,:),FBANDS(1,:));
        
      case 'psd_r2'
        %---------------------------------------------------------------------
        % fit of line to log-log PSD
        %---------------------------------------------------------------------
        p=find(feat_set(n).params);        
        t_stat(n,:)=psd_r2(y,Fs,FBANDS(p,:));
        
      case 'if'
        %---------------------------------------------------------------------
        % instantaneous frequency
        %---------------------------------------------------------------------
        p=find(feat_set(n).params);
        t_stat(n,:)=if_(y,Fs,FBANDS(p,:));
        
      case 'envelope'
        %---------------------------------------------------------------------
        % envelope (Hilbert transform)
        %---------------------------------------------------------------------
        t_stat(n,:)=env(y,Fs);

      case 'edo'
        %---------------------------------------------------------------------
        % envelope--derivative operator
        %---------------------------------------------------------------------
        t_stat(n,:)=edo(x,Fs);
        
      case 'fd-higuchi'
        %---------------------------------------------------------------------
        % fractal dimension estimate (Higuchi method)
        %---------------------------------------------------------------------
        t_stat(n,:)=fd(x,Fs);
        
        
      otherwise
        error(['unknown feature: ' feat_set(n).name]);
    end

    
    if(any(ismember(FEAT_LOG_TRANSFORM,feat_set(n).name)))
        t_stat(n,:)=log( t_stat(n,:) + eps );
    end
    
    
end

    
% for missing data:
t_stat(:,inans)=NaN;






function y=filt_b(x,Fs,F3db_lowpass,F3db_highpass,order)
%---------------------------------------------------------------------
% IIR zero-phase filter (Butterworth)
%---------------------------------------------------------------------
if(nargin<2 || isempty(Fs)), Fs=1; end
if(nargin<3 || isempty(F3db_lowpass) || F3db_lowpass==0), F3db_lowpass=[]; end
if(nargin<4 || isempty(F3db_highpass) || F3db_highpass==0), F3db_highpass=[]; end
if(nargin<5 || isempty(order)), order=3; end


if(isempty(F3db_highpass))
    [b,a]=butter(order,F3db_lowpass/(Fs/2),'low');    
    
elseif(isempty(F3db_lowpass))
    [b,a]=butter(order,F3db_highpass/(Fs/2),'high');        
    
else
    y=filt_b(x,Fs,F3db_lowpass,[],order);    
    y=filt_b(y,Fs,[],F3db_highpass,order);        
    return;    
end


y=filtfilt(b,a,x);











