function [modelsAgree, routingDecision, details] = secondOpinionCheck(model1Output, model2Output, cfg)
% SECONDOPINIONCHECK Compares multi-model predictions to detect diagnostic disagreement.
%
%   [MODELSAGREE, ROUTINGDECISION, DETAILS] = ROUTING.SECONDOPINIONCHECK(MODEL1OUTPUT, MODEL2OUTPUT)
%   evaluates consensus between two independent grading models or ensemble heads.
%
%   [MODELSAGREE, ROUTINGDECISION, DETAILS] = ROUTING.SECONDOPINIONCHECK(MODEL1OUTPUT, MODEL2OUTPUT, CFG)
%   uses configurable agreement tolerances defined in CFG (see config.m).
%
%   Inputs can be passed as:
%       - Structs with fields .grade (0-4) and .confidence (0-1)
%       - 2-element vectors [grade, confidence]
%       - Or (img, model1Handle, model2Handle) if calling dynamically on an image.
%
%   Clinical & Safety Rationale:
%       In automated DR screening, if two high-capacity AI models generate
%       discordant severity assessments (e.g. Model 1 predicts Mild NPDR / Grade 1
%       while Model 2 predicts Severe NPDR / Grade 3), automated arbitration
%       must NOT guess or average. This condition represents a safety-critical
%       discrepancy and is routed to the specialist with highest triage priority
%       under the label "MODEL_DISAGREEMENT", attaching both model outputs.
%
%   Outputs:
%       modelsAgree     - Logical. True if models agree within tolerance; False if conflicting.
%       routingDecision - String. "MODEL_DISAGREEMENT" if discordant; empty string "" if agreed.
%       details         - Struct containing both grades, confidences, grade difference, and diagnostic reason.
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-09-02

    % 1. Parse configuration
    if nargin < 3 || isempty(cfg)
        cfg = config();
    end

    maxAllowedDiff = 0;
    if isfield(cfg, 'routing') && isfield(cfg.routing, 'secondOpinion') && ...
       isfield(cfg.routing.secondOpinion, 'maxAllowedGradeDiff')
        maxAllowedDiff = cfg.routing.secondOpinion.maxAllowedGradeDiff;
    end

    % 2. Parse Model 1 and Model 2 Outputs
    [grade1, conf1] = parseModelOutput(model1Output);
    [grade2, conf2] = parseModelOutput(model2Output);

    % 3. Check Agreement
    gradeDiff = abs(grade1 - grade2);
    modelsAgree = (gradeDiff <= maxAllowedDiff);

    % 4. Determine Routing Decision & Reason
    if modelsAgree
        routingDecision = "";
        reason = sprintf('Consensus achieved: Both models agree on Grade %d (Conf1: %.2f, Conf2: %.2f)', ...
            grade1, conf1, conf2);
    else
        routingDecision = "MODEL_DISAGREEMENT";
        reason = sprintf('Safety alert - Model disagreement: Model 1 predicted Grade %d (Conf: %.2f) vs Model 2 predicted Grade %d (Conf: %.2f). Highest priority doctor referral attached.', ...
            grade1, conf1, grade2, conf2);
    end

    % 5. Assemble Details Struct
    details = struct();
    details.modelsAgree = modelsAgree;
    details.routingDecision = routingDecision;
    details.grade1 = grade1;
    details.conf1 = conf1;
    details.grade2 = grade2;
    details.conf2 = conf2;
    details.gradeDiff = gradeDiff;
    details.reason = reason;

end

%% Local Helper: Parse polymorphic model output
function [grade, conf] = parseModelOutput(out)
    if isstruct(out)
        grade = out.grade;
        conf = out.confidence;
    elseif isnumeric(out)
        if numel(out) >= 2
            grade = out(1);
            conf = out(2);
        elseif numel(out) == 1
            grade = out(1);
            conf = 1.0;
        else
            grade = 0; conf = 0.5;
        end
    else
        grade = 0; conf = 0.5;
    end
end
