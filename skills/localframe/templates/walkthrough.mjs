// Browser walkthrough shot list. Copy into the take directory, edit walk(), then run:
//   BASE_URL=https://app.example.com node walkthrough.mjs
// Optional: RESOLVE="app.example.com 203.0.113.7" maps a hostname without touching /etc/hosts.
import { execFileSync } from 'node:child_process'
import { existsSync, mkdirSync, readFileSync, renameSync, unlinkSync } from 'node:fs'
import { join } from 'node:path'
import { chromium } from 'playwright'

const BASE_URL = process.env.BASE_URL
if (!BASE_URL) throw new Error('Set BASE_URL to the page the walkthrough starts on.')
const OUT = process.env.OUT ?? '.'
const RELAY = join(OUT, '.take')
const SIZE = { width: 1440, height: 900 }

let shots = 0

const pause = (seconds = 2.5) => new Promise((done) => setTimeout(done, seconds * 1000))

async function shot(page, name) {
  shots += 1
  await page.screenshot({ path: join(OUT, `${String(shots).padStart(2, '0')}-${name}.png`) })
}

async function typeSlow(locator, text) {
  await locator.click()
  await locator.pressSequentially(text, { delay: 80 })
}

async function scrollSlow(page, pixels, step = 40) {
  for (let y = 0; y < pixels; y += step) {
    await page.mouse.wheel(0, step)
    await pause(0.05)
  }
}

// A person writes a value the recorder can't get on its own (an emailed code, an
// organisation name) into .take/<file>. The file is read once and deleted.
async function waitFile(file, what, minutes = 10) {
  const path = join(RELAY, file)
  console.log(`>>> Write ${what} to ${path} (waiting up to ${minutes} min)`)
  const deadline = Date.now() + minutes * 60_000
  for (;;) {
    if (existsSync(path)) {
      const value = readFileSync(path, 'utf8').trim()
      if (value) {
        unlinkSync(path)
        return value
      }
    }
    if (Date.now() > deadline) throw new Error(`Timed out waiting for ${path}`)
    await pause(1)
  }
}

async function walk(page) {
  await page.goto(BASE_URL)
  await pause()
  await shot(page, 'landing')

  // Passwordless sign-in. Use a real inbox: throwaway domains are often rejected
  // and no code is ever sent.
  // await typeSlow(page.getByLabel('Email'), 'demo@your-domain.com')
  // await page.getByRole('button', { name: 'Continue' }).click()
  // await pause()
  // await shot(page, 'passcode')
  // const code = await waitFile('code.txt', 'the emailed sign-in code')
  // await typeSlow(page.getByLabel('Code'), code)
  // await pause()
  // await shot(page, 'overview')

  await scrollSlow(page, 900)
  await pause()
  await shot(page, 'scrolled')
}

mkdirSync(join(OUT, 'raw'), { recursive: true })
mkdirSync(RELAY, { recursive: true, mode: 0o700 })

// Add '--no-sandbox' here on hosts where Chromium refuses to start without it.
const args = process.env.RESOLVE ? [`--host-resolver-rules=MAP ${process.env.RESOLVE}`] : []
const browser = await chromium.launch({ args })
const context = await browser.newContext({
  viewport: SIZE,
  recordVideo: { dir: join(OUT, 'raw'), size: SIZE },
})
const page = await context.newPage()
const video = page.video()

try {
  await walk(page)
} finally {
  // Playwright finishes writing the webm only when the context closes.
  await context.close()
  await browser.close()
}

const webm = join(OUT, 'raw', 'walkthrough.webm')
renameSync(await video.path(), webm)
const mp4 = join(OUT, 'walkthrough.mp4')
execFileSync('ffmpeg', [
  '-y', '-loglevel', 'error', '-i', webm,
  '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', mp4,
])
console.log(`${mp4}\n${webm}\n${shots} stills`)
