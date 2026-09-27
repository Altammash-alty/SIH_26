import React from 'react';

const NODES = [
  { step: '01', label: 'Capture', sub: 'Non-mydriatic camera' },
  { step: '02', label: 'Queue', sub: 'Local buffer & sync' },
  { step: '03', label: 'Inference', sub: 'Autonomous pipeline' },
  { step: '04', label: 'Review', sub: 'Specialist tele-triage' },
];

export const RuralDeployment: React.FC = () => {
  return (
    <section id="deployment" style={{ backgroundColor: 'var(--canvas)', padding: '80px 0', borderTop: '1px solid var(--hairline)' }}>
      <div className="section-container">
        {/* Header */}
        <div style={{ marginBottom: '48px', maxWidth: '640px' }}>
          <div className="caption" style={{ marginBottom: '12px' }}>
            Capacity Model
          </div>
          <h2 className="heading-lg" style={{ marginBottom: '16px' }}>
            District-level throughput, not a lab number.
          </h2>
          <p className="body-lg">
            A discrete-event Monte Carlo simulation models a clinic day: image acquisition, processing queue, AI inference, and doctor review, under realistic patient load. Outputs include throughput rate, average wait time, and estimated cost per screening versus unassisted manual review.
          </p>
        </div>

        {/* Four-Node Flow Diagram Card */}
        <div
          className="clinical-card"
          style={{ padding: '32px', marginBottom: '32px' }}
        >
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
              gap: '16px',
              position: 'relative',
            }}
          >
            {NODES.map((node) => (
              <div
                key={node.step}
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px',
                  backgroundColor: node.label === 'Inference' ? 'rgba(15, 118, 110, 0.05)' : 'var(--surface-alt)',
                  border: node.label === 'Inference' ? '1.5px solid var(--teal)' : '1px solid var(--hairline)',
                  borderRadius: 'var(--radius-nested)',
                  padding: '20px',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: '11px', fontFamily: 'var(--font-mono)', fontWeight: 600, color: 'var(--mid-gray)' }}>
                    PHASE {node.step}
                  </span>
                  {node.label === 'Inference' && (
                    <span
                      style={{
                        width: '8px',
                        height: '8px',
                        borderRadius: '50%',
                        backgroundColor: 'var(--teal)',
                        display: 'inline-block',
                      }}
                    />
                  )}
                </div>
                <div style={{ fontSize: '16px', fontWeight: 600, color: 'var(--ink)' }}>
                  {node.label}
                </div>
                <div style={{ fontSize: '12px', color: 'var(--mid-gray)' }}>
                  {node.sub}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Simulation Output Metrics Grid */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: '16px',
          }}
        >
          <div className="clinical-card" style={{ padding: '20px' }}>
            <div className="caption" style={{ marginBottom: '6px' }}>AI throughput</div>
            <div style={{ fontSize: '24px', fontWeight: 600, color: 'var(--ink)', marginBottom: '4px' }}>
              13.4 <span style={{ fontSize: '14px', fontWeight: 400, color: 'var(--mid-gray)' }}>/ hr</span>
            </div>
            <div style={{ fontSize: '12px', color: 'var(--mid-gray)' }}>patients per hour</div>
          </div>

          <div className="clinical-card" style={{ padding: '20px' }}>
            <div className="caption" style={{ marginBottom: '6px' }}>Manual throughput</div>
            <div style={{ fontSize: '24px', fontWeight: 600, color: 'var(--ink)', marginBottom: '4px' }}>
              4.9 <span style={{ fontSize: '14px', fontWeight: 400, color: 'var(--mid-gray)' }}>/ hr</span>
            </div>
            <div style={{ fontSize: '12px', color: 'var(--mid-gray)' }}>patients per hour</div>
          </div>

          <div className="clinical-card" style={{ padding: '20px' }}>
            <div className="caption" style={{ marginBottom: '6px' }}>Doctor time saved</div>
            <div style={{ fontSize: '24px', fontWeight: 600, color: 'var(--teal)', marginBottom: '4px' }}>
              85.2%
            </div>
            <div style={{ fontSize: '12px', color: 'var(--mid-gray)' }}>clinical hours freed</div>
          </div>

          <div className="clinical-card" style={{ padding: '20px' }}>
            <div className="caption" style={{ marginBottom: '6px' }}>Average wait time</div>
            <div style={{ fontSize: '24px', fontWeight: 600, color: 'var(--ink)', marginBottom: '4px' }}>
              9.0 <span style={{ fontSize: '14px', fontWeight: 400, color: 'var(--mid-gray)' }}>mins</span>
            </div>
            <div style={{ fontSize: '12px', color: 'var(--mid-gray)' }}>vs 500.2 min unassisted</div>
          </div>

          <div className="clinical-card" style={{ padding: '20px' }}>
            <div className="caption" style={{ marginBottom: '6px' }}>Daily cost saving</div>
            <div style={{ fontSize: '24px', fontWeight: 600, color: 'var(--ink)', marginBottom: '4px' }}>
              $3,900
            </div>
            <div style={{ fontSize: '12px', color: 'var(--mid-gray)' }}>USD per 120 patients</div>
          </div>
        </div>
      </div>
    </section>
  );
};
