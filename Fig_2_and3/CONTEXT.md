# Fig_2_and3 Plot Context

## State (current)
- `run_plot.m`: single-file contour plotter, parameterized via workspace vars
- `run_batch.m`: loops over 300/400/800 fs, calls run_plot each iteration
- MATLAB: `/Applications/MATLAB_R2025a.app/bin/matlab`
- Run cmd: `cd Fig_2_and3 && /Applications/MATLAB_R2025a.app/bin/matlab -nosplash -nodesktop -batch "run_plot"` or `"run_batch"`

## Input files
Pattern: `{N}fs_HBQ.csv` — available: 150, 250, 300, 350, 400, 450, 500, 800

## Output files
Pattern: `plot_{N}fs_HBQ.{svg,png,fig}`

## Parameterization (run_plot.m)
Script checks `exist()` before setting defaults — pre-set these vars to override:
```
csv_file    = '500fs_HBQ.csv'   % default
fig_label   = '500 fs'
output_name = 'plot_500fs_HBQ'
```
run_batch.m sets these before each `run_plot` call, then `clearvars -except files ii`.

## Colormap
- Base: `redblue_3(255)` (blue→white→red)
- Asymmetric resampling: cmin=-0.1, cmax=0.2 → n_blue=85 (neg range), n_red=170 (pos range)
- Result: white = exactly zero, blue = negative, red = positive
- `SymmetricColorbar = false`, `caxis = [-0.1, 0.2]`

## Contour lines (key toggle in run_plot.m ~line 14)
```matlab
% 500 fs (18 lines):
% line_levels = [-0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9];
% 300/400/800 fs (15 lines — active):
line_levels  = [-0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9];
```
To switch to 500 fs lines: uncomment first, comment second.

## Color levels (clevels)
`[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.85 0.9 0.95 1.0]` — same for all time points.

## Key settings
| param | value |
|---|---|
| custom_scalar | 1.5 |
| line_width | 2.2 |
| fig size | 13×10 cm |
| font_size | 16 |
| png_dpi | 300 |
| noise_threshold | 0 (off) |
| smooth_sigma | 0 (off) |
