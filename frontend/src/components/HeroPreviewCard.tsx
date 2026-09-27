import React from 'react';

export const HeroPreviewCard: React.FC = () => {
  return (
    <div
      style={{
        backgroundColor: 'var(--paper)',
        borderRadius: 'var(--radius-card)',
        border: 'var(--card-border)',
        boxShadow: 'var(--card-shadow)',
        padding: '20px',
        width: '100%',
        maxWidth: '440px',
      }}
    >
      {/* Top Header */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '16px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span
            style={{
              width: '8px',
              height: '8px',
              borderRadius: '50%',
              backgroundColor: 'var(--teal)',
              display: 'inline-block',
            }}
          />
          <span style={{ fontSize: '13px', fontWeight: 500, color: 'var(--ink)' }}>
            Case IDRiD_004
          </span>
        </div>
        <span className="badge-teal">Quality 87.6 · Passed</span>
      </div>

      {/* Simulated Fundus Viewport */}
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
          marginBottom: '16px',
        }}
      >
        {/* Subtle schematic fundus retina SVG */}
        <svg
          viewBox="0 0 400 300"
          style={{ width: '100%', height: '100%', display: 'block' }}
        >
          {/* Circular retinal boundary */}
          <circle cx="200" cy="150" r="130" fill="#1f1008" stroke="#33180c" strokeWidth="2" />
          
          {/* Optic Disc */}
          <circle cx="270" cy="150" r="28" fill="#e89d52" opacity="0.85" />
          <circle cx="270" cy="150" r="14" fill="#fcd38d" opacity="0.9" />

          {/* Macula / Fovea */}
          <circle cx="150" cy="150" r="16" fill="#140a05" />
          <circle cx="150" cy="150" r="4" fill="#0d0603" />

          {/* Major Vascular Arcades */}
          <path
            d="M 270 150 Q 240 80 160 70 Q 110 65 80 80"
            fill="none"
            stroke="#5c190f"
            strokeWidth="3.5"
            strokeLinecap="round"
          />
          <path
            d="M 270 150 Q 240 220 160 230 Q 110 235 80 220"
            fill="none"
            stroke="#5c190f"
            strokeWidth="3.5"
            strokeLinecap="round"
          />
          <path
            d="M 270 150 Q 300 110 325 90"
            fill="none"
            stroke="#5c190f"
            strokeWidth="2.5"
            strokeLinecap="round"
          />
          <path
            d="M 270 150 Q 300 190 325 210"
            fill="none"
            stroke="#5c190f"
            strokeWidth="2.5"
            strokeLinecap="round"
          />

          {/* Pathological Lesions: Microaneurysms (Amber dots) */}
          <circle cx="180" cy="120" r="3" fill="#b45309" />
          <circle cx="130" cy="130" r="2.5" fill="#b45309" />
          <circle cx="195" cy="175" r="3" fill="#b45309" />
          <circle cx="140" cy="180" r="2" fill="#b45309" />

          {/* Exudates (Yellow/Amber clusters) */}
          <rect x="165" y="140" width="4" height="4" rx="1" fill="#f59e0b" />
          <rect x="171" y="143" width="5" height="4" rx="1" fill="#f59e0b" />
          <rect x="168" y="148" width="4" height="3" rx="1" fill="#f59e0b" />

          {/* Grad-CAM Saliency Halo around lesions */}
          <circle cx="170" cy="145" r="35" fill="none" stroke="#0f766e" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.7" />
        </svg>

        {/* Floating Attention Tag */}
        <div
          style={{
            position: 'absolute',
            bottom: '10px',
            left: '10px',
            backgroundColor: 'rgba(10, 10, 10, 0.85)',
            border: '1px solid rgba(229, 229, 229, 0.2)',
            borderRadius: 'var(--radius-badge)',
            padding: '4px 8px',
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
          }}
        >
          <span style={{ fontSize: '11px', color: '#f5f5f5', fontFamily: 'var(--font-mono)' }}>
            Grad-CAM focus: Macular Arcade
          </span>
        </div>
      </div>

      {/* Metric Breakdown Rows */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            fontSize: '13px',
          }}
        >
          <span style={{ color: 'var(--mid-gray)' }}>AI Severity Grade</span>
          <span style={{ fontWeight: 600, color: 'var(--amber)' }}>
            Proliferative DR (Grade 4)
          </span>
        </div>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            fontSize: '13px',
          }}
        >
          <span style={{ color: 'var(--mid-gray)' }}>Diagnostic Confidence</span>
          <span style={{ fontFamily: 'var(--font-mono)', fontWeight: 500, color: 'var(--ink)' }}>
            99.9%
          </span>
        </div>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            fontSize: '13px',
            paddingTop: '8px',
            borderTop: '1px solid var(--hairline)',
          }}
        >
          <span style={{ color: 'var(--mid-gray)' }}>Triage Routing</span>
          <span style={{ color: 'var(--amber)', fontWeight: 500 }}>
            Specialist Referral (&lt; 48h)
          </span>
        </div>
      </div>
    </div>
  );
};
