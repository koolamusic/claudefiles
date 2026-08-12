#!/usr/bin/env node
// jira:serve — build a static review site from .jira/sprints/**.
// Zero hard deps: resolves a GFM renderer from the host project's node_modules
// (micromark+gfm, marked, or markdown-it); falls back to a built-in mini renderer.
// Usage: node serve-site.mjs [--root <repo>] [--out <dir>] [--only A,B,C]
//        [--include <dir>[:Title]]... [--title <site title>]
import { readFileSync, writeFileSync, mkdirSync, readdirSync, existsSync, statSync, rmSync } from 'node:fs'
import { join, basename, resolve } from 'node:path'
import { pathToFileURL } from 'node:url'

// ---- args ----
const args = process.argv.slice(2)
const opt = (name, dflt) => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : dflt }
const multi = (name) => args.flatMap((a, i) => (a === name ? [args[i + 1]] : []))
const ROOT = resolve(opt('--root', process.cwd()))
const OUT = resolve(opt('--out', `/tmp/jira-serve/${basename(ROOT)}`))
const ONLY = opt('--only', null)?.split(',').map((s) => s.trim().replace(/\.md$/, ''))
const INCLUDES = multi('--include').map((s) => { const [dir, title] = s.split(':'); return { dir: resolve(ROOT, dir), title: title || basename(dir) } })
const TITLE = opt('--title', `${basename(ROOT)} · Sprint Review`)
const SPRINTS_DIR = join(ROOT, '.jira/sprints')

// ---- markdown renderer resolution ----
async function resolveRenderer() {
  const pnpm = join(ROOT, 'node_modules/.pnpm')
  const probe = (prefix) => {
    if (!existsSync(pnpm)) return null
    const hit = readdirSync(pnpm).find((d) => d.startsWith(prefix + '@') && !d.includes('extension-gfm-'))
    return hit ? join(pnpm, hit, 'node_modules', prefix) : null
  }
  const direct = (name) => { const p = join(ROOT, 'node_modules', name); return existsSync(p) ? p : null }
  const mmPath = direct('micromark') || probe('micromark')
  const gfmPath = direct('micromark-extension-gfm') || probe('micromark-extension-gfm')
  if (mmPath && gfmPath) {
    try {
      const mm = await import(pathToFileURL(join(mmPath, 'index.js')))
      const gf = await import(pathToFileURL(join(gfmPath, 'index.js')))
      return (md) => mm.micromark(md, { extensions: [gf.gfm()], htmlExtensions: [gf.gfmHtml()] })
    } catch {}
  }
  for (const name of ['marked', 'markdown-it']) {
    const p = direct(name) || probe(name)
    if (!p) continue
    try {
      const lib = await import(pathToFileURL(join(p, name === 'marked' ? 'lib/marked.esm.js' : 'index.mjs')))
      if (name === 'marked') return (md) => lib.marked.parse(md, { gfm: true })
      const it = new lib.default({ html: false, linkify: true }); return (md) => it.render(md)
    } catch {}
  }
  console.error('[serve-site] no markdown lib found in project — using built-in mini renderer (tables/code/lists only)')
  return miniRender
}

function miniRender(md) {
  const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  const lines = md.split('\n'); const out = []; let inCode = false, inList = false, inTable = false
  const closeAll = () => { if (inList) { out.push('</ul>'); inList = false } if (inTable) { out.push('</table>'); inTable = false } }
  const inline = (s) => esc(s)
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>')
  for (const line of lines) {
    if (/^\s*```/.test(line)) { closeAll(); out.push(inCode ? '</code></pre>' : '<pre><code>'); inCode = !inCode; continue }
    if (inCode) { out.push(esc(line)); continue }
    const h = line.match(/^(#{1,4})\s+(.*)/)
    if (h) { closeAll(); out.push(`<h${h[1].length}>${inline(h[2])}</h${h[1].length}>`); continue }
    if (/^\s*\|/.test(line)) { if (/^\s*\|[\s:|-]+\|\s*$/.test(line)) continue
      if (!inTable) { out.push('<table>'); inTable = true }
      out.push('<tr>' + line.split('|').slice(1, -1).map((c) => `<td>${inline(c.trim())}</td>`).join('') + '</tr>'); continue }
    if (inTable) { out.push('</table>'); inTable = false }
    if (/^\s*[-*]\s+/.test(line)) { if (!inList) { out.push('<ul>'); inList = true } out.push(`<li>${inline(line.replace(/^\s*[-*]\s+/, ''))}</li>`); continue }
    if (inList && line.trim() === '') { out.push('</ul>'); inList = false; continue }
    if (line.trim() === '---') { closeAll(); out.push('<hr>'); continue }
    out.push(line.trim() === '' ? '' : `<p>${inline(line)}</p>`)
  }
  closeAll(); if (inCode) out.push('</code></pre>')
  return out.join('\n')
}

// escape raw angle brackets outside code so tokens like foo_<id> survive
function preEscape(md) {
  const lines = md.split('\n'); let inFence = false
  return lines.map((line) => {
    if (/^\s*(```|~~~)/.test(line)) { inFence = !inFence; return line }
    if (inFence) return line
    return line.split('`').map((seg, i) => (i % 2 === 1 ? seg : seg
      .replace(/&(?![a-zA-Z#0-9]+;)/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'))).join('`')
  }).join('\n')
}

function splitFrontmatter(md) {
  const m = md.match(/^---\n([\s\S]*?)\n---\n/)
  return m ? { fm: m[1], body: md.slice(m[0].length) } : { fm: null, body: md }
}

const CSS = `
:root{--bg:#0e1116;--panel:#151920;--line:#232a35;--text:#d7dce4;--dim:#8b95a5;--accent:#7aa2f7;--code:#1a1f28}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:15px/1.65 -apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif}
a{color:var(--accent);text-decoration:none}a:hover{text-decoration:underline}
.layout{display:flex;min-height:100vh}
nav{width:300px;flex:0 0 300px;background:var(--panel);border-right:1px solid var(--line);padding:20px 0;position:sticky;top:0;height:100vh;overflow-y:auto;font-size:13px}
nav .brand{padding:0 18px 14px;font-weight:700;font-size:15px}nav .brand a{color:var(--text)}
nav h4{margin:16px 18px 6px;color:var(--dim);text-transform:uppercase;font-size:10.5px;letter-spacing:.12em}
nav a.item{display:block;padding:3px 18px;color:var(--text);opacity:.85;border-left:2px solid transparent}
nav a.item:hover{opacity:1;background:#1a2029;text-decoration:none}
nav a.item.active{border-left-color:var(--accent);color:var(--accent);opacity:1}
nav details{margin:0}nav summary{cursor:pointer;padding:3px 18px;opacity:.9;list-style:none;display:flex;align-items:center;gap:6px}
nav summary::before{content:'▸';color:var(--dim);font-size:10px}nav details[open] summary::before{content:'▾'}
nav details a.item{padding-left:34px;font-size:12.5px}
.badge{font-size:9.5px;font-weight:700;padding:1px 6px;border-radius:8px;margin-left:auto}
.badge.ok{background:rgba(46,163,107,.16);color:#5ecf98}.badge.rev{background:rgba(209,154,47,.16);color:#e6b95c}
main{flex:1;min-width:0;padding:40px 48px 90px}article{max-width:52rem;margin:0 auto}
.crumbs{color:var(--dim);font-size:12.5px;margin-bottom:18px}.crumbs a{color:var(--dim)}
article h1{font-size:26px;margin:.2em 0 .6em}article h2{font-size:20px;margin-top:2em;padding-bottom:.25em;border-bottom:1px solid var(--line)}
article h3{font-size:16.5px;margin-top:1.6em}
article code{background:var(--code);border:1px solid var(--line);border-radius:4px;padding:.08em .35em;font:12.5px ui-monospace,Menlo,Consolas,monospace}
article pre{background:var(--code);border:1px solid var(--line);border-radius:8px;padding:14px 16px;overflow-x:auto}
article pre code{background:none;border:none;padding:0}
article table{border-collapse:collapse;width:100%;margin:1.2em 0;font-size:13.5px;display:block;overflow-x:auto}
article th,article td{border:1px solid var(--line);padding:7px 10px;text-align:left;vertical-align:top}
article th{background:var(--panel);color:var(--dim);font-size:12px;text-transform:uppercase}
article blockquote{border-left:3px solid var(--accent);margin:1.2em 0;padding:.2em 1.1em;color:var(--dim);border-radius:0 6px 6px 0}
details.fm{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:8px 14px;margin-bottom:1.4em;font-size:12.5px}
details.fm summary{cursor:pointer;color:var(--dim);text-transform:uppercase;font-size:10.5px}
details.fm pre{margin:.6em 0 .3em;font-size:12px;white-space:pre-wrap}
.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:12px;margin:1.4em 0}
.card{background:var(--panel);border:1px solid var(--line);border-radius:10px;padding:14px 16px}
.card .t{font-weight:600;display:flex;align-items:center;gap:8px}.card .m{color:var(--dim);font-size:12.5px;margin-top:6px}
.stamp{color:var(--dim);font-size:11.5px;margin-top:60px;border-top:1px solid var(--line);padding-top:12px}
`

const DOC_ORDER = ['BRIEF', 'RESEARCH', 'CONTEXT']
const DOC_TAIL = ['CHECK', 'ISSUE-DRAFT', 'EXECUTION', 'VERIFICATION', 'RETRO']
function orderDocs(files) {
  const names = files.map((f) => f.replace(/\.md$/, ''))
  const plans = names.filter((n) => /^\d+-PLAN$/.test(n)).sort()
  const head = DOC_ORDER.filter((n) => names.includes(n))
  const tail = DOC_TAIL.filter((n) => names.includes(n))
  const rest = names.filter((n) => !head.includes(n) && !plans.includes(n) && !tail.includes(n)).sort()
  return [...head, ...plans, ...tail, ...rest]
}

const main = async () => {
  const render0 = await resolveRenderer()
  const render = (md) => {
    const { fm, body } = splitFrontmatter(md)
    let html = render0(preEscape(body))
    if (fm) html = `<details class="fm"><summary>frontmatter</summary><pre>${fm.replace(/&/g, '&amp;').replace(/</g, '&lt;')}</pre></details>` + html
    return html
  }
  const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;')

  if (!existsSync(SPRINTS_DIR)) { console.error(`[serve-site] no ${SPRINTS_DIR} — run /jira:init first`); process.exit(1) }
  const sprints = readdirSync(SPRINTS_DIR)
    .filter((d) => statSync(join(SPRINTS_DIR, d)).isDirectory())
    .map((slug) => {
      const dir = join(SPRINTS_DIR, slug)
      let docs = orderDocs(readdirSync(dir).filter((f) => f.endsWith('.md')))
      if (ONLY) docs = docs.filter((n) => ONLY.includes(n))
      const featDir = join(dir, 'features')
      const features = existsSync(featDir) ? readdirSync(featDir).filter((f) => f.endsWith('.feature')).sort() : []
      let verdict = null
      const check = join(dir, 'CHECK.md')
      if (existsSync(check)) { const m = readFileSync(check, 'utf8').match(/VERDICT:\s*(APPROVE|REVISE)(?![\s\S]*VERDICT:)/); verdict = m?.[1] ?? null }
      return { slug, dir, docs, features, mtime: statSync(dir).mtimeMs, verdict }
    })
    .filter((s) => s.docs.length)
    .sort((a, b) => b.mtime - a.mtime)

  const includes = INCLUDES.filter((i) => existsSync(i.dir)).map((i) => ({
    ...i, files: readdirSync(i.dir).filter((f) => f.endsWith('.md') && statSync(join(i.dir, f)).size > 0).sort(),
  }))
  const hasState = existsSync(join(ROOT, '.jira/STATE.md'))

  function navHtml(active) {
    let h = `<div class="brand"><a href="/index.html">${esc(TITLE)}</a></div>`
    if (hasState) h += `<h4>Project</h4><a class="item${active === 'state' ? ' active' : ''}" href="/state.html">STATE</a>`
    h += `<h4>Sprints</h4>`
    for (const s of sprints) {
      const badge = s.verdict ? `<span class="badge ${s.verdict === 'APPROVE' ? 'ok' : 'rev'}">${s.verdict === 'APPROVE' ? 'OK' : 'REV'}</span>` : ''
      h += `<details${active.startsWith(`s/${s.slug}/`) ? ' open' : ''}><summary>${esc(s.slug)}${badge}</summary>`
      for (const d of s.docs) {
        h += `<a class="item${active === `s/${s.slug}/${d}` ? ' active' : ''}" href="/s/${s.slug}/${d}.html">${esc(d)}</a>`
        if (d === 'CONTEXT') for (const f of s.features) { const n = f.replace(/\.feature$/, ''); h += `<a class="item${active === `s/${s.slug}/features/${n}` ? ' active' : ''}" href="/s/${s.slug}/features/${n}.html">${esc(f)}</a>` }
      }
      if (!s.docs.includes('CONTEXT')) for (const f of s.features) { const n = f.replace(/\.feature$/, ''); h += `<a class="item${active === `s/${s.slug}/features/${n}` ? ' active' : ''}" href="/s/${s.slug}/features/${n}.html">${esc(f)}</a>` }
      h += `</details>`
    }
    for (const inc of includes) {
      h += `<h4>${esc(inc.title)}</h4>`
      for (const f of inc.files) { const n = f.replace(/\.md$/, ''); h += `<a class="item${active === `x/${inc.title}/${n}` ? ' active' : ''}" href="/x/${encodeURIComponent(inc.title)}/${n}.html">${esc(n)}</a>` }
    }
    return h
  }
  const shell = ({ title, crumbs, body, active }) => `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${esc(title)}</title><style>${CSS}</style></head><body><div class="layout"><nav>${navHtml(active)}</nav><main><article><div class="crumbs">${crumbs}</div>${body}<div class="stamp">${esc(TITLE)} · generated ${new Date().toISOString().slice(0, 16).replace('T', ' ')} UTC</div></article></main></div></body></html>`

  rmSync(OUT, { recursive: true, force: true })
  let pages = 0
  if (hasState) {
    mkdirSync(OUT, { recursive: true })
    writeFileSync(join(OUT, 'state.html'), shell({ title: 'STATE', crumbs: `<a href="/index.html">review</a> / state`, body: `<h1 style="margin-top:0">STATE</h1>` + render(readFileSync(join(ROOT, '.jira/STATE.md'), 'utf8')), active: 'state' })); pages++
  }
  for (const s of sprints) {
    mkdirSync(join(OUT, 's', s.slug), { recursive: true })
    for (const d of s.docs) {
      writeFileSync(join(OUT, 's', s.slug, `${d}.html`), shell({ title: `${s.slug} · ${d}`, crumbs: `<a href="/index.html">review</a> / ${esc(s.slug)}`, body: `<h1 style="margin-top:0">${esc(s.slug)} · ${esc(d)}</h1>` + render(readFileSync(join(s.dir, `${d}.md`), 'utf8')), active: `s/${s.slug}/${d}` })); pages++
    }
    if (s.features.length) mkdirSync(join(OUT, 's', s.slug, 'features'), { recursive: true })
    for (const f of s.features) {
      const n = f.replace(/\.feature$/, '')
      writeFileSync(join(OUT, 's', s.slug, 'features', `${n}.html`), shell({ title: `${s.slug} · ${f}`, crumbs: `<a href="/index.html">review</a> / ${esc(s.slug)} / features`, body: `<h1 style="margin-top:0">${esc(s.slug)} · ${esc(f)}</h1><pre><code>${esc(readFileSync(join(s.dir, 'features', f), 'utf8'))}</code></pre>`, active: `s/${s.slug}/features/${n}` })); pages++
    }
  }
  for (const inc of includes) {
    mkdirSync(join(OUT, 'x', inc.title), { recursive: true })
    for (const f of inc.files) {
      const n = f.replace(/\.md$/, '')
      writeFileSync(join(OUT, 'x', inc.title, `${n}.html`), shell({ title: `${inc.title} · ${n}`, crumbs: `<a href="/index.html">review</a> / ${esc(inc.title)}`, body: `<h1 style="margin-top:0">${esc(inc.title)} · ${esc(n)}</h1>` + render(readFileSync(join(inc.dir, f), 'utf8')), active: `x/${inc.title}/${n}` })); pages++
    }
  }
  const cards = sprints.map((s) => `<div class="card"><div class="t"><a href="/s/${s.slug}/${s.docs[0]}.html">${esc(s.slug)}</a>${s.verdict ? `<span class="badge ${s.verdict === 'APPROVE' ? 'ok' : 'rev'}">${s.verdict}</span>` : ''}</div><div class="m">${s.docs.length} docs</div></div>`).join('')
  const idx = `<h1 style="margin-top:0">${esc(TITLE)}</h1>${hasState ? `<p><a href="/state.html">Project STATE</a></p>` : ''}<h2>Sprints</h2><div class="cards">${cards}</div>${includes.map((inc) => `<h2>${esc(inc.title)}</h2><div class="cards">${inc.files.map((f) => { const n = f.replace(/\.md$/, ''); return `<div class="card"><div class="t"><a href="/x/${encodeURIComponent(inc.title)}/${n}.html">${esc(n)}</a></div></div>` }).join('')}</div>`).join('')}`
  writeFileSync(join(OUT, 'index.html'), shell({ title: TITLE, crumbs: 'review', body: idx, active: 'index' })); pages++
  console.log(`[serve-site] built ${pages} pages -> ${OUT}`)
}
main()
