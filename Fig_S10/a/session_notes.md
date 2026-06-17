# Fig_S10/a — w1 Projection Pipeline: Session Notes

## Goal

Load the 3DVE data cube and sum over the w1 dimension (2500–3000 cm⁻¹) to produce a w3 × w2 map (CCD frequency × time). Same pixel window as the parent Fig_S10 (pixels 550–1000). No FFT — pure projection (sum along dim 2).

---

## Files Created / Modified

| File | Action |
|------|--------|
| `Fig_S10/a/ProjectionExperiment.m` | Created — OOP class for the projection pipeline |
| `Fig_S10/a/project.m` | Created — driver script with USER SETTINGS block |
| `Fig_S10/VE3D.m` | Modified — renamed `exp` → `ve3d` throughout |
| `Fig_S10/VE3DExperiment.m` | Modified — renamed `exp` → `ve3d` in header + docblocks |

---

## Data Cube

- File: `data_cube_3DVE.mat`, variable: `dataCube2`
- Shape: `[1600 × 4096 × 61]` = `[pixels(w3) × FTbins(w1) × timePoints(w2)]`
- No time variable inside the .mat — time axis is hardcoded from `main3Danalysis.m`

---

## Key Settings (project.m)

```matlab
ax2d        = [2500 3000 550 1000];   % [w1_min w1_max pix_min pix_max]
FTsize      = 4096;
time_axis   = 110:15:1015;            % 61 points, fs
custom_scalar = 1.5;
white_band    = 0.005;
```

---

## Projection Logic

```matlab
% MCT bin indices from frequency axis
freqRes  = (1/1.0554e-15) / 2.99792458e10 / 4096;
MCTRange = round([2500 3000] ./ freqRes);   % [w1Min w1Max]

% Extract and sum
data = dataCube(pixMin:pixMax, w1Min:w1Max, :);  % [Nw3 × Nw1 × Nt]
plotArea = squeeze(sum(data, 2));                 % [Nw3 × Nt]
```

---

## Plot Options (ProjectionExperiment.plot)

| Parameter | Default | Notes |
|-----------|---------|-------|
| `Clevels` | `[0.001 0.005 0.01 0.02 0.05 0.1 0.2 0.3 0.5 0.7 1.0]` | Start at 0.001 to close fill gap near zero |
| `LineLevels` | `[]` | No contour lines — colormap fades to white naturally |
| `CustomScalar` | `1.5` | Colorbar stretch |
| `WhiteBand` | `0.02` | Fraction of colormap forced white around zero |
| `ColorbarLabel` | `'\DeltaA/A'` | |
| `NumCbTicks` | `11` | Multiples of 10: `ceil(-clim/10)*10 : 10 : floor(clim/10)*10` |

---

## Bugs Fixed

### 1. Black lines at plot edges
Negative contour line levels (e.g., −27) were far outside the data minimum (−3.69), causing MATLAB `contour` artifacts at boundaries.

**Fix:** Filter line levels to strictly within `[min(data(:)), max(data(:))]` before drawing:
```matlab
lineLevels = lineLevels(lineLevels > min(data(:)) & lineLevels < max(data(:)));
```

### 2. White area at 800–1000 fs
`contourf` left a gap between ±(lowestLevel × scalar). The fill didn't start until the first contour level (0.02 × 1.5 × scalar ≈ 1.08), leaving near-zero values unfilled.

**Fix:** Lower `Clevels` minimum to `0.001` — closes the fill gap from near-zero, colormap fade handles the rest.

### 3. `exp` variable name clash
Both `VE3D.m` (parent) and `project.m` (new) used `exp` as the experiment object variable. MATLAB `exp()` is a builtin — also a naming risk.

**Fix:** Renamed `exp` → `ve3d` in VE3D.m + VE3DExperiment.m; `exp` → `proj` in project.m + ProjectionExperiment.m. Verified with grep — zero remaining occurrences.

---

## Colorbar Tick Logic

```matlab
clim_val = o.CustomScalar * scalar;
step     = 10;
cb.Ticks = (ceil(-clim_val/step)*step : step : floor(clim_val/step)*step);
cb.TickLabels = arrayfun(@(v) sprintf('%.0f', v), cb.Ticks, 'UniformOutput', false);
```
Produces clean multiples of 10: −50, −40, …, 0, …, 40, 50.

---

## Run Sequence

```matlab
cd(fileparts(mfilename('fullpath')));
addpath('..');   % plotContourData_sc_v4, redblue_3

proj = ProjectionExperiment(data_file, waxis_file);
proj.ax2d     = ax2d;
proj.FTsize   = FTsize;
proj.timeAxis = time_axis;

proj.load();
proj.project();
proj.plot('CustomScalar', custom_scalar, 'WhiteBand', white_band, 'Title', fig_title, ...
    'Clevels',    [0.001 0.005 0.01 0.02 0.05 0.1 0.2 0.3 0.5 0.7 1.0], ...
    'LineLevels', []);
proj.export(output_name);
```

Exports: `plot_projection.pdf`, `.svg`, `.png`, `.fig`
