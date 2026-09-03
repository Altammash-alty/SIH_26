import { useState } from 'react';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { TrustStrip } from './components/TrustStrip';
import { WorkflowSection } from './components/WorkflowSection';
import { ScreeningDemo } from './components/ScreeningDemo';
import { QualityModule } from './components/QualityModule';
import { ExplainabilitySection } from './components/ExplainabilitySection';
import { SeverityScale } from './components/SeverityScale';
import { HumanInLoop } from './components/HumanInLoop';
import { RuralDeployment } from './components/RuralDeployment';
import { ValidationSection } from './components/ValidationSection';
import { FinalCTA } from './components/FinalCTA';
import { Footer } from './components/Footer';
import { ScreeningStudio } from './components/ScreeningStudio';

export function App() {
  const [screeningOpen, setScreeningOpen] = useState(false);

  return (
    <div style={{ background: 'linear-gradient(180deg, #061521 0%, #0a1a2b 100%)', minHeight: '100vh', color: 'var(--text-primary)' }}>
      {screeningOpen && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(2, 6, 23, 0.72)',
            backdropFilter: 'blur(8px)',
            zIndex: 50,
            overflowY: 'auto',
            padding: '32px 20px',
          }}
        >
          <div style={{ maxWidth: '1500px', margin: '0 auto', position: 'relative' }}>
            <button
              type="button"
              onClick={() => setScreeningOpen(false)}
              style={{
                position: 'absolute',
                top: '12px',
                right: '12px',
                zIndex: 1,
                border: '1px solid rgba(148, 163, 184, 0.5)',
                background: 'rgba(15, 23, 42, 0.8)',
                color: '#fff',
                borderRadius: '999px',
                padding: '10px 14px',
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              Close
            </button>
            <div
              style={{
                background: 'linear-gradient(180deg, rgba(8, 20, 33, 0.96), rgba(13, 28, 46, 0.96))',
                borderRadius: '28px',
                border: '1px solid rgba(148, 163, 184, 0.28)',
                boxShadow: '0 28px 80px rgba(2, 6, 23, 0.65)',
                overflow: 'hidden',
              }}
            >
              <ScreeningStudio />
            </div>
          </div>
        </div>
      )}

      <Navbar onLaunch={() => setScreeningOpen(true)} />
      <Hero onLaunch={() => setScreeningOpen(true)} />
      <TrustStrip />
      <WorkflowSection />
      <ScreeningDemo />
      <QualityModule />
      <ExplainabilitySection />
      <SeverityScale />
      <HumanInLoop />
      <RuralDeployment />
      <ValidationSection />
      <FinalCTA onLaunch={() => setScreeningOpen(true)} />
      <Footer />
    </div>
  );
}

export default App;
