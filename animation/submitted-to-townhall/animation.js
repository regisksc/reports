export function buildTimeline(gsap) {
  const timeline = gsap.timeline({ paused: true });
  timeline.set('#button', { attr: { transform: 'translate(960 540) scale(1 1) rotate(0)' } }, 0);
  timeline.fromTo('#button',
    { attr: { transform: 'translate(960 540) scale(1 1) rotate(0)' } },
    { attr: { transform: 'translate(960 540) scale(12 12) rotate(0)' }, duration: 0.6, ease: 'power3.in' }, 0.45);
  timeline.fromTo('#button-underside', { attr: { opacity: 1 } },
    { attr: { opacity: 0 }, duration: 0.15 }, 0.5);
  timeline.fromTo('#button',
    { attr: { transform: 'translate(960 540) scale(12 12) rotate(0)' } },
    { attr: { transform: 'translate(960 540) scale(1 1) rotate(0)' }, duration: 0.75, ease: 'power3.out' }, 1.05);
  timeline.fromTo('#button-face',
    { attr: { d: 'M -465 -85 L 465 -85 Q 510 -85 510 -40 L 510 30 Q 510 75 465 75 L -465 75 Q -510 75 -510 30 L -510 -40 Q -510 -85 -465 -85 Z' } },
    { attr: { d: 'M -240 -160 L 240 -160 Q 260 -160 260 -140 L 260 140 Q 260 160 240 160 L -240 160 Q -260 160 -260 140 L -260 -140 Q -260 -160 -240 -160 Z' }, duration: 0.6, ease: 'power2.inOut' }, 1.05);
  timeline.fromTo('#envelope-lines', { attr: { opacity: 0 } },
    { attr: { opacity: 1 }, duration: 0.18, ease: 'power2.out' }, 1.55);
  timeline.to('#button', { attr: { transform: 'translate(2200 410) scale(0.62 0.62) rotate(12)' }, duration: 0.4, ease: 'power3.in' }, 1.9);
  // Both handoff positions are offscreen, preserving the visible flight direction.
  timeline.set('#button', { attr: { transform: 'translate(-200 410) scale(0.62 0.62) rotate(-18)' } }, 2.5);
  timeline.to('#button', { attr: { transform: 'translate(450 450) scale(0.4 0.4) rotate(12)' }, duration: 0.3, ease: 'power3.in' }, 2.5);
  timeline.to('#button', { attr: { transform: 'translate(780 610) scale(0.28 0.28) rotate(18)' }, duration: 0.22, ease: 'power3.out' }, 2.8);
  timeline.set('#speed-trail', { attr: { transform: 'translate(0 0) scale(1 1)' } }, 0);
  timeline.fromTo('#speed-trail', { attr: { opacity: 0, 'stroke-dasharray': '0 1800' } },
    { attr: { opacity: 1, 'stroke-dasharray': '1600 1800' }, duration: 0.25, ease: 'power3.in' }, 2);
  timeline.to('#speed-trail', { attr: { opacity: 0 }, duration: 0.18, ease: 'power2.out' }, 2.3);
  timeline.set('#speed-trail', { attr: { transform: 'translate(-1000 750) scale(1 -1)' } }, 2.5);
  timeline.fromTo('#speed-trail', { attr: { opacity: 0, 'stroke-dasharray': '0 1800' } },
    { attr: { opacity: 1, 'stroke-dasharray': '1600 1800' }, duration: 0.25, ease: 'power3.in' }, 2.5);
  timeline.to('#speed-trail', { attr: { opacity: 0 }, duration: 0.25, ease: 'power2.out' }, 2.82);
  timeline.fromTo('#town-hall', { attr: { opacity: 0, transform: 'translate(960 840) scale(0.85 0.85) translate(-960 -760)' } },
    { attr: { opacity: 1, transform: 'translate(960 760) scale(1 1) translate(-960 -760)' }, duration: 0.65, ease: 'back.out(1.1)' }, 2.5);
  timeline.to('#button', { attr: { transform: 'translate(960 700) scale(0.13 0.13) rotate(0)' }, duration: 0.53, ease: 'power3.out' }, 3.02);
  timeline.to('#button', { attr: { transform: 'translate(960 700) scale(0.11 0.012) rotate(0)' }, duration: 0.28, ease: 'power2.in' }, 3.65);
  timeline.fromTo('#button', { attr: { opacity: 1 } }, { attr: { opacity: 0 }, duration: 0.1 }, 3.85);
  timeline.fromTo('#mail-glow', { attr: { opacity: 0 } }, { attr: { opacity: 1 }, duration: 0.28, ease: 'power2.out' }, 3.85);
  timeline.fromTo('#confirmation', { attr: { opacity: 0 } }, { attr: { opacity: 1 }, duration: 0.2, ease: 'power2.out' }, 3.98);
  timeline.fromTo('#confirmation', { attr: { transform: 'translate(960 700) scale(0.6 0.6) translate(-960 -700)' } },
    { attr: { transform: 'translate(960 700) scale(1 1) translate(-960 -700)' }, duration: 0.35, ease: 'back.out(1.5)' }, 3.98);
  return timeline;
}
