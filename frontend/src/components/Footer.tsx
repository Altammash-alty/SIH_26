export function Footer() {
  return (
    <footer style={{ borderTop: '1px solid var(--border-default)', background: 'var(--bg-surface)', padding: 'var(--space-8) 0' }}>
      <div className="container">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 'var(--space-4)', flexWrap: 'wrap' }}>
          <div>
            <div style={{ fontSize: 'var(--text-base)', fontWeight: 700, color: 'var(--text-primary)' }}>RetinaAI</div>
            <div style={{ fontSize: 'var(--text-sm)', color: 'var(--text-secondary)' }}>Explainable DR Screening</div>
          </div>

          <div style={{ display: 'flex', gap: 'var(--space-5)', flexWrap: 'wrap', fontSize: 'var(--text-sm)', color: 'var(--text-secondary)' }}>
            <span>Platform</span>
            <span>Explainability</span>
            <span>Clinical Workflow</span>
            <span>Validation</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
