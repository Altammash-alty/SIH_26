import React from 'react';

const LESION_EVIDENCE = [
  { name: 'Microaneurysms', count: 48, confidence: '99.4%', status: 'Detected (High)', flag: 'amber' },
  { name: 'Hemorrhages', count: 18, confidence: '98.1%', status: 'Detected (High)', flag: 'amber' },
  { name: 'Hard exudates', count: 24, confidence: '96.5%', status: 'Cluster Detected', flag: 'amber' },
  { name: 'Cotton-wool spots', count: 6, confidence: '91.2%', status: 'Present', flag: 'amber' },
  { name: 'Neovascularization', count: 2, confidence: '95.8%', status: 'NVD Arcade Suspected', flag: 'amber' },
];

export const ExplainabilitySection: React.FC = () => {
  return (
    <section id="workspace" style={{ backgroundColor: 'var(--surface-alt)', padding: '80px 0', borderTop: '1px solid var(--hairline)', borderBottom: '1px solid var(--hairline)' }}>
      <div className="section-container">
        {/* Section Header */}
        <div style={{ marginBottom: '48px', maxWidth: '640px' }}>
          <div className="caption" style={{ marginBottom: '12px' }}>
            Explainability
          </div>
          <h2 className="heading-lg" style={{ marginBottom: '16px' }}>
            Every grade is backed by visible evidence.
          </h2>
          <p className="body-lg">
            The pipeline does not output a number and stop. The saliency map shows which retinal regions drove the classification. The evidence panel lists each detected lesion type, the confidence score for that finding, and whether it is above or below the decision threshold for referral.
          </p>
        </div>

        {/* Evidence Card Grid */}
        <div
          className="clinical-card"
          style={{
            display: 'grid',
            gridTemplateColumns: 'minmax(320px, 1.1fr) minmax(320px, 1fr)',
            gap: '32px',
            padding: '32px',
          }}
        >
          {/* Left: Fundus Saliency Visualizer */}
          <div>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: '16px',
              }}
            >
              <span style={{ fontSize: '14px', fontWeight: 600, color: 'var(--ink)' }}>
                Case VAL-001 Saliency Overlay
              </span>
              <span className="badge-teal">Grad-CAM + Lesion Attention</span>
            </div>

            <div
              style={{
                borderRadius: 'var(--radius-nested)',
                backgroundColor: '#0a0a0a',
                aspectRatio: '4 / 3',
                position: 'relative',
                overflow: 'hidden',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <svg viewBox="0 0 400 300" style={{ width: '100%', height: '100%' }}>
                {/* Retinal Boundary */}
                <circle cx="200" cy="150" r="130" fill="#180e07" stroke="#381b0d" strokeWidth="2" />

                {/* Saliency Heatmap Heat Zones (Grad-CAM Attention) */}
                <ellipse cx="170" cy="140" rx="55" ry="40" fill="rgba(15, 118, 110, 0.25)" />
                <ellipse cx="165" cy="145" rx="35" ry="25" fill="rgba(180, 83, 9, 0.35)" />
                <circle cx="162" cy="146" r="15" fill="rgba(180, 83, 9, 0.55)" />

                {/* Optic Disc */}
                <circle cx="270" cy="150" r="26" fill="#f59e0b" opacity="0.8" />
                <circle cx="270" cy="150" r="13" fill="#fef08a" opacity="0.9" />

                {/* Major Vessels */}
                <path d="M 270 150 Q 230 75 150 70 Q 100 65 75 80" fill="none" stroke="#4a150c" strokeWidth="3" />
                <path d="M 270 150 Q 230 225 150 230 Q 100 235 75 220" fill="none" stroke="#4a150c" strokeWidth="3" />

                {/* Microaneurysms / Hemorrhages (Amber markers) */}
                <circle cx="160" cy="145" r="3.5" fill="#b45309" stroke="#ffffff" strokeWidth="0.8" />
                <circle cx="172" cy="138" r="3" fill="#b45309" stroke="#ffffff" strokeWidth="0.8" />
                <circle cx="152" cy="152" r="3" fill="#b45309" stroke="#ffffff" strokeWidth="0.8" />
                <circle cx="180" cy="158" r="2.5" fill="#b45309" stroke="#ffffff" strokeWidth="0.8" />

                {/* Exudates */}
                <rect x="185" y="130" width="5" height="4" fill="#fbbf24" stroke="#ffffff" strokeWidth="0.5" />
                <rect x="192" y="133" width="6" height="5" fill="#fbbf24" stroke="#ffffff" strokeWidth="0.5" />
              </svg>

              <div
                style={{
                  position: 'absolute',
                  bottom: '12px',
                  left: '12px',
                  backgroundColor: 'rgba(10, 10, 10, 0.85)',
                  border: '1px solid rgba(229, 229, 229, 0.15)',
                  borderRadius: 'var(--radius-badge)',
                  padding: '4px 10px',
                  fontSize: '11px',
                  fontFamily: 'var(--font-mono)',
                  color: '#ffffff',
                }}
              >
                Hotspot: Superior Temporal Arcade (ETDRS Q1)
              </div>
            </div>
          </div>

          {/* Right: Pathological Evidence Table */}
          <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
            <div>
              <div
                style={{
                  fontSize: '11px',
                  fontFamily: 'var(--font-mono)',
                  fontWeight: 600,
                  letterSpacing: '0.04em',
                  color: 'var(--mid-gray)',
                  marginBottom: '8px',
                }}
              >
                CLINICAL REASONING
              </div>
              <h3 style={{ fontSize: '18px', fontWeight: 600, color: 'var(--ink)', marginBottom: '8px' }}>
                Why was this image classified as Proliferative DR?
              </h3>
              <p style={{ fontSize: '13px', color: 'var(--mid-gray)', marginBottom: '24px' }}>
                Automated lesion detection identified extensive dark intraretinal lesions and hard exudate clusters within 1-disc-diameter of the fovea, meeting ETDRS referral criteria.
              </p>

              {/* Lesion List */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                {LESION_EVIDENCE.map((item) => (
                  <div
                    key={item.name}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      padding: '8px 12px',
                      backgroundColor: 'var(--surface-alt)',
                      borderRadius: 'var(--radius-nested)',
                      border: '1px solid var(--hairline)',
                    }}
                  >
                    <div>
                      <div style={{ fontSize: '13px', fontWeight: 500, color: 'var(--ink-soft)' }}>
                        {item.name}
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--mid-gray)', fontFamily: 'var(--font-mono)' }}>
                        Count: {item.count} · {item.status}
                      </div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <span className="badge-amber">{item.confidence}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Model Agreement Bottom Row */}
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                paddingTop: '16px',
                marginTop: '20px',
                borderTop: '1px solid var(--hairline)',
                fontSize: '13px',
              }}
            >
              <span style={{ color: 'var(--mid-gray)' }}>Model agreement:</span>
              <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 600, color: 'var(--teal)' }}>
                100.0% Consensus
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
