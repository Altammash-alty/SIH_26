const evidence = [
  { label: 'Microaneurysms', value: 'Detected in 4 regions', tone: '#DC2626' },
  { label: 'Hemorrhages', value: '2 regions detected', tone: '#991B1B' },
  { label: 'Exudates', value: 'Low evidence', tone: '#D97706' },
  { label: 'Neovascularization', value: 'Not detected', tone: '#16A34A' },
];

export function ExplainabilitySection() {
  return (
    <section style={{ padding: 'var(--space-24) 0', background: 'var(--bg-secondary)' }}>
      <div className="container">
        <div style={{ display: 'grid', gridTemplateColumns: '1.1fr 0.9fr', gap: 'var(--space-8)', alignItems: 'center' }}>
          <div>
            <div className="eyebrow eyebrow-blue" style={{ marginBottom: 'var(--space-3)' }}>Explainability</div>
            <h2 style={{ marginBottom: 'var(--space-3)' }}>Every prediction comes with evidence.</h2>
            <p style={{ maxWidth: '520px', marginBottom: 'var(--space-6)' }}>
              Move from black-box prediction to clinically interpretable evidence that supports each grade.
            </p>

            <div className="card" style={{ padding: 'var(--space-5)', overflow: 'hidden' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 'var(--space-4)' }}>
                <div>
                  <div style={{ fontSize: 'var(--text-xs)', color: 'var(--text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                    Retinal evidence
                  </div>
                  <div style={{ fontSize: 'var(--text-lg)', fontWeight: 600, color: 'var(--text-primary)' }}>Why was this classified as Level 2?</div>
                </div>
                <div className="badge badge-blue">High agreement</div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: 'var(--space-4)' }}>
                <div style={{ position: 'relative', background: '#0D0404', borderRadius: 'var(--radius-lg)', overflow: 'hidden', minHeight: '220px' }}>
                  <div style={{ position: 'absolute', inset: 0 }}>
                    <svg viewBox="0 0 260 220" width="100%" height="100%" preserveAspectRatio="xMidYMid meet">
                      <defs>
                        <radialGradient id="expGrad" cx="50%" cy="50%" r="50%">
                          <stop offset="0%" stopColor="#8C2A2A" />
                          <stop offset="48%" stopColor="#5B1616" />
                          <stop offset="100%" stopColor="#1B0505" />
                        </radialGradient>
                      </defs>
                      <circle cx="130" cy="110" r="96" fill="url(#expGrad)" />
                      <circle cx="130" cy="110" r="58" fill="none" stroke="#7A2017" strokeWidth="18" strokeOpacity="0.25" />
                      <circle cx="84" cy="108" r="18" fill="#F4D59A" fillOpacity="0.85" />
                      <circle cx="83" cy="108" r="6" fill="#FFF5D0" />
                      <path d="M84,108 Q108,80 140,76 Q170,75 180,90" stroke="#8B2010" strokeWidth="3" fill="none" />
                      <path d="M84,108 Q106,138 142,142 Q171,142 182,128" stroke="#8B2010" strokeWidth="3" fill="none" />
                      <circle cx="156" cy="118" r="3.2" fill="#DC2626" />
                      <circle cx="168" cy="100" r="3" fill="#DC2626" />
                      <circle cx="175" cy="126" r="2.5" fill="#B91C1C" />
                      <circle cx="170" cy="144" r="2.8" fill="#F59E0B" />
                    </svg>
                  </div>
                  <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(135deg, rgba(220,38,38,0.18), rgba(245,158,11,0.0) 45%, rgba(30,41,59,0.0))' }} />
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-3)' }}>
                  {evidence.map((item) => (
                    <div key={item.label} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: 'var(--space-3)', borderRadius: 'var(--radius-md)', background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
                        <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: item.tone, display: 'inline-block' }} />
                        <span style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--text-primary)' }}>{item.label}</span>
                      </div>
                      <span style={{ fontSize: 'var(--text-xs)', color: 'var(--text-secondary)' }}>{item.value}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>

          <div>
            <div className="card" style={{ padding: 'var(--space-6)' }}>
              <div style={{ fontSize: 'var(--text-xs)', color: 'var(--text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 'var(--space-4)' }}>
                Confidence summary
              </div>

              <div style={{ marginBottom: 'var(--space-5)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                  <span style={{ fontSize: 'var(--text-sm)', color: 'var(--text-secondary)' }}>Evidence confidence</span>
                  <span style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--text-primary)' }}>0.92</span>
                </div>
                <div className="conf-bar-track">
                  <div className="conf-bar-fill" style={{ width: '92%', background: 'var(--accent-blue)' }} />
                </div>
              </div>

              <div style={{ display: 'grid', gap: 'var(--space-3)' }}>
                {[
                  { label: 'Microaneurysms', percent: 82 },
                  { label: 'Hemorrhages', percent: 63 },
                  { label: 'Exudates', percent: 44 },
                  { label: 'Neovascularization', percent: 8 },
                ].map((metric) => (
                  <div key={metric.label}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                      <span style={{ fontSize: 'var(--text-sm)', color: 'var(--text-secondary)' }}>{metric.label}</span>
                      <span style={{ fontSize: 'var(--text-xs)', color: 'var(--text-secondary)' }}>{metric.percent}%</span>
                    </div>
                    <div className="conf-bar-track">
                      <div className="conf-bar-fill" style={{ width: `${metric.percent}%`, background: metric.label === 'Neovascularization' ? 'var(--status-success)' : 'var(--accent-blue)' }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
