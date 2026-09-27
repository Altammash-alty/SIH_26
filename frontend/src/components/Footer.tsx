import React from 'react';

export const Footer: React.FC = () => {
  return (
    <footer
      style={{
        backgroundColor: 'var(--canvas)',
        borderTop: '1px solid var(--hairline)',
        padding: '48px 0',
      }}
    >
      <div
        className="section-container"
        style={{
          paddingTop: 0,
          paddingBottom: 0,
          display: 'flex',
          flexDirection: 'column',
          gap: '24px',
        }}
      >
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: '16px',
          }}
        >
          {/* Brand */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div
              style={{
                width: '24px',
                height: '24px',
                backgroundColor: 'var(--ink)',
                borderRadius: '6px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'var(--paper)',
                fontSize: '12px',
                fontWeight: 600,
              }}
            >
              R
            </div>
            <span style={{ fontSize: '15px', fontWeight: 600, color: 'var(--ink)' }}>
              RetinaAI
            </span>
            <span style={{ fontSize: '12px', color: 'var(--mid-gray)', fontFamily: 'var(--font-mono)' }}>
              SIH 26038
            </span>
          </div>

          {/* Links */}
          <div style={{ display: 'flex', gap: '20px' }}>
            <a href="#pipeline" style={{ fontSize: '13px', color: 'var(--mid-gray)', textDecoration: 'none' }}>
              Pipeline
            </a>
            <a href="#workspace" style={{ fontSize: '13px', color: 'var(--mid-gray)', textDecoration: 'none' }}>
              Workspace
            </a>
            <a href="#validation" style={{ fontSize: '13px', color: 'var(--mid-gray)', textDecoration: 'none' }}>
              Validation
            </a>
            <a href="#deployment" style={{ fontSize: '13px', color: 'var(--mid-gray)', textDecoration: 'none' }}>
              Deployment
            </a>
          </div>
        </div>

        {/* Tagline & Legal Note */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: '12px',
            paddingTop: '20px',
            borderTop: '1px solid var(--hairline)',
            fontSize: '12px',
            color: 'var(--mid-gray)',
          }}
        >
          <div>Built for SIH 2025, problem statement 26038. MathWorks partnership.</div>
          <div>Research prototype. Not validated for clinical use without independent verification.</div>
        </div>
      </div>
    </footer>
  );
};
