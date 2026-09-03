import { useState } from 'react';
import { FundusViz } from './FundusViz';

type ViewMode = 'original' | 'enhanced' | 'vessels' | 'gradcam' | 'lesions';

const VIEW_TABS: { key: ViewMode; label: string }[] = [
  { key: 'original', label: 'Original' },
  { key: 'enhanced', label: 'Enhanced' },
  { key: 'vessels', label: 'Vessel Map' },
  { key: 'gradcam', label: 'Grad-CAM' },
  { key: 'lesions', label: 'Lesions' },
];

const EVIDENCE = [
  { label: 'Microaneurysms detected', present: true, count: '4 regions', color: '#DC2626' },
  { label: 'Retinal hemorrhage detected', present: true, count: '2 regions', color: '#991B1B' },
  { label: 'Exudates detected', present: true, count: 'Low–moderate', color: '#D97706' },
  { label: 'No neovascularization detected', present: false, count: 'Not found', color: '#16A34A' },
];

export function ScreeningDemo() {
  const [view, setView] = useState<ViewMode>('original');

  const getImageStyle = (): React.CSSProperties => {
    if (view === 'enhanced') {
      return { filter: 'contrast(1.15) brightness(1.05) saturate(0.9)' };
    }
    if (view === 'vessels') {
      return { filter: 'saturate(0.1) contrast(1.8) invert(0.08)' };
    }
    if (view === 'gradcam') {
      return {};
    }
    return {};
  };

  return (
    <section id="platform" style={{ background: 'radial-gradient(circle at top left, rgba(46, 155, 255, 0.08), transparent 32%), var(--bg-secondary)', padding: '72px 0' }}>
      <div className="container-wide">
        {/* Header */}
        <div style={{ marginBottom: 'var(--space-10)' }}>
          <div className="eyebrow eyebrow-blue" style={{ marginBottom: 'var(--space-3)' }}>Interactive Preview</div>
          <h2 style={{ maxWidth: '480px' }}>
            Clinical screening workspace
          </h2>
        </div>

        {/* 3-column layout */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: '220px 1fr 280px',
          gap: 'var(--space-4)',
          alignItems: 'start',
        }}>

          {/* Left: Patient panel */}
          <div className="card" style={{ padding: 'var(--space-5)' }}>
            <div style={{
              fontSize: 'var(--text-xs)', fontWeight: 700, color: 'var(--text-tertiary)',
              textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 'var(--space-4)',
            }}>
              Patient
            </div>

            {[
              { label: 'Screening ID', val: 'RA-02481' },
              { label: 'Age', val: '58' },
              { label: 'Diabetes', val: '12 years' },
              { label: 'Location', val: 'Primary Health Centre' },
              { label: 'Eye', val: 'Right (OD)' },
              { label: 'Date', val: 'Sep 03, 2026' },
            ].map(({ label, val }) => (
              <div key={label} style={{ marginBottom: 'var(--space-3)' }}>
                <div style={{ fontSize: 'var(--text-xs)', color: 'var(--text-tertiary)', marginBottom: '2px' }}>{label}</div>
                <div style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--text-primary)' }}>{val}</div>
              </div>
            ))}

            <hr className="divider" style={{ margin: 'var(--space-4) 0' }}/>

            {/* Quality indicator */}
            <div style={{ marginBottom: 'var(--space-3)' }}>
              <div style={{ fontSize: 'var(--text-xs)', color: 'var(--text-tertiary)', marginBottom: 'var(--space-2)' }}>Image Quality</div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                <span style={{ fontSize: 'var(--text-xs)', fontWeight: 600, color: 'var(--status-success)' }}>Gradeable</span>
                <span style={{ fontSize: 'var(--text-xs)', fontWeight: 700, color: 'var(--text-primary)' }}>91.9</span>
              </div>
              <div className="conf-bar-track">
                <div className="conf-bar-fill" style={{ width: '91.9%', background: 'var(--status-success)' }}/>
              </div>
            </div>

            {/* Quality sub-scores */}
            {[
              { label: 'Sharpness', val: 30.9, max: 50 },
              { label: 'Illumination', val: 76.8, max: 100 },
              { label: 'FOV Coverage', val: 100, max: 100 },
            ].map(({ label, val, max }) => (
              <div key={label} style={{ marginBottom: 'var(--space-2)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '3px' }}>
                  <span style={{ fontSize: '10px', color: 'var(--text-tertiary)' }}>{label}</span>
                  <span style={{ fontSize: '10px', color: 'var(--text-secondary)', fontWeight: 500 }}>{val}</span>
                </div>
                <div className="conf-bar-track">
                  <div className="conf-bar-fill" style={{ width: `${(val / max) * 100}%`, background: 'var(--accent-blue)' }}/>
                </div>
              </div>
            ))}
          </div>

          {/* Center: Image viewer */}
          <div className="card" style={{ overflow: 'hidden' }}>
            {/* View controls */}
            <div style={{
              padding: 'var(--space-4) var(--space-5)',
              borderBottom: '1px solid var(--border-default)',
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            }}>
              <div style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--text-primary)' }}>
                Retinal Image Viewer
              </div>
              <div className="tab-group">
                {VIEW_TABS.map(t => (
                  <button
                    key={t.key}
                    className={`tab-item${view === t.key ? ' active' : ''}`}
                    onClick={() => setView(t.key)}
                  >
                    {t.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Image area */}
            <div style={{
              background: view === 'vessels' ? '#0A1628' : '#0D0404',
              position: 'relative',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              padding: 'var(--space-6)',
              minHeight: '380px',
            }}>
              <div style={{
                width: '340px', height: '340px',
                position: 'relative',
                transition: 'filter 350ms ease',
                ...getImageStyle(),
              }}>
                <FundusViz showGradcam={view === 'gradcam'} />

                {/* Lesion overlays for lesions mode */}
                {view === 'lesions' && (
                  <>
                    {/* MA circles */}
                    {[[58, 46], [61, 49], [56, 53], [68, 46]].map(([x, y], i) => (
                      <div key={i} style={{
                        position: 'absolute', left: `${x}%`, top: `${y}%`,
                        width: '10px', height: '10px', borderRadius: '50%',
                        border: '2px solid #EF4444', transform: 'translate(-50%,-50%)',
                        boxShadow: '0 0 6px rgba(239,68,68,0.5)',
                      }}/>
                    ))}
                    {/* Exudate rings */}
                    {[[62, 55], [64, 56]].map(([x, y], i) => (
                      <div key={i} style={{
                        position: 'absolute', left: `${x}%`, top: `${y}%`,
                        width: '14px', height: '14px', borderRadius: '50%',
                        border: '2px solid #FBBF24', transform: 'translate(-50%,-50%)',
                        boxShadow: '0 0 6px rgba(251,191,36,0.5)',
                      }}/>
                    ))}
                    {/* Labels */}
                    <div style={{ position: 'absolute', left: '52%', top: '38%', background: 'rgba(220,38,38,0.85)', color: 'white', fontSize: '9px', padding: '2px 6px', borderRadius: '3px', fontWeight: 600 }}>
                      Microaneurysm
                    </div>
                    <div style={{ position: 'absolute', left: '70%', top: '48%', background: 'rgba(127,29,29,0.85)', color: 'white', fontSize: '9px', padding: '2px 6px', borderRadius: '3px', fontWeight: 600 }}>
                      Hemorrhage
                    </div>
                    <div style={{ position: 'absolute', left: '58%', top: '62%', background: 'rgba(217,119,6,0.85)', color: 'white', fontSize: '9px', padding: '2px 6px', borderRadius: '3px', fontWeight: 600 }}>
                      Exudate
                    </div>
                  </>
                )}
              </div>

              {/* Mode label */}
              <div style={{
                position: 'absolute', bottom: 'var(--space-4)', left: 'var(--space-5)',
                fontSize: '10px', color: 'rgba(255,255,255,0.5)', fontWeight: 500,
              }}>
                {VIEW_TABS.find(t => t.key === view)?.label} · Patient RA-02481
              </div>
            </div>

            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(4, minmax(0, 1fr))',
              gap: 'var(--space-3)',
              padding: 'var(--space-4) var(--space-5)',
              background: 'linear-gradient(180deg, rgba(14, 26, 39, 0.75), rgba(11, 19, 28, 0.75))',
              borderTop: '1px solid var(--border-default)',
            }}>
              {[
                { label: 'Quality', value: '91.9' },
                { label: 'Sharpness', value: '30.9' },
                { label: 'Illumination', value: '76.8' },
                { label: 'Vessel Density', value: '34.9%' },
              ].map((item) => (
                <div key={item.label} style={{
                  background: 'rgba(148,163,184,0.05)',
                  border: '1px solid var(--border-default)',
                  borderRadius: '10px',
                  padding: '10px 12px',
                }}>
                  <div style={{ fontSize: '10px', color: 'var(--text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '4px' }}>{item.label}</div>
                  <div style={{ fontSize: '15px', fontWeight: 700, color: 'var(--text-primary)' }}>{item.value}</div>
                </div>
              ))}
            </div>

            {/* Inference footer */}
            <div style={{
              padding: 'var(--space-3) var(--space-5)',
              borderTop: '1px solid var(--border-default)',
              display: 'flex', gap: 'var(--space-6)', background: 'var(--bg-subtle)',
            }}>
              {[
                { label: 'Inference', val: '2.3 sec' },
                { label: 'OD CDR', val: '0.25' },
                { label: 'Vessel Density', val: '34.9%' },
                { label: 'Lesion Count', val: '6 MA + 2 HE' },
              ].map(({ label, val }) => (
                <div key={label}>
                  <div style={{ fontSize: '10px', color: 'var(--text-tertiary)' }}>{label}</div>
                  <div style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--text-primary)' }}>{val}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Right: Clinical result panel */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' }}>
            {/* AI Assessment */}
            <div className="card" style={{ padding: 'var(--space-5)' }}>
              <div style={{ fontSize: 'var(--text-xs)', fontWeight: 700, color: 'var(--text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 'var(--space-4)' }}>
                AI Assessment
              </div>

              {/* Grade result */}
              <div style={{
                padding: 'var(--space-4)',
                background: '#FFF7ED', border: '1px solid #FED7AA',
                borderRadius: 'var(--radius-md)', marginBottom: 'var(--space-4)',
              }}>
                <div style={{ fontSize: 'var(--text-xs)', color: '#9A3412', fontWeight: 600, marginBottom: '6px', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                  Referable DR Detected
                </div>
                <div style={{ fontSize: '36px', fontWeight: 700, color: '#C2410C', letterSpacing: '-0.04em', lineHeight: 1, marginBottom: '4px' }}>
                  Level 2
                </div>
                <div style={{ fontSize: 'var(--text-sm)', color: '#9A3412' }}>
                  Moderate Nonproliferative DR
                </div>
              </div>

              {/* Confidence */}
              <div style={{ marginBottom: 'var(--space-4)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 'var(--space-2)' }}>
                  <span style={{ fontSize: 'var(--text-xs)', color: 'var(--text-secondary)', fontWeight: 600 }}>Confidence</span>
                  <span style={{ fontSize: 'var(--text-sm)', fontWeight: 700, color: 'var(--text-primary)' }}>94.8%</span>
                </div>
                <div className="conf-bar-track">
                  <div className="metric-bar-fill conf-bar-fill" style={{ width: '94.8%', background: 'linear-gradient(90deg, var(--accent-blue), #63d7ff)' }}/>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '4px' }}>
                  <span style={{ fontSize: '10px', color: 'var(--text-tertiary)' }}>Softmax score</span>
                  <span style={{ fontSize: '10px', color: 'var(--text-tertiary)' }}>Calibrated</span>
                </div>
              </div>

              {/* Per-class probabilities */}
              <div style={{ marginBottom: 'var(--space-4)' }}>
                <div style={{ fontSize: 'var(--text-xs)', color: 'var(--text-tertiary)', marginBottom: 'var(--space-2)' }}>Class Probabilities</div>
                {[
                  { label: 'Level 0', pct: 2 },
                  { label: 'Level 1', pct: 5 },
                  { label: 'Level 2', pct: 86, active: true },
                  { label: 'Level 3', pct: 5 },
                  { label: 'Level 4', pct: 2 },
                ].map((c, index) => (
                  <div key={c.label} style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)', marginBottom: '6px' }}>
                    <span style={{ fontSize: '10px', color: c.active ? 'var(--text-primary)' : 'var(--text-tertiary)', fontWeight: c.active ? 600 : 400, width: '44px' }}>{c.label}</span>
                    <div style={{ flex: 1, height: '4px', background: 'var(--border-default)', borderRadius: '2px', overflow: 'hidden' }}>
                      <div className="metric-bar-fill" style={{ height: '100%', width: `${c.pct}%`, background: c.active ? 'linear-gradient(90deg, var(--accent-blue), #63d7ff)' : '#CBD5E1', borderRadius: '2px', animationDelay: `${index * 70}ms` }}/>
                    </div>
                    <span style={{ fontSize: '10px', color: c.active ? 'var(--text-primary)' : 'var(--text-tertiary)', fontWeight: c.active ? 600 : 400, width: '28px', textAlign: 'right' }}>{c.pct}%</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Clinical Evidence */}
            <div className="card" style={{ padding: 'var(--space-5)' }}>
              <div style={{ fontSize: 'var(--text-xs)', fontWeight: 700, color: 'var(--text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 'var(--space-4)' }}>
                Clinical Evidence
              </div>
              {EVIDENCE.map(e => (
                <div key={e.label} className="evidence-row">
                  <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
                    <span style={{ width: '5px', height: '5px', borderRadius: '50%', background: e.color, flexShrink: 0 }}/>
                    <span style={{ fontSize: 'var(--text-sm)', color: 'var(--text-primary)', fontWeight: 500 }}>{e.label}</span>
                  </div>
                  <span style={{ fontSize: 'var(--text-xs)', color: 'var(--text-tertiary)', fontWeight: 500 }}>{e.count}</span>
                </div>
              ))}
            </div>

            {/* Explainability */}
            <div className="card" style={{ padding: 'var(--space-5)' }}>
              <div style={{ fontSize: 'var(--text-xs)', fontWeight: 700, color: 'var(--text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 'var(--space-3)' }}>
                Explainability
              </div>
              {[
                { label: 'Grad-CAM agreement', val: 'High' },
                { label: 'Evidence confidence', val: '0.92' },
                { label: 'Routing', val: 'Doctor Review' },
              ].map(({ label, val }) => (
                <div key={label} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-2)' }}>
                  <span style={{ fontSize: 'var(--text-xs)', color: 'var(--text-secondary)' }}>{label}</span>
                  <span style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--text-primary)' }}>{val}</span>
                </div>
              ))}
            </div>

            {/* Review CTA */}
            <button className="btn btn-primary" style={{ width: '100%', justifyContent: 'center', padding: '12px' }}>
              Review & Validate
            </button>
            <p style={{ fontSize: '10px', color: 'var(--text-tertiary)', textAlign: 'center', lineHeight: 1.5 }}>
              AI-assisted screening. Final clinical decision remains with the reviewing clinician.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
