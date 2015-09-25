%-------------------------------------------------------------------------------
% parameters for the burst detector
%

% John M. O' Toole, University College Cork
% Started: 28-11-2014
%
% last update: Time-stamp: <2015-09-25 08:29:49 (otoolej)>
%-------------------------------------------------------------------------------

%---------------------------------------------------------------------
% 1. feature set 
%---------------------------------------------------------------------
clear FEATURE_SET_FINAL;
FEATURE_SET_FINAL(1).name='envelope';	FEATURE_SET_FINAL(1).params=[0 1 0 0 0];
FEATURE_SET_FINAL(2).name='fd-higuchi';	FEATURE_SET_FINAL(2).params=[];
FEATURE_SET_FINAL(3).name='edo';	FEATURE_SET_FINAL(3).params=[];
FEATURE_SET_FINAL(4).name='if';	        FEATURE_SET_FINAL(4).params=[0 0 0 0 1];
FEATURE_SET_FINAL(5).name='psd_r2';	FEATURE_SET_FINAL(5).params=[0 1 0 0 0];
FEATURE_SET_FINAL(6).name='envelope';	FEATURE_SET_FINAL(6).params=[0 0 0 0 1];
FEATURE_SET_FINAL(7).name='envelope';	FEATURE_SET_FINAL(7).params=[0 0 0 1 0];
FEATURE_SET_FINAL(8).name='spec-power';	FEATURE_SET_FINAL(8).params=[0 0 0 0 1];


%---------------------------------------------------------------------
% 2. parameters for SVM 
%    DO NOT EDIT: indexing corresponds to features above
%---------------------------------------------------------------------
clear lin_svm_params_st;
% linear regression parameters:
lin_svm_params_st.coeff(1)=1.7231474419918471;
lin_svm_params_st.coeff(2)=1.0944716356730551;
lin_svm_params_st.coeff(3)=0.7363681616540538;
lin_svm_params_st.coeff(4)=0.2108197752929180;
lin_svm_params_st.coeff(5)=0.1599842614703928;
lin_svm_params_st.coeff(6)=1.2797596630663119;
lin_svm_params_st.coeff(7)=0.1359372077622752;
lin_svm_params_st.coeff(8)=-0.4639574087961215;
lin_svm_params_st.bias=1.9547538993812108;

% z-score parameters:
lin_svm_params_st.x_shift(1)=2.2236308408108432;
lin_svm_params_st.x_shift(2)=-1.4936074444300351;
lin_svm_params_st.x_shift(3)=-2.3027523468322415;
lin_svm_params_st.x_shift(4)=0.6397162426448688;
lin_svm_params_st.x_shift(5)=0.8560832002385120;
lin_svm_params_st.x_shift(6)=-0.4875872867038523;
lin_svm_params_st.x_shift(7)=-0.1620584673697459;
lin_svm_params_st.x_shift(8)=-5.5624983363377645;
lin_svm_params_st.x_scale(1)=1.1129990354895545;
lin_svm_params_st.x_scale(2)=0.1944487737255839;
lin_svm_params_st.x_scale(3)=1.8773426455696265;
lin_svm_params_st.x_scale(4)=0.0742902276773938;
lin_svm_params_st.x_scale(5)=0.0454168957546715;
lin_svm_params_st.x_scale(6)=0.6524400617931475;
lin_svm_params_st.x_scale(7)=0.8130292037078876;
lin_svm_params_st.x_scale(8)=1.1720334471495857;

% trim off start and end of detector output (as features use
% short-time windowing approach): 
WIN_TRIM=1;   % in seconds


%---------------------------------------------------------------------
% 3. filter details (IIR Butterworth filter)
%---------------------------------------------------------------------
L_FILTER_ORDER=5;    
% band-pass filter in this band    
FBANDS=[0.5 30; 0.5 3; 3 8; 8 15; 15 30]; 



%---------------------------------------------------------------------
% 2. use either static (1) or adaptive (0) threshold:
%---------------------------------------------------------------------
STATIC_THRES=1;


%---------------------------------------------------------------------
% 3. post-processing to force minimum duration IBI and bursts:
%---------------------------------------------------------------------
% set to 0 to turn off: (in seconds)
MIN_IBI_DUR=1.1;
MIN_BURST_DUR=0.9;
