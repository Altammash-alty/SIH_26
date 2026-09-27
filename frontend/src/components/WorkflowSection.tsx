import React from 'react';

const STAGES = [
  {
    step: '01',
    name: 'Quality Gate',
    desc: 'Measures focus, illumination uniformity, and field-of-view coverage. Rejects images below threshold.',
    metric: 'Blur, Illumination & FOV check',
  },
  {
    step: '02',
    name: 'CLAHE Enhancement',
    desc: 'Applies contrast-limited adaptive histogram equalization on the green channel. Normalizes illumination.',
    metric: 'Rayleigh Green-CLAHE + Denoise',
  },
  {
    step: '03',
    name: 'Lesion Detection',
    desc: 'Identifies dark lesions (microaneurysms, hemorrhages) and bright lesions (hard exudates, cotton-wool spots).',
    metric: 'Morphological top/bottom-hat filters',
  },
  {
    step: '04',
    name: 'DR Grading',
    desc: 'Classifies severity on the ICDR 0–4 scale using lesion counts and spatial distribution. Returns per-class probabilities.',
    metric: 'ETDRS 4-2-1 rule table & softmax',
  },
  {
    step: '05',
    name: 'Explainability',
    desc: 'Generates a Grad-CAM saliency map. Lists lesion evidence with confidence scores. Routes result to clinician or auto-clear queue.',
    metric: 'Grad-CAM overlay & Mahalanobis OOD',
  },
];

export const WorkflowSection: React.FC = () => {
  return (
    <section id="pipeline" style={{ backgroundColor: 'var(--canvas)', padding: '80px 0' }}>
      <div className="section-container">
        {/* Header */}
        <div style={{ marginBottom: '48px', maxWidth: '640px' }}>
          <div className="caption" style={{ marginBottom: '12px' }}>
            5-Stage Pipeline
          </div>
          <h2 className="heading-lg" style={{ marginBottom: '16px' }}>
            From retinal photograph to clinical evidence.
          </h2>
          <p className="body-lg">
            Each stage runs in sequence. A quality gate at Stage 1 stops processing if the image is too degraded to yield a reliable result. A human clinician remains in the loop at Stage 5.
          </p>
        </div>

        {/* 5-Stage Cards Grid */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
            gap: '16px',
            position: 'relative',
          }}
        >
          {STAGES.map((s) => (
            <div
              key={s.step}
              className="clinical-card"
              style={{
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'space-between',
                padding: '24px',
                transition: 'border-color 150ms ease, box-shadow 150ms ease',
              }}
            >
              <div>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'baseline',
                    marginBottom: '16px',
                  }}
                >
                  <span
                    style={{
                      fontFamily: 'var(--font-mono)',
                      fontSize: '13px',
                      fontWeight: 600,
                      color: 'var(--teal)',
                    }}
                  >
                    STAGE {s.step}
                  </span>
                </div>
                <h3
                  style={{
                    fontSize: '17px',
                    fontWeight: 600,
                    color: 'var(--ink)',
                    marginBottom: '12px',
                    lineHeight: 1.3,
                  }}
                >
                  {s.name}
                </h3>
                <p
                  style={{
                    fontSize: '13px',
                    lineHeight: 1.5,
                    color: 'var(--mid-gray)',
                    marginBottom: '20px',
                  }}
                >
                  {s.desc}
                </p>
              </div>

              <div
                style={{
                  paddingTop: '12px',
                  borderTop: '1px solid var(--hairline)',
                  fontSize: '11px',
                  fontFamily: 'var(--font-mono)',
                  color: 'var(--ink-soft)',
                }}
              >
                {s.metric}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
