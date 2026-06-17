# Contour Plot Instructions

## Data format
- `w1.csv` — 1×N row vector (x-axis, pump frequency)
- `w3.csv` — 1×M row vector (y-axis, probe frequency)
- Data CSV — M×N matrix (rows = w3, columns = w1), no headers

## To plot a new dataset
1. Place the data CSV, `w1.csv`, and `w3.csv` in the same folder as `run_plot.m`
2. Edit the **USER SETTINGS** block at the top of `run_plot.m`:
   - `raw` — change filename to your CSV (use `-1*readmatrix(...)` to flip sign if needed)
   - `fig_label` — title shown on plot
   - `output_name` — base name for exported files (no extension)
3. Run `run_plot.m` — exports `.png`, `.fig`, `.svg` to the same folder

## To batch-plot multiple CSVs
Use `mcp__matlab__evaluate_matlab_code` with a loop (see the loop pattern used in Fig_S6). Load `w1.csv` and `w3.csv` once outside the loop; iterate over filenames.

## Key settings
| Setting | Default | Effect |
|---|---|---|
| `clevels` | `[0.2…1.0]` | Filled contour levels (positive half; negatives mirrored) |
| `line_levels` | `[-0.9…0.9]` | Black contour line positions |
| `custom_scalar` | `1.5` | Stretches color axis beyond data max |
| `noise_threshold` | `0.1` | Zeros data below this fraction of peak |
| `smooth_sigma` | `0` | Gaussian smooth radius in pixels (0 = off) |
| `fig_width_cm` | `16` | Figure width |
| `fig_height_cm` | `13` | Figure height |

## Dependencies (must be in same folder)
- `plotContourData_sc_v4.m`
- `redblue_3.m`

## Notes
- Data is passed as-is to `plotContourData_sc_v4(w1, w3, data, ...)` — **no transpose**
- Figure background is forced white via `'Color', [1 1 1]` and `groot` defaults
- Colorbar color is explicitly set to black to survive theme changes

## Updates applied in Fig_3 (apply here too)

### 1. Convert ΔT/T → ΔA (flips colorbar sign)
```matlab
integrated_data = -cell2mat(raw(2:end, 2:end)) / log(10);
```
Change colorbar label to `'\DeltaA/A'`.

### 2. Force white background after plotContourData_sc_v4
Add after `ax = gca`:
```matlab
ax.Color  = [1 1 1];
ax.XColor = 'black';
ax.YColor = 'black';
fig.Color = [1 1 1];
```

### 3. Force colorbar text/ticks to black
```matlab
set(cb, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
cb.Label.Color = 'black';
```

### 4. Square axes box
Add after `ax = gca`:
```matlab
axis(ax, 'square');
```

### 5. White band around zero in colormap (suppresses noise-floor color)
Add `white_band` to USER SETTINGS (e.g. `0.01`), use odd colormap count, then:
```matlab
cmap = redblue_3(255);
n_cmap    = size(cmap, 1);
half_band = round(n_cmap * white_band);
center    = ceil(n_cmap / 2);
cmap(center-half_band : center+half_band, :) = 1;
```
Then after `caxis(...)`:
```matlab
colormap(ax, cmap);
```
