// Settings: built-in defaults ← global (~/.seecode) ← project (.seecode/).
// A project's first run is detected by the absence of .seecode/config.json;
// the skill then asks the user once and calls init().
import { existsSync, readFileSync, writeFileSync, mkdirSync, readdirSync } from 'node:fs';
import { homedir } from 'node:os';
import { join, dirname, resolve } from 'node:path';

export const DEFAULTS = {
  skin: 'light',
  motion: 'auto',
  exportFormats: ['html', 'png'],
  size: 'auto',
  scale: 'auto',
  fps: 30,
  duration: 'auto',
  outputDir: 'diagrams',
  profile: null,
  watermark: true,
};

const KNOWN = new Set(Object.keys(DEFAULTS).concat(['brand']));

export function globalDir() {
  return process.env.SEECODE_HOME || join(homedir(), '.seecode');
}

export function projectRoot(start = process.cwd()) {
  let dir = resolve(start);
  for (;;) {
    if (existsSync(join(dir, '.seecode', 'config.json')) || existsSync(join(dir, '.git'))) return dir;
    const up = dirname(dir);
    if (up === dir) return resolve(start);
    dir = up;
  }
}

function readJson(path) {
  try {
    return JSON.parse(readFileSync(path, 'utf8'));
  } catch {
    return null;
  }
}

function writeJson(path, obj) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, `${JSON.stringify(obj, null, 2)}\n`);
}

export function paths(cwd) {
  const root = projectRoot(cwd);
  return { root, project: join(root, '.seecode', 'config.json'), global: join(globalDir(), 'config.json'), profiles: join(globalDir(), 'profiles') };
}

export function loadProfile(slug) {
  if (!slug) return null;
  return readJson(join(globalDir(), 'profiles', `${slug}.json`));
}

const HEX = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i;
const BRAND_KEYS = ['accent', 'link', 'paper', 'ink', 'muted'];

// Brand profile: ~/.seecode/profiles/<slug>.json = {brand:{accent,link,paper,ink,muted}, dark?:{…}}
function cleanRoles(roles, label) {
  const clean = {};
  for (const k of BRAND_KEYS) {
    if (roles[k] === undefined) continue;
    if (!HEX.test(roles[k])) throw new Error(`${label}${k} must be a hex colour like #e4572e`);
    clean[k] = roles[k];
  }
  return clean;
}

export function saveProfile(slug, brand, { dark, source } = {}) {
  if (!/^[a-z0-9][a-z0-9-]{0,40}$/.test(slug)) throw new Error('profile slug must be lowercase letters, digits, dashes');
  const clean = cleanRoles(brand, '');
  if (!Object.keys(clean).length) throw new Error(`give at least one of --${BRAND_KEYS.join(', --')}`);
  const file = join(globalDir(), 'profiles', `${slug}.json`);
  const prev = readJson(file) || {};
  const next = { ...prev, brand: { ...(prev.brand || {}), ...clean } };
  delete next.brand['accent-tint'];
  if (dark) next.dark = cleanRoles(dark, 'dark.');
  if (source) next.source = source;
  writeJson(file, next);
  return { slug, file, brand: next.brand, ...(next.dark ? { dark: next.dark } : {}) };
}

export function listProfiles() {
  try {
    return readdirSync(join(globalDir(), 'profiles')).filter((f) => f.endsWith('.json')).map((f) => f.slice(0, -5));
  } catch {
    return [];
  }
}

export function status(cwd) {
  const p = paths(cwd);
  const g = readJson(p.global);
  const proj = readJson(p.project);
  let state = 'first-run';
  if (proj) state = proj.inherit === 'global' ? 'inherits-global' : 'project';
  const settings = { ...DEFAULTS, ...(g || {}), ...(proj && proj.inherit !== 'global' ? proj : {}) };
  delete settings.inherit;
  const profile = loadProfile(settings.profile);
  if (profile) settings.brand = { ...(profile.brand || {}), ...(profile.dark ? { dark: profile.dark } : {}), ...(settings.brand || {}) };
  return { state, root: p.root, hasGlobal: !!g, settings };
}

export function init(cwd, use) {
  const p = paths(cwd);
  if (!readJson(p.global)) writeJson(p.global, { ...DEFAULTS });
  if (use === 'global') writeJson(p.project, { inherit: 'global' });
  else writeJson(p.project, { ...DEFAULTS, ...(readJson(p.global) || {}) });
  return status(cwd);
}

function coerce(v) {
  if (v === 'true') return true;
  if (v === 'false') return false;
  if (v === 'null') return null;
  if (/^-?\d+(\.\d+)?$/.test(v)) return Number(v);
  if (/^[[{]/.test(v)) return JSON.parse(v);
  if (v.includes(',')) return v.split(',').map((s) => s.trim());
  return v;
}

export function set(cwd, key, value, { global = false } = {}) {
  if (!KNOWN.has(key)) throw new Error(`unknown setting "${key}" (known: ${[...KNOWN].join(', ')})`);
  const p = paths(cwd);
  const file = global ? p.global : p.project;
  let cur = readJson(file) || (global ? { ...DEFAULTS } : {});
  if (!global && cur.inherit === 'global') cur = { ...DEFAULTS, ...(readJson(p.global) || {}) };
  delete cur.inherit;
  cur[key] = coerce(String(value));
  writeJson(file, cur);
  return status(cwd);
}
