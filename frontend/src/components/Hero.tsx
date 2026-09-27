import React from 'react';
import { HeroPreviewCard } from './HeroPreviewCard';

interface HeroProps {
  onLaunch: () => void;
}

export const Hero: React.FC<HeroProps> = ({ onLaunch }) => {
  return (
    <section
      style={{
        backgroundColor: 'var(--canvas)',
        paddingTop: '120px',
        paddingBottom: '64px',
        borderBottom: '1px solid var(--hairline)',
      }}
    >
      <div
        className="section-container"
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 1.2fr) minmax(360px, 440px)',
          gap: 'var(--sp-48)',
          alignItems: 'center',
          paddingTop: 0,
          paddingBottom: 0,
        }}
      >
        {/* Left Column: Copy & Actions */}
        <div>
          {/* Eyebrow */}
          <div
            style={{
              fontSize: '12px',
              fontWeight: 500,
              letterSpacing: '0.04em',
              color: 'var(--mid-gray)',
              fontFamily: 'var(--font-mono)',
              marginBottom: '16px',
            }}
          >
            ICDR Grade 0–4 · SIH 26038 · MathWorks
          </div>

          {/* Display Headline */}
          <h1
            className="display-title"
            style={{ marginBottom: '20px', maxWidth: '620px' }}
          >
            Fundus screening that explains itself.
          </h1>

          {/* Subhead */}
          <p
            className="body-lg"
            style={{ marginBottom: '32px', maxWidth: '520px' }}
          >
            A 5-stage computer vision pipeline that assesses image quality, enhances contrast, detects retinal lesions, grades diabetic retinopathy severity on the ICDR scale, and returns a Grad-CAM attention map alongside each finding. Built for primary care and tele-ophthalmology.
          </p>

          {/* Action CTAs */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              marginBottom: '48px',
            }}
          >
            <button
              type="button"
              onClick={onLaunch}
              className="btn-primary"
              style={{ padding: '12px 24px', fontSize: '15px' }}
            >
              Screen an image
            </button>
            <a
              href="#pipeline"
              className="btn-secondary"
              style={{ padding: '12px 24px', fontSize: '15px' }}
            >
              See the pipeline
            </a>
          </div>

          {/* Stat Strip Below CTA Line */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
              paddingTop: '20px',
              borderTop: '1px solid var(--hairline)',
            }}
          >
            <div style={{ fontSize: '12px', color: 'var(--mid-gray)' }}>
              <span style={{ fontWeight: 600, color: 'var(--ink)' }}>ICDR Grade 0–4</span>{' '}
              severity classification
            </div>
            <span style={{ color: 'var(--hairline)' }}>/</span>
            <div style={{ fontSize: '12px', color: 'var(--mid-gray)' }}>
              <span style={{ fontWeight: 600, color: 'var(--ink)' }}>Grad-CAM</span>{' '}
              lesion-level evidence
            </div>
            <span style={{ color: 'var(--hairline)' }}>/</span>
            <div style={{ fontSize: '12px', color: 'var(--mid-gray)' }}>
              <span style={{ fontWeight: 600, color: 'var(--ink)' }}>IDRiD + Messidor-2</span>{' '}
              validation datasets
            </div>
          </div>
        </div>

        {/* Right Column: HeroPreviewCard */}
        <div style={{ display: 'flex', justifyContent: 'center' }}>
          <HeroPreviewCard />
        </div>
      </div>
    </section>
  );
};
