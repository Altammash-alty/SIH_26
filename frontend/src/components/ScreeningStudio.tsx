import { useState, useEffect } from 'react';
import { 
  Upload, 
  RefreshCw, 
  ChevronRight,
  Image as ImageIcon
} from 'lucide-react';

interface SampleItem {
  id: string;
  name: string;
  source: string;
  groundTruthGrade: number;
  gradeLabel: string;
  path: string;
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

  // Load sample dataset list on mount
  useEffect(() => {
    fetch('/api/samples')
      .then(r => r.json())
      .then(data => {
        if (data.samples && data.samples.length > 0) {
          setSamples(data.samples);
          setSelectedSample(data.samples[0]);
          setPreviewUrl(data.samples[0].path);
        }
      })
      .catch(err => console.error("Failed to fetch samples:", err));
  }, []);

  const handleSelectSample = (sample: SampleItem) => {
    setSelectedSample(sample);
    setSelectedFile(null);
    setPreviewUrl(sample.path);
    setResult(null);
  };

  const handleFileDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const f = e.dataTransfer.files[0];
      setSelectedFile(f);
      setSelectedSample(null);
      setPreviewUrl(URL.createObjectURL(f));
      setResult(null);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const f = e.target.files[0];
      setSelectedFile(f);
      setSelectedSample(null);
      setPreviewUrl(URL.createObjectURL(f));
      setResult(null);
    }
  };

  const handleExecuteScreening = async () => {
    setLoading(true);
    try {
      const formData = new FormData();
      if (selectedFile) {
        formData.append('file', selectedFile);
      } else if (selectedSample) {
        formData.append('sampleFilename', selectedSample.name);
      } else {
        alert("Please select or upload a fundus photograph.");
        setLoading(false);
        return;
      }

      formData.append('patientId', selectedSample ? `IDRiD-${selectedSample.name.replace('.jpg','')}` : 'PAT-2026-LIVE');
      formData.append('patientAge', '59');
      formData.append('patientGender', 'F');
      formData.append('eyeLaterality', 'OD (Right Eye)');

      const res = await fetch('/api/screen', {
        method: 'POST',
        body: formData
      });

      if (!res.ok) {
        throw new Error(`Screening failed: ${res.statusText}`);
      }

      const data: ScreeningResult = await res.json();
      setResult(data);
    } catch (err: any) {
      console.error(err);
      alert(`Screening execution error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const getRoutingColor = (dec: string) => {
    switch (dec) {
      case 'AUTO_CLEAR': return 'var(--emerald-400)';
      case 'DOCTOR_REVIEW': return 'var(--amber-400)';
      case 'OOD_FLAG': return 'var(--rose-400)';
      case 'RETAKE': return 'var(--rose-400)';
      default: return 'var(--cyan-400)';
    }
  };

  return (
    <div style={{ maxWidth: '1400px', margin: '0 auto', padding: '2rem' }}>
      
      {/* Studio Header */}
      <div style={{ marginBottom: '2rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
          <span className="badge badge-info">DIAGNOSTIC WORKBENCH</span>
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
            Real-Time 5-Stage Autonomous Screening
          </span>
        </div>
        <h2 style={{ fontSize: '2.2rem', fontWeight: 800, letterSpacing: '-0.02em' }}>
          Clinical Screening Studio
        </h2>
        <p style={{ color: 'var(--text-secondary)' }}>
          Inspect fundus photographs across Quality Gate, CLAHE enhancement, segmentation, 5-class ICDR severity, and explainability heatmaps.
        </p>
      </div>

      <div style={{
        display: 'grid',
        gridTemplateColumns: '380px 1fr',
        gap: '2rem',
        alignItems: 'start'
      }}>
        
        {/* Left Column: Image Selection & Uploader */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          
          {/* Dataset Sample Selector */}
          <div className="glass-panel" style={{ padding: '1.5rem' }}>
            <h3 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <ImageIcon size={18} color="var(--cyan-400)" />
              1. Choose Real Dataset Sample
            </h3>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', maxHeight: '260px', overflowY: 'auto' }}>
              {samples.map((s) => {
                const isSelected = selectedSample?.id === s.id;
                return (
                  <div
                    key={s.id}
                    onClick={() => handleSelectSample(s)}
                    style={{
                      padding: '10px 12px',
                      borderRadius: 'var(--radius-md)',
                      background: isSelected ? 'rgba(56, 189, 248, 0.15)' : 'rgba(255, 255, 255, 0.03)',
                      border: isSelected ? '1px solid var(--cyan-400)' : '1px solid var(--border-subtle)',
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      transition: 'all 0.15s ease'
                    }}
                  >
                    <div>
                      <div style={{ fontSize: '0.85rem', fontWeight: 700, color: isSelected ? 'var(--cyan-400)' : '#ffffff' }}>
                        {s.name}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                        {s.gradeLabel}
                      </div>
                    </div>
                    <span className="badge" style={{
                      fontSize: '0.65rem',
                      background: 'rgba(255, 255, 255, 0.08)',
                      borderColor: 'var(--border-subtle)'
                    }}>
                      G{s.groundTruthGrade}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Drag and Drop Uploader */}
          <div 
            className="glass-panel"
            style={{
              padding: '1.75rem',
              borderStyle: 'dashed',
              borderWidth: '2px',
              borderColor: selectedFile ? 'var(--cyan-400)' : 'rgba(255, 255, 255, 0.15)',
              textAlign: 'center',
              cursor: 'pointer'
            }}
            onDragOver={(e) => e.preventDefault()}
            onDrop={handleFileDrop}
          >
            <input 
              type="file" 
              id="fundus-upload" 
              accept="image/*" 
              style={{ display: 'none' }}
              onChange={handleFileChange}
            />
            <label htmlFor="fundus-upload" style={{ cursor: 'pointer', display: 'block' }}>
              <div style={{
                width: '48px',
                height: '48px',
                borderRadius: '50%',
                background: 'rgba(56, 189, 248, 0.1)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                margin: '0 auto 12px'
              }}>
                <Upload size={22} color="var(--cyan-400)" />
              </div>
              <h4 style={{ fontSize: '0.95rem', fontWeight: 700, marginBottom: '4px' }}>
                Or Upload Fundus Photograph
              </h4>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '8px' }}>
                Drag & drop .jpg, .png, .tif (IDRiD / Messidor-2 supported)
              </p>
              {selectedFile && (
                <div style={{ fontSize: '0.8rem', color: 'var(--emerald-400)', fontWeight: 600 }}>
                  Selected: {selectedFile.name}
                </div>
              )}
            </label>
          </div>

          {/* Action Trigger Button */}
          <button
            onClick={handleExecuteScreening}
            disabled={loading || (!selectedSample && !selectedFile)}
            style={{
              background: 'linear-gradient(135deg, var(--cyan-500), #2563eb)',
              color: '#ffffff',
              border: 'none',
              padding: '16px',
              borderRadius: 'var(--radius-md)',
              fontSize: '1rem',
              fontWeight: 700,
              cursor: loading ? 'not-allowed' : 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '10px',
              boxShadow: '0 8px 25px rgba(14, 165, 233, 0.35)',
              opacity: loading ? 0.7 : 1,
              transition: 'transform 0.15s ease'
            }}
          >
            {loading ? (
              <>
                <RefreshCw size={18} className="pulse-glow" />
                Executing Pipeline Stages...
              </>
            ) : (
              <>
                Run 5-Stage Autonomous Screening
                <ChevronRight size={18} />
              </>
            )}
          </button>
        </div>

        {/* Right Column: Visual Inspection & Diagnostic Results */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          
          {/* Main Visual Display Card */}
          <div className="glass-panel" style={{ padding: '1.5rem', position: 'relative' }}>
            
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1rem' }}>
              <div>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 700 }}>
                  Retinal Fundus Optical Viewer
                </h3>
                <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                  {result ? `Patient ID: ${result.patient.id} | Eye: ${result.patient.eye}` : 'Awaiting diagnostic execution'}
                </span>
              </div>

              {/* View Switcher Tabs */}
              {result && (
                <div style={{
                  display: 'flex',
                  gap: '4px',
                  background: 'rgba(0, 0, 0, 0.4)',
                  padding: '4px',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border-subtle)'
                }}>
                  <button
                    onClick={() => setActiveImageView('raw')}
                    style={{
                      padding: '6px 12px',
                      borderRadius: '6px',
                      fontSize: '0.75rem',
                      fontWeight: 600,
                      background: activeImageView === 'raw' ? 'var(--bg-surface-hover)' : 'transparent',
                      color: activeImageView === 'raw' ? 'var(--cyan-400)' : 'var(--text-secondary)',
                      border: 'none',
                      cursor: 'pointer'
                    }}
                  >
                    Raw Input
                  </button>

                  <button
                    onClick={() => setActiveImageView('enhanced')}
                    style={{
                      padding: '6px 12px',
                      borderRadius: '6px',
                      fontSize: '0.75rem',
                      fontWeight: 600,
                      background: activeImageView === 'enhanced' ? 'var(--bg-surface-hover)' : 'transparent',
                      color: activeImageView === 'enhanced' ? 'var(--cyan-400)' : 'var(--text-secondary)',
                      border: 'none',
                      cursor: 'pointer'
                    }}
                  >
                    Stage 2 CLAHE
                  </button>

                  <button
                    onClick={() => setActiveImageView('heatmap')}
                    style={{
                      padding: '6px 12px',
                      borderRadius: '6px',
                      fontSize: '0.75rem',
                      fontWeight: 600,
                      background: activeImageView === 'heatmap' ? 'var(--bg-surface-hover)' : 'transparent',
                      color: activeImageView === 'heatmap' ? 'var(--cyan-400)' : 'var(--text-secondary)',
                      border: 'none',
                      cursor: 'pointer'
                    }}
                  >
                    Stage 5 Heatmap
                  </button>
                </div>
              )}
            </div>

            {/* Viewport Area */}
            <div style={{
              width: '100%',
              height: '460px',
              borderRadius: 'var(--radius-md)',
              background: '#040711',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              overflow: 'hidden',
              position: 'relative',
              border: '1px solid var(--border-subtle)'
            }}>
              {previewUrl ? (
                <img 
                  src={
                    result 
                      ? (activeImageView === 'raw' ? result.images.raw : (activeImageView === 'enhanced' ? result.images.enhanced : result.images.heatmap))
                      : previewUrl
                  } 
                  alt="Fundus photograph" 
                  style={{ maxHeight: '100%', maxWidth: '100%', objectFit: 'contain' }}
                />
              ) : (
                <div style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                  No fundus image selected
                </div>
              )}

              {/* Live Overlay Badges */}
              {result && (
                <div style={{
                  position: 'absolute',
                  top: '16px',
                  left: '16px',
                  display: 'flex',
                  gap: '8px'
                }}>
                  <span className={`badge ${result.stage1Quality.isGood ? 'badge-pass' : 'badge-danger'}`}>
                    Quality: {result.stage1Quality.overallScore}/100
                  </span>
                  <span className="badge badge-info">
                    CDR: {result.stage3Segmentation.cupToDiscRatio}
                  </span>
                  <span className="badge badge-info">
                    Vessels: {result.stage3Segmentation.vesselDensityPercent}%
                  </span>
                </div>
              )}
            </div>
          </div>

          {result && result.routing.decision === 'RETAKE' && (
            <div className="glass-panel" style={{
              padding: '1rem 1.25rem',
              borderColor: 'rgba(248, 113, 113, 0.6)',
              background: 'rgba(127, 29, 29, 0.22)',
              boxShadow: '0 0 0 1px rgba(248, 113, 113, 0.08)'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px', flexWrap: 'wrap' }}>
                <div>
                  <div style={{ fontSize: '0.72rem', letterSpacing: '0.12em', textTransform: 'uppercase', color: 'var(--rose-400)', fontWeight: 800 }}>
                    Retake Required
                  </div>
                  <div style={{ fontSize: '1.05rem', fontWeight: 700, color: 'var(--text-primary)', marginTop: '4px' }}>
                    Please upload a new fundus image with better focus, illumination, and field-of-view.
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => { setResult(null); setPreviewUrl(selectedFile ? URL.createObjectURL(selectedFile) : (selectedSample ? selectedSample.path : null)); }}
                  style={{
                    background: 'rgba(248, 113, 113, 0.12)',
                    color: 'var(--rose-400)',
                    border: '1px solid rgba(248, 113, 113, 0.35)',
                    borderRadius: '10px',
                    padding: '10px 14px',
                    fontWeight: 700,
                    cursor: 'pointer'
                  }}
                >
                  Re-upload Image
                </button>
              </div>
            </div>
          )}

          {/* Diagnostic Findings Grid */}
          {result && (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1.25rem' }}>
              
              {/* Card 1: Stage 4 AI Diagnosis & DME */}
              <div className="glass-panel" style={{ padding: '1.5rem' }}>
                <span className="badge badge-info" style={{ marginBottom: '8px' }}>
                  STAGE 4 AI CLASSIFICATION
                </span>
                <div style={{ fontSize: '1.4rem', fontWeight: 800, marginTop: '4px' }}>
                  {result.stage4Grading.gradeName}
                </div>
                <div style={{ fontSize: '0.85rem', color: 'var(--cyan-400)', fontFamily: 'var(--font-mono)', marginTop: '2px' }}>
                  ICD-10: {result.stage4Grading.icd10Code} | Confidence: {(result.stage4Grading.confidence * 100).toFixed(1)}%
                </div>

                <div style={{ marginTop: '1.25rem', padding: '12px', borderRadius: 'var(--radius-sm)', background: 'rgba(0,0,0,0.3)' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>
                    Diabetic Macular Edema (DME) Risk
                  </div>
                  <div style={{ fontSize: '0.95rem', fontWeight: 700, color: result.stage4Grading.dmeRisk.includes('High') ? 'var(--rose-400)' : 'var(--emerald-400)', marginTop: '2px' }}>
                    {result.stage4Grading.dmeRisk}
                  </div>
                </div>

                <div style={{ marginTop: '1rem' }}>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>
                    Clinical Referral Timeline
                  </div>
                  <div style={{ fontSize: '0.9rem', color: 'var(--text-primary)', marginTop: '2px' }}>
                    {result.stage4Grading.urgency}
                  </div>
                </div>
              </div>

              {/* Card 2: Trust & Routing Decision */}
              <div className="glass-panel" style={{ padding: '1.5rem' }}>
                <span className="badge" style={{
                  background: 'rgba(255, 255, 255, 0.08)',
                  color: getRoutingColor(result.routing.decision),
                  marginBottom: '8px'
                }}>
                  TRUST & ROUTING LAYER
                </span>

                <div style={{ 
                  fontSize: '1.4rem', 
                  fontWeight: 800, 
                  color: getRoutingColor(result.routing.decision),
                  marginTop: '4px' 
                }}>
                  [{result.routing.decision}]
                </div>

                <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginTop: '8px', lineHeight: 1.5 }}>
                  {result.routing.reason}
                </p>

                <div style={{ marginTop: '1.25rem', display: 'flex', gap: '16px' }}>
                  <div>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Mahalanobis OOD Dist:</span>
                    <div style={{ fontSize: '1rem', fontWeight: 700, fontFamily: 'var(--font-mono)' }}>
                      {result.routing.mahalanobisDistance} (Cutoff: 3.80)
                    </div>
                  </div>
                  <div>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Distribution Status:</span>
                    <div style={{ fontSize: '1rem', fontWeight: 700, color: result.routing.isTypical ? 'var(--emerald-400)' : 'var(--rose-400)' }}>
                      {result.routing.isTypical ? 'Within Manifold' : 'Atypical OOD'}
                    </div>
                  </div>
                </div>
              </div>

              {/* Card 3: Quantitative Lesions Breakdown */}
              <div className="glass-panel" style={{ padding: '1.25rem' }}>
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>
                  STAGE 3 BIOMARKERS
                </span>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '10px', marginTop: '10px' }}>
                  <div style={{ background: 'rgba(0,0,0,0.3)', padding: '10px', borderRadius: '8px' }}>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Dark Hemorrhages / MAs</span>
                    <div style={{ fontSize: '1.2rem', fontWeight: 800 }}>{result.stage3Segmentation.darkLesionCount}</div>
                  </div>
                  <div style={{ background: 'rgba(0,0,0,0.3)', padding: '10px', borderRadius: '8px' }}>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Bright Exudates</span>
                    <div style={{ fontSize: '1.2rem', fontWeight: 800 }}>{result.stage3Segmentation.brightExudateCount}</div>
                  </div>
                </div>
              </div>

              {/* Card 4: Quality Gate Details */}
              <div className="glass-panel" style={{ padding: '1.25rem' }}>
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>
                  STAGE 1 QUALITY BREAKDOWN
                </span>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '8px', marginTop: '10px' }}>
                  <div style={{ background: 'rgba(0,0,0,0.3)', padding: '8px', borderRadius: '8px', textAlign: 'center' }}>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Sharpness</span>
                    <div style={{ fontSize: '1rem', fontWeight: 700 }}>{result.stage1Quality.blurScore}</div>
                  </div>
                  <div style={{ background: 'rgba(0,0,0,0.3)', padding: '8px', borderRadius: '8px', textAlign: 'center' }}>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Illumination</span>
                    <div style={{ fontSize: '1rem', fontWeight: 700 }}>{result.stage1Quality.illumScore}</div>
                  </div>
                  <div style={{ background: 'rgba(0,0,0,0.3)', padding: '8px', borderRadius: '8px', textAlign: 'center' }}>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>FOV Area</span>
                    <div style={{ fontSize: '1rem', fontWeight: 700 }}>{result.stage1Quality.fovScore}%</div>
                  </div>
                </div>
              </div>

            </div>
          )}

        </div>

      </div>

    </div>
  );
};
