# Fig_2_and3 — Folder Overview

## Scripts

| Script | Purpose |
|--------|---------|
| `plot_2DVE.m` | 2D contour plots (w1 × w3) from matrix-format CSVs in `csv/` |
| `plot_w1_projection.m` | ω₁ projection line plots from pre-computed 3-column CSVs in `tau2_data/` |
| `plot_w1_projection_cube.m` | ω₁ projection line plots + standalone FTIR figure, loads directly from 3D data cube |
| `save_all_tau2_csvs.m` | Batch-generates all 61 τ₂ CSVs (3-column: w1_cm, intensity, sd) into `tau2_data/` |
| `gui/w1_projection_gui.m` | Interactive GUI for exploring τ₂ slices and saving CSVs |

## Data folders

| Folder | Contents |
|--------|---------|
| `csv/` | Matrix-format CSVs (w1 × w3 full data): 150–800 fs + FTIR.csv + w1/w3/data |
| `tau2_data/` | 3-column CSVs (w1_cm, intensity, sd) for all 61 τ₂ points (110–1010 fs, 15 fs steps) |

## Output folders

| Folder | Contents |
|--------|---------|
| `HBQ_fig/<tau>/` | 2D contour plots per τ₂, all formats (PDF, SVG, PNG, .fig) |
| `figures/` | ω₁ projection line plots |
| `ftir_fig/` | Standalone FTIR figure |
| `DMSO_fig/` | DMSO control plots |

## plot_2DVE.m — key settings

| Parameter | Value |
|-----------|-------|
| `caxis_lim` | `[-0.1  0.2]` (asymmetric) |
| `custom_scalar` | 1.5 |
| `line_width` | 2.2 |
| `clevels` | `[0.1 0.2 … 0.95 1.0]` (12 levels) |
| `line_levels` | 15 lines (see script) |
| `fig size` | 13 × 10 cm |
| `font_size` | 16 |
| `png_dpi` | 300 |

## Colormap
- Base: `redblue_3(255)` — blue → white → red
- Asymmetric resampling: `cmin = −0.1`, `cmax = 0.2` → ~85 blue / ~170 red bins
- White = exactly zero; `SymmetricColorbar = false`
