const metrics = [
  { value: 'Target', label: 'Sensitivity', detail: '>90%' },
  { value: 'Target', label: 'Specificity', detail: '>85%' },
  { value: 'Level 2+', label: 'Referable DR', detail: 'Clinical triage threshold' },
  { value: 'Target', label: 'Review time', detail: '< 30s' },
];

export function ValidationSection() {
  return (
    <section style={{ padding: 'var(--space-24) 0', background: 'var(--bg-primary)' }}>
      <div className="container">
        <div style={{ marginBottom: 'var(--space-10)' }}>
          <div className="eyebrow eyebrow-blue" style={{ marginBottom: 'var(--space-3)' }}>Validation</div>
          <h2>Built for measurable clinical performance.</h2>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, minmax(0, 1fr))', gap: 'var(--space-5)' }}>
          {metrics.map((metric) => (
            <div key={metric.label} className="card card-hover" style={{ padding: 'var(--space-5)', textAlign: 'center' }}>
              <div style={{ fontSize: 'var(--text-xs)', color: 'var(--text-tertiary)', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 'var(--space-3)' }}>
                {metric.label}
              </div>
              <div style={{ fontSize: 'var(--text-3xl)', fontWeight: 700, color: 'var(--text-primary)', letterSpacing: '-0.04em', marginBottom: '6px' }}>{metric.value}</div>
              <div style={{ fontSize: 'var(--text-sm)', color: 'var(--text-secondary)' }}>{metric.detail}</div>
            </div>
          ))}
        </div>

        <div style={{ marginTop: 'var(--space-8)', padding: 'var(--space-5)', border: '1px solid var(--border-default)', background: 'var(--bg-surface)', borderRadius: 'var(--radius-lg)' }}>
          <div style={{ fontSize: 'var(--text-sm)', color: 'var(--text-secondary)', textAlign: 'center' }}>
            Evidence {'>'} marketing · Clinical clarity {'>'} visual complexity · Whitespace {'>'} cards
          </div>
        </div>
      </div>
    </section>
  );
}
