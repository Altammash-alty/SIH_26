% Reproducible TUNE/SELECTION referable-DR analysis. Never loads test/.
% Run from project root: matlab -batch "run('run_referable_analysis.m')"
clearvars -except ans; clc;
addpath(pwd);
rng(2026,'twister');
outDir = fullfile(pwd,'results'); if ~exist(outDir,'dir'), mkdir(outDir); end
s = load(fullfile(outDir,'splits.mat'),'trainTbl','tuneIdxs','selectIdxs');
assert(numel(s.tuneIdxs)==311 && numel(s.selectIdxs)==102,'Unexpected fixed split sizes.');
cfg = config();
splitNames = {'TUNE','SELECTION'}; splitTables = {s.trainTbl(s.tuneIdxs,:),s.trainTbl(s.selectIdxs,:)};
allFeatures = cell(2,1);
for si=1:2
    T=splitTables{si}; n=height(T);
    dark=zeros(n,1); bright=dark; darkArea=dark; brightArea=dark;
    qd=zeros(n,4); qb=zeros(n,4); severe=dark; vd=dark; vt=dark; cdr=dark; qualityScore=dark;
    probs=zeros(n,5); nnGrade=zeros(n,1); ruleGrade=zeros(n,1); gatedGrade=zeros(n,1); qpass=false(n,1);
    for k=1:n
        raw=imread(T.ImagePath{k}); md=max(size(raw,1),size(raw,2)); if md>768, raw=imresize(raw,768/md); end
        [qpass(k),~,qm]=quality.assessQuality(raw,cfg);
        if ~isfield(qm,'mask')||isempty(qm.mask), qm.mask=rgb2gray(raw)>10; end
        [enh,~]=preprocess.enhanceImage(raw,cfg);
        seg=segment.segmentAll(enh,qm.mask,cfg);
        [g,~,~,~,~,~,~,det]=classify.gradeDR(enh,seg,cfg);
        f=det.features; dark(k)=f.darkCountTotal; bright(k)=f.brightCountTotal;
        darkArea(k)=seg.lesions.darkAreaTotalPixels; brightArea(k)=seg.lesions.brightAreaTotalPixels;
        qd(k,:)=f.quadrantDark; qb(k,:)=f.quadrantBright; severe(k)=f.quadsWithSevereHemo;
        vd(k)=f.vesselDensity; vt(k)=f.vesselTortuosity; cdr(k)=f.cupToDiscRatio;
        qualityScore(k)=qm.overallScore; probs(k,:)=det.nnProbs; nnGrade(k)=det.nnGrade;
        gatedGrade(k)=g;
        % The ungated rule output is recovered by re-running only classification on cached segmentation.
        noGate=cfg; noGate.classify.grade0NoiseCeiling=-Inf;
        [ruleGrade(k),~,~,~,~,~,~,~]=classify.gradeDR(enh,seg,noGate);
        if mod(k,10)==0||k==n, fprintf('%s %d/%d\n',splitNames{si},k,n); end
    end
    % Grade 0 gate collapses eligible grades to zero; the no-gate value is separately retained.
    labels=T.DRGrade>=2;
    tbl=table(T.ImageName,T.DRGrade,labels,dark,bright,qd(:,1),qd(:,2),qd(:,3),qd(:,4), ...
        qb(:,1),qb(:,2),qb(:,3),qb(:,4),severe,darkArea,brightArea,vd,vt,cdr,qualityScore,qpass,nnGrade, ...
        probs(:,1),probs(:,2),probs(:,3),probs(:,4),probs(:,5),ruleGrade,gatedGrade, ...
        'VariableNames',{'ImageName','Grade','Referable','darkCount','brightCount','darkQ1','darkQ2','darkQ3','darkQ4', ...
        'brightQ1','brightQ2','brightQ3','brightQ4','quadsSevere','darkArea','brightArea','vesselDensity','vesselTortuosity', ...
        'cupToDiscRatio','qualityScore','qualityPass','nnGrade','PGrade0','PGrade1','PGrade2','PGrade3','PGrade4','gradeNoGate','gradeGate'});
    allFeatures{si}=tbl;
    save(fullfile(outDir,['features_' lower(splitNames{si}) '.mat']),'tbl','cfg','-v7.3');
end
% Step 0 and operating-point analysis, all fixed thresholds learned on TUNE.
S=allFeatures{2}; Y=S.Referable;
scores={S.PGrade2+S.PGrade3+S.PGrade4, S.darkCount+S.brightCount, ...
    0.5*(S.PGrade2+S.PGrade3+S.PGrade4)+0.5*rescale(S.darkCount+S.brightCount)};
T=allFeatures{1}; ty=T.Referable;
tuneScores={T.PGrade2+T.PGrade3+T.PGrade4,T.darkCount+T.brightCount, ...
    0.5*(T.PGrade2+T.PGrade3+T.PGrade4)+0.5*rescale(T.darkCount+T.brightCount)};
names={'networkReferableProbability','lesionCount','networkLesionBlend'}; rows=cell(3,1);
for j=1:3
    [~,~,~,auc]=perfcurve(ty,tuneScores{j},true);
    cand=unique(tuneScores{j}); cand=[-Inf;cand(:);Inf]; best=-Inf; cut=Inf;
    for c=cand'
        m=evalReferable(tuneScores{j},ty,c);
        if m.sensitivity>=0.92 && m.specificity>best, best=m.specificity; cut=c; end
    end
    [~,~,~,aucSel]=perfcurve(Y,scores{j},true);
    m=evalReferable(scores{j},Y,cut);
    rows{j}=table(string(names{j}),cut,auc,aucSel,m.n,m.sensitivity,m.specificity,m.sensitivityCI(1),m.sensitivityCI(2), ...
        m.specificityCI(1),m.specificityCI(2),m.TP,m.FN,m.TN,m.FP,'VariableNames', ...
        {'Candidate','TuneCutoff','TuneAUC','SelectionAUC','N','Sensitivity','Specificity','SensLow','SensHigh','SpecLow','SpecHigh','TP','FN','TN','FP'});
end
step2=vertcat(rows{:}); writetable(step2,fullfile(outDir,'referable_step2.csv'));
fprintf('Feature cache and Step 2 operating points saved in results/.\n');
