const FEATURES = [
  { label: 'Image Quality Assessment' },
  { label: 'DR Severity 0–4' },
  { label: 'Grad-CAM Explainability' },
  { label: 'Lesion-Level Evidence' },
  { label: 'Human-in-the-Loop' },
  { label: 'Simulink Capacity Modeling' },
];

export function TrustStrip() {
  return (
    <div style={{
      borderTop: '1px solid var(--border-default)',
      borderBottom: '1px solid var(--border-default)',
      background: 'var(--bg-surface)',
      padding: 'var(--space-4) 0',
    }}>
      <div className="container">
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 'var(--space-4)',
          flexWrap: 'wrap',
        }}>
          {FEATURES.map((f, i) => (
            <div key={f.label} style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
              {i > 0 && (
                <span style={{
                  width: '1px', height: '14px', background: 'var(--border-default)',
                  display: 'inline-block', marginRight: 'var(--space-3)',
                }}/>
              )}
              <span style={{
                fontSize: 'var(--text-xs)', fontWeight: 600, color: 'var(--text-secondary)',
                letterSpacing: '0.02em', whiteSpace: 'nowrap',
              }}>
                {f.label}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
