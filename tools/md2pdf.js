// 訓練教材 md → PDF 講義產生器
//
// 用法（在 repo 根目錄）：
//   node tools/md2pdf.js          只重產「md 比 PDF 新」的檔案（增量）
//   node tools/md2pdf.js --all    全部重產
//
// 相依（皆為本機既有，不需安裝）：
//   - VS Code extension yzane.markdown-pdf（借用其 CSS 樣式）
//   - VS Code extension tom-latham.markdown-pdf-plus（借用其 puppeteer-core）
//   - Microsoft Edge（headless 列印引擎）
// 注意：重產會覆蓋同名 PDF（包含手動用 Word/extension 匯出的版本）。
const fs = require('fs');
const path = require('path');
const os = require('os');

const DIR = path.join(__dirname, '..', 'src', 'ABAP_Training');

function findLatest(base, prefix) {
  const hits = fs.readdirSync(base).filter(f => f.startsWith(prefix)).sort();
  if (!hits.length) throw new Error(`找不到 ${prefix}*，請確認 VS Code extension 已安裝`);
  return path.join(base, hits[hits.length - 1]);
}

const EXT_BASE = path.join(os.homedir(), '.vscode', 'extensions');
const STYLES = path.join(findLatest(EXT_BASE, 'yzane.markdown-pdf-'), 'styles');
const PUPPETEER = path.join(findLatest(EXT_BASE, 'tom-latham.markdown-pdf-plus-'),
  'node_modules', 'puppeteer-core');
const EDGE = ['C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  'C:/Program Files/Microsoft/Edge/Application/msedge.exe'].find(fs.existsSync);
if (!EDGE) throw new Error('找不到 Microsoft Edge');

const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function inline(s) {
  s = esc(s);
  s = s.replace(/`([^`]+)`/g, (m, c) => '<code>' + c + '</code>');
  s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  s = s.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
  return s;
}

function renderBlocks(lines) {
  const out = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];

    if (/^```/.test(line)) {                       // fenced code block
      const buf = [];
      i++;
      while (i < lines.length && !/^```/.test(lines[i])) { buf.push(lines[i]); i++; }
      i++;
      out.push('<pre class="hljs"><code>' + esc(buf.join('\n')) + '</code></pre>');
      continue;
    }

    const h = line.match(/^(#{1,6})\s+(.*)$/);      // heading
    if (h) {
      const lvl = h[1].length;
      out.push(`<h${lvl}>` + inline(h[2]) + `</h${lvl}>`);
      i++;
      continue;
    }

    if (/^>\s?/.test(line)) {                       // blockquote（可含清單）
      const buf = [];
      while (i < lines.length && /^>\s?/.test(lines[i])) { buf.push(lines[i].replace(/^>\s?/, '')); i++; }
      out.push('<blockquote>' + renderBlocks(buf) + '</blockquote>');
      continue;
    }

    if (/^\|/.test(line)) {                         // table
      const rows = [];
      while (i < lines.length && /^\|/.test(lines[i])) { rows.push(lines[i]); i++; }
      const cells = r => r.replace(/^\|/, '').replace(/\|\s*$/, '').split('|').map(c => c.trim());
      let html = '<table><thead><tr>';
      html += cells(rows[0]).map(c => '<th>' + inline(c) + '</th>').join('');
      html += '</tr></thead><tbody>';
      for (let r = 2; r < rows.length; r++) {       // rows[1] 是分隔線
        html += '<tr>' + cells(rows[r]).map(c => '<td>' + inline(c) + '</td>').join('') + '</tr>';
      }
      html += '</tbody></table>';
      out.push(html);
      continue;
    }

    if (/^\s*([-*]|\d+\.)\s+/.test(line)) {         // list（支援一層縮排巢狀）
      const items = [];
      while (i < lines.length && /^\s*([-*]|\d+\.)\s+/.test(lines[i])) { items.push(lines[i]); i++; }
      const ordered = /^\s*\d+\./.test(items[0]);
      const tag = ordered ? 'ol' : 'ul';
      let html = `<${tag}>`;
      let subBuf = null;
      const flushSub = () => { if (subBuf) { html += subBuf.html + `</${subBuf.tag}></li>`; subBuf = null; } };
      for (const it of items) {
        const m = it.match(/^(\s*)([-*]|\d+\.)\s+(.*)$/);
        const text = m[3].replace(/^\[ \]\s*/, '&#9744; ').replace(/^\[x\]\s*/i, '&#9745; ');
        if (m[1].length >= 2) {                     // 巢狀項目
          if (!subBuf) {
            const subTag = /\d+\./.test(m[2]) ? 'ol' : 'ul';
            html = html.replace(/<\/li>$/, '');
            subBuf = { tag: subTag, html: `<${subTag}>` };
          }
          subBuf.html += '<li>' + inline(text) + '</li>';
        } else {
          flushSub();
          html += '<li>' + inline(text) + '</li>';
        }
      }
      flushSub();
      html += `</${tag}>`;
      out.push(html);
      continue;
    }

    if (/^\s*---+\s*$/.test(line)) { out.push('<hr>'); i++; continue; }
    if (/^\s*$/.test(line)) { i++; continue; }

    const buf = [line];                             // paragraph
    i++;
    while (i < lines.length && !/^\s*$/.test(lines[i]) &&
           !/^(#{1,6}\s|```|\||>\s?|\s*([-*]|\d+\.)\s|\s*---+\s*$)/.test(lines[i])) {
      buf.push(lines[i]); i++;
    }
    out.push('<p>' + inline(buf.join(' ')) + '</p>');
  }
  return out.join('\n');
}

function buildHtml(title, body) {
  const css = ['markdown.css', 'markdown-pdf.css', 'tomorrow.css']
    .map(f => fs.readFileSync(path.join(STYLES, f), 'utf8')).join('\n');
  return `<!DOCTYPE html><html><head><title>${esc(title)}</title>
<meta http-equiv="Content-type" content="text/html;charset=UTF-8">
<style>${css}
body { font-family: "Segoe UI", "Microsoft JhengHei", "PingFang TC", sans-serif; }
code, pre { font-family: Consolas, "Courier New", "Microsoft JhengHei", monospace; }
</style></head><body>${body}</body></html>`;
}

(async () => {
  const forceAll = process.argv.includes('--all');
  const targets = fs.readdirSync(DIR).filter(f => f.endsWith('.md')).filter(f => {
    if (forceAll) return true;
    const pdf = path.join(DIR, f.replace(/\.md$/, '.pdf'));
    return !fs.existsSync(pdf) || fs.statSync(path.join(DIR, f)).mtimeMs > fs.statSync(pdf).mtimeMs;
  });
  if (!targets.length) { console.log('所有 PDF 都是最新的，無需重產'); return; }
  console.log('待轉換:', targets.join(', '));

  const puppeteer = require(PUPPETEER);
  const browser = await puppeteer.launch({ executablePath: EDGE, headless: true });
  for (const f of targets) {
    const md = fs.readFileSync(path.join(DIR, f), 'utf8');
    const html = buildHtml(f, renderBlocks(md.split(/\r?\n/)));
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: 'load' });
    await page.pdf({
      path: path.join(DIR, f.replace(/\.md$/, '.pdf')),
      format: 'A4', printBackground: true,
      margin: { top: '1.5cm', bottom: '1.5cm', left: '1cm', right: '1cm' }
    });
    await page.close();
    console.log('完成:', f);
  }
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
