import { readFileSync } from 'node:fs';
import { expect, test } from 'vitest';
const html = readFileSync(`${process.cwd()}/index.html`, 'utf8');

test('the local composition contains only wordless vector artwork', async () => {
  document.body.innerHTML = html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/g, '');
  expect(document.querySelector('h1, text, img, video, audio')).toBeNull();
  expect(html).not.toMatch(/https?:/);
  expect(document.querySelector('#root').dataset.duration).toBe('5.5');
  const { buildTimeline } = await import('./animation.js');
  const { gsap } = await import('gsap');
  const timeline = buildTimeline(gsap);
  expect(timeline.paused()).toBe(true);
  timeline.seek(0);
  expect(document.querySelector('#button-face').getAttribute('fill')).toBe('#ff9800');
  timeline.kill();
});

test('the button fills the frame before folding into an orange envelope', async () => {
  document.body.innerHTML = html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/g, '');
  const { buildTimeline } = await import('./animation.js');
  const { gsap } = await import('gsap');
  const timeline = buildTimeline(gsap);
  timeline.seek(1.05);
  expect(document.querySelector('#button').getAttribute('transform')).toContain('scale(12 12)');
  timeline.seek(1.9);
  expect(document.querySelector('#button-face').getAttribute('d')).toContain('M -240 -160');
  expect(document.querySelector('#envelope-lines').getAttribute('opacity')).toBe('1');
  timeline.seek(1.05);
  expect(document.querySelector('#button').getAttribute('transform')).toContain('scale(12 12)');
  timeline.kill();
});

test('the envelope crosses the frame rapidly with a short trailing streak', async () => {
  document.body.innerHTML = html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/g, '');
  const { buildTimeline } = await import('./animation.js');
  const { gsap } = await import('gsap');
  const timeline = buildTimeline(gsap);
  timeline.seek(2.3);
  expect(document.querySelector('#button').getAttribute('transform')).toContain('translate(2200 410)');
  timeline.seek(2.8);
  expect(document.querySelector('#button').getAttribute('transform')).toContain('translate(450 450)');
  expect(Number(document.querySelector('#speed-trail').getAttribute('opacity'))).toBeGreaterThan(0.9);
  timeline.seek(3.1);
  expect(document.querySelector('#speed-trail').getAttribute('opacity')).toBe('0');
  timeline.seek(0);
  expect(document.querySelector('#button').getAttribute('transform')).toContain('scale(1 1)');
  timeline.kill();
});

test('the town hall receives the envelope and holds a wordless confirmation', async () => {
  document.body.innerHTML = html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/g, '');
  const { buildTimeline } = await import('./animation.js');
  const { gsap } = await import('gsap');
  const timeline = buildTimeline(gsap);
  timeline.seek(3.2);
  expect(Number(document.querySelector('#button').getAttribute('transform').match(/scale\([^ ]+ ([^)]+)\)/)[1])).toBeGreaterThan(0);
  timeline.seek(3.55);
  expect(document.querySelector('#town-hall')?.getAttribute('opacity')).toBe('1');
  expect(document.querySelector('#button').getAttribute('transform')).toContain('translate(960 700)');
  timeline.seek(4.2);
  expect(document.querySelector('#button').getAttribute('opacity')).toBe('0');
  expect(document.querySelector('#confirmation').getAttribute('opacity')).toBe('1');
  timeline.seek(5.45);
  expect(document.querySelector('#mail-glow').getAttribute('opacity')).toBe('1');
  timeline.seek(0);
  expect(document.querySelector('#town-hall').getAttribute('opacity')).toBe('0');
  expect(document.querySelector('#confirmation').getAttribute('opacity')).toBe('0');
  timeline.kill();
});

test('the envelope exits right, then enters from screen-left and lands rightward', async () => {
  document.body.innerHTML = html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/g, '');
  const { buildTimeline } = await import('./animation.js');
  const { gsap } = await import('gsap');
  const timeline = buildTimeline(gsap);
  const envelopeBounds = () => {
    const transform = document.querySelector('#button').getAttribute('transform');
    const [x, , scaleX, scaleY, degrees] = transform.match(/-?\d+(?:\.\d+)?/g).map(Number);
    const radians = degrees * Math.PI / 180;
    const halfWidth = Math.abs(260 * scaleX * Math.cos(radians)) + Math.abs(160 * scaleY * Math.sin(radians));
    return { x, left: x - halfWidth, right: x + halfWidth };
  };
  timeline.seek(1.9);
  let previousX = envelopeBounds().x;
  for (let frame = 58; frame <= 69; frame += 1) {
    timeline.seek(frame / 30);
    expect(envelopeBounds().x).toBeGreaterThan(previousX);
    previousX = envelopeBounds().x;
  }
  expect(envelopeBounds().left).toBeGreaterThan(1920);
  timeline.seek(2.49);
  expect(envelopeBounds().left).toBeGreaterThan(1920);
  timeline.seek(2.5);
  expect(envelopeBounds().right).toBeLessThan(0);
  previousX = envelopeBounds().x;
  for (let frame = 76; frame <= 106; frame += 1) {
    timeline.seek(frame / 30);
    const currentX = envelopeBounds().x;
    expect(currentX).toBeGreaterThan(previousX);
    expect(currentX).toBeLessThan(960);
    previousX = currentX;
  }
  timeline.seek(3.55);
  expect(document.querySelector('#button').getAttribute('transform')).toContain('translate(960 700)');
  timeline.seek(2.3);
  expect(envelopeBounds().left).toBeGreaterThan(1920);
  timeline.kill();
});

test('the handoff records ticket 25 and the right-exit, left-entry route', () => {
  const handoff = readFileSync(`${process.cwd()}/HANDOFF.md`, 'utf8');
  expect(handoff).toContain('The envelope exits through the source scene’s right edge, then enters beyond the town-hall scene’s left edge and flies rightward to the door. This MP4 is the visual reference for ticket 25; the app still needs its native animation.');
});
