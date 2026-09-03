const STEPS = [
  {
    icon: '📷',
    label: 'Capture',
    desc: 'Fundus image acquired via portable camera.',
  },
  {
    icon: '✓',
    label: 'Quality Check',
    desc: 'Focus, illumination and FOV assessment.',
  },
  {
    icon: '⬛',
    label: 'Enhancement',
    desc: 'CLAHE green-channel preprocessing and denoising.',
  },
  {
    icon: '◎',
    label: 'Detection',
    desc: 'Identify microaneurysms, hemorrhages and exudates.',
  },
  {
    icon: '▤',
    label: 'Grading',
    desc: 'ICDR DR severity Level 0–4 classification.',
  },
  {
    icon: '⊛',
    label: 'Explanation',
    desc: 'Grad-CAM and lesion-level evidence.',
  },
  {
    icon: '✦',
    label: 'Review',
    desc: 'Clinician validates or overrides the AI result.',
  },
];

export function WorkflowSection() {
  return (
    <section id="clinical-workflow" className="section" style={{ background: 'linear-gradient(180deg, rgba(7, 24, 39, 0.8), rgba(10, 21, 35, 0.96))', paddingTop: '72px', paddingBottom: '72px' }}>
      <div className="container">
        <div style={{ textAlign: 'center', marginBottom: 'var(--space-10)' }}>
          <h2 style={{ marginBottom: 'var(--space-3)' }}>
            From retinal image to explainable clinical evidence.
          </h2>
          <p style={{ fontSize: 'var(--text-base)', maxWidth: '480px', margin: '0 auto', color: 'var(--text-secondary)' }}>
            A seven-stage automated pipeline with a human review gate at the end.
          </p>
        </div>

        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(7, minmax(0, 1fr))',
          gap: 0,
          alignItems: 'stretch',
          background: 'rgba(12, 26, 39, 0.9)',
          border: '1px solid var(--border-default)',
          borderRadius: 'var(--radius-xl)',
          overflow: 'hidden',
          boxShadow: '0 18px 40px rgba(2, 6, 23, 0.18)',
        }}>
          {STEPS.map((step, i) => (
            <div key={step.label} className="stage-card" style={{
              padding: 'var(--space-5) var(--space-4)',
              borderRight: i < STEPS.length - 1 ? '1px solid var(--border-default)' : 'none',
              textAlign: 'center',
              position: 'relative',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'flex-start',
              alignItems: 'center',
              minHeight: '170px',
              animationDelay: `${i * 80}ms`,
            }}>
              {/* Step number */}
              <div style={{
                fontSize: 'var(--text-xs)', fontWeight: 700, color: 'var(--text-tertiary)',
                marginBottom: 'var(--space-3)', fontVariantNumeric: 'tabular-nums',
              }}>
                {String(i + 1).padStart(2, '0')}
              </div>
              {/* Icon */}
              <div style={{
                width: '36px', height: '36px', borderRadius: '9px',
                background: i === 5 ? 'var(--accent-blue-light)' : 'var(--bg-secondary)',
                border: `1px solid ${i === 5 ? '#BFDBFE' : 'var(--border-default)'}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                margin: '0 auto var(--space-3)',
                fontSize: '15px',
              }}>
                {step.icon}
              </div>
              {/* Label */}
              <div style={{
                fontSize: 'var(--text-sm)', fontWeight: 600, color: 'var(--text-primary)',
                marginBottom: 'var(--space-1)',
              }}>
                {step.label}
              </div>
              {/* Desc */}
              <div style={{ fontSize: '11px', color: 'var(--text-tertiary)', lineHeight: 1.45 }}>
                {step.desc}
              </div>

              {/* Arrow connector */}
              {i < STEPS.length - 1 && (
                <div style={{
                  position: 'absolute', right: '-7px', top: '50%', transform: 'translateY(-50%)',
                  zIndex: 2, width: '14px', height: '14px',
                  background: 'var(--bg-surface)', border: '1px solid var(--border-default)',
                  borderRadius: '3px', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: '8px', color: 'var(--text-tertiary)',
                }}>
                  ›
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
