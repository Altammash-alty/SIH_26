%% RUN_BAYESOPT_CALIBRATION.M
% Calibrates RetinaAI lesion detection parameters using bayesopt on the TUNE split.
% Adheres strictly to the Part 5 specification.

function run_bayesopt_calibration(maxIter, tuneSampleSize)
    if nargin < 1 || isempty(maxIter)
        maxIter = 40;
    end
    if nargin < 2 || isempty(tuneSampleSize)
        tuneSampleSize = 40; % Representative stratified subset of TUNE split for speed & coverage
    end

    fprintf('\n=================================================================\n');
    fprintf(' PART 5: BAYESIAN PARAMETER CALIBRATION (bayesopt)\n');
    fprintf(' Iteration Budget: %d\n', maxIter);
    fprintf(' TUNE Subset Size: %d images (Stratified)\n', tuneSampleSize);
    fprintf('=================================================================\n\n');

    % 1. Load TUNE split from results/splits.mat
    splitsPath = fullfile('results', 'splits.mat');
    if ~exist(splitsPath, 'file')
        splitsPath = fullfile(fileparts(mfilename('fullpath')), '..', 'results', 'splits.mat');
    end
    if ~exist(splitsPath, 'file')
        error('run_bayesopt_calibration:NoSplits', 'results/splits.mat not found.');
    end
    s = load(splitsPath);
    tuneTbl = s.trainTbl(s.tuneIdxs, :);

    % Stratified subset from TUNE split
    rng(2026);
    selectedTuneIdxs = [];
    perGrade = round(tuneSampleSize / 5);
    for g = 0:4
        gIdxs = find(tuneTbl.DRGrade == g);
        takeN = min(numel(gIdxs), perGrade);
        perm = randperm(numel(gIdxs), takeN);
        selectedTuneIdxs = [selectedTuneIdxs; gIdxs(perm)]; %#ok<AGROW>
    end
    tuneSubset = tuneTbl(selectedTuneIdxs, :);

    tuneImages = repmat(struct('imgPath', '', 'drGrade', 0), height(tuneSubset), 1);
    for k = 1:height(tuneSubset)
        tuneImages(k).imgPath = tuneSubset.ImagePath{k};
        tuneImages(k).drGrade = tuneSubset.DRGrade(k);
    end
    tuneGrades = tuneSubset.DRGrade;

    % 2. Search Space (optimizableVariable) per Part 5
    vars = [
        optimizableVariable('darkSensitivity',     [1.5, 5.0],   'Type', 'real')
        optimizableVariable('brightSensitivity',   [1.5, 5.0],   'Type', 'real')
        optimizableVariable('marginFactor',        [1.0, 2.0],   'Type', 'real')
        optimizableVariable('darkMaxSize',         [500, 5000],  'Type', 'integer')
        optimizableVariable('brightMaxSize',       [1000, 15000],'Type', 'integer')
        optimizableVariable('vesselBufferRadius',  [1, 6],       'Type', 'integer')
        optimizableVariable('solidityCutoff',      [0.50, 0.90], 'Type', 'real')
        optimizableVariable('localContrastMargin', [0.02, 0.15], 'Type', 'real')
    ];

    % Objective function wrapper
    objFcn = @(params) drPipelineObjective(params, tuneImages, tuneGrades);

    % 3. Run bayesopt
    results = bayesopt(objFcn, vars, ...
        'MaxObjectiveEvaluations', maxIter, ...
        'AcquisitionFunctionName', 'expected-improvement-plus', ...
        'IsObjectiveDeterministic', true, ...
        'UseParallel', false, ...
        'Verbose', 1, ...
        'PlotFcn', {});

    % Save trace to results/bayesopt_trace.csv
    traceTbl = results.UserDataTrace;
    traceData = results.XTrace;
    traceData.Objective = results.ObjectiveTrace;
    writetable(traceData, fullfile('results', 'bayesopt_trace.csv'));
    fprintf('\nBayesopt trace saved to results/bayesopt_trace.csv\n');

    % 4. Bound checking
    fprintf('\n--- Checking Parameter Boundaries ---\n');
    bestP = results.XAtMinObjective;
    boundLow  = [1.5, 1.5, 1.0, 500, 1000, 1, 0.50, 0.02];
    boundHigh = [5.0, 5.0, 2.0, 5000, 15000, 6, 0.90, 0.15];
    pNames = {'darkSensitivity', 'brightSensitivity', 'marginFactor', ...
              'darkMaxSize', 'brightMaxSize', 'vesselBufferRadius', ...
              'solidityCutoff', 'localContrastMargin'};

    for i = 1:numel(pNames)
        val = double(bestP.(pNames{i}));
        tol = 0.05 * (boundHigh(i) - boundLow(i));
        atMin = (val - boundLow(i)) <= tol;
        atMax = (boundHigh(i) - val) <= tol;
        status = 'INTERIOR';
        if atMin, status = 'AT LOWER BOUND'; end
        if atMax, status = 'AT UPPER BOUND'; end
        fprintf('  %-20s: %8.3f [%5.2f, %5.2f] -> %s\n', pNames{i}, val, boundLow(i), boundHigh(i), status);
    end

    % 5. Rank top 5 parameter sets by TUNE loss
    [sortedLosses, sortIdx] = sort(results.ObjectiveTrace, 'ascend');
    top5Idx = sortIdx(1:min(5, numel(sortIdx)));
    top5Params = results.XTrace(top5Idx, :);
    fprintf('\n--- Evaluating Top %d Candidates on SELECTION Split ---\n', height(top5Params));

    selectTbl = s.trainTbl(s.selectIdxs, :);
    winnerLoss = Inf;
    winnerIdx = 1;
    winnerReport = [];
    winnerStats = [];
    winnerCfg = [];

    for c = 1:height(top5Params)
        cand = top5Params(c, :);
        fprintf('\nCandidate %d (TUNE Loss = %.4f):\n', c, sortedLosses(c));
        disp(cand);

        cfgCand = config();
        cfgCand.segment.lesion.darkSensitivity        = double(cand.darkSensitivity);
        cfgCand.segment.lesion.brightSensitivity      = double(cand.brightSensitivity);
        cfgCand.segment.lesion.marginFactor           = double(cand.marginFactor);
        cfgCand.segment.lesion.darkMaxSize            = round(double(cand.darkMaxSize));
        cfgCand.segment.lesion.brightMaxSize          = round(double(cand.brightMaxSize));
        cfgCand.segment.lesion.vesselBufferRadius     = round(double(cand.vesselBufferRadius));
        cfgCand.segment.lesion.solidityCutoff         = double(cand.solidityCutoff);
        cfgCand.segment.lesion.darkLocalMinContrast   = double(cand.localContrastMargin);
        cfgCand.segment.lesion.brightLocalMinContrast = double(cand.localContrastMargin);
        cfgCand.debug = false;

        outCsv = fullfile('results', sprintf('candidate_%d_selection_report.csv', c));
        [repTbl, cm, acc, sens, spec, g0Stats] = validate_against_labels(cfgCand, 'selection', outCsv);

        normG0 = min(1.0, (g0Stats.avgDark + g0Stats.avgBright) / 50.0);
        selectionLoss = 0.50 * (1.0 - spec) + 0.30 * (1.0 - sens) + 0.20 * normG0;
        if sens < 0.90
            selectionLoss = selectionLoss + 10.0 * (0.90 - sens);
        end

        fprintf('Candidate %d SELECTION Loss = %.4f (Spec=%.1f%%, Sens=%.1f%%, ExactAcc=%.1f%%, G0Dark=%.1f, G0Bright=%.1f)\n', ...
            c, selectionLoss, spec*100, sens*100, acc*100, g0Stats.avgDark, g0Stats.avgBright);

        if selectionLoss < winnerLoss
            winnerLoss = selectionLoss;
            winnerIdx = c;
            winnerReport = repTbl;
            winnerStats = struct('cm', cm, 'acc', acc, 'sens', sens, 'spec', spec, 'g0', g0Stats, 'loss', selectionLoss);
            winnerCfg = cfgCand;
        end
    end

    fprintf('\n=================================================================\n');
    fprintf(' WINNING PARAMETER SET: Candidate %d (SELECTION Loss = %.4f)\n', winnerIdx, winnerLoss);
    winningParams = top5Params(winnerIdx, :);
    disp(winningParams);
    fprintf('=================================================================\n');

    % 6. Lock best parameters (Part 6)
    if ~exist('params', 'dir'), mkdir('params'); end
    save(fullfile('params', 'best_params.mat'), 'winningParams', 'winnerStats', 'winnerLoss');

    % Also save as clean JSON
    jsonStruct = struct();
    for p = 1:numel(pNames)
        jsonStruct.(pNames{p}) = double(winningParams.(pNames{p}));
    end
    jsonStruct.calibration_date = char(datetime('now'));
    jsonStruct.dataset = 'IDRiD';
    jsonStruct.split_seed = 2026;
    jsonStruct.tune_sample_size = tuneSampleSize;
    jsonStruct.bayesopt_iterations = maxIter;
    jsonStruct.selection_loss = winnerLoss;
    jsonStruct.selection_sensitivity = winnerStats.sens;
    jsonStruct.selection_specificity = winnerStats.spec;
    jsonStruct.selection_accuracy = winnerStats.acc;

    jsonText = jsonencode(jsonStruct, 'PrettyPrint', true);
    fid = fopen(fullfile('params', 'best_params.json'), 'w');
    fwrite(fid, jsonText);
    fclose(fid);
    fprintf('Saved params/best_params.mat and params/best_params.json\n');
end
