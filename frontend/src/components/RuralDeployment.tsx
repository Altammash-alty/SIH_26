const nodes = ['Patient', 'PHC', 'AI Screening', 'Explainable Report', 'Ophthalmologist', 'Referral'];
const photoStory = [
  {
    label: 'Community screening queue',
    subtitle: 'Village outreach & trust building',
    image: '/ChatGPT%20Image%20Sep%203,%202026,%2006_26_57%20PM.png',
  },
  {
    label: 'A primary health centre',
    subtitle: 'Local care infrastructure',
    image: '/ChatGPT%20Image%20Sep%203,%202026,%2006_20_02%20PM.png',
  },
  {
    label: 'Portable eye screening',
    subtitle: 'Field exam with AI-supported review',
    image: '/ChatGPT%20Image%20Sep%203,%202026,%2006_25_56%20PM.png',
  },
  {
    label: 'Clinician review and referral',
    subtitle: 'Tele-ophthalmology follow-up',
    image: '/Gemini_Generated_Image_6qw7uu6qw7uu6qw7.png',
  },
];

export function RuralDeployment() {
  return (
    <section style={{ padding: 'var(--space-24) 0', background: 'var(--bg-primary)' }}>
      <div className="container">
        <div style={{ marginBottom: 'var(--space-10)' }}>
          <div className="eyebrow eyebrow-blue" style={{ marginBottom: 'var(--space-3)' }}>Rural deployment</div>
          <h2>Designed for the realities of rural healthcare.</h2>
        </div>

        <div className="card" style={{ padding: 'var(--space-6)' }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, minmax(0, 1fr))', gap: 'var(--space-3)', alignItems: 'center' }}>
            {nodes.map((node, index) => (
              <div key={node} style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
                <div style={{
                  flex: 1,
                  minHeight: '72px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  padding: 'var(--space-3)',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border-default)',
                  background: index === 2 ? 'var(--accent-blue-light)' : 'var(--bg-subtle)',
                  color: 'var(--text-primary)',
                  fontSize: 'var(--text-sm)',
                  fontWeight: 600,
                  textAlign: 'center',
                }}>
                  {node}
                </div>
                {index < nodes.length - 1 && (
                  <div style={{ fontSize: '1.2rem', color: 'var(--text-tertiary)' }}>→</div>
                )}
              </div>
            ))}
          </div>
        </div>

        <div className="photo-grid" style={{ marginTop: 'var(--space-8)' }}>
          {photoStory.map((story) => (
            <div key={story.label} className="photo-tile card-hover" style={{ backgroundImage: `url(${story.image})` }}>
              <div className="photo-tile-overlay" />
              <div className="photo-tile-content">
                <div className="eyebrow" style={{ color: '#E2E8F0', marginBottom: 'var(--space-2)' }}>{story.label}</div>
                <div style={{ fontSize: 'var(--text-sm)', color: '#E2E8F0', opacity: 0.9 }}>{story.subtitle}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
