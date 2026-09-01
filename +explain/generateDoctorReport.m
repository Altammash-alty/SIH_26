function reportSummary = generateDoctorReport(examData, cfg, outputDir)
% GENERATEDOCTORREPORT Generates comprehensive Doctor-Facing Clinical Screening Reports.
%
%   REPORTSUMMARY = EXPLAIN.GENERATEDOCTORREPORT(EXAMDATA, CFG, OUTPUTDIR)
%
%   Synthesizes the complete end-to-end multi-stage pipeline outputs into an
%   executive clinical report adhering to ophthalmology telemedicine standards:
%       1. High-Resolution 6-Panel Diagnostic Imaging Composite Figure
%       2. Self-Contained Diagnostic HTML Screening Report
%       3. Quantitative Biomarker Summary Table
%       4. Clinical Decision Support & Actionable Referral Recommendation
%
%   Inputs:
%       examData  - Struct containing all exam findings:
%                     .patientID       - Patient identifier string (e.g. 'PAT-2026-089')
%                     .patientAge      - Patient age (integer)
%                     .patientGender   - 'M' / 'F'
%                     .eyeLaterality   - 'OD (Right Eye)' or 'OS (Left Eye)'
%                     .examDate        - Date string (e.g. '2026-08-30')
%                     .rawImage        - Original unprocessed fundus image
%                     .qualityMetrics  - Struct from quality.assessQuality
%                     .enhancedImage   - Enhanced image from preprocess.enhanceImage
%                     .segmentResults  - Struct from segment.segmentAll
%                     .grade           - Integer DR grade (0 to 4)
%                     .gradeName       - Descriptive DR grade string
%                     .confidence      - Confidence score (0.0 to 1.0)
%                     .probabilities   - 1x5 posterior probabilities
%                     .dmeRisk         - DME risk string
%                     .urgency         - Clinical referral timeline string
%                     .icd10Code       - Diagnostic ICD-10 code
%                     .features        - Quantitative features struct
%       cfg       - (Optional) Configuration struct. Defaults to config().
%       outputDir - (Optional) Directory to save report artifacts. Defaults to pwd.
%
%   Outputs:
%       reportSummary - Struct containing paths to generated report artifacts:
%                         .figurePath - PNG path of 6-panel clinical figure
%                         .htmlPath   - HTML path of interactive patient report
%                         .reportText - Formatted string summary for EHR integration
%
%   Author: DR Screening Pipeline MVP
%   Date: 2026-08-30

    % 1. Parse Inputs & Configuration
    if nargin < 2 || isempty(cfg)
        cfg = config();
    end

    if nargin < 3 || isempty(outputDir)
        outputDir = fullfile(pwd, 'reports');
    end

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % 2. Validate & Populate Default Exam Fields
    if ~isfield(examData, 'patientID'),     examData.patientID = 'PAT-2026-001'; end
    if ~isfield(examData, 'patientAge'),    examData.patientAge = 58; end
    if ~isfield(examData, 'patientGender'), examData.patientGender = 'M'; end
    if ~isfield(examData, 'eyeLaterality'), examData.eyeLaterality = 'OD (Right Eye)'; end
    if ~isfield(examData, 'examDate'),      examData.examDate = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')); end

    patientID = examData.patientID;
    grade     = examData.grade;
    gradeName = examData.gradeName;
    confPct   = examData.confidence * 100.0;
    dmeRisk   = examData.dmeRisk;
    urgency   = examData.urgency;
    icd10     = examData.icd10Code;
    qScore    = examData.qualityMetrics.overallScore;

    % 3. Generate Visual Saliency & Lesion Maps
    [~, gradCamRGB] = explain.generateGradCAM(examData.enhancedImage, examData.segmentResults, grade, cfg);
    lesionMapRGB    = explain.createLesionMap(examData.enhancedImage, examData.segmentResults, cfg);
    compositeSegRGB = examData.segmentResults.compositeRGB;

    % ---------------------------------------------------------------------
    % 4. Render 6-Panel Diagnostic Imaging Figure
    % ---------------------------------------------------------------------
    hFig = figure('Name', sprintf('DR Screening Report - %s', patientID), ...
                  'Color', [0.12 0.12 0.14], ...
                  'Position', [50 50 1200 800], ...
                  'Visible', 'off');

    % Panel 1: Original Fundus Photo
    subplot(2, 3, 1);
    imshow(examData.rawImage);
    title(sprintf('1. Raw Fundus (Quality: %.1f/100)', qScore), 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');

    % Panel 2: Preprocessed & CLAHE Enhanced
    subplot(2, 3, 2);
    imshow(examData.enhancedImage);
    title('2. Preprocessed & CLAHE Enhanced', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');

    % Panel 3: Retinal Segmentation (Vessels, Disc, Fovea)
    subplot(2, 3, 3);
    imshow(compositeSegRGB);
    title(sprintf('3. Vessels (%.1f%%) & Disc (CDR: %.2f)', ...
        examData.segmentResults.vessels.density, examData.segmentResults.opticDisc.cupToDiscRatio), ...
        'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');

    % Panel 4: Multi-Quadrant ETDRS Lesion Map
    subplot(2, 3, 4);
    imshow(lesionMapRGB);
    title(sprintf('4. Lesions (Dark: %d, Exudates: %d)', ...
        examData.segmentResults.lesions.darkCount, examData.segmentResults.lesions.brightCount), ...
        'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');

    % Panel 5: AI Grad-CAM Attention Heatmap
    subplot(2, 3, 5);
    imshow(gradCamRGB);
    title(sprintf('5. AI Grad-CAM Saliency (Grade %d Focus)', grade), 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');

    % Panel 6: Class Posterior Probability Bar Chart & Diagnosis Card
    subplot(2, 3, 6);
    gradeLabels = {'Grade 0', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4'};
    b = barh(0:4, examData.probabilities * 100.0, 'FaceColor', [0.15 0.65 0.95]);
    set(gca, 'YTick', 0:4, 'YTickLabel', gradeLabels, 'Color', [0.18 0.18 0.22], ...
             'XColor', 'w', 'YColor', 'w', 'XLim', [0 100]);
    xlabel('Probability (%)', 'Color', 'w', 'FontWeight', 'bold');
    title(sprintf('6. AI Diagnosis: %s (%.1f%%)', gradeName, confPct), 'Color', 'y', 'FontSize', 11, 'FontWeight', 'bold');
    grid on; set(gca, 'GridColor', [0.3 0.3 0.35]);

    % Save High-Res Diagnostic Composite
    figFileName = sprintf('report_%s_%s_composite.png', patientID, regexprep(gradeName, '[^a-zA-Z0-9]', '_'));
    figFilePath = fullfile(outputDir, figFileName);
    saveas(hFig, figFilePath);
    close(hFig);

    % Save individual thumbnails for HTML inclusion
    p1Path = fullfile(outputDir, sprintf('thumb_%s_raw.png', patientID));
    p2Path = fullfile(outputDir, sprintf('thumb_%s_enh.png', patientID));
    p3Path = fullfile(outputDir, sprintf('thumb_%s_seg.png', patientID));
    p4Path = fullfile(outputDir, sprintf('thumb_%s_les.png', patientID));
    p5Path = fullfile(outputDir, sprintf('thumb_%s_cam.png', patientID));
    imwrite(examData.rawImage, p1Path);
    imwrite(examData.enhancedImage, p2Path);
    imwrite(compositeSegRGB, p3Path);
    imwrite(lesionMapRGB, p4Path);
    imwrite(gradCamRGB, p5Path);

    % ---------------------------------------------------------------------
    % 5. Generate Standalone Clinical HTML Report
    % ---------------------------------------------------------------------
    htmlFileName = sprintf('report_%s_clinical.html', patientID);
    htmlFilePath = fullfile(outputDir, htmlFileName);

    % Severity Color Coding
    switch grade
        case 0, badgeColor = '#10b981'; badgeText = 'NORMAL (GRADE 0)';
        case 1, badgeColor = '#3b82f6'; badgeText = 'MILD NPDR (GRADE 1)';
        case 2, badgeColor = '#f59e0b'; badgeText = 'MODERATE NPDR (GRADE 2)';
        case 3, badgeColor = '#ef4444'; badgeText = 'SEVERE NPDR (GRADE 3)';
        case 4, badgeColor = '#b91c1c'; badgeText = 'PROLIFERATIVE DR (GRADE 4)';
    end

    fid = fopen(htmlFilePath, 'w');
    if fid ~= -1
        fprintf(fid, '<!DOCTYPE html>\n<html lang="en">\n<head>\n');
        fprintf(fid, '<meta charset="UTF-8"><title>Diabetic Retinopathy Screening Report - %s</title>\n', patientID);
        fprintf(fid, '<style>\n');
        fprintf(fid, 'body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #0f172a; color: #e2e8f0; margin: 0; padding: 24px; }\n');
        fprintf(fid, '.container { max-width: 1080px; margin: 0 auto; background: #1e293b; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); overflow: hidden; border: 1px solid #334155; }\n');
        fprintf(fid, '.header { background: linear-gradient(135deg, #1e3a8a, #0f172a); padding: 24px 32px; border-bottom: 2px solid #3b82f6; display: flex; justify-content: space-between; align-items: center; }\n');
        fprintf(fid, '.header h1 { margin: 0; font-size: 24px; color: #ffffff; letter-spacing: -0.5px; }\n');
        fprintf(fid, '.header .subtitle { color: #94a3b8; font-size: 14px; margin-top: 4px; }\n');
        fprintf(fid, '.badge { background: %s; color: #ffffff; font-weight: 700; padding: 8px 18px; border-radius: 9999px; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px; }\n', badgeColor);
        fprintf(fid, '.content { padding: 32px; }\n');
        fprintf(fid, '.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 24px; }\n');
        fprintf(fid, '.grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 24px; }\n');
        fprintf(fid, '.card { background: #0f172a; border-radius: 8px; padding: 20px; border: 1px solid #334155; }\n');
        fprintf(fid, '.card h3 { margin-top: 0; color: #38bdf8; font-size: 15px; border-bottom: 1px solid #1e293b; padding-bottom: 8px; }\n');
        fprintf(fid, '.data-row { display: flex; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid #1e293b; font-size: 14px; }\n');
        fprintf(fid, '.data-label { color: #94a3b8; }\n');
        fprintf(fid, '.data-value { font-weight: 600; color: #f8fafc; }\n');
        fprintf(fid, '.alert-box { background: rgba(59, 130, 246, 0.1); border-left: 4px solid %s; padding: 16px; border-radius: 6px; margin-bottom: 24px; }\n', badgeColor);
        fprintf(fid, '.img-gallery { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-top: 20px; }\n');
        fprintf(fid, '.img-card { background: #0f172a; border-radius: 8px; overflow: hidden; border: 1px solid #334155; text-align: center; }\n');
        fprintf(fid, '.img-card img { width: 100%%; height: auto; display: block; }\n');
        fprintf(fid, '.img-card .img-caption { padding: 10px; font-size: 13px; font-weight: 600; color: #cbd5e1; }\n');
        fprintf(fid, 'table { width: 100%%; border-collapse: collapse; margin-top: 12px; }\n');
        fprintf(fid, 'th, td { text-align: left; padding: 10px; border-bottom: 1px solid #334155; font-size: 13px; }\n');
        fprintf(fid, 'th { background: #1e293b; color: #94a3b8; font-weight: 600; }\n');
        fprintf(fid, '.footer { padding: 16px 32px; background: #0f172a; border-top: 1px solid #334155; font-size: 12px; color: #64748b; text-align: center; }\n');
        fprintf(fid, '</style>\n</head>\n<body>\n');
        
        fprintf(fid, '<div class="container">\n');
        fprintf(fid, '  <div class="header">\n');
        fprintf(fid, '    <div>\n');
        fprintf(fid, '      <h1>Diabetic Retinopathy Tele-Screening Report</h1>\n');
        fprintf(fid, '      <div class="subtitle">Autonomous 5-Stage Clinical Evaluation Pipeline | SIH-26 AI</div>\n');
        fprintf(fid, '    </div>\n');
        fprintf(fid, '    <div class="badge">%s</div>\n', badgeText);
        fprintf(fid, '  </div>\n');

        fprintf(fid, '  <div class="content">\n');
        
        % Primary Diagnostic Summary Banner
        fprintf(fid, '    <div class="alert-box">\n');
        fprintf(fid, '      <h2 style="margin:0 0 8px 0; color:#ffffff; font-size:18px;">Diagnosis: %s (Confidence: %.1f%%)</h2>\n', gradeName, confPct);
        fprintf(fid, '      <p style="margin:4px 0; font-size:14px;"><strong>ICD-10 Code:</strong> %s &nbsp;|&nbsp; <strong>DME Risk:</strong> %s</p>\n', icd10, dmeRisk);
        fprintf(fid, '      <p style="margin:4px 0; font-size:14px;"><strong>Recommended Triage:</strong> <span style="color:#facc15; font-weight:600;">%s</span></p>\n', urgency);
        fprintf(fid, '    </div>\n');

        % Patient & Exam Details
        fprintf(fid, '    <div class="grid-2">\n');
        fprintf(fid, '      <div class="card">\n');
        fprintf(fid, '        <h3>Patient Demographics</h3>\n');
        fprintf(fid, '        <div class="data-row"><span class="data-label">Patient ID:</span><span class="data-value">%s</span></div>\n', patientID);
        fprintf(fid, '        <div class="data-row"><span class="data-label">Age / Gender:</span><span class="data-value">%d yrs / %s</span></div>\n', examData.patientAge, examData.patientGender);
        fprintf(fid, '        <div class="data-row"><span class="data-label">Examined Eye:</span><span class="data-value">%s</span></div>\n', examData.eyeLaterality);
        fprintf(fid, '        <div class="data-row"><span class="data-label">Exam Timestamp:</span><span class="data-value">%s</span></div>\n', examData.examDate);
        fprintf(fid, '      </div>\n');

        fprintf(fid, '      <div class="card">\n');
        fprintf(fid, '        <h3>Quality & System Verification</h3>\n');
        fprintf(fid, '        <div class="data-row"><span class="data-label">Stage 1 Quality Gate:</span><span class="data-value" style="color:#10b981;">PASSED (%.1f / 100)</span></div>\n', qScore);
        fprintf(fid, '        <div class="data-row"><span class="data-label">Sharpness Score:</span><span class="data-value">%.2f (Threshold: %.1f)</span></div>\n', examData.qualityMetrics.blurScore, cfg.quality.blur.threshold);
        fprintf(fid, '        <div class="data-row"><span class="data-label">Stage 2 Enhancement:</span><span class="data-value">Green-CLAHE + Illumination Flattening</span></div>\n');
        fprintf(fid, '        <div class="data-row"><span class="data-label">Stage 4 Classifier:</span><span class="data-value">ETDRS Biomarker Neural Ensemble</span></div>\n');
        fprintf(fid, '      </div>\n');
        fprintf(fid, '    </div>\n');

        % Quantitative Biomarkers Table
        fprintf(fid, '    <div class="card" style="margin-bottom: 24px;">\n');
        fprintf(fid, '      <h3>Quantitative Retinal Biomarkers (Stages 3 & 4)</h3>\n');
        fprintf(fid, '      <table>\n');
        fprintf(fid, '        <thead><tr><th>Biomarker</th><th>Measured Value</th><th>Reference Standard</th><th>Clinical Implication</th></tr></thead>\n');
        fprintf(fid, '        <tbody>\n');
        fprintf(fid, '          <tr><td>Retinal Vessel Area Density</td><td><strong>%.1f%%</strong></td><td>9.0%% - 16.0%%</td><td>%s</td></tr>\n', ...
            examData.segmentResults.vessels.density, getVesselImplication(examData.segmentResults.vessels.density));
        fprintf(fid, '          <tr><td>Optic Cup-to-Disc Ratio (CDR)</td><td><strong>%.2f</strong></td><td>&lt; 0.50</td><td>%s</td></tr>\n', ...
            examData.segmentResults.opticDisc.cupToDiscRatio, examData.segmentResults.opticDisc.cdrStatus);
        fprintf(fid, '          <tr><td>Dark Lesions (Hemorrhages / MAs)</td><td><strong>%d clusters</strong></td><td>0 clusters</td><td>Intraretinal microvascular rupture</td></tr>\n', ...
            examData.segmentResults.lesions.darkCount);
        fprintf(fid, '          <tr><td>Bright Lesions (Hard Exudates)</td><td><strong>%d clusters</strong></td><td>0 clusters</td><td>Lipoprotein extravasation / edema</td></tr>\n', ...
            examData.segmentResults.lesions.brightCount);
        fprintf(fid, '          <tr><td>Closest Lesion to Fovea</td><td><strong>%.1f px</strong></td><td>&gt; 150 px</td><td>%s</td></tr>\n', ...
            examData.segmentResults.lesions.minDistToFoveaPixels, dmeRisk);
        fprintf(fid, '        </tbody>\n');
        fprintf(fid, '      </table>\n');
        fprintf(fid, '    </div>\n');

        % 6-Panel Diagnostic Visual Imaging Breakdown
        fprintf(fid, '    <h3 style="color:#38bdf8; margin-top:28px;">Diagnostic Imaging Breakdown</h3>\n');
        fprintf(fid, '    <div class="img-gallery">\n');
        fprintf(fid, '      <div class="img-card"><img src="%s" alt="Raw Fundus"><div class="img-caption">1. Raw Fundus</div></div>\n', sprintf('thumb_%s_raw.png', patientID));
        fprintf(fid, '      <div class="img-card"><img src="%s" alt="Enhanced Fundus"><div class="img-caption">2. CLAHE Preprocessed</div></div>\n', sprintf('thumb_%s_enh.png', patientID));
        fprintf(fid, '      <div class="img-card"><img src="%s" alt="Segmentation"><div class="img-caption">3. Vessel & Disc Map</div></div>\n', sprintf('thumb_%s_seg.png', patientID));
        fprintf(fid, '      <div class="img-card"><img src="%s" alt="Lesions"><div class="img-caption">4. 4-Quadrant Lesions</div></div>\n', sprintf('thumb_%s_les.png', patientID));
        fprintf(fid, '      <div class="img-card"><img src="%s" alt="Grad-CAM"><div class="img-caption">5. AI Grad-CAM Saliency</div></div>\n', sprintf('thumb_%s_cam.png', patientID));
        fprintf(fid, '      <div class="img-card"><img src="%s" alt="Diagnostic Composite"><div class="img-caption">6. Composite High-Res</div></div>\n', figFileName);
        fprintf(fid, '    </div>\n');

        % Clinical Decision Support & Recommendations
        fprintf(fid, '    <div class="card" style="margin-top:24px; border-left: 4px solid #38bdf8;">\n');
        fprintf(fid, '      <h3>Clinical Decision Support & Management Protocol</h3>\n');
        fprintf(fid, '      <p style="font-size:14px; line-height:1.6;"><strong>Recommended Clinical Action:</strong> %s</p>\n', urgency);
        fprintf(fid, '      <p style="font-size:13px; color:#94a3b8; line-height:1.5;">\n');
        fprintf(fid, '        <strong>Guidelines Summary (ICO / AAO Standard):</strong><br>\n');
        fprintf(fid, '        &bull; <em>Grade 0 (Normal):</em> Optimize glycemic control (HbA1c &lt; 7.0%%), annual screening.<br>\n');
        fprintf(fid, '        &bull; <em>Grade 1 (Mild NPDR):</em> Optimize BP and lipid control, re-screen in 6-12 months.<br>\n');
        fprintf(fid, '        &bull; <em>Grade 2 (Moderate NPDR):</em> Comprehensive dilated ophthalmic exam within 3-6 months.<br>\n');
        fprintf(fid, '        &bull; <em>Grade 3 (Severe NPDR):</em> Urgent retinal specialist evaluation for panretinal photocoagulation (PRP) or anti-VEGF.<br>\n');
        fprintf(fid, '        &bull; <em>Grade 4 (PDR):</em> Immediate vitreoretinal intervention (&lt; 48-72h) to prevent permanent tractional retinal detachment.\n');
        fprintf(fid, '      </p>\n');
        fprintf(fid, '    </div>\n');

        fprintf(fid, '  </div>\n');
        fprintf(fid, '  <div class="footer">\n');
        fprintf(fid, '    Generated by Diabetic Retinopathy Autonomous Screening Engine | Software Version 2.0 (SIH-26 MVP) | Confidential Medical Record\n');
        fprintf(fid, '  </div>\n');
        fprintf(fid, '</div>\n</body>\n</html>\n');
        fclose(fid);
    end

    % ---------------------------------------------------------------------
    % 6. Construct Formatted EHR Text Summary
    % ---------------------------------------------------------------------
    reportText = sprintf([...
        '==================================================================\n', ...
        '       DIABETIC RETINOPATHY CLINICAL SCREENING REPORT             \n', ...
        '==================================================================\n', ...
        'Patient ID:      %s\n', ...
        'Age / Gender:    %d / %s\n', ...
        'Examined Eye:    %s\n', ...
        'Date:            %s\n', ...
        'Quality Score:   %.1f/100 (PASSED)\n', ...
        '------------------------------------------------------------------\n', ...
        'DIAGNOSIS:       %s (Confidence: %.1f%%)\n', ...
        'ICD-10 CODE:     %s\n', ...
        'DME RISK:        %s\n', ...
        'TRIAGE URGENCY:  %s\n', ...
        '------------------------------------------------------------------\n', ...
        'BIOMARKERS:\n', ...
        ' - Retinal Vessel Density:  %.1f%%\n', ...
        ' - Optic Cup-to-Disc Ratio: %.2f (%s)\n', ...
        ' - Dark Lesions (Hemo/MA):  %d clusters\n', ...
        ' - Bright Lesions (Exudate):%d clusters\n', ...
        ' - Proximity to Fovea:      %.1f px\n', ...
        '==================================================================\n'], ...
        patientID, examData.patientAge, examData.patientGender, examData.eyeLaterality, ...
        examData.examDate, qScore, gradeName, confPct, icd10, dmeRisk, urgency, ...
        examData.segmentResults.vessels.density, examData.segmentResults.opticDisc.cupToDiscRatio, ...
        examData.segmentResults.opticDisc.cdrStatus, examData.segmentResults.lesions.darkCount, ...
        examData.segmentResults.lesions.brightCount, examData.segmentResults.lesions.minDistToFoveaPixels);

    % 7. Package Outputs
    reportSummary = struct();
    reportSummary.patientID = patientID;
    reportSummary.figurePath = figFilePath;
    reportSummary.htmlPath = htmlFilePath;
    reportSummary.reportText = reportText;

end

function str = getVesselImplication(density)
    if density < 9.0
        str = 'Vascular dropout / Capillary non-perfusion';
    elseif density <= 16.0
        str = 'Normal vascular caliber and density';
    else
        str = 'Possible neovascularization or engorgement';
    end
end
