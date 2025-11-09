#!/usr/bin/env python3
import sys
import os
from datetime import datetime

OUTDIR = sys.argv[1]
if not os.path.isdir(OUTDIR):
    print("Sonuç dizini bulunamadı:", OUTDIR)
    sys.exit(1)

report_md = os.path.join(OUTDIR, 'report.md')
with open(report_md, 'w', encoding='utf-8') as f:
    f.write(f"# Tarama Raporu - {os.path.basename(OUTDIR)}\n")
    f.write(f"Generated at: {datetime.utcnow().isoformat()}Z\n\n")

    subs = os.path.join(OUTDIR, 'subdomains.txt')
    if os.path.isfile(subs):
        with open(subs, 'r', encoding='utf-8') as s:
            lines = [l.strip() for l in s if l.strip()]
        f.write(f"## Subdomainler ({len(lines)})\n\n")
        for l in lines[:1000]:
            f.write(f"- {l}\n")
    else:
        f.write("## Subdomainler: bulunamadı\n")

    live = os.path.join(OUTDIR, 'live.txt')
    if os.path.isfile(live):
        f.write('\n## Canlı hostlar (httpx)\n\n')
        with open(live, 'r', encoding='utf-8') as lf:
            for l in lf:
                f.write(f"- {l}")

    nuclei = os.path.join(OUTDIR, 'nuclei-results.json')
    if os.path.isfile(nuclei):
        f.write('\n## Nuclei bulguları (özet)\n\n')
        try:
            import json
            with open(nuclei, 'r', encoding='utf-8') as nj:
                items = [json.loads(line) for line in nj if line.strip()]
            by_template = {}
            for it in items:
                tpl = it.get('info', {}).get('name', 'unknown')
                by_template.setdefault(tpl, 0)
                by_template[tpl] += 1
            for tpl, cnt in sorted(by_template.items(), key=lambda x: -x[1]):
                f.write(f"- {tpl}: {cnt} bulgu\n")
        except Exception:
            f.write("Nuclei sonuçları okunamadı veya yok.\n")

print("Rapor oluşturuldu:", report_md)
