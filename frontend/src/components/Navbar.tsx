import { useState, useEffect } from 'react';

interface NavbarProps {
  onLaunch: () => void;
}

export function Navbar({ onLaunch }: NavbarProps) {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const navStyle: React.CSSProperties = {
    position: 'fixed',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 1000,
    height: '56px',
    display: 'flex',
    alignItems: 'center',
    background: scrolled ? 'rgba(248,250,252,0.95)' : 'rgba(248,250,252,0.80)',
    backdropFilter: 'blur(12px)',
    borderBottom: scrolled ? '1px solid var(--border-default)' : '1px solid transparent',
    transition: 'all 200ms ease',
  };

  return (
    <nav style={navStyle}>
      <div className="container" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
        {/* Brand */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            width: '28px', height: '28px', borderRadius: '7px',
            background: 'var(--accent-blue)', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <circle cx="8" cy="8" r="6" stroke="white" strokeWidth="1.5" fill="none"/>
              <circle cx="8" cy="8" r="2" fill="white"/>
              <line x1="8" y1="2" x2="8" y2="4" stroke="white" strokeWidth="1.5" strokeLinecap="round"/>
              <line x1="8" y1="12" x2="8" y2="14" stroke="white" strokeWidth="1.5" strokeLinecap="round"/>
            </svg>
          </div>
          <div>
            <div style={{ fontSize: '15px', fontWeight: 600, color: 'var(--text-primary)', lineHeight: 1 }}>
              RetinaAI
            </div>
            <div style={{ fontSize: '10px', color: 'var(--text-tertiary)', lineHeight: 1, marginTop: '2px' }}>
              Explainable DR Screening
            </div>
          </div>
        </div>

        {/* Nav links */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
          {['Platform', 'Explainability', 'Clinical Workflow', 'Validation'].map(item => (
            <a
              key={item}
              href={`#${item.toLowerCase().replace(/ /g, '-')}`}
              style={{
                padding: '6px 12px',
                fontSize: 'var(--text-sm)',
                color: 'var(--text-secondary)',
                textDecoration: 'none',
                borderRadius: 'var(--radius-sm)',
                transition: 'color 150ms',
                fontWeight: 450,
              }}
              onMouseEnter={e => (e.currentTarget.style.color = 'var(--text-primary)')}
              onMouseLeave={e => (e.currentTarget.style.color = 'var(--text-secondary)')}
            >
              {item}
            </a>
          ))}
          <button
            className="btn btn-primary btn-sm"
            onClick={onLaunch}
            style={{ marginLeft: 'var(--space-2)' }}
          >
            Launch Screening
          </button>
        </div>
      </div>
    </nav>
  );
}
