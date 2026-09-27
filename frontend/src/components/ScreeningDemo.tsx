import React, { useState } from 'react';

type ViewMode = 'original' | 'enhanced' | 'vessels' | 'gradcam';

const VIEW_TABS: { key: ViewMode; label: string }[] = [
  { key: 'original', label: 'Raw input' },
  { key: 'enhanced', label: 'CLAHE enhanced' },
  { key: 'vessels', label: 'Vessel map' },
  { key: 'gradcam', label: 'Saliency map' },
];

const EVIDENCE = [
  { label: 'Microaneurysms', count: '4 regions', flag: 'amber' },
  { label: 'Hemorrhages', count: '2 regions', flag: 'amber' },
  { label: 'Exudates', count: 'Low to moderate', flag: 'amber' },
  { label: 'Neovascularization', count: 'None detected', flag: 'teal' },
];

const PROBS = [
  { label: 'Grade 0 (None)', pct: 2 },
  { label: 'Grade 1 (Mild)', pct: 5 },
  { label: 'Grade 2 (Moderate)', pct: 86, active: true },
  { label: 'Grade 3 (Severe)', pct: 5 },
  { label: 'Grade 4 (Proliferative)', pct: 2 },
];

interface ScreeningDemoProps {
  onLaunch: () => void;
}

export const ScreeningDemo: React.FC<ScreeningDemoProps> = ({ onLaunch }) => {
  const [view, setView] = useState<ViewMode>('enhanced');

  return (
    <section style={{ backgroundColor: 'var(--canvas)', padding: '80px 0' }}>
      <div className="section-container">
        {/* Section Header */}
        <div style={{ marginBottom: '40px', maxWidth: '640px' }}>
          <div className="caption" style={{ marginBottom: '12px' }}>
            Diagnostic Workbench
          </div>
          <h2 className="heading-lg" style={{ marginBottom: '16px' }}>
            Run the pipeline on a real fundus photograph.
          </h2>
          <p className="body-lg">
            Select an image from the IDRiD held-out test set, or upload your own. Results include quality metrics, lesion counts, grade with per-class probabilities, and a saliency map.
          </p>
        </div>

        {/* Console 3-Panel Card */}
        <div
          className="clinical-card"
          style={{
            display: 'grid',
            gridTemplateColumns: '240px minmax(0, 1.3fr) 280px',
            gap: '24px',
            padding: '24px',
          }}
        >
          {/* Left: Patient Metadata & Quality */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div className="caption">Examination Details</div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '13px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '6px', borderBottom: '1px solid var(--hairline)' }}>
                <span style={{ color: 'var(--mid-gray)' }}>Case ID</span>
                <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 600, color: 'var(--ink)' }}>VAL-003</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '6px', borderBottom: '1px solid var(--hairline)' }}>
                <span style={{ color: 'var(--mid-gray)' }}>Patient Age</span>
                <span style={{ color: 'var(--ink)' }}>58</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '6px', borderBottom: '1px solid var(--hairline)' }}>
                <span style={{ color: 'var(--mid-gray)' }}>Laterality</span>
                <span style={{ color: 'var(--ink)' }}>Right Eye (OD)</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '6px', borderBottom: '1px solid var(--hairline)' }}>
                <span style={{ color: 'var(--mid-gray)' }}>Source Set</span>
                <span style={{ color: 'var(--ink)' }}>IDRiD Test Split</span>
              </div>
            </div>

            <div style={{ marginTop: 'auto', backgroundColor: 'var(--surface-alt)', padding: '12px', borderRadius: 'var(--radius-nested)', border: '1px solid var(--hairline)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '6px' }}>
                <span style={{ color: 'var(--mid-gray)' }}>Quality Gate</span>
                <span style={{ fontWeight: 600, color: 'var(--teal)', fontFamily: 'var(--font-mono)' }}>91.9 / 100</span>
              </div>
              <div style={{ height: '4px', backgroundColor: 'var(--hairline)', borderRadius: '2px', overflow: 'hidden' }}>
                <div style={{ width: '91.9%', height: '100%', backgroundColor: 'var(--teal)' }} />
              </div>
              <div style={{ fontSize: '11px', color: 'var(--teal)', marginTop: '6px' }}>
                Pass: Sharpness & FOV verified
              </div>
            </div>
          </div>

          {/* Center: Retinal Viewport */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--ink)' }}>
                Fundus Viewport
              </span>
              <div style={{ display: 'flex', gap: '6px' }}>
                {VIEW_TABS.map((t) => (
                  <button
                    key={t.key}
                    type="button"
                    onClick={() => setView(t.key)}
                    style={{
                      padding: '4px 10px',
                      fontSize: '11px',
                      fontWeight: 500,
                      borderRadius: 'var(--radius-badge)',
                      border: view === t.key ? '1px solid var(--ink)' : '1px solid var(--hairline)',
                      backgroundColor: view === t.key ? 'var(--ink)' : 'var(--surface-alt)',
                      color: view === t.key ? 'var(--paper)' : 'var(--mid-gray)',
                      cursor: 'pointer',
                    }}
                  >
                    {t.label}
                  </button>
                ))}
              </div>
            </div>

            <div
              style={{
                flex: 1,
                minHeight: '340px',
                borderRadius: 'var(--radius-nested)',
                backgroundColor: '#0a0a0a',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                overflow: 'hidden',
                position: 'relative',
              }}
            >
              <svg viewBox="0 0 400 300" style={{ width: '100%', height: '100%' }}>
                <circle cx="200" cy="150" r="130" fill="#1b0e06" stroke="#381b0d" strokeWidth="2" />
                <circle cx="270" cy="150" r="26" fill="#f59e0b" opacity="0.8" />
                <circle cx="270" cy="150" r="13" fill="#fef08a" opacity="0.9" />

                {/* Vessels */}
                <path d="M 270 150 Q 230 75 150 70 Q 100 65 75 80" fill="none" stroke="#4a150c" strokeWidth="3" />
                <path d="M 270 150 Q 230 225 150 230 Q 100 235 75 220" fill="none" stroke="#4a150c" strokeWidth="3" />

                {view === 'gradcam' && (
                  <>
                    <ellipse cx="165" cy="145" rx="45" ry="30" fill="rgba(180, 83, 9, 0.4)" />
                    <circle cx="165" cy="145" r="15" fill="rgba(180, 83, 9, 0.6)" />
                  </>
                )}

                {/* Lesions */}
                <circle cx="160" cy="140" r="3" fill="#b45309" />
                <circle cx="170" cy="150" r="2.5" fill="#b45309" />
                <circle cx="150" cy="155" r="3" fill="#b45309" />
              </svg>

              <div
                style={{
                  position: 'absolute',
                  bottom: '10px',
                  left: '10px',
                  backgroundColor: 'rgba(10, 10, 10, 0.85)',
                  padding: '3px 8px',
                  borderRadius: 'var(--radius-badge)',
                  fontSize: '11px',
                  fontFamily: 'var(--font-mono)',
                  color: '#ffffff',
                }}
              >
                {view === 'original' && 'Raw 24-bit fundus capture'}
                {view === 'enhanced' && 'Rayleigh Green-CLAHE'}
                {view === 'vessels' && 'Vessel segmentation density: 38.4%'}
                {view === 'gradcam' && 'Grad-CAM attention: Macular Arcade'}
              </div>
            </div>
          </div>

          {/* Right: Pathological Findings & Referral Action */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <div className="caption" style={{ marginBottom: '6px' }}>
                Classification
              </div>
              <div style={{ fontSize: '18px', fontWeight: 600, color: 'var(--amber)', marginBottom: '2px' }}>
                Moderate NPDR (Grade 2)
              </div>
              <div style={{ fontSize: '11px', fontFamily: 'var(--font-mono)', color: 'var(--mid-gray)' }}>
                ICD-10: E11.329 · Conf: 86.0%
              </div>
            </div>

            {/* Probability Bars */}
            <div>
              <div style={{ fontSize: '11px', fontWeight: 500, color: 'var(--mid-gray)', marginBottom: '6px' }}>
                Probability distribution
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                {PROBS.map((p) => (
                  <div key={p.label}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', marginBottom: '2px' }}>
                      <span style={{ color: p.active ? 'var(--ink)' : 'var(--mid-gray)', fontWeight: p.active ? 600 : 400 }}>
                        {p.label}
                      </span>
                      <span style={{ fontFamily: 'var(--font-mono)', color: p.active ? 'var(--amber)' : 'var(--mid-gray)' }}>
                        {p.pct}%
                      </span>
                    </div>
                    <div style={{ height: '3px', backgroundColor: 'var(--hairline)', borderRadius: '2px', overflow: 'hidden' }}>
                      <div style={{ width: `${p.pct}%`, height: '100%', backgroundColor: p.active ? 'var(--amber)' : 'var(--hairline)' }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Evidence summary */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
              <div style={{ fontSize: '11px', fontWeight: 500, color: 'var(--mid-gray)' }}>
                Detected lesions
              </div>
              {EVIDENCE.map((item) => (
                <div
                  key={item.label}
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    fontSize: '11px',
                    padding: '4px 8px',
                    backgroundColor: 'var(--surface-alt)',
                    borderRadius: '4px',
                  }}
                >
                  <span style={{ color: 'var(--ink-soft)' }}>{item.label}</span>
                  <span style={{ fontWeight: 500, color: item.flag === 'amber' ? 'var(--amber)' : 'var(--teal)' }}>
                    {item.count}
                  </span>
                </div>
              ))}
            </div>

            {/* Launch Full Workspace Button */}
            <button
              type="button"
              onClick={onLaunch}
              className="btn-primary"
              style={{ width: '100%', padding: '10px', fontSize: '13px', marginTop: 'auto' }}
            >
              Open Screening Studio
            </button>
          </div>
        </div>
      </div>
    </section>
  );
};
