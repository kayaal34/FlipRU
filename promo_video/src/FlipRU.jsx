// FlipRU tanıtım videosu: 1080x1920, 30 fps, ~30 sn.
//
// Akış: telefon kutudan çıkıp büyür, FlipRU ikonuna dokunulur ve uygulama
// açılır → telefon dönüp kilit ekranına geçer (widget + seri bildirimi) →
// logolu çizgi boyunca yedi özellik → kapanış kartı.
import {
  AbsoluteFill, Audio, Img, Sequence, staticFile, useCurrentFrame,
  interpolate, Easing, delayRender, continueRender,
} from 'remotion';

const C = {
  canvas: '#F4F4F7', surface: '#FFFFFF', accent: '#5E5CE6', pink: '#E0489A',
  text: '#111114', text2: '#6B6B76', text3: '#9C9CA7', sep: '#E6E6EC',
  star: '#EFA818', learned: '#16A34A', review: '#E5342A',
};

// ---- Yazı tipi -------------------------------------------------------------
const fontHandle = delayRender('Inter yükleniyor');
Promise.all(
  [[400, 'Regular'], [500, 'Medium'], [600, 'SemiBold'], [700, 'Bold'], [800, 'ExtraBold']].map(
    ([w, n]) => new FontFace('Inter', `url(${staticFile(`fonts/Inter-${n}.ttf`)})`, { weight: String(w) })
      .load().then((f) => document.fonts.add(f)),
  ),
).then(() => continueRender(fontHandle));

// ---- Zaman çizelgesi ---------------------------------------------------------
// Zamanlar "sanal" karelerle yazılı; SPEED ile hepsi biraz hızlanıyor.
const SPEED = 1.15;
const R = (v) => Math.round(v / SPEED);
const useV = () => useCurrentFrame() * SPEED;
const OPEN_END = 174;
const F0 = 164, FL = 90, NF = 7;
const END = F0 + FL * NF;          // 794 (sanal)
const OUTRO = 120;
export const TOTAL = R(END + OUTRO); // ≈ 795 kare ≈ 26,5 sn

const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' };
// Tüm hareketler yaysız, yumuşak yavaşlayan eğrilerle: "tak" diye durmasın.
const OUT = Easing.bezier(0.16, 1, 0.3, 1);      // hızlı başlar, çok yumuşak oturur
const INOUT = Easing.bezier(0.65, 0, 0.35, 1);   // iki ucu da yumuşak
const IN = Easing.bezier(0.5, 0, 0.75, 0);
const tw = (f, a, b, from = 0, to = 1, e = OUT) => interpolate(f, [a, b], [from, to], { ...clamp, easing: e });

// Kelime kelime yukarı süzülen başlık.
const Rise = ({ text, at = 0, size = 88, color = C.text, weight = 800, stagger = 3, style }) => {
  const f = useV();
  return (
    <div style={{ fontSize: size, fontWeight: weight, color, lineHeight: 1.08, letterSpacing: -size * 0.03, ...style }}>
      {text.split(' ').map((w, i) => {
        const t = tw(f, at + i * stagger, at + i * stagger + 22);
        return (
          <span key={i} style={{ display: 'inline-block', overflow: 'hidden', verticalAlign: 'top', paddingBottom: size * 0.12 }}>
            <span style={{ display: 'inline-block', transform: `translateY(${(1 - t) * 100}%)`, opacity: t }}>
              {w}{' '}
            </span>
          </span>
        );
      })}
    </div>
  );
};

// ---- Telefon ---------------------------------------------------------------
const SHOT_RATIO = 892 / 412;
const statusOf = (w) => w * 0.085;
const Phone = ({ w = 540, children, style, dark = false }) => {
  const bez = w * 0.035;
  const sh = w * SHOT_RATIO + statusOf(w);
  return (
    <div style={{
      width: w + bez * 2, height: sh + bez * 2, borderRadius: w * 0.16, background: '#0E0E12',
      padding: bez, boxShadow: '0 60px 120px rgba(40,30,120,0.26), 0 20px 40px rgba(0,0,0,0.16)', ...style,
    }}>
      <div style={{ position: 'relative', width: w, height: sh, borderRadius: w * 0.13, overflow: 'hidden', background: dark ? '#0F0A22' : C.canvas }}>
        {children}
        <div style={{
          position: 'absolute', top: w * 0.025, left: '50%', width: w * 0.3, height: w * 0.065,
          marginLeft: -w * 0.15, borderRadius: 999, background: '#000',
        }} />
      </div>
    </div>
  );
};

const StatusBar = ({ w, color = C.text }) => (
  <div style={{ height: statusOf(w), display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: `0 ${w * 0.09}px`, fontSize: w * 0.032, fontWeight: 600, color }}>
    <span>9:41</span><span style={{ letterSpacing: 2 }}>▮▮▮ ◔</span>
  </div>
);

const Shot = ({ src, w = 540, style }) => (
  <div style={{ position: 'absolute', inset: 0, background: C.canvas, ...style }}>
    <StatusBar w={w} />
    <Img src={staticFile(`shots/${src}.png`)} style={{ width: w, display: 'block' }} />
  </div>
);

// Ekran görüntüleri arasında sırayla geçiş: [[kare, ad], ...]
const ShotSeq = ({ seq, w, f, slide = false }) => (
  <>
    {seq.map(([at, src], i) => {
      if (i > 0 && f < at) return null;
      const t = i === 0 ? 1 : tw(f, at, at + 16, 0, 1, INOUT);
      return (
        <Shot key={src} src={src} w={w} style={{
          opacity: slide ? 1 : t,
          transform: slide && i > 0 ? `translateX(${(1 - t) * 100}%)` : undefined,
        }} />
      );
    })}
  </>
);

// Ekrana dokunma halkası; x/y uygulamanın CSS pikseli (412 genişlik).
const TapDot = ({ f, at, x, y, w, hold = 0 }) => {
  if (f < at - 6 || f > at + hold + 18) return null;
  const t = interpolate(f, [at - 6, at, at + hold + 1, at + hold + 12], [0, 1, 1, 0], clamp);
  const ring = tw(f, at, at + 16);
  const k = w / 412;
  return (
    <div style={{ position: 'absolute', left: x * k - 40, top: statusOf(w) + y * k - 40, width: 80, height: 80 }}>
      <div style={{ position: 'absolute', inset: 0, borderRadius: 99, background: 'rgba(94,92,230,0.32)', border: '4px solid rgba(255,255,255,0.95)', opacity: t, transform: `scale(${0.7 + t * 0.3})` }} />
      <div style={{ position: 'absolute', inset: 0, borderRadius: 99, border: `4px solid ${C.accent}`, opacity: f >= at ? (1 - ring) * 0.8 : 0, transform: `scale(${1 + ring * 1.1})` }} />
    </div>
  );
};

// ---- Ana ekran ikonları (markasız, genel görünüm) -----------------------------
const IconSvg = ({ type }) => {
  const S = (p) => <svg viewBox="0 0 100 100" width="100%" height="100%">{p}</svg>;
  switch (type) {
    case 'calendar': return S(<>
      <rect width="100" height="100" fill="#fff" />
      <text x="50" y="30" fontSize="17" fontWeight="600" fill="#FF3B30" textAnchor="middle" fontFamily="Inter">CUM</text>
      <text x="50" y="80" fontSize="50" fontWeight="400" fill="#111" textAnchor="middle" fontFamily="Inter">19</text></>);
    case 'photos': return S(<>
      <rect width="100" height="100" fill="#fff" />
      {['#FBBC05', '#F97316', '#EF4444', '#EC4899', '#A855F7', '#3B82F6', '#14B8A6', '#22C55E'].map((c, i) => (
        <ellipse key={i} cx="50" cy="31" rx="10" ry="19" fill={c} opacity="0.8" transform={`rotate(${i * 45} 50 50)`} />
      ))}</>);
    case 'music': return S(<>
      <defs><linearGradient id="gm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor="#FF6482" /><stop offset="1" stopColor="#F2213B" /></linearGradient></defs>
      <rect width="100" height="100" fill="url(#gm)" />
      <path d="M40 28 L70 22 L70 64 A9 8 0 1 1 64 57 L64 34 L46 38 L46 70 A9 8 0 1 1 40 63 Z" fill="#fff" /></>);
    case 'clock': return S(<>
      <rect width="100" height="100" fill="#111" />
      <circle cx="50" cy="50" r="38" fill="#fff" />
      {Array.from({ length: 12 }).map((_, i) => <rect key={i} x="49" y="15" width="2" height="6" fill="#111" transform={`rotate(${i * 30} 50 50)`} />)}
      <rect x="48.5" y="28" width="3" height="24" rx="1.5" fill="#111" transform="rotate(-50 50 50)" />
      <rect x="49" y="20" width="2" height="32" rx="1" fill="#111" transform="rotate(95 50 50)" />
      <rect x="49.5" y="18" width="1" height="36" fill="#FF9500" transform="rotate(200 50 50)" /></>);
    case 'tv': return S(<>
      <rect width="100" height="100" fill="#111" />
      <text x="50" y="62" fontSize="32" fontWeight="700" fill="#fff" textAnchor="middle" fontFamily="Inter">tv</text></>);
    case 'settings': return S(<>
      <defs><linearGradient id="gs" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor="#A9AEB5" /><stop offset="1" stopColor="#6E737B" /></linearGradient></defs>
      <rect width="100" height="100" fill="url(#gs)" />
      {Array.from({ length: 10 }).map((_, i) => <rect key={i} x="45" y="16" width="10" height="16" rx="2" fill="#3A3D42" transform={`rotate(${i * 36} 50 50)`} />)}
      <circle cx="50" cy="50" r="24" fill="#3A3D42" /><circle cx="50" cy="50" r="10" fill="#A9AEB5" /></>);
    case 'notes': return S(<>
      <rect width="100" height="100" fill="#fff" />
      <rect width="100" height="26" fill="#FFCC33" />
      {[42, 56, 70, 84].map((y) => <rect key={y} x="14" y={y} width="72" height="2" fill="#D8D8DC" />)}</>);
    case 'reminders': return S(<>
      <rect width="100" height="100" fill="#fff" />
      {[['#0A84FF', 28], ['#FF3B30', 50], ['#FF9500', 72]].map(([c, y]) => (
        <g key={y}><circle cx="24" cy={y} r="7" fill={c} /><rect x="38" y={y - 2} width="46" height="4" rx="2" fill="#E0E0E5" /></g>
      ))}</>);
    case 'camera': return S(<>
      <defs><linearGradient id="gc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor="#E5E5EA" /><stop offset="1" stopColor="#B8B8BE" /></linearGradient></defs>
      <rect width="100" height="100" fill="url(#gc)" />
      <rect x="16" y="32" width="68" height="46" rx="9" fill="#2B2B30" /><rect x="38" y="25" width="24" height="10" rx="3" fill="#2B2B30" />
      <circle cx="50" cy="55" r="15" fill="#5B5B63" /><circle cx="50" cy="55" r="9" fill="#1B1B1F" /></>);
    case 'fitness': return S(<>
      <rect width="100" height="100" fill="#111" />
      {[['#FA114F', 34], ['#92E82A', 25], ['#1EEAEF', 16]].map(([c, r]) => (
        <circle key={r} cx="50" cy="50" r={r} fill="none" stroke={c} strokeWidth="8" strokeDasharray={`${2 * Math.PI * r * 0.75} 999`} strokeLinecap="round" transform="rotate(-90 50 50)" />
      ))}</>);
    case 'maps': return S(<>
      <rect width="100" height="100" fill="#D9F2D0" />
      <path d="M0 70 L100 40" stroke="#fff" strokeWidth="12" /><path d="M35 0 L60 100" stroke="#FFD34D" strokeWidth="9" />
      <circle cx="70" cy="30" r="10" fill="#0A84FF" stroke="#fff" strokeWidth="4" /></>);
    case 'mail': return S(<>
      <defs><linearGradient id="gma" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor="#5AC8FA" /><stop offset="1" stopColor="#1C7CF4" /></linearGradient></defs>
      <rect width="100" height="100" fill="url(#gma)" />
      <rect x="18" y="30" width="64" height="42" rx="5" fill="#fff" /><path d="M20 33 L50 55 L80 33" fill="none" stroke="#9CC9F5" strokeWidth="3" /></>);
    case 'books': return S(<>
      <defs><linearGradient id="gb" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor="#FFA43B" /><stop offset="1" stopColor="#FF7A00" /></linearGradient></defs>
      <rect width="100" height="100" fill="url(#gb)" />
      <path d="M50 32 C40 25 26 25 18 28 L18 74 C26 71 40 71 50 78 C60 71 74 71 82 74 L82 28 C74 25 60 25 50 32 Z" fill="#fff" />
      <path d="M50 32 L50 78" stroke="#FF9A2E" strokeWidth="2.5" /></>);
    case 'phone': return S(<>
      <defs><linearGradient id="gp" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor="#65E07A" /><stop offset="1" stopColor="#2BB84A" /></linearGradient></defs>
      <rect width="100" height="100" fill="url(#gp)" />
      <path d="M33 24 C30 24 25 29 25 34 C25 55 45 75 66 75 C71 75 76 70 76 67 L76 60 L63 55 L57 61 C49 57 43 51 39 43 L45 37 L40 24 Z" fill="#fff" /></>);
    case 'messages': return S(<>
      <defs><linearGradient id="gmsg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor="#65E07A" /><stop offset="1" stopColor="#2BB84A" /></linearGradient></defs>
      <rect width="100" height="100" fill="url(#gmsg)" />
      <ellipse cx="50" cy="48" rx="32" ry="26" fill="#fff" /><path d="M28 64 L22 78 L40 70 Z" fill="#fff" /></>);
    case 'compass': return S(<>
      <rect width="100" height="100" fill="#fff" />
      <circle cx="50" cy="50" r="38" fill="#1E90FF" /><circle cx="50" cy="50" r="33" fill="none" stroke="#fff" strokeWidth="1.5" strokeDasharray="1.5 4" />
      <path d="M50 50 L68 32 L56 56 Z" fill="#FF3B30" /><path d="M50 50 L32 68 L44 44 Z" fill="#fff" /></>);
    default: return null;
  }
};

const WeatherWidget = ({ w, h }) => (
  <div style={{
    width: w, height: h, borderRadius: w * 0.12, padding: w * 0.09, boxSizing: 'border-box', color: '#fff',
    background: 'linear-gradient(170deg, #4B8FE8, #2A63C9)', display: 'flex', flexDirection: 'column',
  }}>
    <div style={{ fontSize: w * 0.085, fontWeight: 600 }}>İstanbul ➤</div>
    <div style={{ fontSize: w * 0.3, fontWeight: 300, lineHeight: 1 }}>22°</div>
    <div style={{ flex: 1 }} />
    <svg width={w * 0.2} height={w * 0.14} viewBox="0 0 40 28"><circle cx="14" cy="16" r="9" fill="#fff" /><circle cx="24" cy="12" r="10" fill="#fff" /><rect x="8" y="16" width="26" height="10" rx="5" fill="#fff" /></svg>
    <div style={{ fontSize: w * 0.075, fontWeight: 600, marginTop: 4 }}>Parçalı bulutlu</div>
    <div style={{ fontSize: w * 0.07, opacity: 0.85 }}>Y:24° D:16°</div>
  </div>
);

// ---- Açılış: kutudaki telefon → ikon → uygulama → kilit ekranı ----------------
const HomeScreen = ({ w, f }) => {
  const k = w / 560;
  const icon = 100 * k, gap = (w - icon * 4) / 5, top0 = 90 * k, rowH = icon + 42 * k;
  const col = (c) => gap + c * (icon + gap);
  const row = (r) => top0 + r * rowH;
  const items = [
    { t: 'weather', x: col(0), y: row(0), w: icon * 2 + gap, h: icon + rowH },
    { t: 'calendar', x: col(2), y: row(0) }, { t: 'photos', x: col(3), y: row(0) },
    { t: 'clock', x: col(2), y: row(1) }, { t: 'music', x: col(3), y: row(1) },
    { t: 'tv', x: col(0), y: row(2) }, { t: 'settings', x: col(1), y: row(2) },
    { t: 'notes', x: col(2), y: row(2) }, { t: 'reminders', x: col(3), y: row(2) },
    { t: 'camera', x: col(0), y: row(3) }, { t: 'fitness', x: col(2), y: row(3) }, { t: 'maps', x: col(3), y: row(3) },
  ];
  const dockY = w * SHOT_RATIO + statusOf(w) - icon - 44 * k;
  ['phone', 'compass', 'messages', 'books'].forEach((t, i) => items.push({ t, x: col(i), y: dockY }));
  const mailSpot = { t: 'mail', x: col(3), y: row(4) };
  items.push(mailSpot, { t: 'calendar', x: col(0), y: row(4) }, { t: 'notes', x: col(2), y: row(4) });

  // FlipRU ikonu 4. satır 2. sütunda: diğerleri dağılır, o ortaya gelir,
  // dokunulunca ekranı kaplayarak uygulamayı açar.
  const scatter = tw(f, 30, 62, 0, 1, INOUT);
  const open = tw(f, 56, 76, 0, 1, INOUT);
  const cx = w / 2, cy = (w * SHOT_RATIO + statusOf(w)) / 2;
  const hx = col(1) + icon / 2, hy = row(3) + icon / 2;
  const mx = interpolate(scatter, [0, 1], [hx, cx]), my = interpolate(scatter, [0, 1], [hy, cy]);
  const press = interpolate(f, [48, 52, 58], [1, 0.92, 1], clamp);
  const size = (icon * (1 + scatter * 0.55) + open * (w * 2.4)) * press;
  return (
    <AbsoluteFill>
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(90% 60% at 15% 20%, #3C6FF0 0%, #1B2A7A 40%, #0B0B1E 75%), #0B0B1E' }} />
      <div style={{ position: 'absolute', left: -w * 0.3, top: w * 0.9, width: w * 1.4, height: w * 1.4, borderRadius: '50%', background: 'radial-gradient(closest-side, rgba(232,40,110,0.95), rgba(232,40,110,0.35) 70%, transparent)' }} />
      <StatusBar w={w} color="#fff" />
      <div style={{ position: 'absolute', left: gap * 0.6, right: gap * 0.6, top: dockY - 20 * k, height: icon + 40 * k, borderRadius: 36 * k, background: 'rgba(255,255,255,0.18)', opacity: 1 - scatter }} />
      {items.map((it, i) => {
        const iw = it.w || icon, ih = it.h || icon;
        const dx = it.x + iw / 2 - hx, dy = it.y + ih / 2 - hy;
        const d = Math.hypot(dx, dy) || 1;
        // Uzaktakiler biraz gecikmeli dağılır; dalga gibi.
        const s = tw(f, 30 + Math.min(10, d / 40), 64 + Math.min(10, d / 40), 0, 1, INOUT);
        const push = s * 620 * k;
        return (
          <div key={i} style={{
            position: 'absolute', left: it.x, top: it.y, width: iw, height: ih, borderRadius: icon * 0.23, overflow: 'hidden',
            transform: `translate(${(dx / d) * push}px, ${(dy / d) * push}px) scale(${1 - s * 0.3}) rotate(${(dx / d) * s * 25}deg)`,
            opacity: 1 - s,
          }}>
            {it.t === 'weather' ? <WeatherWidget w={iw} h={ih} /> : <IconSvg type={it.t} />}
          </div>
        );
      })}
      <div style={{
        position: 'absolute', left: mx - size / 2, top: my - size / 2, width: size, height: size,
        borderRadius: size * interpolate(open, [0, 1], [0.23, 0.05]), overflow: 'hidden',
        boxShadow: `0 0 ${60 * scatter}px rgba(140,120,255,${0.7 * scatter})`,
      }}>
        <Img src={staticFile('logo.png')} style={{ width: '100%', height: '100%' }} />
      </div>
      <TapDot f={f} at={52} x={206} y={((cy - statusOf(w)) / w) * 412} w={w} />
    </AbsoluteFill>
  );
};

const Widget = ({ scale = 1 }) => (
  <div style={{
    width: 440 * scale, borderRadius: 30 * scale, background: 'rgba(24,24,30,0.92)', padding: `${22 * scale}px ${28 * scale}px`,
    boxShadow: '0 20px 50px rgba(0,0,0,0.35)',
  }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 14 * scale }}>
      <span style={{ color: '#FFC93C', fontWeight: 700, fontSize: 32 * scale }}>🔥 12</span>
      <span style={{ flex: 1, color: '#9C9CA7', fontWeight: 700, fontSize: 17 * scale, letterSpacing: 1.4 * scale }}>GÜNÜN KELİMESİ</span>
      <span style={{ color: '#8886FF', fontWeight: 700, fontSize: 19 * scale }}>A1</span>
    </div>
    <div style={{ color: '#F5F5F7', fontWeight: 700, fontSize: 44 * scale, marginTop: 12 * scale }}>приве́т</div>
    <div style={{ color: '#66666F', fontSize: 19 * scale }}>pri-VET</div>
    <div style={{ color: '#9C9CA7', fontSize: 25 * scale, marginTop: 8 * scale }}>merhaba, selam</div>
  </div>
);

const Notif = ({ w }) => (
  <div style={{
    width: w, borderRadius: 34, background: 'rgba(245,245,250,0.92)', padding: '22px 24px',
    display: 'flex', gap: 18, alignItems: 'center', boxShadow: '0 16px 40px rgba(0,0,0,0.3)',
  }}>
    <Img src={staticFile('logo.png')} style={{ width: 64, height: 64, borderRadius: 16 }} />
    <div style={{ flex: 1 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 20, color: C.text2 }}>
        <span style={{ fontWeight: 600 }}>FlipRU</span><span>şimdi</span>
      </div>
      <div style={{ fontSize: 25, fontWeight: 700, color: C.text, marginTop: 2 }}>Seri bozulmak üzere 🔥</div>
      <div style={{ fontSize: 22, color: C.text2, marginTop: 2 }}>12 günlük seriyi kaybetmemek için bugün uğra.</div>
    </div>
  </div>
);

const LockScreen = ({ w, f }) => {
  const wg = tw(f, 104, 126);
  const nt = tw(f, 118, 140);
  return (
    <AbsoluteFill>
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(120% 70% at 20% 10%, #7B7BFF 0%, #5A3FD8 35%, #2A1560 65%, #0F0A22 100%)' }} />
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(80% 50% at 90% 95%, rgba(232,72,154,0.85), rgba(232,72,154,0) 70%)' }} />
      <div style={{ position: 'absolute', top: 120, width: '100%', textAlign: 'center', color: 'rgba(255,255,255,0.92)' }}>
        <div style={{ fontSize: 26, fontWeight: 600 }}>19 Eylül Cumartesi</div>
        <div style={{ fontSize: 150, fontWeight: 700, lineHeight: 1, letterSpacing: -4 }}>9:41</div>
      </div>
      <div style={{ position: 'absolute', top: 420, left: 60, transform: `scale(${0.8 + wg * 0.2})`, transformOrigin: '20% 50%', opacity: wg }}>
        <Widget />
      </div>
      <div style={{ position: 'absolute', top: 770, left: 24, transform: `translateY(${(1 - nt) * -260}px) scale(${0.94 + nt * 0.06})`, opacity: nt }}>
        <Notif w={w - 48} />
      </div>
    </AbsoluteFill>
  );
};

const Opening = () => {
  const f = useV();
  const W = 560;
  // 1) Kutudaki küçük, eğik telefon tek bir akışta gelip doğrulur ve
  //    büyür; arada duraksama yok.
  const p = tw(f, 0, 44, 0, 1, Easing.bezier(0.3, 0.1, 0.2, 1));
  const a = p, b = p;
  const scale = 0.42 + 0.58 * p;
  const rotZ = -38 * (1 - p);
  const rotX = 22 * (1 - p), rotY = -24 * (1 - p);
  const tx = -260 * (1 - p);
  const ty = 520 * (1 - p);
  const float = Math.sin(f / 18) * 5 * p;
  // 2) Kilit ekranına geçerken telefon kendi ekseninde döner.
  const turn = f < 92 ? tw(f, 80, 92, 0, 90, IN) : tw(f, 92, 108, -90, 0);
  // 3) Özelliklere geçerken yumuşakça aşağı iner.
  const out = tw(f, 148, 170, 0, 1, IN);
  const lock = f >= 92;
  const cap1 = 1 - tw(f, 74, 86, 0, 1, INOUT);
  const cap2 = 1 - tw(f, 146, 160, 0, 1, INOUT);
  return (
    <AbsoluteFill style={{ alignItems: 'center' }}>
      {f < 88 && (
        <div style={{ position: 'absolute', top: 150, width: '100%', textAlign: 'center', opacity: cap1 }}>
          <Rise text="Rusçayı" at={2} size={92} />
          <Rise text="cebinden öğren." at={8} size={92} color={C.accent} />
        </div>
      )}
      {f >= 82 && (
        <div style={{ position: 'absolute', top: 150, width: '100%', textAlign: 'center', opacity: cap2 }}>
          <Rise text="Her gün bir kelime," at={88} size={80} />
          <Rise text="serini bozma. 🔥" at={95} size={80} color={C.accent} />
        </div>
      )}
      <div style={{ position: 'absolute', top: 470, perspective: 2000 }}>
        <div style={{
          transform: `translate(${tx}px, ${ty + float + out * 1500}px) rotateX(${rotX}deg) rotateY(${rotY + turn}deg) rotateZ(${rotZ}deg) scale(${scale})`,
        }}>
          <Phone w={W} dark>
            {!lock && <HomeScreen w={W} f={f} />}
            {!lock && f >= 70 && <Shot src="home" w={W} style={{ opacity: tw(f, 70, 82) }} />}
            {lock && <LockScreen w={W} f={f} />}
          </Phone>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ---- Özellikler: logolu dalgalı çizgi --------------------------------------
const NODE_Y = 330;
const lineX = (y) => 150 + 55 * Math.sin((y / 1920) * Math.PI * 2.2);
// Her özellik geçişinde çizgi yukarı kayar; adım adım ilerleme hissi.
const scrollAt = (f) => {
  let s = f * 1.0;
  for (let k = 1; k < NF; k++) s += 520 * tw(f, k * FL - 8, k * FL + 18, 0, 1, INOUT);
  return s;
};

const Line = () => {
  const f = useV();
  const sc = scrollAt(f);
  const draw = tw(f, 0, 34, 0, 1, INOUT);
  const leave = tw(f, END - F0 - 6, END - F0 + 26, 0, 1, INOUT);
  const pts = [];
  for (let y = -40; y <= 1960; y += 16) pts.push(`${lineX(y + sc).toFixed(1)},${y}`);
  const nx = lineX(NODE_Y + sc);
  const x = nx + (540 - nx) * leave, y = NODE_Y + (700 - NODE_Y) * leave;
  const size = 104 + 136 * leave;
  const pop = tw(f, 4, 26);
  const ring = f < END - F0 ? tw(f % FL, 0, 28) : 1;
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} style={{ position: 'absolute', opacity: 1 - leave }}>
        <defs>
          <linearGradient id="lg" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor={C.accent} stopOpacity="0.15" />
            <stop offset="0.25" stopColor={C.accent} />
            <stop offset="1" stopColor={C.pink} />
          </linearGradient>
        </defs>
        <polyline points={pts.join(' ')} fill="none" stroke="url(#lg)" strokeWidth={7} strokeLinecap="round"
          pathLength={1} strokeDasharray={1} strokeDashoffset={1 - draw} />
      </svg>
      <div style={{
        position: 'absolute', left: x - size / 2 - 30, top: y - size / 2 - 30, width: size + 60, height: size + 60,
        borderRadius: 999, border: `4px solid ${C.accent}`, opacity: (1 - ring) * 0.5 * (1 - leave),
        transform: `scale(${0.75 + ring * 0.8})`,
      }} />
      <div style={{
        position: 'absolute', left: x - size / 2, top: y - size / 2, width: size, height: size,
        transform: `scale(${0.4 + pop * 0.6})`, opacity: pop, borderRadius: size * 0.24,
        boxShadow: `0 0 0 ${10 + 5 * Math.sin(f / 9)}px rgba(94,92,230,0.12), 0 20px 40px rgba(94,92,230,0.35)`,
      }}>
        <Img src={staticFile('logo.png')} style={{ width: '100%', height: '100%' }} />
      </div>
    </AbsoluteFill>
  );
};

// Özellik sahnesi: çıkarken yumuşakça yukarı kayar, yenisi gelmeden biter.
const Feature = ({ children }) => {
  const f = useV();
  const out = tw(f, FL - 10, FL + 6, 0, 1, IN);
  return (
    <AbsoluteFill style={{ transform: `translateY(${-out * 420}px)`, opacity: 1 - out }}>
      {children}
    </AbsoluteFill>
  );
};

const FeatureText = ({ idx, title, sub, titleNode }) => {
  const f = useV();
  const s = tw(f, 14, 36);
  return (
    <div style={{ position: 'absolute', left: 290, top: NODE_Y - 92, right: 50 }}>
      <div style={{ fontSize: 30, fontWeight: 700, color: C.accent, opacity: tw(f, 6, 18), letterSpacing: 2, transform: `translateX(${(1 - tw(f, 6, 24)) * -30}px)` }}>
        0{idx} / 0{NF}
      </div>
      {titleNode || <Rise text={title} at={8} size={72} />}
      <div style={{ fontSize: 36, color: C.text2, marginTop: 6, opacity: s, transform: `translateY(${(1 - s) * 20}px)` }}>
        {sub}
      </div>
    </div>
  );
};

// Telefon alttan süzülerek gelir ve yavaşça oturur; hafifçe salınır.
const RisingPhone = ({ children, w = 500, top = 640, delay = 6 }) => {
  const f = useV();
  const s = tw(f, delay, delay + 34);
  const drift = Math.sin(f / 24) * 5;
  return (
    <div style={{ position: 'absolute', top, left: 540 - (w * 1.07) / 2, perspective: 1600 }}>
      <div style={{ transform: `translateY(${(1 - s) * 1150 + drift}px) rotateY(${(1 - s) * 16 - 3}deg) rotateX(${3 + (1 - s) * 14}deg) rotateZ(${(1 - s) * 5}deg)` }}>
        <Phone w={w}>{children}</Phone>
      </div>
    </div>
  );
};

// Yumuşakça beliren, hafifçe süzülen rozet.
const Chip = ({ f, at, left, right, top, size = 132, bg, color, children, tilt = 8, font = 54 }) => {
  const s = tw(f, at, at + 24);
  const side = left !== undefined ? -1 : 1;
  return (
    <div style={{
      position: 'absolute', top, left, right, minWidth: size, height: size, padding: '0 26px', boxSizing: 'border-box',
      borderRadius: size * 0.28, background: bg, color, fontSize: font, fontWeight: 800,
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12,
      transform: `translate(${(1 - s) * side * 90}px, ${Math.sin((f + at * 7) / 20) * 6}px) rotate(${side * tilt * s + (1 - s) * side * 18}deg) scale(${0.6 + s * 0.4})`,
      opacity: s, boxShadow: '0 18px 36px rgba(40,30,120,0.14)', border: `3px solid ${C.surface}`, whiteSpace: 'nowrap',
    }}>{children}</div>
  );
};

const LEVELS = [
  ['A1', '#14B8A6', '#D5F5F0'], ['A2', '#3B82F6', '#DBE8FE'], ['B1', '#6366F1', '#E2E3FD'],
  ['B2', '#A855F7', '#F0E2FE'], ['C1', '#EC4899', '#FCE1EF'],
];

const F1Words = () => {
  const f = useV();
  const n = Math.round(interpolate(f, [4, 42], [0, 8000], { ...clamp, easing: Easing.out(Easing.cubic) }));
  const plus = tw(f, 40, 56);
  return (
    <Feature>
      <FeatureText idx={1} sub="A1'den C1'e, beş seviye"
        titleNode={
          <div style={{ fontSize: 96, fontWeight: 800, letterSpacing: -3, color: C.text, lineHeight: 1.1, opacity: tw(f, 2, 10) }}>
            {n.toLocaleString('tr-TR')}
            <span style={{ color: C.accent, display: 'inline-block', transform: `scale(${plus})` }}>+</span>
            <span style={{ fontSize: 56, marginLeft: 16 }}>kelime</span>
          </div>
        } />
      <RisingPhone><Shot src="pratik" w={500} /></RisingPhone>
      {LEVELS.map(([l, c, bg], i) => (
        <Chip key={l} f={f} at={24 + i * 5} top={820 + i * 190} {...(i % 2 === 0 ? { left: 40 } : { right: 40 })} bg={bg} color={c}>{l}</Chip>
      ))}
    </Feature>
  );
};

const F2Alphabet = () => {
  const f = useV();
  const letters = ['Жж', 'Щщ', 'Ёё', 'Юю', 'Ыы', 'Фф'];
  return (
    <Feature>
      <FeatureText idx={2} title="Alfabe sıfırdan" sub="Yeni başlayanlar için harf harf" />
      <RisingPhone>
        <ShotSeq f={f} w={500} seq={[[0, 'alfabe'], [46, 'harf']]} />
        <TapDot f={f} at={42} x={62} y={593} w={500} />
      </RisingPhone>
      {letters.map((l, i) => (
        <Chip key={l} f={f} at={18 + i * 4} size={150} font={64} bg={C.surface} color={C.accent} tilt={6}
          top={800 + Math.floor(i / 2) * 330 + (i % 2 ? 150 : 0)} {...(i % 2 === 0 ? { left: 36 } : { right: 36 })}>{l}</Chip>
      ))}
    </Feature>
  );
};

// Kart kaydırma: kart bölgesi (CSS px) ekran görüntüsünden kırpılıp sürüklenir.
const CARD = { x: 22, y: 103, w: 368, h: 688, r: 32 };
const SwipeBadge = ({ learn, k, t }) => {
  const color = learn ? C.learned : C.review;
  return (
    <div style={{
      position: 'absolute', top: 78 * k, [learn ? 'left' : 'right']: 24 * k, opacity: t,
      transform: `rotate(${learn ? -10 : 10}deg) scale(${0.86 + t * 0.14})`,
      padding: `${9 * k}px ${14 * k}px`, borderRadius: 12 * k, border: `${2.5 * k}px solid ${color}`,
      background: learn ? 'rgba(22,163,74,0.14)' : 'rgba(229,52,42,0.14)', color, fontSize: 13 * k, fontWeight: 700,
      letterSpacing: k, display: 'flex', alignItems: 'center', gap: 6 * k,
    }}>
      <span style={{ fontSize: 16 * k }}>{learn ? '✓' : '↻'}</span>{learn ? 'ÖĞRENDİM' : 'TEKRAR'}
    </div>
  );
};

const SwipingCard = ({ src, w, dx, learn }) => {
  const k = w / 412;
  const intensity = Math.min(1, Math.abs(dx) / (412 * 0.55 * 0.6));
  const color = learn ? C.learned : C.review;
  return (
    <div style={{
      position: 'absolute', left: CARD.x * k, top: statusOf(w) + CARD.y * k, width: CARD.w * k, height: CARD.h * k,
      borderRadius: CARD.r * k, overflow: 'hidden',
      transform: `translateX(${dx * k}px) rotate(${dx * 0.045}deg)`, transformOrigin: '50% 120%',
      boxShadow: `0 ${10 + intensity * 20}px ${30 + intensity * 30}px rgba(0,0,0,${0.08 + intensity * 0.1})`,
      outline: `${(1 + intensity * 1.6) * k}px solid ${intensity > 0.05 ? color : 'transparent'}`, outlineOffset: -2 * k,
    }}>
      <Img src={staticFile(`shots/${src}.png`)} style={{ position: 'absolute', width: w, left: -CARD.x * k, top: -CARD.y * k }} />
      <div style={{ position: 'absolute', inset: 0, background: color, opacity: intensity * 0.14 }} />
      <SwipeBadge learn={learn} k={k} t={intensity} />
    </div>
  );
};

// Sürükleme eğrisi: yavaşça çekilir, eşiği geçince hızlanıp çıkar.
const dragX = (f, at, dir) => {
  const pull = interpolate(f, [at, at + 16], [0, 150], { ...clamp, easing: INOUT });
  const fly = interpolate(f, [at + 18, at + 30], [0, 420], { ...clamp, easing: IN });
  return dir * (pull + fly);
};

const F3Swipe = () => {
  const f = useV();
  const W = 500;
  const k = W / 412;
  const d1 = dragX(f, 20, 1), d2 = dragX(f, 54, -1);
  const done1 = f >= 48, done2 = f >= 84;
  const finger = (at, dir, dx) => {
    if (f < at - 6 || f > at + 22) return null;
    const o = interpolate(f, [at - 6, at, at + 16, at + 22], [0, 1, 1, 0], clamp);
    return (
      <div style={{
        position: 'absolute', left: (206 + dx) * k - 40, top: statusOf(W) + 460 * k - 40, width: 80, height: 80, borderRadius: 99,
        background: 'rgba(94,92,230,0.3)', border: '4px solid rgba(255,255,255,0.95)', opacity: o,
      }} />
    );
  };
  return (
    <Feature>
      <FeatureText idx={3} title="Kaydırarak öğren" sub="Sağa: öğrendim · Sola: tekrar" />
      <RisingPhone>
        {/* Altta hep bir sonraki kart durur; üstteki kart kayınca o görünür. */}
        <Shot src={done1 ? 'swipe_c' : 'swipe_b'} w={W} />
        {/* Başlık ve sayaç kart çıkana kadar eski hâliyle kalsın. */}
        {!done1 && (
          <div style={{ position: 'absolute', left: 0, top: 0, width: W, height: statusOf(W) + CARD.y * k, overflow: 'hidden' }}>
            <Shot src="swipe_a" w={W} />
          </div>
        )}
        {!done1 && <SwipingCard src="swipe_a" w={W} dx={d1} learn />}
        {done1 && !done2 && (
          <>
            <div style={{ position: 'absolute', left: 0, top: 0, width: W, height: statusOf(W) + CARD.y * k, overflow: 'hidden' }}>
              <Shot src="swipe_b" w={W} />
            </div>
            <SwipingCard src="swipe_b" w={W} dx={d2} learn={false} />
          </>
        )}
        {finger(20, 1, d1)}
        {finger(54, -1, d2)}
      </RisingPhone>
      <Chip f={f} at={36} top={900} right={24} size={104} font={32} bg="#E7F7EC" color={C.learned} tilt={6}>✓ Öğrendim</Chip>
      <Chip f={f} at={70} top={1250} left={24} size={104} font={32} bg="#FDE8E7" color={C.review} tilt={6}>↻ Tekrar</Chip>
    </Feature>
  );
};

const F4Examples = () => {
  const f = useV();
  const W = 500;
  const flip = tw(f, 22, 40, 0, 1, INOUT);
  const flipScale = Math.max(0.02, Math.abs(Math.cos(flip * Math.PI)));
  const toDetail = tw(f, 50, 68, 0, 1, INOUT);
  const k = W / 412;
  const hl = tw(f, 66, 84);
  return (
    <Feature>
      <FeatureText idx={4} title="Örnek cümlelerle öğren" sub="Kartı çevir: anlamı ve cümlesi karşında" />
      <RisingPhone>
        <div style={{ position: 'absolute', inset: 0, transform: `translateX(${-toDetail * 100}%)` }}>
          <div style={{ position: 'absolute', inset: 0, transform: `scaleX(${flipScale})` }}>
            <Shot src={flip < 0.5 ? 'calis' : 'calis2'} w={W} />
          </div>
          <TapDot f={f} at={18} x={206} y={420} w={W} />
        </div>
        <div style={{ position: 'absolute', inset: 0, transform: `translateX(${(1 - toDetail) * 100}%)` }}>
          <Shot src="kart2" w={W} />
          <div style={{
            position: 'absolute', left: 14 * k, top: statusOf(W) + 468 * k, width: 384 * k, height: 128 * k,
            borderRadius: 22, border: `5px solid ${C.accent}`, opacity: hl, transform: `scale(${1.08 - hl * 0.08})`,
            boxShadow: `0 0 0 2000px rgba(0,0,0,${0.16 * hl})`,
          }} />
        </div>
      </RisingPhone>
    </Feature>
  );
};

const F5Levels = () => {
  const f = useV();
  return (
    <Feature>
      <FeatureText idx={5} title="400+ seviye testi" sub="Her seviyede ilerlemeni bölüm bölüm takip et" />
      <RisingPhone>
        <ShotSeq f={f} w={500} slide seq={[[0, 'seviye'], [36, 'quiz'], [58, 'soru2']]} />
        <TapDot f={f} at={54} x={78} y={158} w={500} />
      </RisingPhone>
      <Chip f={f} at={24} top={900} left={30} size={112} font={34} bg={C.surface} color={C.learned}>✓ 35/35 bölüm</Chip>
      <Chip f={f} at={64} top={1420} right={30} size={112} font={34} bg="#E7F7EC" color={C.learned}>Doğru! ✓</Chip>
    </Feature>
  );
};

const TYPE_TAPS = [[16, 349, 698, 'yaz_1'], [27, 349, 641, 'yaz_2'], [38, 64, 641, 'yaz_3'], [52, 332, 833, 'yaz_4']];
const F6Writing = () => {
  const f = useV();
  const seq = [[0, 'yaz_0'], ...TYPE_TAPS.map(([at, , , s]) => [at + 1, s])];
  return (
    <Feature>
      <FeatureText idx={6} title="Onlarca yazma testi" sub="Kelimeyi yaz, anlamını yaz" />
      <RisingPhone>
        {seq.map(([at, src], i) => (f >= at ? <Shot key={src} src={src} w={500} style={{ opacity: i === 0 ? 1 : tw(f, at, at + 4) }} /> : null))}
        {TYPE_TAPS.map(([at, x, y]) => <TapDot key={at} f={f} at={at} x={x} y={y} w={500} />)}
      </RisingPhone>
      <Chip f={f} at={22} top={940} left={30} size={104} font={32} bg={C.surface} color={C.accent} tilt={-6}>✎ Kelimeyi yaz</Chip>
      <Chip f={f} at={30} top={1300} right={30} size={104} font={32} bg={C.surface} color={C.pink} tilt={-6}>Aa Anlamı yaz</Chip>
    </Feature>
  );
};

const BARS = [18, 26, 12, 34, 22, 40, 30];
const DAYS = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];

const F7Stats = () => {
  const f = useV();
  const card = tw(f, 6, 40);
  const wg = tw(f, 40, 64);
  const learned = Math.round(interpolate(f, [10, 48], [0, 1240], { ...clamp, easing: Easing.out(Easing.cubic) }));
  const max = Math.max(...BARS);
  return (
    <Feature>
      <FeatureText idx={7} title="İlerlemeni takip et" sub="Seri, istatistik ve tekrar" />
      <div style={{
        position: 'absolute', top: 630, left: 90, width: 900, padding: 40, borderRadius: 48, background: C.canvas,
        boxShadow: '0 50px 100px rgba(40,30,120,0.18)', border: `2px solid ${C.surface}`,
        transform: `translateY(${(1 - card) * 1000}px) rotate(${(1 - card) * 4}deg)`,
      }}>
        <div style={{ fontSize: 40, fontWeight: 700, color: C.text, textAlign: 'center', marginBottom: 28 }}>İstatistikler</div>
        <div style={{ display: 'flex', gap: 24 }}>
          {[[learned.toLocaleString('tr-TR'), 'Öğrenilen kelime', C.learned, '✓'], ['12', 'Günlük seri', C.star, '🔥']].map(([v, l, c, ic]) => (
            <div key={l} style={{ flex: 1, background: C.surface, borderRadius: 30, padding: '28px 0', textAlign: 'center', border: `2px solid ${C.sep}` }}>
              <div style={{ fontSize: 36, color: c }}>{ic}</div>
              <div style={{ fontSize: 72, fontWeight: 800, color: c, lineHeight: 1.1 }}>{v}</div>
              <div style={{ fontSize: 28, color: C.text2 }}>{l}</div>
            </div>
          ))}
        </div>
        <div style={{ marginTop: 24, background: C.surface, borderRadius: 30, padding: '30px 30px 22px', border: `2px solid ${C.sep}` }}>
          <div style={{ fontSize: 28, fontWeight: 600, color: C.text2, marginBottom: 14 }}>Son 7 gün</div>
          <div style={{ display: 'flex', alignItems: 'flex-end', height: 300, gap: 18 }}>
            {BARS.map((b, i) => {
              const t = tw(f, 20 + i * 3, 44 + i * 3);
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-end', height: '100%' }}>
                  <div style={{ fontSize: 22, color: C.text3, opacity: t }}>{b}</div>
                  <div style={{ width: '100%', height: Math.max(6, 230 * (b / max) * t), borderRadius: 10, marginTop: 6, background: C.accent, opacity: 0.35 + 0.65 * t }} />
                  <div style={{ fontSize: 22, color: C.text3, marginTop: 10 }}>{DAYS[i]}</div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
      <div style={{ position: 'absolute', top: 1400, left: 540 - 220 * 1.25, opacity: wg, transform: `translateY(${(1 - wg) * 80}px) scale(${0.85 + wg * 0.15}) rotate(${-3 * wg}deg)` }}>
        <Widget scale={1.25} />
      </div>
    </Feature>
  );
};

// ---- Kapanış ----------------------------------------------------------------
// Arkada yavaşça yükselen, soluk Kiril harfleri.
const DRIFT = 'АБВГДЖЗИЛФЦЧШЩЫЭЮЯ'.split('');
const Drift = ({ f }) => (
  <AbsoluteFill style={{ overflow: 'hidden' }}>
    {DRIFT.map((ch, i) => {
      const x = (i * 197) % 1000 + 20;
      const speed = 1.2 + (i % 5) * 0.35;
      const y = 1980 - ((f * speed + i * 260) % 2200);
      const size = 60 + (i % 4) * 34;
      return (
        <div key={i} style={{
          position: 'absolute', left: x, top: y, fontSize: size, fontWeight: 800,
          color: i % 3 ? C.accent : C.pink, opacity: 0.07 * tw(f, 0, 20), transform: `rotate(${(i % 7) * 8 - 24}deg)`,
        }}>{ch}</div>
      );
    })}
  </AbsoluteFill>
);

// Resmî rozetle aynı ölçüde "çok yakında" kartı. Uygulama henüz App Store'da
// olmadığı için Apple'ın indirme rozeti kullanılmıyor.
const SoonBadge = ({ w }) => (
  <div style={{
    width: w * 0.985, height: w * 0.37, borderRadius: w * 0.05, background: '#000', border: '3px solid #A6A6A6',
    boxSizing: 'border-box', color: '#fff', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
  }}>
    <div style={{ fontSize: w * 0.062, fontWeight: 600, letterSpacing: 2, color: '#FFD60A' }}>ÇOK YAKINDA</div>
    <div style={{ fontSize: w * 0.135, fontWeight: 600, lineHeight: 1.05, letterSpacing: -1 }}>App Store'da</div>
  </div>
);

const Outro = () => {
  const f = useV();
  const free = tw(f, 22, 44);
  const badges = tw(f, 40, 64);
  const shine = interpolate(f, [60, 90], [-40, 140], clamp);
  const items = ['8.000+ kelime', 'Reklamsız', 'Çevrimdışı'];
  return (
    <AbsoluteFill style={{ alignItems: 'center' }}>
      <Drift f={f} />
      <div style={{
        position: 'absolute', left: 540 - 420, top: 700 - 420, width: 840, height: 840, borderRadius: '50%',
        background: 'radial-gradient(closest-side, rgba(94,92,230,0.16), rgba(224,72,154,0.06) 60%, transparent)',
        opacity: tw(f, 0, 30), transform: `scale(${1 + 0.04 * Math.sin(f / 16)})`,
      }} />
      <div style={{ position: 'absolute', top: 870, width: '100%', textAlign: 'center' }}>
        <Rise text="FlipRU" at={8} size={124} />
        <div style={{ fontSize: 42, color: C.text2, marginTop: 2, opacity: tw(f, 16, 32) }}>Rusça–Türkçe kelime öğren</div>
        <div style={{
          marginTop: 44, fontSize: 84, fontWeight: 800, letterSpacing: -2, lineHeight: 1.1,
          background: `linear-gradient(90deg, ${C.accent}, ${C.pink})`, WebkitBackgroundClip: 'text', color: 'transparent',
          opacity: free, transform: `translateY(${(1 - free) * 30}px) scale(${0.92 + free * 0.08})`,
        }}>
          Tamamen ücretsiz
        </div>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 16, marginTop: 26 }}>
          {items.map((t, i) => {
            const s = tw(f, 30 + i * 4, 52 + i * 4);
            return (
              <div key={t} style={{ padding: '12px 26px', borderRadius: 999, background: C.surface, color: C.accent, fontSize: 30, fontWeight: 700, opacity: s, transform: `translateY(${(1 - s) * 20}px)`, border: `2px solid ${C.sep}` }}>{t}</div>
            );
          })}
        </div>
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 28, marginTop: 70, opacity: badges, transform: `translateY(${(1 - badges) * 40}px)` }}>
          <div style={{ position: 'relative', width: 440, overflow: 'hidden', borderRadius: 24 }}>
            <Img src={staticFile('google_play_tr.png')} style={{ width: 440, display: 'block' }} />
            <div style={{
              position: 'absolute', top: 0, bottom: 0, left: `${shine}%`, width: '22%',
              background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.35), transparent)', transform: 'skewX(-20deg)',
            }} />
          </div>
          <SoonBadge w={440} />
        </div>
      </div>
    </AbsoluteFill>
  );
};

// ---- Sesler ------------------------------------------------------------------
// Kare numaraları sanal; ekleme sırasında gerçek kareye çevriliyor.
const FEATS = [F1Words, F2Alphabet, F3Swipe, F4Examples, F5Levels, F6Writing, F7Stats];
const fs = (i) => F0 + i * FL;
const SFX = [
  [52, 'tap', 0.7], [60, 'pop', 0.35], [104, 'pop', 0.4], [118, 'ding', 0.4],
  // Her özellik başında bir üst nota: adım adım çıkan bir melodi.
  ...FEATS.map((_, i) => [fs(i) + 2, `note${i + 1}`, 0.6]),
  // 1: sayaç
  ...Array.from({ length: 10 }, (_, j) => [fs(0) + 4 + j * 3.5, 'tick', 0.3]),
  // 2: alfabe
  [fs(1) + 42, 'tap', 0.6],
  // 3: kaydırma
  [fs(2) + 34, 'slide', 0.6], [fs(2) + 68, 'slide', 0.6],
  // 4: kart çevirme
  [fs(3) + 18, 'tap', 0.6], [fs(3) + 24, 'slide', 0.4],
  // 5: seviye testleri
  [fs(4) + 54, 'tap', 0.6], [fs(4) + 64, 'ding', 0.45],
  // 6: yazma
  ...TYPE_TAPS.slice(0, 3).map(([at]) => [fs(5) + at, 'key', 0.7]),
  [fs(5) + 52, 'tap', 0.6], [fs(5) + 54, 'ding', 0.45],
  // 7: istatistik
  ...BARS.map((_, j) => [fs(6) + 22 + j * 3.5, 'tick', 0.3]),
  // Kapanış
  [END + 4, 'sparkle', 0.5], [END + 24, 'note7', 0.35], [END + 42, 'pop', 0.35],
];

// ---- Birleşim ----------------------------------------------------------------
export const FlipRU = () => {
  const f = useV();
  const total = TOTAL;
  return (
    <AbsoluteFill style={{ fontFamily: 'Inter', background: C.canvas }}>
      <AbsoluteFill style={{
        background: `radial-gradient(60% 35% at ${20 + Math.sin(f / 60) * 10}% 8%, rgba(94,92,230,0.10), transparent 70%),
                     radial-gradient(60% 35% at ${85 + Math.cos(f / 70) * 8}% 92%, rgba(224,72,154,0.08), transparent 70%)`,
      }} />
      <Sequence from={0} durationInFrames={R(OPEN_END)}><Opening /></Sequence>
      <Sequence from={R(F0)}><Line /></Sequence>
      {FEATS.map((Comp, i) => (
        <Sequence key={i} from={R(fs(i))} durationInFrames={R(FL + 8)}><Comp /></Sequence>
      ))}
      <Sequence from={R(END)}><Outro /></Sequence>
      <Audio src={staticFile('audio/music.wav')}
        volume={(fr) => interpolate(fr, [0, 8, total - 40, total], [0, 0.6, 0.6, 0], clamp)} />
      {SFX.map(([at, name, vol], i) => (
        <Sequence key={i} from={R(at)} durationInFrames={50}>
          <Audio src={staticFile(`audio/${name}.wav`)} volume={vol} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};
