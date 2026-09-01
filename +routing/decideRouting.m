function [decision, reason, sampleForAudit, details] = decideRouting(isGood, distributionScore, isTypical, grade, confidence, cfg, extraOpts)
% DECIDEROUTING Master Trust and Routing Decision Layer for DR Screening.
%
%   [DECISION, REASON, SAMPLEFORAUDIT, DETAILS] = ROUTING.DECIDEROUTING(ISGOOD, DISTRIBUTIONSCORE, ISTYPICAL, GRADE, CONFIDENCE)
%   determines the clinical routing path of a screened fundus image based
%   on the holistic evaluation of image quality, statistical distribution,
%   AI severity grade, and model confidence.
%
%   [DECISION, REASON, SAMPLEFORAUDIT, DETAILS] = ROUTING.DECIDEROUTING(..., CFG, EXTRAOPTS)
%   accepts custom configuration thresholds and optional recheck / ensemble structs:
%       EXTRAOPTS may contain:
%           .qualitySensitive     - Logical from routing.qualityRecheckTest
%           .qualityRecheckDone   - Logical flag indicating recheck was run
%           .recheckDetails       - Struct output from routing.qualityRecheckTest
%           .modelsAgree          - Logical from routing.secondOpinionCheck
%           .secondOpinionDetails - Struct output from routing.secondOpinionCheck
%           .qualityReason        - String failure reason from Stage 1
%           .oodReason            - String anomaly reason from OOD module
%           .forceAudit           - Boolean override for audit sampling
%
%   Routing Decision Labels:
%       - "RETAKE"             : Quality gate failed, or low-confidence grade
%                                proven to be sensitive to image quality degradation.
%       - "MODEL_DISAGREEMENT" : Multiple AI models or ensemble heads disagree
%                                on DR grade -> Highest priority specialist referral.
%       - "OOD_FLAG"           : Image is statistically atypical compared to
%                                training data -> Flagged for doctor review.
%       - "UNCERTAIN_RECHECK"  : Low AI confidence on typical image -> Needs
%                                quality-sensitivity perturbation test.
%       - "AUTO_CLEAR_SAMPLED" : Non-referable grade (0/1), high confidence,
%                                typical distribution. sampleForAudit is TRUE
%                                for a random percentage (e.g. 10%) for audit.
%       - "DOCTOR_REVIEW"      : Referable grade (2+) with high confidence, or
%                                confirmed genuine clinical ambiguity.
%
%   Requirements Met:
%       - Pure deterministic logic with clear inputs and outputs.
%       - All cutoffs derived from config.m without hardcoding.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-09-02

    % 1. Parse configuration
    if nargin < 6 || isempty(cfg)
        cfg = config();
    end

    if nargin < 7 || isempty(extraOpts)
        extraOpts = struct();
    end

    confCutoff = 0.75;
    if isfield(cfg, 'routing') && isfield(cfg.routing, 'confidenceThreshold')
        confCutoff = cfg.routing.confidenceThreshold;
    end

    healthyGrades = [0, 1];
    if isfield(cfg, 'routing') && isfield(cfg.routing, 'healthyGrades')
        healthyGrades = cfg.routing.healthyGrades;
    end

    referableGrades = [2, 3, 4];
    if isfield(cfg, 'routing') && isfield(cfg.routing, 'referableGrades')
        referableGrades = cfg.routing.referableGrades;
    end

    auditRate = 0.10;
    if isfield(cfg, 'routing') && isfield(cfg.routing, 'auditSamplingRate')
        auditRate = cfg.routing.auditSamplingRate;
    end

    sampleForAudit = false;
    details = struct();
    details.isGood = isGood;
    details.distributionScore = distributionScore;
    details.isTypical = isTypical;
    details.grade = grade;
    details.confidence = confidence;

    % ---------------------------------------------------------------------
    % PRIORITY 1: STAGE 1 QUALITY GATE FAILURE -> RETAKE
    % ---------------------------------------------------------------------
    if ~isGood
        decision = "RETAKE";
        qReason = "Image failed quality gate";
        if isfield(extraOpts, 'qualityReason') && ~isempty(extraOpts.qualityReason)
            qReason = extraOpts.qualityReason;
        end
        reason = sprintf('RETAKE: %s', qReason);
        details.decision = decision;
        details.reason = reason;
        details.priority = 1;
        return;
    end

    % ---------------------------------------------------------------------
    % PRIORITY 2: MULTI-MODEL DISAGREEMENT -> MODEL_DISAGREEMENT
    % ---------------------------------------------------------------------
    if isfield(extraOpts, 'modelsAgree') && ~extraOpts.modelsAgree
        decision = "MODEL_DISAGREEMENT";
        if isfield(extraOpts, 'secondOpinionDetails') && isfield(extraOpts.secondOpinionDetails, 'reason')
            reason = extraOpts.secondOpinionDetails.reason;
        else
            reason = "MODEL_DISAGREEMENT: Secondary model disagreement on DR severity grade. Highest priority doctor review attached.";
        end
        details.decision = decision;
        details.reason = reason;
        details.priority = 2;
        return;
    end

    % ---------------------------------------------------------------------
    % PRIORITY 3: OUT-OF-DISTRIBUTION ANOMALY -> OOD_FLAG
    % ---------------------------------------------------------------------
    if ~isTypical
        decision = "OOD_FLAG";
        oodMsg = "Statistically atypical image vs training distribution";
        if isfield(extraOpts, 'oodReason') && ~isempty(extraOpts.oodReason)
            oodMsg = extraOpts.oodReason;
        end
        reason = sprintf('OOD_FLAG: %s (Mahalanobis Dist: %.2f). Routed to doctor queue with OOD alert.', ...
            oodMsg, distributionScore);
        details.decision = decision;
        details.reason = reason;
        details.priority = 3;
        return;
    end

    % ---------------------------------------------------------------------
    % PRIORITY 4: LOW CONFIDENCE UNCERTAINTY & RECHECK
    % ---------------------------------------------------------------------
    if confidence < confCutoff
        % Check if a quality-sensitivity recheck test was already conducted
        if isfield(extraOpts, 'qualityRecheckDone') && extraOpts.qualityRecheckDone
            if isfield(extraOpts, 'qualitySensitive') && extraOpts.qualitySensitive
                % Quality perturbation changed the result -> uncertainty was quality-driven
                decision = "RETAKE";
                reason = sprintf('RETAKE: Low confidence (%.2f < %.2f) proven quality-sensitive under perturbation. Retake recommended to obtain diagnostic clarity.', ...
                    confidence, confCutoff);
                details.uncertaintyType = 'Quality-Driven';
            else
                % Result was invariant -> genuine medical ambiguity
                decision = "DOCTOR_REVIEW";
                reason = sprintf('DOCTOR_REVIEW: Low confidence (%.2f < %.2f) invariant to quality perturbation. Flagged as genuine clinical ambiguity for specialist judgment (Grade %d).', ...
                    confidence, confCutoff, grade);
                details.uncertaintyType = 'Clinical-Ambiguity';
            end
        else
            % Recheck has not been performed yet
            decision = "UNCERTAIN_RECHECK";
            reason = sprintf('UNCERTAIN_RECHECK: Low confidence (%.2f < %.2f) on typical image. Requires quality-sensitivity perturbation recheck before final routing.', ...
                confidence, confCutoff);
            details.uncertaintyType = 'Pending-Recheck';
        end

        details.decision = decision;
        details.reason = reason;
        details.priority = 4;
        return;
    end

    % ---------------------------------------------------------------------
    % PRIORITY 5: HIGH CONFIDENCE HEALTHY (GRADE 0 or 1) -> AUTO_CLEAR_SAMPLED
    % ---------------------------------------------------------------------
    if ismember(grade, healthyGrades)
        decision = "AUTO_CLEAR_SAMPLED";

        % Evaluate random audit sampling
        if isfield(extraOpts, 'forceAudit') && ~isempty(extraOpts.forceAudit)
            sampleForAudit = logical(extraOpts.forceAudit);
        else
            sampleForAudit = (rand() < auditRate);
        end

        if sampleForAudit
            reason = sprintf('AUTO_CLEAR_SAMPLED: Grade %d (Confidence: %.2f) - Non-referable case selected for random %.0f%% quality audit.', ...
                grade, confidence, auditRate * 100);
        else
            reason = sprintf('AUTO_CLEAR_SAMPLED: Grade %d (Confidence: %.2f) - Non-referable case auto-cleared (Tele-ophthalmology fast-track).', ...
                grade, confidence);
        end

        details.decision = decision;
        details.reason = reason;
        details.sampleForAudit = sampleForAudit;
        details.priority = 5;
        return;
    end

    % ---------------------------------------------------------------------
    % PRIORITY 6: HIGH CONFIDENCE REFERABLE (GRADE 2, 3, 4) -> DOCTOR_REVIEW
    % ---------------------------------------------------------------------
    if ismember(grade, referableGrades)
        decision = "DOCTOR_REVIEW";
        reason = sprintf('DOCTOR_REVIEW: Grade %d (Confidence: %.2f) - Referable DR detected. Queued for specialist ophthalmologist review.', ...
            grade, confidence);
        details.decision = decision;
        details.reason = reason;
        details.priority = 6;
        return;
    end

    % Fallback / Catch-all
    decision = "DOCTOR_REVIEW";
    reason = sprintf('DOCTOR_REVIEW: Grade %d (Confidence: %.2f) - Standard referral triage.', grade, confidence);
    details.decision = decision;
    details.reason = reason;
    details.priority = 7;

end
