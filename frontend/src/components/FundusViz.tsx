/* ── FundusViz: SVG-based synthetic retinal image with clinical overlays ── */

interface FundusVizProps {
  showGradcam?: boolean;
}

export function FundusViz({ showGradcam = false }: FundusVizProps) {
  return (
    <svg viewBox="0 0 400 400" width="100%" height="100%">
      <defs>
        {/* Retinal background gradient */}
        <radialGradient id="fundus-bg" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#7B2F2F"/>
          <stop offset="40%" stopColor="#5C1A1A"/>
          <stop offset="85%" stopColor="#3D0F0F"/>
          <stop offset="100%" stopColor="#1A0505"/>
        </radialGradient>

        {/* Optic disc glow */}
        <radialGradient id="od-glow" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#FFFBF0"/>
          <stop offset="35%" stopColor="#FFE8A0"/>
          <stop offset="70%" stopColor="#E8B060"/>
          <stop offset="100%" stopColor="#C87830" stopOpacity="0"/>
        </radialGradient>

        {/* Grad-CAM heatmap */}
        <radialGradient id="gradcam-center" cx="58%" cy="52%" r="28%">
          <stop offset="0%" stopColor="#DC2626" stopOpacity="0.55"/>
          <stop offset="40%" stopColor="#EF4444" stopOpacity="0.35"/>
          <stop offset="100%" stopColor="#F97316" stopOpacity="0"/>
        </radialGradient>

        <radialGradient id="gradcam-outer" cx="40%" cy="44%" r="20%">
          <stop offset="0%" stopColor="#F59E0B" stopOpacity="0.42"/>
          <stop offset="100%" stopColor="#F59E0B" stopOpacity="0"/>
        </radialGradient>

        {/* Circular mask */}
        <clipPath id="retina-circle">
          <circle cx="200" cy="200" r="186"/>
        </clipPath>
      </defs>

      {/* Outer ring - clinical frame */}
      <circle cx="200" cy="200" r="194" fill="none" stroke="#E2E8F0" strokeWidth="1"/>
      <circle cx="200" cy="200" r="186" fill="none" stroke="#CBD5E1" strokeWidth="0.5"/>

      {/* Fundus background */}
      <circle cx="200" cy="200" r="186" fill="url(#fundus-bg)"/>

      {/* Everything clipped to retina circle */}
      <g clipPath="url(#retina-circle)">
        {/* RPE texture - subtle noise-like radial bands */}
        <circle cx="200" cy="200" r="160" fill="none" stroke="#6B2020" strokeWidth="30" strokeOpacity="0.15"/>
        <circle cx="200" cy="200" r="130" fill="none" stroke="#7B2828" strokeWidth="20" strokeOpacity="0.1"/>

        {/* Optic disc */}
        <circle cx="128" cy="200" r="34" fill="url(#od-glow)"/>
        <circle cx="128" cy="200" r="26" fill="#FFE8A0" fillOpacity="0.9"/>
        <circle cx="128" cy="200" r="12" fill="#FFF5D0" fillOpacity="0.95"/>
        {/* Cup */}
        <circle cx="128" cy="200" r="8" fill="#FFFBF0" fillOpacity="1"/>

        {/* Superior temporal arcade */}
        <path d="M128,200 Q165,145 248,148 Q290,148 320,135" stroke="#8B2010" strokeWidth="3.5" fill="none" strokeLinecap="round"/>
        <path d="M128,200 Q170,155 250,155 Q295,154 322,142" stroke="#A02818" strokeWidth="2.5" fill="none" strokeLinecap="round"/>
        <path d="M128,200 Q175,165 252,162 Q298,161 324,149" stroke="#8B2010" strokeWidth="1.8" fill="none" strokeLinecap="round"/>

        {/* Inferior temporal arcade */}
        <path d="M128,200 Q165,255 248,252 Q290,252 320,265" stroke="#8B2010" strokeWidth="3.5" fill="none" strokeLinecap="round"/>
        <path d="M128,200 Q170,245 250,245 Q295,246 322,258" stroke="#A02818" strokeWidth="2.5" fill="none" strokeLinecap="round"/>
        <path d="M128,200 Q175,235 252,238 Q298,239 324,251" stroke="#8B2010" strokeWidth="1.8" fill="none" strokeLinecap="round"/>

        {/* Nasal vessels */}
        <path d="M128,200 Q95,175 62,165" stroke="#7A1C0C" strokeWidth="2.2" fill="none" strokeLinecap="round"/>
        <path d="M128,200 Q95,225 62,235" stroke="#7A1C0C" strokeWidth="2.2" fill="none" strokeLinecap="round"/>

        {/* Branch vessels - superior */}
        <path d="M200,152 Q225,138 240,125" stroke="#8B2010" strokeWidth="1.4" fill="none" strokeLinecap="round"/>
        <path d="M220,150 Q245,140 265,132" stroke="#8B2010" strokeWidth="1.2" fill="none" strokeLinecap="round"/>
        <path d="M245,148 Q268,145 285,138" stroke="#8B2010" strokeWidth="1.0" fill="none" strokeLinecap="round"/>

        {/* Branch vessels - inferior */}
        <path d="M200,252 Q225,265 242,278" stroke="#8B2010" strokeWidth="1.4" fill="none" strokeLinecap="round"/>
        <path d="M222,250 Q248,260 268,268" stroke="#8B2010" strokeWidth="1.2" fill="none" strokeLinecap="round"/>

        {/* Foveal avascular zone - slight darkening */}
        <circle cx="262" cy="200" r="22" fill="#4A1010" fillOpacity="0.5"/>
        <circle cx="262" cy="200" r="12" fill="#3A0D0D" fillOpacity="0.6"/>

        {/* Grad-CAM overlays (conditionally enhanced) */}
        {showGradcam && (
          <>
            <circle cx="200" cy="200" r="186" fill="url(#gradcam-center)"/>
            <circle cx="200" cy="200" r="186" fill="url(#gradcam-outer)"/>
          </>
        )}
        {!showGradcam && (
          <>
            {/* Very subtle heatmap always present */}
            <circle cx="200" cy="200" r="186" fill="url(#gradcam-center)" fillOpacity="0.35"/>
          </>
        )}

        {/* Microaneurysms - tiny dark red dots */}
        <circle cx="230" cy="185" r="2.5" fill="#DC2626" fillOpacity="0.85"/>
        <circle cx="245" cy="195" r="2" fill="#DC2626" fillOpacity="0.8"/>
        <circle cx="222" cy="210" r="2.5" fill="#B91C1C" fillOpacity="0.85"/>
        <circle cx="270" cy="185" r="2" fill="#DC2626" fillOpacity="0.75"/>

        {/* Hemorrhage spots - larger blot */}
        <ellipse cx="290" cy="192" rx="6" ry="5" fill="#7F1D1D" fillOpacity="0.8"/>
        <ellipse cx="305" cy="215" rx="5" ry="4" fill="#7F1D1D" fillOpacity="0.75"/>

        {/* Hard exudates - bright yellow */}
        <circle cx="248" cy="218" r="3.5" fill="#FBBF24" fillOpacity="0.85"/>
        <circle cx="256" cy="225" r="3" fill="#F59E0B" fillOpacity="0.8"/>
        <circle cx="240" cy="226" r="2.5" fill="#FBBF24" fillOpacity="0.75"/>
        <circle cx="260" cy="210" r="2.5" fill="#FCD34D" fillOpacity="0.7"/>
      </g>

      {/* Clinical annotation lines & labels */}
      {/* Optic Disc label */}
      <line x1="128" y1="166" x2="82" y2="140" stroke="#64748B" strokeWidth="0.8" strokeDasharray="3,2"/>
      <text x="78" y="137" fontSize="9" fill="#475569" fontFamily="Inter,sans-serif" fontWeight="600" textAnchor="middle">Optic Disc</text>

      {/* Fovea label */}
      <line x1="262" y1="178" x2="262" y2="150" stroke="#64748B" strokeWidth="0.8" strokeDasharray="3,2"/>
      <text x="262" y="146" fontSize="9" fill="#475569" fontFamily="Inter,sans-serif" fontWeight="600" textAnchor="middle">Fovea</text>

      {/* Microaneurysm label */}
      <line x1="230" y1="183" x2="218" y2="165" stroke="#DC2626" strokeWidth="0.8" strokeDasharray="2,2"/>
      <rect x="175" y="154" width="70" height="13" rx="3" fill="white" fillOpacity="0.9" stroke="#FCA5A5" strokeWidth="0.8"/>
      <text x="210" y="163.5" fontSize="8.5" fill="#DC2626" fontFamily="Inter,sans-serif" fontWeight="600" textAnchor="middle">Microaneurysm</text>

      {/* Exudate label */}
      <line x1="248" y1="221" x2="330" y2="240" stroke="#D97706" strokeWidth="0.8" strokeDasharray="2,2"/>
      <rect x="320" y="234" width="54" height="13" rx="3" fill="white" fillOpacity="0.9" stroke="#FDE68A" strokeWidth="0.8"/>
      <text x="347" y="243.5" fontSize="8.5" fill="#D97706" fontFamily="Inter,sans-serif" fontWeight="600" textAnchor="middle">Exudate</text>

      {/* Hemorrhage label */}
      <line x1="290" y1="192" x2="348" y2="178" stroke="#7F1D1D" strokeWidth="0.8" strokeDasharray="2,2"/>
      <rect x="335" y="170" width="60" height="13" rx="3" fill="white" fillOpacity="0.9" stroke="#FCA5A5" strokeWidth="0.8"/>
      <text x="365" y="179.5" fontSize="8.5" fill="#991B1B" fontFamily="Inter,sans-serif" fontWeight="600" textAnchor="middle">Hemorrhage</text>

      {/* Vessel Map label */}
      <line x1="195" y1="155" x2="175" y2="128" stroke="#0F766E" strokeWidth="0.8" strokeDasharray="2,2"/>
      <rect x="128" y="120" width="60" height="13" rx="3" fill="white" fillOpacity="0.9" stroke="#99F6E4" strokeWidth="0.8"/>
      <text x="158" y="129.5" fontSize="8.5" fill="#0F766E" fontFamily="Inter,sans-serif" fontWeight="600" textAnchor="middle">Vessel Map</text>
    </svg>
  );
}
