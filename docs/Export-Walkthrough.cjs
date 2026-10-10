// Export this repository's walkthrough as a printable HTML document.
// Node.js is only needed to regenerate the document, not to run Destek.
const fs = require('node:fs');
const path = require('node:path');
const escape = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const inline = s => escape(s)
  .replace(/`([^`]+)`/g, '<code>$1</code>')
  .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
  .replace(/\*([^*]+)\*/g, '<em>$1</em>')
  .replace(/!\[([^\]]*)\]\(([^)]+)\)/g, (_, alt, src) => {
    const file = path.resolve(__dirname, decodeURIComponent(src));
    const mime = path.extname(file).toLowerCase() === '.svg' ? 'image/svg+xml' : 'image/png';
    return `<img alt="${alt}" src="data:${mime};base64,${fs.readFileSync(file).toString('base64')}">`;
  })
  .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
const lines = fs.readFileSync(path.join(__dirname, 'OptionRomWalkthrough.md'), 'utf8').split(/\r?\n/);
function render(lines) {
const blocks = [];
for (let i = 0; i < lines.length;) {
  const line = lines[i];
  if (!line.trim()) { i++; continue; }
  if (/^\d+\. /.test(line)) {
    const items = [];
    const first = Number(line.match(/^\d+/)[0]);
    while (i < lines.length && /^\d+\. /.test(lines[i])) {
      const item = [lines[i++].replace(/^\d+\. /, '')];
      while (i < lines.length && (!lines[i].trim() || lines[i].startsWith('   '))) {
        item.push(lines[i].startsWith('   ') ? lines[i].slice(3) : lines[i]);
        i++;
      }
      items.push(`<li>${render(item)}</li>`);
    }
    blocks.push(`<ol start="${first}">${items.join('\n')}</ol>`);
  } else if (line.startsWith('```')) {
    const code = [];
    for (i++; i < lines.length && !lines[i].startsWith('```'); i++) code.push(lines[i]);
    i++;
    blocks.push(`<pre><code>${escape(code.join('\n'))}</code></pre>`);
  } else if (/^#+ /.test(line)) {
    const [, marks, text] = line.match(/^(#+) (.*)$/);
    const id = text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
    blocks.push(`<h${marks.length} id="${id}">${inline(text)}</h${marks.length}>`);
    i++;
  } else if (line.startsWith('|')) {
    const rows = [];
    for (; i < lines.length && lines[i].startsWith('|'); i++) {
      if (/^\|[ :|\-]+$/.test(lines[i])) continue;
      const tag = rows.length ? 'td' : 'th';
      const cells = lines[i].slice(1, -1).split('|').map(c => `<${tag}>${inline(c.trim())}</${tag}>`).join('');
      rows.push(`<tr>${cells}</tr>`);
    }
    blocks.push(`<table><thead>${rows.shift()}</thead><tbody>${rows.join('\n')}</tbody></table>`);
  } else {
    const paragraph = [];
    for (; i < lines.length && lines[i].trim(); i++) paragraph.push(lines[i]);
    blocks.push(`<p>${inline(paragraph.join(' '))}</p>`);
  }
}
return blocks.join('\n');
}
const html = `<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Destek Option ROM execution walkthrough</title>
<style>
body{font:16px/1.55 system-ui,sans-serif;color:#202b32;margin:0;background:#edf1f3}
main{max-width:1000px;margin:32px auto;padding:48px;background:white}
h1{font-size:34px;line-height:1.2;color:#12465b}h2{margin-top:2.3em;border-bottom:2px solid #d4e1e6;padding-bottom:.3em}h3{margin-top:1.8em}
a{color:#075b83}table{border-collapse:collapse;width:100%;font-size:14px;margin:22px 0}
th,td{border:1px solid #cad5da;padding:10px;vertical-align:top;text-align:left}th{background:#eaf1f4}
code{font-family:Consolas,monospace;font-size:.88em;overflow-wrap:anywhere}pre{padding:16px;background:#f0f3f5;white-space:pre-wrap;border-left:3px solid #467f95}
img{display:block;max-width:100%;height:auto;margin:20px auto 8px;border:1px solid #afbec5}p:has(>em:only-child){font-size:14px;color:#43555f}
ol{padding-left:1.8em}li{padding-left:.3em;margin-bottom:1.6em}li>p:first-child{break-after:avoid}p:has(>em:only-child){break-after:avoid}
@media print{body{background:white;font-size:10pt}main{margin:0;padding:0;max-width:none}h1{font-size:23pt}h2,h3{break-after:avoid}img,pre,tr{break-inside:avoid}table{font-size:9pt}a{color:inherit}img{max-height:145mm}p:has(>img){break-after:avoid}}
@page{size:A4;margin:16mm}
</style><main>${render(lines)}</main></html>`;
fs.writeFileSync(path.join(__dirname, 'OptionRomWalkthrough.html'), html);
console.log('Wrote docs/OptionRomWalkthrough.html with embedded screenshots.');

