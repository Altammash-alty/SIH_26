%% APPLY_OPTIMISED_PARAMS.M
% Quick-apply helper: manually sets the bayesopt-candidate threshold values
% and reruns the full validate_against_labels harness to confirm improvement.
%
% PURPOSE:
%   Lets you test a specific parameter set WITHOUT needing to run the full
%   bayesopt sweep first. Useful for:
%     a) Testing hand-tuned values before committing bayesopt budget.
%     b) Applying the output of config_optimised.m to the full training set.
%     c) Verifying that updated parameters produce coherent before/after numbers.
%
% USAGE (from MATLAB command window):
%   apply_optimised_params                   % uses the default candidate values below
%   apply_optimised_params('results/bayesopt/config_optimised.m')  % from bayesopt output
%
% Author: DR Screening Pipeline MVP (SIH-26)
% Date:   2026-09-27

function apply_optimised_params(configOptPath)

    fprintf('\n');
    fprintf('================================================================\n');
    fprintf(' APPLY OPTIMISED PARAMETERS — Full validation run              \n');
    fprintf('================================================================\n\n');

    cfg = config();

    % ── Load from bayesopt output file if provided ───────────────────────
    if nargin >= 1 && ~isempty(configOptPath) && exist(configOptPath, 'file')
        fprintf('[INFO] Loading parameters from: %s\n\n', configOptPath);
        run(configOptPath);  % executes the cfg.segment.lesion.* assignments
    else
        % ── Default "Round 3" hand-tuned candidate values ─────────────────
        % These are conservative starting values based on diagnostic sweep:
        %   Grade-0 signal analysis showed bg_std ≈ 2.78 → 3σ gives thresh=12
        %   Local contrast p90 = 0.055 → gate at 0.10 removes 75% of FPs
        %   Minimum size 10px removes sub-resolution noise
        fprintf('[INFO] No config file provided. Using hand-tuned candidate values:\n\n');

        cfg.segment.lesion.darkSensitivity        = 3.5;   % Tighter than 3.0
        cfg.segment.lesion.brightSensitivity      = 3.5;
        cfg.segment.lesion.darkLocalMinContrast   = 0.10;  % Raised from 0.04
        cfg.segment.lesion.brightLocalMinContrast = 0.10;  % Raised from 0.05
        cfg.segment.lesion.darkMinSize            = 10;    % Raised from 3 px
        cfg.segment.lesion.darkMaxSize            = 2500;
        cfg.segment.lesion.brightMinSize          = 8;     % Raised from 3 px
        cfg.segment.lesion.brightMaxSize          = 8000;
        cfg.segment.vessel.closingRadius          = 2;     % Slightly larger bridge
    end

    % Print active parameters for audit trail
    fprintf('  darkSensitivity        = %.4f\n', cfg.segment.lesion.darkSensitivity);
    fprintf('  brightSensitivity      = %.4f\n', cfg.segment.lesion.brightSensitivity);
    fprintf('  darkLocalMinContrast   = %.4f\n', cfg.segment.lesion.darkLocalMinContrast);
    fprintf('  brightLocalMinContrast = %.4f\n', cfg.segment.lesion.brightLocalMinContrast);
    fprintf('  darkMinSize            = %d px\n', cfg.segment.lesion.darkMinSize);
    fprintf('  darkMaxSize            = %d px\n', cfg.segment.lesion.darkMaxSize);
    fprintf('  brightMinSize          = %d px\n', cfg.segment.lesion.brightMinSize);
    fprintf('  brightMaxSize          = %d px\n', cfg.segment.lesion.brightMaxSize);
    fprintf('  vessel.closingRadius   = %d px\n', cfg.segment.vessel.closingRadius);
    fprintf('\n');

    % ── Run validation on 10 samples per grade (50 total) ────────────────
    fprintf('[VALIDATION] Running full 50-image stratified validation harness...\n\n');
    [reportTbl, confMat, acc, sens, spec, g0Stats] = validate_against_labels(cfg, 10);

    % ── Write a round-specific CSV for before/after comparison ───────────
    outCsv = 'validation_round3_hand_tuned.csv';
    writetable(reportTbl, outCsv);
    fprintf('\n  Round 3 report saved: %s\n', outCsv);

    % ── Print the Before vs After table for this run ─────────────────────
    fprintf('\n');
    fprintf('================================================================\n');
    fprintf(' BEFORE vs AFTER COMPARISON (vs. last known result)\n');
    fprintf('================================================================\n');
    fprintf('  Metric                     | Round 2 (baseline)  | Round 3 (this run)\n');
    fprintf('  ---------------------------+---------------------+-------------------\n');
    fprintf('  Exact-Grade Accuracy       | 20.0%%               | %.1f%%\n',   acc  * 100);
    fprintf('  Referable DR Sensitivity   | 100.0%%              | %.1f%%\n',   sens * 100);
    fprintf('  Referable DR Specificity   | 0.0%%                | %.1f%%\n',   spec * 100);
    fprintf('  Grade-0 Avg Dark FP Count  | 453.5               | %.1f\n',     g0Stats.avgDark);
    fprintf('  Grade-0 Avg Bright FP Count| 380.4               | %.1f\n',     g0Stats.avgBright);
    fprintf('================================================================\n\n');

    if spec > 0.0
        fprintf('  [IMPROVEMENT] Specificity has improved from 0.0%% to %.1f%%!\n', spec * 100);
    else
        fprintf('  [STILL FAILING] Specificity still 0%%. Run bayesopt for systematic search.\n');
        fprintf('  To launch: run_bayesopt_calibration(50)\n');
    end
    fprintf('\n');
end
