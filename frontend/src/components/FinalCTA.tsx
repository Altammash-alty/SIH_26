interface FinalCTAProps {
  onLaunch: () => void;
}

export function FinalCTA({ onLaunch }: FinalCTAProps) {
  return (
    <section style={{ padding: 'var(--space-24) 0', background: 'var(--bg-primary)' }}>
      <div className="container">
        <div className="card" style={{ padding: 'var(--space-8)', background: '#FFFFFF', border: '1px solid var(--border-default)', boxShadow: 'var(--shadow-md)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 'var(--space-6)', flexWrap: 'wrap' }}>
            <div style={{ maxWidth: '620px' }}>
              <div className="eyebrow eyebrow-blue" style={{ marginBottom: 'var(--space-3)' }}>Clinical decision support</div>
              <h2 style={{ marginBottom: 'var(--space-3)' }}>Retinal image → AI analysis → explainable evidence → clinician review.</h2>
              <p style={{ marginBottom: 0 }}>Designed for primary health centers, telemedicine pathways, and rural screening workflows.</p>
            </div>
            <button className="btn btn-primary btn-lg" onClick={onLaunch}>Start Screening</button>
          </div>
        </div>
      </div>
    </section>
  );
}
