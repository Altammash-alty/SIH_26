import { useState } from 'react';
import { Activity, Play, RefreshCw, Clock, DollarSign, BarChart3, Info } from 'lucide-react';

interface SimulationMetrics {
  numPatients: number;
  aiThroughputPatientsPerHour: number;
  manualThroughputPatientsPerHour: number;
  throughputMultiplier: number;
  aiAvgWaitTimeMinutes: number;
  manualAvgWaitTimeMinutes: number;
  doctorTimeSavedPercent: number;
  totalDailyCostSavingsUSD: number;
  totalAiShiftHours: number;
  totalManualShiftHours: number;
  gradeCounts: {
    grade0: number;
    grade1: number;
    grade2: number;
    grade3: number;
    grade4: number;
  };
  retakeCount: number;
}

export const SimulationDashboard: React.FC = () => {
  const [numPatients, setNumPatients] = useState<number>(120);
  const [arrivalRate, setArrivalRate] = useState<number>(15);
  const [scanDuration, setScanDuration] = useState<number>(3.0);
  const [retakeRate, setRetakeRate] = useState<number>(0.08);

  const [simMetrics, setSimMetrics] = useState<SimulationMetrics | null>({
    numPatients: 120,
    aiThroughputPatientsPerHour: 13.4,
    manualThroughputPatientsPerHour: 4.9,
    throughputMultiplier: 2.73,
    aiAvgWaitTimeMinutes: 9.0,
    manualAvgWaitTimeMinutes: 500.2,
    doctorTimeSavedPercent: 85.2,
    totalDailyCostSavingsUSD: 3900.0,
    totalAiShiftHours: 8.9,
    totalManualShiftHours: 24.5,
    gradeCounts: {
      grade0: 78,
      grade1: 22,
      grade2: 12,
      grade3: 5,
      grade4: 3
    },
    retakeCount: 10
  });

  const [running, setRunning] = useState<boolean>(false);

  const handleRunSimulation = async () => {
    setRunning(true);
    try {
      const res = await fetch('/api/simulate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          numPatients,
          arrivalRatePerHour: arrivalRate,
          scanDurationMinutes: scanDuration,
          retakeProbability: retakeRate
        })
      });

      if (!res.ok) throw new Error('Simulation calculation failed');
      const data: SimulationMetrics = await res.json();
      setSimMetrics(data);
    } catch (err: any) {
      console.error(err);
      alert('Failed to run simulation: ' + err.message);
    } finally {
      setRunning(false);
    }
  };

  return (
    <div style={{ maxWidth: '1400px', margin: '0 auto', padding: '2rem' }}>
      
      {/* Header */}
      <div style={{ marginBottom: '2.5rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
          <span className="badge badge-info">STAGE 6 CLINICAL OPERATIONS</span>
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
            Discrete-Event Monte Carlo Simulation Model
          </span>
        </div>
        <h2 style={{ fontSize: '2.2rem', fontWeight: 800, letterSpacing: '-0.02em' }}>
          Tele-Ophthalmology Clinic Throughput Simulator
        </h2>
        <p style={{ color: 'var(--text-secondary)' }}>
          Simulates patient Poisson arrivals, technician camera acquisition, empirical retake penalties, and AI fast-tracking against traditional manual ophthalmologist examinations.
        </p>
      </div>

      <div style={{
        display: 'grid',
        gridTemplateColumns: '380px 1fr',
        gap: '2rem',
        alignItems: 'start'
      }}>
        
        {/* Controls Column */}
        <div className="glass-panel" style={{ padding: '1.75rem' }}>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Activity size={18} color="var(--cyan-400)" />
            Simulation Parameters
          </h3>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            
            {/* Slider 1: Cohort Volume */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                <label style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>
                  Daily Patient Cohort
                </label>
                <span style={{ fontSize: '0.85rem', fontWeight: 800, fontFamily: 'var(--font-mono)', color: 'var(--cyan-400)' }}>
                  {numPatients} patients
                </span>
              </div>
              <input
                type="range"
                min={30}
                max={300}
                step={10}
                value={numPatients}
                onChange={(e) => setNumPatients(Number(e.target.value))}
                style={{ width: '100%', accentColor: 'var(--cyan-500)', cursor: 'pointer' }}
              />
            </div>

            {/* Slider 2: Arrival Rate */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                <label style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>
                  Poisson Arrival Rate
                </label>
                <span style={{ fontSize: '0.85rem', fontWeight: 800, fontFamily: 'var(--font-mono)', color: 'var(--cyan-400)' }}>
                  {arrivalRate} pts / hr
                </span>
              </div>
              <input
                type="range"
                min={5}
                max={40}
                step={1}
                value={arrivalRate}
                onChange={(e) => setArrivalRate(Number(e.target.value))}
                style={{ width: '100%', accentColor: 'var(--cyan-500)', cursor: 'pointer' }}
              />
            </div>

            {/* Slider 3: Technician Camera Time */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                <label style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>
                  Technician Scan Duration
                </label>
                <span style={{ fontSize: '0.85rem', fontWeight: 800, fontFamily: 'var(--font-mono)', color: 'var(--cyan-400)' }}>
                  {scanDuration.toFixed(1)} mins
                </span>
              </div>
              <input
                type="range"
                min={1.5}
                max={6.0}
                step={0.5}
                value={scanDuration}
                onChange={(e) => setScanDuration(Number(e.target.value))}
                style={{ width: '100%', accentColor: 'var(--cyan-500)', cursor: 'pointer' }}
              />
            </div>

            {/* Slider 4: Stage 1 Retake Rate */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
                <label style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>
                  Empirical Retake Rate
                </label>
                <span style={{ fontSize: '0.85rem', fontWeight: 800, fontFamily: 'var(--font-mono)', color: 'var(--cyan-400)' }}>
                  {(retakeRate * 100).toFixed(0)}%
                </span>
              </div>
              <input
                type="range"
                min={0.02}
                max={0.25}
                step={0.01}
                value={retakeRate}
                onChange={(e) => setRetakeRate(Number(e.target.value))}
                style={{ width: '100%', accentColor: 'var(--cyan-500)', cursor: 'pointer' }}
              />
            </div>

            <button
              onClick={handleRunSimulation}
              disabled={running}
              style={{
                marginTop: '1rem',
                background: 'linear-gradient(135deg, var(--cyan-500), #2563eb)',
                color: '#ffffff',
                border: 'none',
                padding: '14px',
                borderRadius: 'var(--radius-md)',
                fontSize: '0.95rem',
                fontWeight: 700,
                cursor: running ? 'not-allowed' : 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px',
                boxShadow: '0 4px 15px rgba(14, 165, 233, 0.35)'
              }}
            >
              {running ? <RefreshCw size={18} className="pulse-glow" /> : <Play size={18} />}
              Run Monte Carlo Engine
            </button>

            <div style={{
              background: 'rgba(255, 255, 255, 0.03)',
              padding: '12px',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--border-subtle)',
              fontSize: '0.75rem',
              color: 'var(--text-muted)',
              lineHeight: 1.5,
              display: 'flex',
              gap: '8px'
            }}>
              <Info size={24} style={{ flexShrink: 0, color: 'var(--cyan-400)' }} />
              <span>
                <strong>Data Provenance Notice:</strong> Retake rate and AI latency are calibrated from real IDRiD measurements; doctor review durations are simulated constants based on NHS/ETDRS literature.
              </span>
            </div>

          </div>
        </div>

        {/* Results Metrics Column */}
        {simMetrics && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            
            {/* Top KPI Cards */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(3, 1fr)',
              gap: '1.25rem'
            }}>
              
              <div className="glass-panel" style={{ padding: '1.5rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>
                    Throughput Speedup
                  </span>
                  <BarChart3 size={18} color="var(--cyan-400)" />
                </div>
                <div style={{ fontSize: '2.4rem', fontWeight: 800, color: 'var(--cyan-400)', marginTop: '4px' }}>
                  {simMetrics.throughputMultiplier}x
                </div>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '4px' }}>
                  {simMetrics.aiThroughputPatientsPerHour} vs {simMetrics.manualThroughputPatientsPerHour} patients/hr
                </div>
              </div>

              <div className="glass-panel" style={{ padding: '1.5rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>
                    Workload Reduction
                  </span>
                  <Clock size={18} color="var(--emerald-400)" />
                </div>
                <div style={{ fontSize: '2.4rem', fontWeight: 800, color: 'var(--emerald-400)', marginTop: '4px' }}>
                  {simMetrics.doctorTimeSavedPercent}%
                </div>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '4px' }}>
                  Specialist clinic time saved
                </div>
              </div>

              <div className="glass-panel" style={{ padding: '1.5rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>
                    Daily Cost Savings
                  </span>
                  <DollarSign size={18} color="var(--amber-400)" />
                </div>
                <div style={{ fontSize: '2.4rem', fontWeight: 800, color: 'var(--amber-400)', marginTop: '4px' }}>
                  ${simMetrics.totalDailyCostSavingsUSD.toLocaleString()}
                </div>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: '4px' }}>
                  Estimated across {simMetrics.numPatients} patients
                </div>
              </div>

            </div>

            {/* Detailed Comparisons Table */}
            <div className="glass-panel" style={{ padding: '1.75rem' }}>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '1.25rem' }}>
                Workflow Comparison: AI-Assisted vs Manual Tele-Screening
              </h3>

              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.9rem' }}>
                  <thead>
                    <tr style={{ borderBottom: '1px solid var(--border-subtle)', color: 'var(--text-muted)' }}>
                      <th style={{ padding: '12px 16px' }}>Operational Parameter</th>
                      <th style={{ padding: '12px 16px', color: 'var(--cyan-400)' }}>Autonomous AI Triage</th>
                      <th style={{ padding: '12px 16px', color: 'var(--text-secondary)' }}>Traditional Manual</th>
                      <th style={{ padding: '12px 16px', color: 'var(--emerald-400)' }}>Net Efficiency Gain</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                      <td style={{ padding: '14px 16px', fontWeight: 600 }}>Total Shift Duration</td>
                      <td style={{ padding: '14px 16px', fontFamily: 'var(--font-mono)', fontWeight: 700 }}>
                        {simMetrics.totalAiShiftHours} hours
                      </td>
                      <td style={{ padding: '14px 16px', fontFamily: 'var(--font-mono)', color: 'var(--text-secondary)' }}>
                        {simMetrics.totalManualShiftHours} hours
                      </td>
                      <td style={{ padding: '14px 16px', color: 'var(--emerald-400)', fontWeight: 700 }}>
                        {(simMetrics.totalManualShiftHours - simMetrics.totalAiShiftHours).toFixed(1)} hrs saved
                      </td>
                    </tr>

                    <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                      <td style={{ padding: '14px 16px', fontWeight: 600 }}>Average Patient Wait Time</td>
                      <td style={{ padding: '14px 16px', fontFamily: 'var(--font-mono)', fontWeight: 700 }}>
                        {simMetrics.aiAvgWaitTimeMinutes} mins
                      </td>
                      <td style={{ padding: '14px 16px', fontFamily: 'var(--font-mono)', color: 'var(--text-secondary)' }}>
                        {simMetrics.manualAvgWaitTimeMinutes} mins
                      </td>
                      <td style={{ padding: '14px 16px', color: 'var(--emerald-400)', fontWeight: 700 }}>
                        {(simMetrics.manualAvgWaitTimeMinutes - simMetrics.aiAvgWaitTimeMinutes).toFixed(1)} mins faster
                      </td>
                    </tr>

                    <tr>
                      <td style={{ padding: '14px 16px', fontWeight: 600 }}>Screening Throughput</td>
                      <td style={{ padding: '14px 16px', fontFamily: 'var(--font-mono)', fontWeight: 700 }}>
                        {simMetrics.aiThroughputPatientsPerHour} patients/hr
                      </td>
                      <td style={{ padding: '14px 16px', fontFamily: 'var(--font-mono)', color: 'var(--text-secondary)' }}>
                        {simMetrics.manualThroughputPatientsPerHour} patients/hr
                      </td>
                      <td style={{ padding: '14px 16px', color: 'var(--emerald-400)', fontWeight: 700 }}>
                        +{((simMetrics.aiThroughputPatientsPerHour - simMetrics.manualThroughputPatientsPerHour)).toFixed(1)} patients/hr
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            {/* Patient Cohort Stratification Bar */}
            <div className="glass-panel" style={{ padding: '1.5rem' }}>
              <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>
                Simulated Cohort Severity Distribution
              </span>
              
              <div style={{
                display: 'flex',
                height: '32px',
                borderRadius: '8px',
                overflow: 'hidden',
                margin: '12px 0 8px',
                gap: '2px'
              }}>
                <div style={{ flex: simMetrics.gradeCounts.grade0, background: '#10b981' }} title={`Grade 0: ${simMetrics.gradeCounts.grade0}`} />
                <div style={{ flex: simMetrics.gradeCounts.grade1, background: '#38bdf8' }} title={`Grade 1: ${simMetrics.gradeCounts.grade1}`} />
                <div style={{ flex: simMetrics.gradeCounts.grade2, background: '#f59e0b' }} title={`Grade 2: ${simMetrics.gradeCounts.grade2}`} />
                <div style={{ flex: simMetrics.gradeCounts.grade3, background: '#f97316' }} title={`Grade 3: ${simMetrics.gradeCounts.grade3}`} />
                <div style={{ flex: simMetrics.gradeCounts.grade4, background: '#f43f5e' }} title={`Grade 4: ${simMetrics.gradeCounts.grade4}`} />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                <span>Grade 0 ({simMetrics.gradeCounts.grade0})</span>
                <span>Grade 1 ({simMetrics.gradeCounts.grade1})</span>
                <span>Grade 2 ({simMetrics.gradeCounts.grade2})</span>
                <span>Grade 3 ({simMetrics.gradeCounts.grade3})</span>
                <span>Grade 4 ({simMetrics.gradeCounts.grade4})</span>
              </div>
            </div>

          </div>
        )}

      </div>

    </div>
  );
};
