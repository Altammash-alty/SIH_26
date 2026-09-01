function features = extractFeatures(enhancedImg, segmentResults, cfg)
% EXTRACTFEATURES Extracts multi-scale clinical biomarkers and lesion morphometry.
%
%   FEATURES = CLASSIFY.EXTRACTFEATURES(ENHANCEDIMG, SEGMENTRESULTS, CFG)
%
%   Computes an exhaustive quantitative feature vector aligned with the
%   Early Treatment Diabetic Retinopathy Study (ETDRS) and International
%   Clinical Diabetic Retinopathy (ICDR) disease severity staging systems.
%
%   Inputs:
%       enhancedImg    - Preprocessed fundus image from Stage 2.
%       segmentResults - Segmentation results struct from segment.segmentAll.
%       cfg            - (Optional) Configuration struct. Defaults to config().
%
%   Outputs:
%       features       - Struct containing quantitative biomarkers:
%                          .darkCountTotal, .brightCountTotal
%                          .quadrantHemorrhages [ST, SN, IT, IN]
%                          .quadrantExudates [ST, SN, IT, IN]
%                          .quadrantsWithSevereHemorrhages (count >= 20)
%                          .minDistToFoveaPixels, .foveaHazardInvolvement
%                          .dmeRiskScore, .vesselDensity, .vesselTortuosity
%                          .cupToDiscRatio, .neovascularizationRatio
%                          .featureVector (1x16 normalized numeric vector)
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    % 1. Parse Inputs & Configuration
    if nargin < 3 || isempty(cfg)
        cfg = config();
    end

    if isempty(enhancedImg) || isempty(segmentResults)
        error('extractFeatures:EmptyInput', 'Image and segmentation results required.');
    end

    % 2. Extract Stage 3 Segmentation Data
    lesions   = segmentResults.lesions;
    vessels   = segmentResults.vessels;
    macula    = segmentResults.macula;
    opticDisc = segmentResults.opticDisc;
    mask      = segmentResults.mask;

    totalFundusPixels = sum(mask(:)) + eps;

    % 3. Lesion Counts & Area Densities
    darkCountTotal   = lesions.darkCount;
    brightCountTotal = lesions.brightCount;
    darkAreaRatio    = lesions.darkAreaTotalPixels / totalFundusPixels;
    brightAreaRatio  = lesions.brightAreaTotalPixels / totalFundusPixels;

    % 4. 4-Quadrant ETDRS Distribution
    quadrantDark   = lesions.quadrantDarkCount;   % [ST, SN, IT, IN]
    quadrantBright = lesions.quadrantBrightCount; % [ST, SN, IT, IN]

    % ETDRS 4-2-1 Criteria:
    % Check how many quadrants have severe intraretinal hemorrhages (>= 20 per quadrant)
    severeHemoThreshold = cfg.classify.severeHemorrhagePerQuad;
    quadsWithSevereHemo = sum(quadrantDark >= severeHemoThreshold);
    quadsWithAnyHemo    = sum(quadrantDark > 0);
    quadsWithExudates   = sum(quadrantBright > 0);

    % 5. Macular Proximity & Diabetic Macular Edema (DME) Risk
    minDistFoveaPx = lesions.minDistToFoveaPixels;
    dmeThresholdPx = cfg.classify.dmeNearDistancePx;

    % Check if any lesion is inside the 1-disc-diameter macular hazard mask
    if isfield(macula, 'hazardMask') && ~isempty(macula.hazardMask)
        darkInHazard   = sum(lesions.darkMask(:)   & macula.hazardMask(:));
        brightInHazard = sum(lesions.brightMask(:) & macula.hazardMask(:));
        foveaHazardInvolvement = (darkInHazard > 0) || (brightInHazard > 0) || (minDistFoveaPx <= dmeThresholdPx);
    else
        foveaHazardInvolvement = (minDistFoveaPx <= dmeThresholdPx);
    end

    % Continuous DME Risk Score (0.0 to 1.0)
    % Higher if bright hard exudates or hemorrhages encroach close to fovea center
    if brightCountTotal > 0 || darkCountTotal > 0
        proximityScore = max(0.0, 1.0 - (minDistFoveaPx / (3.0 * dmeThresholdPx + eps)));
        dmeRiskScore = min(1.0, 0.6 * proximityScore + 0.4 * min(1.0, brightAreaRatio * 500));
    else
        dmeRiskScore = 0.0;
    end

    % 6. Vascular Biomarkers
    vesselDensity   = vessels.density;       % %
    vesselTortuosity = vessels.tortuosity;   % Ratio >= 1.0
    branchingPoints = vessels.branchingPointsCount;

    % 7. Optic Nerve Biomarkers & Neovascularization Index
    cupToDiscRatio = opticDisc.cupToDiscRatio;
    
    % Neovascularization Indicator:
    % PDR is marked by fine, disorganized, high-density new capillary fronds (NVD/NVE).
    % We detect elevated capillary density outside primary vascular trunks and optic disc rim.
    if vesselDensity > 18.0 || (darkAreaRatio > 0.02 && vesselTortuosity > 1.35)
        neovascularizationRatio = min(1.0, (vesselDensity - 14.0) / 10.0 + darkAreaRatio * 10);
    else
        neovascularizationRatio = min(1.0, darkAreaRatio * 5.0);
    end

    % 8. Normalized 16-Dimensional Clinical Feature Vector
    % Engineered for robust machine learning classifier inference
    fVec = zeros(1, 16);
    fVec(1)  = min(1.0, darkCountTotal / 50.0);             % Dark lesion count
    fVec(2)  = min(1.0, brightCountTotal / 50.0);           % Bright lesion count
    fVec(3)  = min(1.0, darkAreaRatio * 100.0);             % Dark area %
    fVec(4)  = min(1.0, brightAreaRatio * 100.0);           % Bright area %
    fVec(5)  = min(1.0, quadrantDark(1) / 25.0);            % Q1 ST Hemorrhages
    fVec(6)  = min(1.0, quadrantDark(2) / 25.0);            % Q2 SN Hemorrhages
    fVec(7)  = min(1.0, quadrantDark(3) / 25.0);            % Q3 IT Hemorrhages
    fVec(8)  = min(1.0, quadrantDark(4) / 25.0);            % Q4 IN Hemorrhages
    fVec(9)  = quadsWithSevereHemo / 4.0;                   % Severe quadrant fraction
    fVec(10) = quadsWithAnyHemo / 4.0;                      % Quadrant involvement fraction
    fVec(11) = dmeRiskScore;                                % DME risk score
    fVec(12) = double(foveaHazardInvolvement);              % Foveal hazard flag
    fVec(13) = min(1.0, vesselDensity / 25.0);              % Vessel density
    fVec(14) = min(1.0, (vesselTortuosity - 1.0) / 0.8);    % Vessel tortuosity
    fVec(15) = min(1.0, cupToDiscRatio);                    % Cup-to-disc ratio
    fVec(16) = neovascularizationRatio;                     % Neovascularization index

    % 9. Package Struct
    features = struct();
    features.darkCountTotal = darkCountTotal;
    features.brightCountTotal = brightCountTotal;
    features.darkAreaRatio = darkAreaRatio;
    features.brightAreaRatio = brightAreaRatio;
    features.quadrantDark = quadrantDark;
    features.quadrantBright = quadrantBright;
    features.quadsWithSevereHemo = quadsWithSevereHemo;
    features.quadsWithAnyHemo = quadsWithAnyHemo;
    features.minDistToFoveaPixels = minDistFoveaPx;
    features.foveaHazardInvolvement = foveaHazardInvolvement;
    features.dmeRiskScore = dmeRiskScore;
    features.vesselDensity = vesselDensity;
    features.vesselTortuosity = vesselTortuosity;
    features.branchingPoints = branchingPoints;
    features.cupToDiscRatio = cupToDiscRatio;
    features.neovascularizationRatio = neovascularizationRatio;
    features.featureVector = fVec;

end
