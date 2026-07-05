// 將投影片源檔（Marp markdown）轉成 HTML + PPTX
//
// 用法（在 repo 根目錄）：
//   node tools/md2slides.js [目錄] [--all]
//   目錄預設 src/ABAP_Training/lectures/slides；--all 全轉，
//   預設只轉 html/pptx 缺少或比 md 舊的。
//
// 前置：Node（npx 會自動抓 @marp-team/marp-cli）、Microsoft Edge（PPTX 渲染用）。
// 注意：PPTX 每頁是整頁圖片（Marp 天性），要可編輯的 pptx 得改走 pandoc。

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const args = process.argv.slice(2);
const ALL = args.includes('--all');
const dirArg = args.find(a => !a.startsWith('--'));
const DIR = dirArg ? path.resolve(dirArg)
                   : path.join(__dirname, '..', 'src', 'ABAP_Training', 'lectures', 'slides');

const EDGE = ['C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  'C:/Program Files/Microsoft/Edge/Application/msedge.exe'].find(fs.existsSync);
if (!EDGE) throw new Error('找不到 Microsoft Edge（PPTX 渲染需要）');

const mds = fs.readdirSync(DIR).filter(f => f.endsWith('_slides.md'));
if (!mds.length) { console.log(`${DIR} 沒有 *_slides.md`); process.exit(0); }

let done = 0;
for (const md of mds) {
  const src = path.join(DIR, md);
  const stem = md.replace(/\.md$/, '');
  const targets = ['.html', '.pptx'].filter(ext => {
    const out = path.join(DIR, stem + ext);
    return ALL || !fs.existsSync(out) ||
      fs.statSync(out).mtimeMs < fs.statSync(src).mtimeMs;
  });
  if (!targets.length) continue;
  for (const ext of targets) {
    console.log(`轉換: ${md} => ${stem}${ext}`);
    execSync(`npx -y @marp-team/marp-cli --no-stdin "${src}" -o "${path.join(DIR, stem + ext)}"`,
      { stdio: 'inherit', env: { ...process.env, CHROME_PATH: EDGE } });
  }
  done++;
}
console.log(done ? `完成：${done} 份投影片` : '全部都是最新，無需轉換');
