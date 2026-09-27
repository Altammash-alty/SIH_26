import { useEffect, useRef, useState } from 'react';
import { FundusViz } from './FundusViz';
import { usePrefersReducedMotion } from '../hooks/usePrefersReducedMotion';

const LOG_LINES = [
  '> scanning optic disc region...',
  '> microaneurysm detected — 4 regions',
  '> hemorrhage detected — 2 regions',
  '> exudates — low–moderate evidence',
];

const MARKERS: { x: number; y: number; kind: 'ma' | 'he' | 'ex'; afterLine: number }[] = [
  { x: 58, y: 46, kind: 'ma', afterLine: 1 },
  { x: 61, y: 49, kind: 'ma', afterLine: 1 },
  { x: 56, y: 53, kind: 'ma', afterLine: 1 },
  { x: 68, y: 46, kind: 'ma', afterLine: 1 },
  { x: 72, y: 48, kind: 'he', afterLine: 2 },
  { x: 76, y: 54, kind: 'he', afterLine: 2 },
  { x: 62, y: 55, kind: 'ex', afterLine: 3 },
  { x: 64, y: 56, kind: 'ex', afterLine: 3 },
];

function sleep(ms: number, signal: { cancelled: boolean }) {
  return new Promise<void>((resolve) => {
    const t = window.setTimeout(() => resolve(), ms);
    const poll = window.setInterval(() => {
      if (signal.cancelled) {
        window.clearTimeout(t);
        window.clearInterval(poll);
        resolve();
      }
    }, 40);
    window.setTimeout(() => window.clearInterval(poll), ms + 50);
  });
}

function markerColor(kind: 'ma' | 'he' | 'ex') {
  if (kind === 'ex') return 'var(--amber)';
  return 'var(--red)';
}

export function LiveAnalysisCard() {
  const reduced = usePrefersReducedMotion();
  const [logText, setLogText] = useState('');
  const [visibleMarkers, setVisibleMarkers] = useState(0);
  const [showResult, setShowResult] = useState(false);
  const [confidence, setConfidence] = useState(0);
  const [reviewed, setReviewed] = useState(false);
  const runId = useRef(0);

  useEffect(() => {
    if (reduced) {
      setLogText(LOG_LINES.join('\n'));
      setVisibleMarkers(MARKERS.length);
      setShowResult(true);
      setConfidence(94.8);
      setReviewed(true);
      return;
    }

    const signal = { cancelled: false };
    const id = ++runId.current;

    const countUp = () =>
      new Promise<void>((resolve) => {
        const start = performance.now();
        const tick = (now: number) => {
          if (signal.cancelled || runId.current !== id) return resolve();
          const p = Math.min(1, (now - start) / 900);
          const eased = 1 - (1 - p) ** 3;
          setConfidence(94.8 * eased);
          if (p < 1) requestAnimationFrame(tick);
          else resolve();
        };
        requestAnimationFrame(tick);
      });

    const cycle = async () => {
      while (!signal.cancelled) {
        setLogText('');
        setVisibleMarkers(0);
        setShowResult(false);
        setConfidence(0);
        setReviewed(false);

        let assembled = '';
        for (let i = 0; i < LOG_LINES.length; i++) {
          if (signal.cancelled) return;
          const line = (i === 0 ? '' : '\n') + LOG_LINES[i];
          for (let c = 0; c < line.length; c++) {
            if (signal.cancelled) return;
            assembled += line[c];
            setLogText(assembled);
            await sleep(16, signal);
          }
          setVisibleMarkers(MARKERS.filter((m) => m.afterLine <= i + 1).length);
          await sleep(280, signal);
        }

        if (signal.cancelled) return;
        setShowResult(true);
        await countUp();
        await sleep(500, signal);
        setReviewed(true);
        await sleep(1600, signal);
        await sleep(700, signal);
      }
    };

    void cycle();
    return () => {
      signal.cancelled = true;
    };
  }, [reduced]);

  return (
    <div className="live-card">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <div>
          <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', color: 'var(--ink-mid)' }}>
            Live analysis
          </div>
          <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--ink-mid)', marginTop: 2 }}>
            RA-02481 · OD
          </div>
        </div>
        <span
          className={reviewed ? 'badge badge-success' : 'badge badge-teal pulse-badge'}
          style={{ background: reviewed ? 'rgba(47,214,174,0.16)' : 'rgba(47,214,174,0.12)', color: '#0f6b56' }}
        >
          {!reviewed && <span className="blink-dot" style={{ background: '#0f6b56' }} />}
          {reviewed ? 'Reviewed' : 'Analyzing'}
        </span>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 132px', gap: 14, alignItems: 'start' }}>
        <div>
          <div style={{ position: 'relative', width: '100%', maxWidth: 268, margin: '0 auto', aspectRatio: '1' }}>
            <div className="scan-ring" aria-hidden="true" />
            <div style={{ position: 'relative', borderRadius: '50%', overflow: 'hidden', background: '#0D0404', aspectRatio: '1' }}>
              <FundusViz clean />
              {MARKERS.map((m, i) => (
                <span
                  key={i}
                  className={`lesion-dot${i < visibleMarkers ? ' on' : ''}`}
                  style={{
                    left: `${m.x}%`,
                    top: `${m.y}%`,
                    width: m.kind === 'he' ? 11 : 8,
                    height: m.kind === 'he' ? 11 : 8,
                    background: markerColor(m.kind),
                    boxShadow: `0 0 0 2px rgba(247,248,250,0.85), 0 0 10px ${markerColor(m.kind)}`,
                  }}
                />
              ))}
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, minHeight: 268 }}>
          <div
            style={{
              flex: 1,
              background: 'rgba(18,22,31,0.05)',
              borderRadius: 10,
              padding: '8px 10px',
              fontFamily: 'var(--font-mono)',
              fontSize: 10,
              lineHeight: 1.55,
              color: 'var(--ink-mid)',
              whiteSpace: 'pre-wrap',
              minHeight: 92,
            }}
          >
            {logText}
            {!reviewed && <span style={{ opacity: 0.45 }}>▍</span>}
          </div>

          <div
            style={{
              borderRadius: 10,
              padding: '10px 10px 9px',
              background: showResult ? 'rgba(240,166,63,0.12)' : 'rgba(18,22,31,0.04)',
              border: `1px solid ${showResult ? 'rgba(240,166,63,0.4)' : 'rgba(18,22,31,0.08)'}`,
              opacity: showResult ? 1 : 0.35,
              transition: 'opacity 400ms var(--ease-out), background 400ms var(--ease-out)',
            }}
          >
            <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--ink-mid)' }}>
              Severity
            </div>
            <div className="display" style={{ fontSize: 26, color: 'var(--ink)', lineHeight: 1, margin: '4px 0 2px' }}>
              Level 2
            </div>
            <div style={{ fontSize: 11, color: 'var(--ink-mid)' }}>Moderate NPDR</div>
          </div>

          <div style={{ borderRadius: 10, padding: '8px 10px', background: 'rgba(18,22,31,0.04)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: 'var(--ink-mid)', marginBottom: 5 }}>
              <span>Confidence</span>
              <span className="mono" style={{ color: 'var(--ink)', fontWeight: 500 }}>{confidence.toFixed(1)}%</span>
            </div>
            <div className="conf-bar-track" style={{ background: 'rgba(18,22,31,0.12)' }}>
              <div className="conf-bar-fill" style={{ width: `${(confidence / 94.8) * 94.8}%`, background: 'var(--teal)' }} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
