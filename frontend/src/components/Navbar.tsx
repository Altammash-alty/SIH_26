import React, { useState, useEffect } from 'react';

interface NavbarProps {
  onLaunch: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ onLaunch }) => {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <nav
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        height: '56px',
        backgroundColor: scrolled ? 'var(--surface-alt)' : 'transparent',
        borderBottom: scrolled ? '1px solid var(--hairline)' : '1px solid transparent',
        transition: 'background-color 200ms ease, border-color 200ms ease',
        zIndex: 40,
        display: 'flex',
        alignItems: 'center',
      }}
    >
      <div
        style={{
          maxWidth: '1200px',
          width: '100%',
          margin: '0 auto',
          padding: '0 var(--sp-24)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        {/* Brand Wordmark */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div
            style={{
              width: '28px',
              height: '28px',
              backgroundColor: 'var(--ink)',
              borderRadius: 'var(--radius-nested)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'var(--paper)',
              fontSize: '14px',
              fontWeight: 600,
            }}
          >
            R
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '8px' }}>
            <span style={{ fontSize: '16px', fontWeight: 600, letterSpacing: '-0.02em', color: 'var(--ink)' }}>
              RetinaAI
            </span>
            <span style={{ fontSize: '11px', color: 'var(--mid-gray)', fontFamily: 'var(--font-mono)' }}>
              SIH 26038
            </span>
          </div>
        </div>

        {/* Anchor Navigation Links */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
          <a
            href="#pipeline"
            style={{
              fontSize: '14px',
              fontWeight: 400,
              color: 'var(--mid-gray)',
              textDecoration: 'none',
              transition: 'color 150ms ease',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--ink)')}
            onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--mid-gray)')}
          >
            Pipeline
          </a>
          <a
            href="#workspace"
            style={{
              fontSize: '14px',
              fontWeight: 400,
              color: 'var(--mid-gray)',
              textDecoration: 'none',
              transition: 'color 150ms ease',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--ink)')}
            onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--mid-gray)')}
          >
            Workspace
          </a>
          <a
            href="#validation"
            style={{
              fontSize: '14px',
              fontWeight: 400,
              color: 'var(--mid-gray)',
              textDecoration: 'none',
              transition: 'color 150ms ease',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--ink)')}
            onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--mid-gray)')}
          >
            Validation
          </a>
          <a
            href="#deployment"
            style={{
              fontSize: '14px',
              fontWeight: 400,
              color: 'var(--mid-gray)',
              textDecoration: 'none',
              transition: 'color 150ms ease',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.color = 'var(--ink)')}
            onMouseLeave={(e) => (e.currentTarget.style.color = 'var(--mid-gray)')}
          >
            Deployment
          </a>
        </div>

        {/* Primary CTA */}
        <button
          type="button"
          onClick={onLaunch}
          className="btn-primary"
          style={{ height: '36px', fontSize: '13px', padding: '0 16px' }}
        >
          Screen an Image
        </button>
      </div>
    </nav>
  );
};
