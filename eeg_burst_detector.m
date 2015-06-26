%-------------------------------------------------------------------------------
% eeg_burst_detector: Detect bursts for one (bipolar) channel of EEG
%
% Syntax: [burst_anno,t_stat]=eeg_burst_detector(eeg_data,Fs)
%
% Inputs: 
%     eeg_data   - 1-channel of EEG data (size 1 x N)
%     Fs         - sampling frequency (in Hz, must be ≥64 Hz)
%
% Outputs: 
%     burst_anno - annotation of bursts, with 1 for burst, 0 otherwise (size 1 x N)
%     svm_out    - distance function from linear regression equation (size 1 x N)
%     t_stat     - P features (from bd_parameters.m, size P x N)
%
% Example:
%     N=10000; 
%     x=gen_impulsive_noise(N).*10;
%     Fs=64; 
%
%     [burst_anno,svm_out]=eeg_burst_detector(x,Fs);
% 
%     figure(1); clf; 
%     t=(0:N-1)./Fs;
%     hax(1)=subplot(211); hold all;
%     plot(t,burst_anno); plot(t,svm_out);
%     hax(2)=subplot(212); 
%     plot(t,x);
%     linkaxes(hax,'x');
%     xlabel('time (seconds)');

% John M. O' Toole, University College Cork
% Started: 28-11-2014
%
% last update: Time-stamp: <2015-06-26 10:05:03 (otoolej)>
%-------------------------------------------------------------------------------
function [burst_anno,svm_out,t_stat]=eeg_burst_detector(eeg_data,Fs)
if(nargin<2 || isempty(Fs)), Fs=64; end


if(Fs<64)
    error('sampling frequency should be 64 Hz or greater.'); 
end


% load parameters:
bd_parameters;

if(min(size(eeg_data))>1)
    error('for only 1-channel of EEG');
end
eeg_data=eeg_data(:)';
N=length(eeg_data);

%---------------------------------------------------------------------
% 1. generate features
%---------------------------------------------------------------------
t_stat=gen_features(eeg_data,Fs,FEATURE_SET_FINAL);
N_feats=length(FEATURE_SET_FINAL);

%---------------------------------------------------------------------
% 2. linear SVM
%---------------------------------------------------------------------
% a. shift and scale data:
x=bsxfun(@minus,t_stat,[lin_svm_params_st.x_shift]');
x=bsxfun(@times,x,(1./[lin_svm_params_st.x_scale])');

% b. y ~ b + ∑ᵢ wᵢ xᵢ
y=lin_svm_params_st.bias;
for n=1:N_feats
    y=y+lin_svm_params_st.coeff(n).*x(n,:);
end


% c. trim off start and end times:
if(~isempty(WIN_TRIM))
    WIN_TRIM=ceil(WIN_TRIM*Fs); 
    y(1:WIN_TRIM)=NaN;
    N=length(y);
    y(N:-1:(N-WIN_TRIM+1))=NaN;
end


%---------------------------------------------------------------------
% 3. threshold
%---------------------------------------------------------------------
burst_anno=y; svm_out=y;
if(STATIC_THRES)
    burst_anno(burst_anno>=0)=1;
    burst_anno(burst_anno~=1)=0;
else
    ad_thres=nan_mean(y);
    burst_anno=zeros(size(y));
    burst_anno(y>ad_thres)=1;
end



%---------------------------------------------------------------------
% 4. post-processing
%---------------------------------------------------------------------
if(MIN_IBI_DUR>0)
    burst_anno=min_ibi_burst(burst_anno,0,MIN_IBI_DUR*Fs);
end
if(MIN_BURST_DUR>0)
    burst_anno=min_ibi_burst(burst_anno,1,MIN_BURST_DUR*Fs);    
end






function sat_score=min_ibi_burst(sat_score,burst_or_ibi,min_duration)
%---------------------------------------------------------------------
% enforce minimum burst of IBI duration
%---------------------------------------------------------------------
N=length(sat_score);


% a. minimum burst duration:
if(burst_or_ibi==1)
    [ilengths,istart,iend]=len_zeros(sat_score,1);
    iconsider=find(ilengths<min_duration);
    for p=1:length(iconsider)
        in=istart( iconsider(p) ):iend( iconsider(p) );
        sat_score(in)=0;
    end
    sat_score=sat_score(1:N);


% b. minimum IBI:
elseif(burst_or_ibi==0)
    [ilengths,istart,iend]=len_zeros(sat_score,0);
    iconsider=find(ilengths<min_duration);
    for p=1:length(iconsider)
        in=istart( iconsider(p) ):iend( iconsider(p) );
        sat_score(in)=1;
    end
    sat_score=sat_score(1:N);
end




function [lens,istart,iend]=len_zeros(x,const)
%---------------------------------------------------------------------
% length of continuous runs of zeros
%---------------------------------------------------------------------
if(nargin<2 || isempty(const)), const=0; end

DBplot=0;

x=x(:).';

if( ~all(ismember(sort(unique(x(~isnan(x)))),[0 1])) || ...
    ~ismember(const,[0 1]) )
    warning('must be binary signal');
    return;
end
if(const==1)
    y=x;
    y(~isnan(x))=~x(~isnan(x));
else
    y=x;
end

% find run of zeros:
iedge=diff([0 y==0 0]);
istart=find(iedge==1);
iend=find(iedge==-1)-1;
lens=[iend-istart];



function x_mean=nan_mean(x)
%---------------------------------------------------------------------
% implement 'nanmean.m'
%---------------------------------------------------------------------
inans=isnan(x);
x(inans)=0;

N=sum(~inans);
N(N==0)=NaN;
x_mean=sum(x)./N;

