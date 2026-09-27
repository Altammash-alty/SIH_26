import React from 'react';

export const ValidationSection: React.FC = () => {
  return (
    <section id="validation" style={{ backgroundColor: 'var(--canvas)', padding: '80px 0' }}>
      <div className="section-container">
        {/* Header */}
        <div style={{ marginBottom: '48px', maxWidth: '640px' }}>
          <div className="caption" style={{ marginBottom: '12px' }}>
            Clinical Validation
          </div>
          <h2 className="heading-lg" style={{ marginBottom: '16px' }}>
            Performance targets on held-out data.
          </h2>
          <p className="body-lg">
            The pipeline targets greater than 90% sensitivity and greater than 85% specificity for referable DR (ICDR Grade 2 and above), evaluated on held-out IDRiD and Messidor-2 images with ground-truth labels. Numbers below are targets; actual results depend on final training run quality and are reported honestly.
          </p>
        </div>

        {/* Metric Cards Grid */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
            gap: '24px',
            marginBottom: '32px',
          }}
        >
          {/* Sensitivity Card */}
          <div className="clinical-card">
            <div className="caption" style={{ marginBottom: '8px' }}>
              Referable DR Sensitivity Target
            </div>
            <div
              style={{
                fontSize: '36px',
                fontWeight: 600,
                letterSpacing: '-0.04em',
                lineHeight: 1.1,
                color: 'var(--ink)',
                marginBottom: '16px',
              }}
            >
              &gt; 90.0%
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                  <span style={{ fontWeight: 500, color: 'var(--ink-soft)' }}>Autonomous Pipeline (Target)</span>
                  <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--teal)' }}>90.0%</span>
                </div>
                <div style={{ height: '6px', backgroundColor: 'var(--hairline)', borderRadius: '3px', overflow: 'hidden' }}>
                  <div style={{ width: '90%', height: '100%', backgroundColor: 'var(--teal)' }} />
                </div>
              </div>

              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                  <span style={{ color: 'var(--mid-gray)' }}>Single-Technique Baseline</span>
                  <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--mid-gray)' }}>76.0%</span>
                </div>
                <div style={{ height: '6px', backgroundColor: 'var(--hairline)', borderRadius: '3px', overflow: 'hidden' }}>
                  <div style={{ width: '76%', height: '100%', backgroundColor: 'var(--mid-gray)' }} />
                </div>
              </div>
            </div>
          </div>

          {/* Specificity Card */}
          <div className="clinical-card">
            <div className="caption" style={{ marginBottom: '8px' }}>
              Diagnostic Specificity Target
            </div>
            <div
              style={{
                fontSize: '36px',
                fontWeight: 600,
                letterSpacing: '-0.04em',
                lineHeight: 1.1,
                color: 'var(--ink)',
                marginBottom: '16px',
              }}
            >
              &gt; 85.0%
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                  <span style={{ fontWeight: 500, color: 'var(--ink-soft)' }}>Autonomous Pipeline (Target)</span>
                  <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--teal)' }}>85.0%</span>
                </div>
                <div style={{ height: '6px', backgroundColor: 'var(--hairline)', borderRadius: '3px', overflow: 'hidden' }}>
                  <div style={{ width: '85%', height: '100%', backgroundColor: 'var(--teal)' }} />
                </div>
              </div>

              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', marginBottom: '4px' }}>
                  <span style={{ color: 'var(--mid-gray)' }}>Single-Technique Baseline</span>
                  <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--mid-gray)' }}>71.0%</span>
                </div>
                <div style={{ height: '6px', backgroundColor: 'var(--hairline)', borderRadius: '3px', overflow: 'hidden' }}>
                  <div style={{ width: '71%', height: '100%', backgroundColor: 'var(--mid-gray)' }} />
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Footnote per CONTENT.md */}
        <p style={{ fontSize: '13px', color: 'var(--mid-gray)', lineHeight: 1.5 }}>
          Quality gate, CLAHE preprocessing, and lesion segmentation verified on real IDRiD and Messidor-2 images. Bars show target operating point versus a typical single-feature detector baseline.
        </p>
      </div>
    </section>
  );
};
