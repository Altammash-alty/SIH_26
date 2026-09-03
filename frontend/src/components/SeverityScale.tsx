const levels = [
  { grade: '0', title: 'No DR', tone: '#E2E8F0' },
  { grade: '1', title: 'Mild NPDR', tone: '#DBEAFE' },
  { grade: '2', title: 'Moderate NPDR', tone: '#93C5FD', active: true },
  { grade: '3', title: 'Severe NPDR', tone: '#60A5FA' },
  { grade: '4', title: 'Proliferative DR', tone: '#2563EB' },
];

export function SeverityScale() {
  return (
    <section style={{ padding: 'var(--space-24) 0', background: 'var(--bg-primary)' }}>
      <div className="container">
        <div style={{ marginBottom: 'var(--space-8)' }}>
          <div className="eyebrow eyebrow-blue" style={{ marginBottom: 'var(--space-3)' }}>International Clinical Diabetic Retinopathy Severity Scale</div>
          <h2 style={{ maxWidth: '560px' }}>Severity levels guide triage and follow-up decisions.</h2>
        </div>

        <div className="card" style={{ padding: 'var(--space-5)' }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, minmax(0, 1fr))', gap: 'var(--space-4)' }}>
            {levels.map((level) => (
              <div key={level.grade} style={{ textAlign: 'center', padding: 'var(--space-4) 0' }}>
                <div style={{
                  width: '52px',
                  height: '52px',
                  borderRadius: '14px',
                  background: level.tone,
                  border: level.active ? '1px solid var(--accent-blue)' : '1px solid var(--border-default)',
                  boxShadow: level.active ? '0 12px 24px rgba(37,99,235,0.12)' : 'none',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  margin: '0 auto var(--space-3)',
                  fontSize: '1.1rem',
                  fontWeight: 700,
                  color: level.active ? 'var(--text-primary)' : 'var(--text-secondary)',
                }}>
                  {level.grade}
                </div>
                <div style={{ fontSize: 'var(--text-sm)', fontWeight: 600, color: level.active ? 'var(--text-primary)' : 'var(--text-secondary)' }}>{level.title}</div>
              </div>
            ))}
          </div>

          <div style={{ marginTop: 'var(--space-5)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 'var(--space-4)', flexWrap: 'wrap' }}>
            <div className="badge badge-blue">Referable threshold: Level 2+</div>
            <div style={{ fontSize: 'var(--text-sm)', color: 'var(--text-secondary)' }}>Clinical review remains human-led for final referral decisions.</div>
          </div>
        </div>
      </div>
    </section>
  );
}
