# CLAUDE.md — stata-to-latex-pipeline

A **reproducible Stata → LaTeX table pipeline** built on the [GSLab SCons
template](../template). It is the pipeline version of the
`../dou-bao-stata-to-latex` tutorial: a single Stata do-file + a LaTeX tutorial
document, re-organized into a tracked, incremental, one-command build.

## Build

```bash
cd stata-to-latex-pipeline
python run.py            # = scons ; builds everything: data -> tables -> PDF
python run.py -c         # clean (remove all outputs), then rebuild
python run.py -n         # dry-run (print what would build)
python run.py 1.prepare-data/output/nlswork_processed.dta   # build one target
```

`run.py` is a thin wrapper that shells out to the `scons` command. Output PDF
ends up in `3.build-paper/output/` and `release/`.

### Prerequisites

- **`gslab_python` (the `andyzhou66` fork)** installed into the Python that runs
  `scons` — on this machine that is **`C:\Program Files\Python311\python.exe`**
  (NOT the project `.venv`, which is a 3.15 beta without SCons). Install with:
  `& 'C:\Program Files\Python311\python.exe' -m pip install --user git+https://github.com/andyzhou66/gslab_python.git@master`
- **`gslab_scons` must be Py3-patched** for this Python/Windows. The fork is NOT
  Py3.11/Chinese-Windows ready as shipped. See the project memory
  `gslab-scons-py3-patches.md` (and the `gslab-py3-fix` skill) for the required
  site-packages patches. Without them, the build crashes at `import gslab_scons`,
  at `end_log` (GBK decode), and at `BuildLatex` (backslash paths).
- **Stata** (`StataSE-64`) and **pdflatex** in PATH.
- **estout** (`ssc install estout`) — install once via
  `config/config_stata.do`, or it is already present if the tutorial built.

## Structure (flat, 3 numbered steps)

```
stata-to-latex-pipeline/
  SConstruct              # root build: BuildStata + BuildLatex + custom BuildPdf
  run.py                  # thin scons wrapper
  config_global.yaml      # versioned config (gslab_version, prereqs, debrief)
  config_user_template.yaml / config_user.yaml   # local, gitignored
  config/                 # configuration.py, requirements.txt, config_stata.do
  1.prepare-data/         # webuse nlswork + transforms -> nlswork_processed.dta
    code/prepare_data.do
  2.generate-tables/      # estout: every table fragment + macro.tex (one Stata session)
    code/generate_tables.do
  3.build-paper/          # multi-pass pdflatex -> stata2latex_guidelines.pdf
    code/stata2latex_guidelines.tex
    code/build_pdf.py     # multi-pass wrapper (BuildLatex runs pdflatex only once)
  tests/                  # pytest smoke tests (run independently of SCons)
  docs/                   # reference snippets not in the build (Section 1 concepts)
```

`output/`, `input-data/`, `temp/`, `release/` are gitignored build artifacts.

## Key architecture decisions

**3 steps, not one-per-table (session-state coupling).** `generate_tables.do` is
one Stata session, not one `.do` per table, because `eststo`/`estadd`/`$controls`
and label mutations flow within a single invocation — they cannot cross
`stata -b` boundaries. This mirrors the template's own granularity (one analysis
`.do` per step) and keeps the 3-step shape legible.

**Custom multi-pass `BuildPdf`.** `gslab_scons.BuildLatex` runs pdflatex exactly
**once**. The guidelines document has a TOC, list of tables, PDF bookmarks, and
`\ref`, all of which need ≥2 passes (bookmarks need 3). `SConstruct` registers a
third builder `BuildPdf` whose action runs `3.build-paper/code/build_pdf.py`,
which loops pdflatex until the `.aux` is stable (max 3 passes).

**Fragment wiring (template gotcha #4).** `env.Install()` does not reliably chain
across SConscripts, so each consuming step lists the *upstream `output/` file*
as a direct source AND `env.Depends()` on its own `input-data/` copy. The
`guidelines.tex` reads fragments via root-relative paths
`\loadfrag{3.build-paper/input-data/table1.tex}` (pdflatex runs from the pipeline
root). `\loadfrag` and self-contained `tblr`/`prehead` files are kept as-is from
the tutorial; only the paths were rewritten.

## Known non-fatal warnings

The tabularray tables (`reg7_tblr.tex`, `table7_tblr.tex`) emit
`! LaTeX3 error: Access to an entry beyond an array's bounds` from their
`\SetCell[c=3]{...}` span rows. pdflatex (`nonstopmode`) recovers and the PDF is
complete (41 pages). These messages are **pre-existing in the source tutorial**
(same fragments, same content) — not a pipeline regression.

## Conventions retained from the tutorial

- Significance stars `star(* 0.10 ** 0.05 *** 0.01)`.
- `\loadfrag` wrapper (not `estwide`/`estauto`); bare `\input` for
  self-contained `tblr`/`prehead-postfoot` files and `\cmidrule` tables.
- `&` in `eqlabels()` escaped as `\&`.
