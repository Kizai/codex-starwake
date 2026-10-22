(() => {
  'use strict';
  const DURATION = 6800;
  const params = new URLSearchParams(location.search);
  const native = Boolean(window.webkit?.messageHandlers?.launcher);
  document.body.classList.toggle('native', native);
  document.body.classList.toggle('film', params.has('film'));
  const canvas = document.getElementById('stars');
  const ctx = canvas.getContext('2d');
  const endcard = document.getElementById('endcard');
  const phase = document.getElementById('phase');
  const count = document.getElementById('count');
  const progress = document.getElementById('progress');
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  let width = 0,
    height = 0,
    frame = 0,
    origin = 0,
    playing = false,
    notified = false;
  let currentTime = 0;
  // A fixed seed makes exported frames and the actual launcher match.
  let seed = 1717;
  const random = () => {
    seed = (seed * 16807) % 2147483647;
    return (seed - 1) / 2147483646;
  };
  const stars = Array.from({ length: 125 }, () => ({
    x: random(),
    y: random(),
    r: 0.3 + random() * 1.2,
    s: random() * 6.28,
    v: random(),
  }));
  const dust = Array.from({ length: 44 }, () => ({
    x: random(),
    y: random(),
    s: random() * 6.28,
    r: random() * 1.7 + 0.5,
  }));
  const clamp = (x) => Math.min(1, Math.max(0, x));
  const ease = (x) => {
    x = clamp(x);
    return x * x * (3 - 2 * x);
  };
  const bridge = (event) =>
    window.webkit?.messageHandlers?.launcher?.postMessage(event);
  function resize() {
    width = innerWidth;
    height = innerHeight;
    const dpr = Math.min(devicePixelRatio || 1, 2);
    canvas.width = width * dpr;
    canvas.height = height * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    draw(currentTime);
  }
  function butterfly(x, y, size, t, opacity) {
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(-0.2 + Math.sin(t * 1.3) * 0.13);
    ctx.globalAlpha = opacity;
    const flap = reduce ? 0.75 : 0.35 + 0.65 * Math.abs(Math.sin(t * 5.5));
    ctx.shadowColor = '#86e8ff';
    ctx.shadowBlur = size * 1.8;
    for (const side of [-1, 1]) {
      ctx.save();
      ctx.scale(side * flap, 1);
      const gradient = ctx.createLinearGradient(0, 0, size * 1.3, -size);
      gradient.addColorStop(0, '#e8fdff');
      gradient.addColorStop(0.35, '#8bdcff');
      gradient.addColorStop(1, '#4696e044');
      ctx.fillStyle = gradient;
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.bezierCurveTo(
        size * 0.25,
        -size * 1.2,
        size * 1.8,
        -size * 1.25,
        size * 1.25,
        -size * 0.2,
      );
      ctx.bezierCurveTo(
        size * 0.8,
        size * 0.1,
        size * 1.2,
        size * 1.1,
        size * 0.55,
        size * 0.65,
      );
      ctx.quadraticCurveTo(size * 0.1, size * 0.3, 0, 0);
      ctx.fill();
      ctx.strokeStyle = '#c9f7ff88';
      ctx.lineWidth = 0.45;
      ctx.stroke();
      ctx.restore();
    }
    ctx.fillStyle = '#eafcff';
    ctx.beginPath();
    ctx.ellipse(0, 0, 1, size * 0.55, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }
  function draw(ms) {
    currentTime = ms;
    ctx.clearRect(0, 0, width, height);
    const t = ms / 1000,
      intro = ease(ms / 1400),
      outro = 1 - ease((ms - 5850) / 950);
    for (const s of stars) {
      const drift = reduce ? 0 : t * (2 + s.v * 5);
      const x = s.x * width,
        y = (s.y * height - drift + height) % height;
      ctx.globalAlpha =
        (0.16 + 0.42 * (0.5 + 0.5 * Math.sin(t * 1.4 + s.s))) * intro * outro;
      ctx.fillStyle = s.v > 0.8 ? '#f4e5c2' : '#a7dbf9';
      ctx.beginPath();
      ctx.arc(x, y, s.r, 0, 6.29);
      ctx.fill();
      if (s.v > 0.96) {
        ctx.fillRect(x - 4, y - 0.3, 8, 0.6);
        ctx.fillRect(x - 0.3, y - 4, 0.6, 8);
      }
    }
    // Low-opacity elliptical wavefronts sit on the sea, rather than over the face.
    ctx.save();
    ctx.translate(width * 0.61, height * 0.81);
    ctx.scale(1, 0.16);
    for (let i = 0; i < 3; i++) {
      const p = (t * 0.24 + i / 3) % 1;
      ctx.globalAlpha = (1 - p) * 0.15 * intro * outro;
      ctx.strokeStyle = '#8bdcf7';
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.arc(0, 0, 40 + p * width * 0.31, 0, 6.29);
      ctx.stroke();
    }
    ctx.restore();
    const travel = ease((ms - 250) / 3200);
    const bx = width * (0.3 + 0.33 * travel),
      by =
        height * (0.52 - 0.14 * travel) -
        Math.sin(travel * Math.PI) * height * 0.14;
    const flyAlpha = ease(ms / 650) * (1 - ease((ms - 4400) / 800)) * outro;
    for (const d of dust) {
      const trail = (1 - travel) * 100;
      ctx.globalAlpha = flyAlpha * 0.5 * (0.5 + 0.5 * Math.sin(d.s + t * 2));
      ctx.fillStyle = '#aae9ff';
      ctx.beginPath();
      ctx.arc(bx - (1 - d.x) * trail - 18, by + (d.y - 0.5) * 65, d.r, 0, 6.29);
      ctx.fill();
    }
    butterfly(bx, by, Math.max(7, width * 0.009), t, flyAlpha);
    // Small butterflies cross the foreground on different trajectories.
    for (let i = 0; i < 3; i++) {
      const p = ease((ms - 1000 - i * 800) / 4500);
      butterfly(
        width * (0.82 - i * 0.12 + p * 0.09),
        height * (0.79 - i * 0.11 - p * 0.15),
        3 + i * 1.4,
        t + i,
        Math.sin(p * Math.PI) * 0.55 * outro,
      );
    }
    ctx.globalAlpha = 1;
    progress.style.transform = `scaleX(${ease(ms / 6150)})`;
    count.textContent = `0${Math.min(6, Math.floor(ms / 1000))} / 06`;
    phase.textContent =
      ms < 2000
        ? '星光正在汇聚'
        : ms < 4100
          ? '循着蓝蝶，穿过星海'
          : ms < 5700
            ? '新的旅程，即将开始'
            : '与你重逢';
  }
  function animations() {
    return document.getAnimations().filter((a) => a.effect?.target !== endcard);
  }
  function finish() {
    if (notified) return;
    notified = true;
    playing = false;
    cancelAnimationFrame(frame);
    draw(DURATION);
    if (native) bridge('finish');
    else if (!params.has('film')) endcard.hidden = false;
  }
  function tick(now) {
    if (!playing) return;
    const time = Math.min(DURATION, now - origin);
    draw(time);
    if (time >= DURATION) finish();
    else frame = requestAnimationFrame(tick);
  }
  function play() {
    cancelAnimationFrame(frame);
    endcard.hidden = true;
    notified = false;
    playing = true;
    animations().forEach((a) => {
      a.currentTime = 0;
      a.play();
    });
    origin = performance.now();
    frame = requestAnimationFrame(tick);
  }
  function seek(ms) {
    playing = false;
    cancelAnimationFrame(frame);
    endcard.hidden = true;
    animations().forEach((a) => {
      a.pause();
      a.currentTime = ms;
    });
    draw(ms);
  }
  document.getElementById('replay').addEventListener('click', play);
  document.getElementById('skip').addEventListener('click', finish);
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') finish();
    if (e.key === ' ') {
      e.preventDefault();
      play();
    }
  });
  document.addEventListener('visibilitychange', () => {
    if (document.hidden && playing) {
      playing = false;
      cancelAnimationFrame(frame);
      animations().forEach((a) => a.pause());
    } else if (!document.hidden && !notified && !params.has('manual')) {
      animations().forEach((a) => a.play());
      origin = performance.now() - currentTime;
      playing = true;
      frame = requestAnimationFrame(tick);
    }
  });
  addEventListener('resize', resize);
  resize();
  const image = new Image();
  image.src = 'assets/shorekeeper.png';
  image
    .decode()
    .then(() => {
      window.shorekeeper = {
        play,
        seek,
        duration: DURATION,
        get time() {
          return currentTime;
        },
        get finished() {
          return notified;
        },
      };
      window.dispatchEvent(new Event('shorekeeper-ready'));
      bridge('ready');
      if (params.has('manual')) seek(0);
      else play();
    })
    .catch(() => {
      phase.textContent = '主视觉载入失败，请检查 assets/shorekeeper.png';
      bridge('error');
    });
})();
