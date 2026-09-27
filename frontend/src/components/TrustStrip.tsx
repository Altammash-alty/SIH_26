import React from 'react';

export const TrustStrip: React.FC = () => {
  return (
    <section
      style={{
        backgroundColor: 'var(--surface-alt)',
        borderTop: '1px solid var(--hairline)',
        borderBottom: '1px solid var(--hairline)',
        padding: '32px 0',
      }}
    >
      <div
        className="section-container"
        style={{
          paddingTop: 0,
          paddingBottom: 0,
          display: 'grid',
          gridTemplateColumns: 'repeat(3, 1fr)',
          gap: 'var(--sp-24)',
        }}
      >
        {/* Metric 1 */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
          <div
            style={{
              fontSize: '36px',
              fontWeight: 600,
              letterSpacing: '-0.04em',
              lineHeight: 1.1,
              color: 'var(--ink)',
            }}
          >
            77M
          </div>
          <div
            style={{
              fontSize: '12px',
              fontWeight: 500,
              letterSpacing: '0.04em',
              color: 'var(--mid-gray)',
            }}
          >
            adults with diabetes in India (IDF 2023)
          </div>
        </div>

        {/* Metric 2 */}
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: '4px',
            borderLeft: '1px solid var(--hairline)',
            paddingLeft: 'var(--sp-24)',
          }}
        >
          <div
            style={{
              fontSize: '36px',
              fontWeight: 600,
              letterSpacing: '-0.04em',
              lineHeight: 1.1,
              color: 'var(--ink)',
            }}
          >
            1 : 100,000
          </div>
          <div
            style={{
              fontSize: '12px',
              fontWeight: 500,
              letterSpacing: '0.04em',
              color: 'var(--mid-gray)',
            }}
          >
            ophthalmologist-to-rural-population ratio
          </div>
        </div>

        {/* Metric 3 */}
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: '4px',
            borderLeft: '1px solid var(--hairline)',
            paddingLeft: 'var(--sp-24)',
          }}
        >
          <div
            style={{
              fontSize: '36px',
              fontWeight: 600,
              letterSpacing: '-0.04em',
              lineHeight: 1.1,
              color: 'var(--ink)',
            }}
          >
            90%
          </div>
          <div
            style={{
              fontSize: '12px',
              fontWeight: 500,
              letterSpacing: '0.04em',
              color: 'var(--mid-gray)',
            }}
          >
            of DR blindness preventable with early detection
          </div>
        </div>
      </div>
    </section>
  );
};
