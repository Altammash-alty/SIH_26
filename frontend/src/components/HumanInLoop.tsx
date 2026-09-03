const steps = [
  'AI Screening',
  'Explainable Evidence',
  'Clinician Review',
  'Validated Result',
  'Referral / Follow-up',
];

export function HumanInLoop() {
  return (
    <section style={{ padding: 'var(--space-24) 0', background: 'var(--bg-secondary)' }}>
      <div className="container">
        <div style={{ textAlign: 'center', marginBottom: 'var(--space-10)' }}>
          <div className="eyebrow eyebrow-blue" style={{ marginBottom: 'var(--space-3)' }}>Human-in-the-loop</div>
          <h2>AI accelerates screening. Clinicians make the decision.</h2>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, minmax(0, 1fr))', gap: 'var(--space-4)', alignItems: 'center' }}>
          {steps.map((step, index) => (
            <div key={step} style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
              <div className="card" style={{ flex: 1, padding: 'var(--space-4)', textAlign: 'center', minHeight: '90px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <div style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--text-primary)' }}>{step}</div>
              </div>
              {index < steps.length - 1 && (
                <div style={{ fontSize: '1.4rem', color: 'var(--text-tertiary)' }}>↓</div>
              )}
            </div>
          ))}
        </div>

        <div style={{ marginTop: 'var(--space-8)', display: 'flex', justifyContent: 'center' }}>
          <div className="badge badge-teal">Target review time · under 30 sec</div>
        </div>
      </div>
    </section>
  );
}
