import { useState } from 'react';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { TrustStrip } from './components/TrustStrip';
import { WorkflowSection } from './components/WorkflowSection';
import { ScreeningDemo } from './components/ScreeningDemo';
import { RuralDeployment } from './components/RuralDeployment';
import { ValidationSection } from './components/ValidationSection';
import { Footer } from './components/Footer';
import { ScreeningStudio } from './components/ScreeningStudio';
import { ExplainabilitySection } from './components/ExplainabilitySection';

export function App() {
  const [screeningOpen, setScreeningOpen] = useState(false);

  return (
    <div style={{ minHeight: '100vh', backgroundColor: 'var(--canvas)', color: 'var(--ink)' }}>
      {screeningOpen && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '16px 24px',
                borderBottom: '1px solid var(--hairline)',
                backgroundColor: 'var(--surface-alt)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ fontSize: '14px', fontWeight: 600, color: 'var(--ink)' }}>
                  Autonomous DR Screening Studio
                </span>
                <span className="badge-teal">MathWorks SIH 26038</span>
              </div>
              <button
                type="button"
                onClick={() => setScreeningOpen(false)}
                className="btn-secondary"
                style={{ padding: '6px 14px', fontSize: '13px' }}
              >
                Close
              </button>
            </div>
            <div>
              <ScreeningStudio />
            </div>
          </div>
        </div>
      )}

      <Navbar onLaunch={() => setScreeningOpen(true)} />
      <Hero onLaunch={() => setScreeningOpen(true)} />
      <TrustStrip />
      <WorkflowSection />
      <ScreeningDemo onLaunch={() => setScreeningOpen(true)} />
      <ExplainabilitySection />
      <ValidationSection />
      <RuralDeployment />
      <Footer />
    </div>
  );
}

export default App;
