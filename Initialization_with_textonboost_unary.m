function Initialization_with_textonboost_unary(db_name,mode)
% Function that Initializes the framework for InriaGraz dataset for PC
clc; close all;
if(~exist('db_name','var') || isempty(db_name))
    db_name='voc2010';
end
if(~exist('mode','var') || isempty(mode))
    mode=1;
end
% Create an object of class jcas.
expJCAS = jcas();
expJCAS.makedb(db_name);
% Default Quickshift superpixels
expJCAS.makesp('Quickshift');
% dsift feature for unary options
expJCAS.makeunary_feats('dsiftext');
% mode for unary and pairwise terms
expJCAS.mode = mode; % 0-U 1-(U+P)
% use precomputed unaries from textonboost
expJCAS.unary.precomputed=1;
expJCAS.unary.precomputed_path=get_dataset_path([db_name,'-texton']);
expJCAS.force_recompute.unary=0;
% kernel svm for bottom-up unary
expJCAS.unary.svm.params.kernel_type = 4; % chi2-rbf kernel
expJCAS.unary.svm.params.rbf = (expJCAS.unary.svm.params.kernel_type == 4);
% determine C value
expJCAS.unary.svm.params.cross = 10 ;
% gamma value for the rbf^2 kernel.
expJCAS.unary.svm.params.gamma = [] ;
% balancing strategy (0 or 1)
expJCAS.unary.svm.params.balance = 0 ;
% return probability value instead of decision value (0 or 1)
expJCAS.unary.svm.params.probability = 1 ;
expJCAS.unary.svm.params.type = 'C';
expJCAS.unary.svm.params.nu = 0.5;
expJCAS.unary.svm.params.C = 1;
% maximum number of features used for clustering (quanization)
expJCAS.unary.dictionary.params.max_features_for_clustering = 1e5;
% number of clusters for bottom up unary quantization
expJCAS.unary.dictionary.params.num_bu_clusters = 400;
% maximum number of histograms per class (used to balance the training)
expJCAS.unary.svm.params.max_hists_per_class_for_training = 1000;
% maximum number of histogram per image
expJCAS.unary.svm.trainingset.params.hists_per_image = 10;
expJCAS.unary.SPneighboorhoodsize=4;
% Slack variable for the Cutting Plane algorithm
% used for the segmentation constraints, this value
% will be divided by the number of training images
expJCAS.optimisation.params.C1 = 1e6;
expJCAS.optimisation.params.eps = 0.01;
expJCAS.optimisation.params.max_iter=1e3;
expJCAS.optimisation.method = 'CP';
expJCAS.optimisation.params.lossFnCP_name = 'hamming';
% SVM_STRUCT_ARGS
expJCAS.optimisation.params.args = '-w 0 -c 1.0';
% Callbacks functions :
expJCAS.optimisation.featureCB = @(parm,x,y) featureFnCP(expJCAS,parm,x,y);
expJCAS.optimisation.lossCB = @(parm,y,yhat) lossFnCP(expJCAS,parm,y,yhat);
expJCAS.optimisation.constraintCB = @(parm,model,x,y) constraintFnCP(expJCAS,parm,model,x,y);
if(expJCAS.mode==1)
    expJCAS.optimisation.params.E_dim = 2;
end
if(expJCAS.mode>=2)
    % -------------------------------------------------------------------------
    % Top Down options
    % -------------------------------------------------------------------------
    expJCAS.maketd_feats('SIFT');
    expJCAS.topdown.dictionary.params.size_dictionary=20;
    expJCAS.topdown.features.params.max_per_image='none';
    expJCAS.topdown.features.params.dimension=128;
end

expJCAS.train;
expJCAS.testing;

fprintf('\n Job done\n');