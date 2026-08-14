#!/usr/bin/env python
"""Multi-pass pdflatex wrapper for the Stata-to-LaTeX guidelines document.

Why this exists: gslab_scons's BuildLatex runs pdflatex exactly ONCE. The
guidelines document has a table of contents, a list of tables, PDF bookmarks,
and \ref cross-references -- all of which need >=2 passes (bookmarks need 3).
This wrapper loops pdflatex until the .aux stops changing (max 3 passes).

Usage:  python build_pdf.py <tex_source> <target_pdf>
Run from the pipeline root (SCons's cwd). Paths are forward-slashed because
pdflatex treats backslashes as TeX escapes on Windows.
"""
import os
import sys
import subprocess
import hashlib
import datetime


def now():
    return datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')


def main():
    tex = sys.argv[1].replace('\\', '/')
    pdf = sys.argv[2].replace('\\', '/')
    jobname = os.path.splitext(pdf)[0]   # e.g. .../3.build-paper/output/stata2latex_guidelines
    aux = jobname + '.aux'
    log_path = '3.build-paper/temp/Sconscript_guidelines.log'

    os.makedirs('3.build-paper/temp', exist_ok=True)
    os.makedirs(os.path.dirname(pdf), exist_ok=True)

    outputs = []
    prev_aux_hash = None
    passes = 0
    for _ in range(3):
        passes += 1
        r = subprocess.run(
            ['pdflatex', '-interaction=nonstopmode', '-jobname', jobname, tex],
            capture_output=True, text=True, encoding='utf-8', errors='replace')
        outputs.append('===== pass %d (exit %d) =====\n%s' %
                       (passes, r.returncode, r.stdout))
        cur_hash = (hashlib.md5(open(aux, 'rb').read()).hexdigest()
                    if os.path.isfile(aux) else None)
        # Converge when the .aux stops changing (refs/TOC/bookmarks resolved).
        if cur_hash is not None and cur_hash == prev_aux_hash:
            break
        prev_aux_hash = cur_hash

    body = ''.join(outputs)
    # gslab-style timestamp-prepended log so end_log merges it into sconstruct.log.
    with open(log_path, 'w', encoding='utf-8') as f:
        f.write('*** Builder log created: {%s}\n' % now())
        f.write('*** Builder log completed: {%s}\n' % now())
        f.write(body)

    if not os.path.isfile(pdf):
        sys.stderr.write('pdflatex failed to produce %s after %d pass(es); '
                         'see %s\n' % (pdf, passes, log_path))
        sys.exit(1)
    print('Built %s in %d pass(es)' % (pdf, passes))


if __name__ == '__main__':
    main()
