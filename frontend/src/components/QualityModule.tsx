const qualityStates = [
  {
    label: 'Good',
    status: 'Gradeable',
    message: 'Image meets retinal quality thresholds for grading.',
    tone: 'success',
    score: '91.9/100',
    progress: 92,
  },
  {
    label: 'Borderline',
    status: 'Enhancement applied',
    message: 'Minor focus or illumination variation addressed via preprocessing.',
    tone: 'warning',
    score: '74.6/100',
    progress: 75,
  },
  {
    label: 'Ungradeable',
    status: 'Recapture required',
    message: 'Insufficient illumination for reliable retinal assessment.',
    tone: 'danger',
    score: '38.2/100',
    progress: 38,
  },
];

export function QualityModule() {
  return (
    <section id="validation" style={{ padding: 'var(--space-24) 0', background: 'var(--bg-primary)' }}>
      <div className="container">
        <div style={{ marginBottom: 'var(--space-10)' }}>
          <div className="eyebrow eyebrow-blue" style={{ marginBottom: 'var(--space-3)' }}>Image Quality</div>
          <h2 style={{ maxWidth: '560px' }}>Quality-aware screening for real-world capture conditions.</h2>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', gap: 'var(--space-5)' }}>
          {qualityStates.map((state) => (
            <div key={state.label} className="card card-hover" style={{ padding: 'var(--space-5)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-4)' }}>
                <div>
                  <div style={{ fontSize: 'var(--text-xs)', color: 'var(--text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: '6px' }}>
                    {state.label}
                  </div>
                  <div
                    style={{
                      fontSize: 'var(--text-sm)',
                      fontWeight: 600,
                      color:
                        state.tone === 'success'
                          ? 'var(--status-success)'
                          : state.tone === 'warning'
                            ? 'var(--status-warning)'
                            : 'var(--status-danger)',
                    }}
                  >
                    {state.status}
                  </div>
                </div>
                <div style={{ fontSize: 'var(--text-sm)', fontWeight: 700, color: 'var(--text-primary)' }}>{state.score}</div>
              </div>

              <div style={{ marginBottom: 'var(--space-4)' }}>
                <div className="conf-bar-track">
                  <div
                    className="conf-bar-fill"
                    style={{
                      width: `${state.progress}%`,
                      background:
                        state.tone === 'success'
                          ? 'var(--status-success)'
                          : state.tone === 'warning'
                            ? 'var(--status-warning)'
                            : 'var(--status-danger)',
                    }}
                  />
                </div>
              </div>

              <p style={{ fontSize: 'var(--text-sm)', lineHeight: 1.6, marginBottom: '0', color: 'var(--text-secondary)' }}>
                {state.message}
              </p>

              {state.label === 'Ungradeable' && (
                <div style={{ marginTop: 'var(--space-4)', fontSize: 'var(--text-sm)', color: 'var(--status-danger)', fontWeight: 600 }}>
                  Insufficient illumination. Recapture with improved retinal illumination.
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
