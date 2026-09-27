import React, { useState, useEffect } from 'react';
import { Upload, RefreshCw, ChevronRight, Image as ImageIcon } from 'lucide-react';

interface SampleItem {
  id: string;
  name: string;
  source: string;
  groundTruthGrade: number;
  gradeLabel: string;
  path: string;
  qualityTier?: 'high' | 'standard';
}

interface ScreeningResult {
  patient: {
    id: string;
    age: number;
    gender: string;
    eye: string;
    examDate: string;
  };
  stage1Quality: {
    isGood: boolean;
    overallScore: number;
    blurScore: number;
    blurPassed: boolean;
    illumScore: number;
    illumPassed: boolean;
    fovScore: number;
    fovPassed: boolean;
    reason: string;
  };
  stage2Preprocess: {
    completed: boolean;
  };
  stage3Segmentation: {
    cupToDiscRatio: number;
    vesselDensityPercent: number;
    darkLesionCount: number;
    brightExudateCount: number;
    microaneurysmCount?: number;
    hemorrhageCount?: number;
    hardExudateCount?: number;
    cottonWoolCount?: number;
    neovascularCount?: number;
    quadrantHemorrhages?: number[];
    quadrantExudates?: number[];
    foveaCenter: [number, number];
    opticDiscCenter: [number, number];
  };
  stage4Grading: {
    grade: number;
    gradeName: string;
    confidence: number;
    probabilities: number[];
    dmeRisk: string;
    urgency: string;
    icd10Code: string;
  };
  routing: {
    decision: 'AUTO_CLEAR' | 'DOCTOR_REVIEW' | 'OOD_FLAG' | 'RETAKE';
    reason: string;
    mahalanobisDistance: number;
    isTypical: boolean;
  };
  images: {
    raw: string;
    enhanced: string;
    heatmap: string;
  };
}

export const ScreeningStudio: React.FC = () => {
  const [samples, setSamples] = useState<SampleItem[]>([]);
  const [selectedSample, setSelectedSample] = useState<SampleItem | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [result, setResult] = useState<ScreeningResult | null>(null);
  const [activeImageView, setActiveImageView] = useState<'raw' | 'enhanced' | 'heatmap'>('enhanced');

  useEffect(() => {
    fetch('/api/samples')
      .then((r) => r.json())
      .then((data) => {
        if (data.samples && data.samples.length > 0) {
          setSamples(data.samples);
          setSelectedSample(data.samples[0]);
          setPreviewUrl(data.samples[0].path);
        }
      })
      .catch((err) => console.error('Failed to fetch samples:', err));
  }, []);

  const handleSelectSample = (sample: SampleItem) => {
    setSelectedSample(sample);
    setSelectedFile(null);
    setPreviewUrl(sample.path);
    setResult(null);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setSelectedFile(file);
      setSelectedSample(null);
      setPreviewUrl(URL.createObjectURL(file));
      setResult(null);
    }
  };

  const handleExecuteScreening = async () => {
    if (!selectedSample && !selectedFile) return;

    setLoading(true);
    try {
      const formData = new FormData();
      if (selectedFile) {
        formData.append('file', selectedFile);
      } else if (selectedSample) {
        formData.append('sampleId', selectedSample.id);
      }

      formData.append('patientId', 'PAT-2026-STUDIO');
      formData.append('patientAge', '58');
      formData.append('patientGender', 'M');
      formData.append('eyeLaterality', 'OD (Right Eye)');

      const res = await fetch('/api/screen', {
        method: 'POST',
        body: formData,
      });

      if (!res.ok) {
        throw new Error(`Screening failed: ${res.statusText}`);
      }

      const data: ScreeningResult = await res.json();
      setResult(data);
      setActiveImageView('enhanced');
    } catch (err) {
      console.error('Error during screening:', err);
    } finally {
      setLoading(false);
    }
  };

  const currentDisplayImage = result
    ? activeImageView === 'raw'
      ? result.images.raw
      : activeImageView === 'enhanced'
      ? result.images.enhanced
      : result.images.heatmap
    : previewUrl;

  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: '320px 1fr 340px',
        backgroundColor: 'var(--paper)',
        minHeight: '720px',
      }}
    >
      {/* ----------------- LEFT PANEL: IMAGE SELECTION ----------------- */}
      <div
        style={{
          backgroundColor: 'var(--surface-alt)',
          borderRight: '1px solid var(--hairline)',
          padding: '24px',
          display: 'flex',
          flexDirection: 'column',
          gap: '20px',
        }}
      >
        <div>
          <div className="caption" style={{ marginBottom: '8px' }}>
            Dataset Samples
          </div>
          <p style={{ fontSize: '13px', color: 'var(--mid-gray)', marginBottom: '12px' }}>
            Held-out validation images with ground truth labels.
          </p>

          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              gap: '6px',
              maxHeight: '260px',
              overflowY: 'auto',
              paddingRight: '4px',
            }}
          >
            {samples.map((s) => {
              const isSelected = selectedSample?.id === s.id;
              return (
                <div
                  key={s.id}
                  onClick={() => handleSelectSample(s)}
                  style={{
                    padding: '10px 12px',
                    borderRadius: 'var(--radius-nested)',
                    backgroundColor: isSelected ? 'rgba(15, 118, 110, 0.08)' : 'var(--paper)',
                    border: isSelected ? '1.5px solid var(--teal)' : '1px solid var(--hairline)',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    transition: 'all 150ms ease',
                  }}
                >
                  <div>
                    <div
                      style={{
                        fontSize: '13px',
                        fontWeight: 500,
                        color: isSelected ? 'var(--teal)' : 'var(--ink)',
                      }}
                    >
                      {s.name}
                    </div>
                    <div style={{ fontSize: '11px', color: 'var(--mid-gray)' }}>
                      {s.gradeLabel}
                    </div>
                  </div>
                  <span className={s.groundTruthGrade >= 2 ? 'badge-amber' : 'badge-teal'}>
                    Grade {s.groundTruthGrade}
                  </span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Upload Custom Photograph */}
        <div
          style={{
            border: '1.5px dashed var(--hairline)',
            borderRadius: 'var(--radius-nested)',
            padding: '20px 16px',
            textAlign: 'center',
            backgroundColor: 'var(--paper)',
          }}
        >
          <input
            type="file"
            id="fundus-upload"
            accept="image/*"
            style={{ display: 'none' }}
            onChange={handleFileChange}
          />
          <label htmlFor="fundus-upload" style={{ cursor: 'pointer', display: 'block' }}>
            <Upload size={20} color="var(--mid-gray)" style={{ margin: '0 auto 8px' }} />
            <div style={{ fontSize: '13px', fontWeight: 500, color: 'var(--ink)', marginBottom: '4px' }}>
              Upload a fundus photograph
            </div>
            <div style={{ fontSize: '11px', color: 'var(--mid-gray)' }}>
              .jpg .png .tif (IDRiD / Messidor-2 format)
            </div>
            {selectedFile && (
              <div
                style={{
                  marginTop: '8px',
                  fontSize: '11px',
                  color: 'var(--teal)',
                  fontFamily: 'var(--font-mono)',
                  fontWeight: 500,
                }}
              >
                Selected: {selectedFile.name}
              </div>
            )}
          </label>
        </div>

        {/* Primary Run Button */}
        <button
          type="button"
          onClick={handleExecuteScreening}
          disabled={loading || (!selectedSample && !selectedFile)}
          className="btn-primary"
          style={{
            width: '100%',
            padding: '12px',
            fontSize: '14px',
            marginTop: 'auto',
            opacity: loading || (!selectedSample && !selectedFile) ? 0.6 : 1,
            cursor: loading || (!selectedSample && !selectedFile) ? 'not-allowed' : 'pointer',
          }}
        >
          {loading ? (
            <>
              <RefreshCw size={16} style={{ animation: 'spin 1s linear infinite' }} />
              Running pipeline...
            </>
          ) : (
            <>
              Run screening
              <ChevronRight size={16} />
            </>
          )}
        </button>
      </div>

      {/* ----------------- CENTER PANEL: IMAGE VIEWER ----------------- */}
      <div
        style={{
          padding: '24px',
          display: 'flex',
          flexDirection: 'column',
          gap: '16px',
          backgroundColor: 'var(--canvas)',
        }}
      >
        {/* Tab Switcher Header */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <div style={{ display: 'flex', gap: '8px' }}>
            <button
              type="button"
              onClick={() => setActiveImageView('raw')}
              style={{
                padding: '6px 14px',
                fontSize: '12px',
                fontWeight: 500,
                borderRadius: 'var(--radius-input)',
                border: activeImageView === 'raw' ? '1px solid var(--ink)' : '1px solid var(--hairline)',
                backgroundColor: activeImageView === 'raw' ? 'var(--ink)' : 'var(--paper)',
                color: activeImageView === 'raw' ? 'var(--paper)' : 'var(--mid-gray)',
                cursor: 'pointer',
              }}
            >
              Raw input
            </button>
            <button
              type="button"
              onClick={() => setActiveImageView('enhanced')}
              style={{
                padding: '6px 14px',
                fontSize: '12px',
                fontWeight: 500,
                borderRadius: 'var(--radius-input)',
                border: activeImageView === 'enhanced' ? '1px solid var(--ink)' : '1px solid var(--hairline)',
                backgroundColor: activeImageView === 'enhanced' ? 'var(--ink)' : 'var(--paper)',
                color: activeImageView === 'enhanced' ? 'var(--paper)' : 'var(--mid-gray)',
                cursor: 'pointer',
              }}
            >
              CLAHE enhanced
            </button>
            <button
              type="button"
              onClick={() => setActiveImageView('heatmap')}
              style={{
                padding: '6px 14px',
                fontSize: '12px',
                fontWeight: 500,
                borderRadius: 'var(--radius-input)',
                border: activeImageView === 'heatmap' ? '1px solid var(--ink)' : '1px solid var(--hairline)',
                backgroundColor: activeImageView === 'heatmap' ? 'var(--ink)' : 'var(--paper)',
                color: activeImageView === 'heatmap' ? 'var(--paper)' : 'var(--mid-gray)',
                cursor: 'pointer',
              }}
            >
              Saliency map
            </button>
          </div>

          {result && (
            <span className="badge-teal">
              Quality Gate Passed ({result.stage1Quality.overallScore}/100)
            </span>
          )}
        </div>

        {/* Viewport Display Area */}
        <div
          style={{
            flex: 1,
            backgroundColor: '#0a0a0a',
            borderRadius: 'var(--radius-nested)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            overflow: 'hidden',
            position: 'relative',
            minHeight: '440px',
          }}
        >
          {currentDisplayImage ? (
            <img
              src={currentDisplayImage}
              alt="Fundus view"
              style={{
                maxWidth: '100%',
                maxHeight: '100%',
                objectFit: 'contain',
                display: 'block',
              }}
            />
          ) : (
            <div style={{ textAlign: 'center', color: '#737373', fontSize: '13px' }}>
              <ImageIcon size={32} style={{ margin: '0 auto 12px', opacity: 0.5 }} />
              <div>Select or upload an image to begin.</div>
            </div>
          )}

          {activeImageView === 'heatmap' && result && (
            <div
              style={{
                position: 'absolute',
                bottom: '12px',
                left: '12px',
                backgroundColor: 'rgba(10, 10, 10, 0.85)',
                border: '1px solid rgba(229, 229, 229, 0.2)',
                borderRadius: 'var(--radius-badge)',
                padding: '4px 8px',
                fontSize: '11px',
                fontFamily: 'var(--font-mono)',
                color: '#ffffff',
              }}
            >
              Grad-CAM lesion evidence overlay
            </div>
          )}
        </div>
      </div>

      {/* ----------------- RIGHT PANEL: DIAGNOSTIC RESULTS ----------------- */}
      <div
        style={{
          borderLeft: '1px solid var(--hairline)',
          backgroundColor: 'var(--surface-alt)',
          padding: '24px',
          display: 'flex',
          flexDirection: 'column',
          gap: '16px',
          overflowY: 'auto',
        }}
      >
        <div className="caption">Diagnostic Results</div>

        {!result ? (
          <div
            style={{
              padding: '32px 16px',
              textAlign: 'center',
              color: 'var(--mid-gray)',
              fontSize: '13px',
              backgroundColor: 'var(--paper)',
              borderRadius: 'var(--radius-nested)',
              border: '1px solid var(--hairline)',
            }}
          >
            Run screening to generate Stage 1–5 findings.
          </div>
        ) : (
          <>
            {/* Stage 1: Quality Gate */}
            <div
              style={{
                backgroundColor: 'var(--paper)',
                border: '1px solid var(--hairline)',
                borderRadius: 'var(--radius-nested)',
                padding: '16px',
              }}
            >
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'baseline',
                  marginBottom: '10px',
                }}
              >
                <span className="caption">Stage 1 · Quality Gate</span>
                <span
                  style={{
                    fontSize: '16px',
                    fontWeight: 600,
                    color: result.stage1Quality.isGood ? 'var(--teal)' : 'var(--amber)',
                  }}
                >
                  {result.stage1Quality.overallScore} / 100
                </span>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', fontSize: '12px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--mid-gray)' }}>Sharpness (Laplacian var)</span>
                  <span style={{ fontFamily: 'var(--font-mono)' }}>
                    {result.stage1Quality.blurScore} {result.stage1Quality.blurPassed ? '✓' : '✗'}
                  </span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--mid-gray)' }}>Illumination Mean</span>
                  <span style={{ fontFamily: 'var(--font-mono)' }}>
                    {result.stage1Quality.illumScore} {result.stage1Quality.illumPassed ? '✓' : '✗'}
                  </span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: 'var(--mid-gray)' }}>Field of View (FOV)</span>
                  <span style={{ fontFamily: 'var(--font-mono)' }}>
                    {result.stage1Quality.fovScore}% {result.stage1Quality.fovPassed ? '✓' : '✗'}
                  </span>
                </div>
              </div>
            </div>

            {/* Stage 3: Lesion Biomarkers Breakdown */}
            <div
              style={{
                backgroundColor: 'var(--paper)',
                border: '1px solid var(--hairline)',
                borderRadius: 'var(--radius-nested)',
                padding: '16px',
              }}
            >
              <div className="caption" style={{ marginBottom: '10px' }}>
                Stage 3 · Quantitative Lesion Phenotyping
              </div>

              {/* Granular Biomarker 4-Grid */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', marginBottom: '12px' }}>
                <div
                  style={{
                    backgroundColor: 'var(--surface-alt)',
                    padding: '8px 10px',
                    borderRadius: '6px',
                    border: '1px solid var(--hairline)',
                  }}
                >
                  <div style={{ fontSize: '11px', color: 'var(--mid-gray)' }}>Microaneurysms (MAs)</div>
                  <div style={{ fontSize: '17px', fontWeight: 600, color: 'var(--ink)' }}>
                    {result.stage3Segmentation.microaneurysmCount ?? 0}
                  </div>
                </div>
                <div
                  style={{
                    backgroundColor: 'var(--surface-alt)',
                    padding: '8px 10px',
                    borderRadius: '6px',
                    border: '1px solid var(--hairline)',
                  }}
                >
                  <div style={{ fontSize: '11px', color: 'var(--mid-gray)' }}>Hemorrhages (Blot/Flame)</div>
                  <div style={{ fontSize: '17px', fontWeight: 600, color: '#dc2626' }}>
                    {result.stage3Segmentation.hemorrhageCount ?? result.stage3Segmentation.darkLesionCount}
                  </div>
                </div>
                <div
                  style={{
                    backgroundColor: 'var(--surface-alt)',
                    padding: '8px 10px',
                    borderRadius: '6px',
                    border: '1px solid var(--hairline)',
                  }}
                >
                  <div style={{ fontSize: '11px', color: 'var(--mid-gray)' }}>Hard Exudates</div>
                  <div style={{ fontSize: '17px', fontWeight: 600, color: 'var(--amber)' }}>
                    {result.stage3Segmentation.hardExudateCount ?? result.stage3Segmentation.brightExudateCount}
                  </div>
                </div>
                <div
                  style={{
                    backgroundColor: 'var(--surface-alt)',
                    padding: '8px 10px',
                    borderRadius: '6px',
                    border: '1px solid var(--hairline)',
                  }}
                >
                  <div style={{ fontSize: '11px', color: 'var(--mid-gray)' }}>Cotton-Wool Spots</div>
                  <div style={{ fontSize: '17px', fontWeight: 600, color: 'var(--ink)' }}>
                    {result.stage3Segmentation.cottonWoolCount ?? 0}
                  </div>
                </div>
              </div>

              {/* Neovascularization flag if present */}
              {(result.stage3Segmentation.neovascularCount ?? 0) > 0 && (
                <div
                  style={{
                    backgroundColor: 'rgba(220, 38, 38, 0.08)',
                    border: '1px solid rgba(220, 38, 38, 0.3)',
                    borderRadius: '4px',
                    padding: '6px 8px',
                    marginBottom: '10px',
                    fontSize: '11px',
                    color: '#dc2626',
                    fontWeight: 500,
                  }}
                >
                  ⚠ Proliferative Neovascular Fronds: {result.stage3Segmentation.neovascularCount} detected
                </div>
              )}

              {/* 4-Quadrant ETDRS Distribution */}
              {result.stage3Segmentation.quadrantHemorrhages && (
                <div style={{ marginBottom: '10px', padding: '8px', backgroundColor: 'var(--surface-alt)', borderRadius: '6px' }}>
                  <div style={{ fontSize: '11px', color: 'var(--mid-gray)', marginBottom: '4px' }}>
                    ETDRS 4-Quadrant Hemorrhages [ST, SN, IT, IN]:
                  </div>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: '12px', fontWeight: 600, color: 'var(--ink)' }}>
                    [{result.stage3Segmentation.quadrantHemorrhages.join(', ')}]
                  </div>
                </div>
              )}

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px' }}>
                <span style={{ color: 'var(--mid-gray)' }}>Vessel Density</span>
                <span style={{ fontFamily: 'var(--font-mono)' }}>
                  {result.stage3Segmentation.vesselDensityPercent}%
                </span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginTop: '4px' }}>
                <span style={{ color: 'var(--mid-gray)' }}>Cup-to-Disc Ratio (CDR)</span>
                <span style={{ fontFamily: 'var(--font-mono)' }}>
                  {result.stage3Segmentation.cupToDiscRatio}
                </span>
              </div>
            </div>

            {/* Stage 4: DR Grade */}
            <div
              style={{
                backgroundColor: 'var(--paper)',
                border: '1px solid var(--hairline)',
                borderRadius: 'var(--radius-nested)',
                padding: '16px',
              }}
            >
              <div className="caption" style={{ marginBottom: '6px' }}>
                Stage 4 · DR Grade
              </div>
              <div style={{ fontSize: '16px', fontWeight: 600, color: 'var(--ink)', marginBottom: '4px' }}>
                {result.stage4Grading.gradeName}
              </div>
              <div style={{ fontSize: '12px', color: 'var(--mid-gray)', marginBottom: '10px' }}>
                ICD-10: <span style={{ fontFamily: 'var(--font-mono)' }}>{result.stage4Grading.icd10Code}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '8px' }}>
                <span style={{ color: 'var(--mid-gray)' }}>AI Confidence</span>
                <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 600, color: 'var(--teal)' }}>
                  {(result.stage4Grading.confidence * 100).toFixed(1)}%
                </span>
              </div>
              <div
                style={{
                  fontSize: '11px',
                  color: 'var(--ink-soft)',
                  backgroundColor: 'var(--surface-alt)',
                  padding: '6px 8px',
                  borderRadius: '4px',
                }}
              >
                {result.stage4Grading.urgency}
              </div>
            </div>

            {/* Stage 5: Routing Decision */}
            <div
              style={{
                backgroundColor: 'var(--paper)',
                border: '1px solid var(--hairline)',
                borderRadius: 'var(--radius-nested)',
                padding: '16px',
              }}
            >
              <div className="caption" style={{ marginBottom: '8px' }}>
                Stage 5 · Routing Decision
              </div>
              <div style={{ marginBottom: '6px' }}>
                <span
                  className={
                    result.routing.decision === 'AUTO_CLEAR'
                      ? 'badge-teal'
                      : result.routing.decision === 'DOCTOR_REVIEW'
                      ? 'badge-amber'
                      : 'badge-neutral'
                  }
                >
                  {result.routing.decision.replace('_', ' ')}
                </span>
              </div>
              <p style={{ fontSize: '12px', color: 'var(--mid-gray)', lineHeight: 1.4 }}>
                {result.routing.reason}
              </p>
            </div>
          </>
        )}
      </div>
    </div>
  );
};
