import { FundusViz } from './FundusViz';

interface HeroProps {
  onLaunch: () => void;
}

export function Hero({ onLaunch }: HeroProps) {
  return (
    <section
      className="hero-shell"
      style={{
        position: 'relative',
        paddingTop: '120px',
        paddingBottom: 'var(--space-16)',
        background: 'radial-gradient(circle at 12% 10%, rgba(70, 122, 255, 0.18), transparent 28%), linear-gradient(180deg, rgba(8, 16, 28, 0.96) 0%, rgba(11, 21, 32, 0.9) 100%)',
        overflow: 'hidden',
      }}
    >
      <div className="ambient-orb" aria-hidden="true" style={{ width: '420px', height: '420px', left: '-80px', top: '80px', background: 'rgba(29, 127, 239, 0.2)' }} />
      <div className="ambient-orb" aria-hidden="true" style={{ width: '360px', height: '360px', right: '10%', bottom: '40px', background: 'rgba(94, 230, 213, 0.18)' }} />
      <div className="hero-photo" aria-hidden="true" />
      <div className="hero-overlay" aria-hidden="true" />
      <div className="container hero-inner">
        <div style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: 'var(--space-16)',
          alignItems: 'center',
          position: 'relative',
          zIndex: 2,
        }}>
          {/* Left: Copy */}
          <div className="hero-copy">
            {/* Eyebrow */}
            <div style={{ marginBottom: 'var(--space-5)' }}>
              <span style={{
                display: 'inline-flex', alignItems: 'center', gap: '8px',
                padding: '4px 10px', borderRadius: '20px',
                border: '1px solid var(--border-default)',
                background: 'var(--bg-surface)',
                fontSize: 'var(--text-xs)', fontWeight: 600, color: 'var(--text-secondary)',
                letterSpacing: '0.05em', textTransform: 'uppercase',
              }}>
                <span style={{ width: '5px', height: '5px', borderRadius: '50%', background: 'var(--accent-blue)', display: 'inline-block' }}/>
                SIH 26038 · MedTech / HealthTech
              </span>
            </div>

            {/* Headline */}
            <h1 style={{
              fontSize: 'clamp(32px, 4vw, 48px)',
              fontWeight: 700,
              letterSpacing: '-0.03em',
              lineHeight: 1.1,
              color: 'var(--text-primary)',
              marginBottom: 'var(--space-5)',
            }}>
              Explainable AI for<br />
              <span style={{ color: 'var(--accent-blue)' }}>Diabetic Retinopathy</span><br />
              Screening
            </h1>

            {/* Subheading */}
            <p style={{
              fontSize: 'var(--text-lg)',
              color: 'var(--text-secondary)',
              lineHeight: 1.6,
              marginBottom: 'var(--space-8)',
              maxWidth: '440px',
            }}>
              Fast, transparent retinal screening designed for primary healthcare
              and telemedicine workflows in rural India.
            </p>

            {/* CTAs */}
            <div style={{ display: 'flex', gap: 'var(--space-3)', flexWrap: 'wrap' }}>
              <button className="btn btn-primary btn-lg" onClick={onLaunch} style={{ boxShadow: '0 12px 28px rgba(46, 155, 255, 0.28)' }}>
                <svg width="15" height="15" viewBox="0 0 15 15" fill="none">
                  <path d="M7.5 1a6.5 6.5 0 100 13A6.5 6.5 0 007.5 1zm.75 9.5H6.75V7h1.5v3.5zm0-5H6.75V4h1.5v1.5z" fill="currentColor"/>
                </svg>
                Start Screening
              </button>
              <a href="#clinical-workflow" className="btn btn-secondary btn-lg">
                View Clinical Workflow
              </a>
            </div>

            {/* Small trust signals */}
            <div style={{
              display: 'flex', gap: 'var(--space-5)', marginTop: 'var(--space-8)',
              paddingTop: 'var(--space-6)', borderTop: '1px solid var(--border-default)',
              flexWrap: 'wrap',
            }}>
              {[
                { label: 'ICDR Grade 0–4', sublabel: 'Severity Scale' },
                { label: 'Grad-CAM Evidence', sublabel: 'Explainability' },
                { label: 'IDRiD + Messidor-2', sublabel: 'Validation Dataset' },
              ].map(({ label, sublabel }) => (
                <div key={label}>
                  <div style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--text-primary)' }}>{label}</div>
                  <div style={{ fontSize: 'var(--text-xs)', color: 'var(--text-tertiary)', marginTop: '2px' }}>{sublabel}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Right: Clinical visualization panel */}
          <div className="hero-visual" style={{ position: 'relative' }}>
            {/* Outer frame */}
            <div className="card hero-panel" style={{
              padding: 'var(--space-4)',
              background: 'linear-gradient(180deg, rgba(14, 28, 41, 0.96), rgba(12, 24, 35, 0.9))',
              backdropFilter: 'blur(14px)',
              boxShadow: '0 34px 72px rgba(2, 6, 23, 0.34), 0 0 0 1px rgba(76, 201, 240, 0.08)',
              borderColor: 'rgba(148,163,184,0.28)',
            }}>
              {/* Panel header */}
              <div style={{
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                marginBottom: 'var(--space-3)', paddingBottom: 'var(--space-3)',
                borderBottom: '1px solid var(--border-subtle)',
              }}>
                <div style={{ fontSize: 'var(--text-xs)', fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                  Retinal Analysis · Patient RA-02481
                </div>
                <span className="badge badge-blue">
                  <span style={{ width: '4px', height: '4px', background: 'var(--accent-blue)', borderRadius: '50%', display: 'inline-block' }}/>
                  AI-assisted
                </span>
              </div>

              {/* Image + result grid */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 'var(--space-4)', alignItems: 'start' }}>
                {/* Fundus image */}
                <div style={{ position: 'relative', borderRadius: 'var(--radius-md)', overflow: 'hidden', background: '#0D0404', aspectRatio: '1' }}>
                  <FundusViz />
                </div>

                {/* Result card */}
                <div style={{ width: '170px', display: 'flex', flexDirection: 'column', gap: 'var(--space-3)' }}>
                  {/* Grade result */}
                  <div style={{
                    padding: 'var(--space-3)',
                    background: 'linear-gradient(180deg, rgba(255, 139, 66, 0.14), rgba(255, 247, 237, 0.06))',
                    border: '1px solid rgba(251, 146, 60, 0.38)',
                    borderRadius: 'var(--radius-md)',
                    textAlign: 'center',
                    boxShadow: '0 18px 30px rgba(251, 146, 60, 0.12)',
                    transform: 'scale(1.06)',
                  }}>
                    <div style={{ fontSize: 'var(--text-xs)', color: '#FDBA74', fontWeight: 700, marginBottom: '6px', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                      Referable DR
                    </div>
                    <div style={{ fontSize: '30px', fontWeight: 800, color: '#F8B06D', letterSpacing: '-0.04em', lineHeight: 1 }}>
                      Level 2
                    </div>
                    <div style={{ fontSize: 'var(--text-xs)', color: '#FDE68A', marginTop: '5px' }}>
                      Moderate NPDR
                    </div>
                  </div>

                  {/* Confidence */}
                  <div style={{
                    padding: 'var(--space-3)',
                    border: '1px solid var(--border-default)',
                    borderRadius: 'var(--radius-md)',
                    background: 'var(--bg-surface)',
                  }}>
                    <div style={{ fontSize: 'var(--text-xs)', color: 'var(--text-tertiary)', marginBottom: '6px', fontWeight: 500 }}>
                      Confidence
                    </div>
                    <div style={{ fontSize: '20px', fontWeight: 700, color: 'var(--text-primary)', letterSpacing: '-0.02em', marginBottom: '6px' }}>
                      94.8%
                    </div>
                    <div style={{ height: '3px', background: 'var(--border-default)', borderRadius: '2px', overflow: 'hidden' }}>
                      <div className="metric-bar-fill" style={{ height: '100%', width: '94.8%', background: 'linear-gradient(90deg, var(--accent-blue), #63d7ff)', borderRadius: '2px' }}/>
                    </div>
                  </div>

                  {/* Evidence summary */}
                  <div style={{
                    padding: 'var(--space-3)',
                    border: '1px solid var(--border-default)',
                    borderRadius: 'var(--radius-md)',
                    background: 'var(--bg-surface)',
                  }}>
                    <div style={{ fontSize: 'var(--text-xs)', color: 'var(--text-tertiary)', marginBottom: 'var(--space-2)', fontWeight: 500 }}>
                      Evidence
                    </div>
                    {[
                      { label: 'Microaneurysms', dot: '#DC2626' },
                      { label: 'Hemorrhage', dot: '#991B1B' },
                      { label: 'Exudates', dot: '#D97706' },
                    ].map(e => (
                      <div key={e.label} style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '4px' }}>
                        <span style={{ width: '5px', height: '5px', background: e.dot, borderRadius: '50%', flexShrink: 0 }}/>
                        <span style={{ fontSize: '10px', color: 'var(--text-secondary)', fontWeight: 500 }}>{e.label}</span>
                      </div>
                    ))}
                  </div>

                  {/* Label */}
                  <div style={{ fontSize: '10px', color: 'var(--text-tertiary)', textAlign: 'center', fontStyle: 'italic' }}>
                    AI-assisted assessment
                  </div>
                </div>
              </div>
            </div>

            {/* Floating quality badge */}
            <div className="floating-pill pulse-ring" style={{
              position: 'absolute', top: '-14px', right: '24px',
              background: 'rgba(9,22,36,0.9)', border: '1px solid rgba(94, 230, 168, 0.32)',
              borderRadius: 'var(--radius-md)', padding: '6px 12px',
              boxShadow: '0 10px 28px rgba(94, 230, 168, 0.14)',
              display: 'flex', alignItems: 'center', gap: '6px',
              fontSize: 'var(--text-xs)', fontWeight: 600, color: 'var(--status-success)',
            }}>
              <span style={{ width: '5px', height: '5px', background: 'var(--status-success)', borderRadius: '50%' }}/>
              Quality Passed · 91.9/100
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
