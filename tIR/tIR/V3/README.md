# tIR Analysis — V3

OOP-based pipeline for processing and plotting time-resolved IR pump-probe data.

---

## Quick Start

1. Copy `example_config.m` and rename it (e.g. `my_sample.m`)
2. Fill in the paths and parameters (see [Configuration](#configuration) below)
3. In `run_tIR_analysis.m`, point `CONFIG_FILE` at your config file
4. Run `run_tIR_analysis.m` in MATLAB

---

## Directory Structure

```
V3/
├── run_tIR_analysis.m      ← top-level script (edit CONFIG_FILE here)
├── example_config.m        ← template config — copy and rename for each experiment
├── tIRConfig.m             ← config defaults and validation
├── @tIRDataset/            ← main data class (load, normalize, plot, export)
├── @tIRExperiment/         ← multi-dataset power-dependence class
├── @SpectroscopyBase/      ← base class (plotting, filtering, saving)
├── utils/                  ← plotContourData.m, redblue.m, wl2wn.m
├── cailbration/            ← calibration .txt files (center_3200nm, 3300nm, 3500nm)
├── tests/run_tests.m       ← test suite (run this on a new PC to verify setup)
└── YYYY_MM/YYYY_MM_DD/     ← your data folders go here
```

---

## Configuration

All experiment parameters live in your config file. The key fields:

### Paths

| Field | Description |
|---|---|
| `cfg.data_dir` | Folder containing your scan `.txt` files |
| `cfg.cal_file` | Calibration file (`cailbration/center_XXXXX.txt`) |
| `cfg.probe_file` | Probe reference file. `''` = auto-detect `probe_*.txt` in `data_dir`; `'none'` = skip normalization |

### Dataset identity

| Field | Example | Description |
|---|---|---|
| `cfg.root_name` | `'FeRuFe_DMSO_trace02_4716_150g_011_Row0'` | Filename prefix **without** `_Data` / `_StDev` / `_Time` suffix |
| `cfg.sample_name` | `'FeRuFe dmso'` | Shown in all plot titles |
| `cfg.pump_power_nJ` | `50` | Pump power in nJ — shown in plot title |
| `cfg.polarisation` | `'ZZZZ'` | Polarisation condition — shown in plot title |

Plot titles are automatically formatted as: `sample_name   polarisation   power nJ`

### Detector

| Field | Options | Description |
|---|---|---|
| `cfg.pixel_region` | `'top'` / `'bottom'` / `'all'` | Which half of the detector array to use |
| `cfg.n_pixels` | `32` | Pixels per half-array |

### Time axis

`cfg.time_zero` is the **absolute scanner position** (in fs) at time zero.

**How to find it:**
1. Set `cfg.time_zero = 0` and run — Fig 1 shows the raw scanner positions
2. The coherent artifact peak is t=0. Read its position from the x-axis
3. The raw time values may be **negative** (scanner runs high→low) — set `cfg.time_zero` to the signed value (e.g. `-26998.7`, not `26998.7`)
4. Re-run — the peak should now sit at τ = 0

| Field | Description |
|---|---|
| `cfg.time_unit` | `'fs'` or `'ps'` — controls all plot x-axes |

### Display options

| Field | Example | Description |
|---|---|---|
| `cfg.plot_xRange` | `[-0.5 3]` | Time range to display on contour (in `time_unit`). `[]` = full range |
| `cfg.plot_yRange` | `[2750 3050]` | Wavenumber range to display on contour. `[]` = full range |
| `cfg.slice_wavenumbers` | `[2800 2850 2900]` | Wavenumbers for spectral slice plots (cm⁻¹) |
| `cfg.slice_times` | `[0 500 2000]` | Time delays for spectral snapshot plots (always in fs) |
| `cfg.bg_subtract` | `true` / `false` | Subtract mean of pre-t0 frames as background |
| `cfg.projection_negate` | `true` / `false` | Flip sign of projection so negative signal decays downward |

---

## Figures Produced

| Figure | Content |
|---|---|
| 1 | Projection — mean \|ΔA\| vs time (full range). Use this to find t=0. |
| 2 | Raw contour — full time range, no probe normalization |
| 3 | Probe-normalised contour — uses `plot_xRange` / `plot_yRange` |
| 4 | Spectral slices — time traces at each wavenumber in `slice_wavenumbers` |
| 5 | Time slices — spectra at each delay in `slice_times` |

---

## Common Workflows

### First run on a new dataset
```matlab
cfg.time_zero = 0;          % show raw scanner positions
cfg.plot_xRange = [];       % show everything
```
Run → read peak position from Fig 1 → set `cfg.time_zero` to that value (with correct sign) → re-run.

### Crop the contour to a time/wavenumber window
```matlab
cfg.plot_xRange = [-0.5 3];     % ps (if time_unit = 'ps')
cfg.plot_yRange = [2750 3050];  % cm-1
```

### Apply Savitzky-Golay smoothing after loading
```matlab
ds.filter('order', 5, 'window', 11);
ds.plotContour('figureNum', 10);
```

### Export data to CSV
```matlab
ds.export('csv');   % writes to data_dir
```

### Power dependence across multiple scans
```matlab
cfgs = tIRExperiment.buildConfigs(base_cfg, ...
    {'scan_25nJ', 'scan_50nJ', 'scan_100nJ'}, [25, 50, 100]);
exp = tIRExperiment(cfgs);
exp.loadAll();
exp.compare(cfg.slice_wavenumbers, 'figureNum', 20);
```

---

## File Naming Convention

The code expects three files per scan sharing the same root name:

```
<root_name>_Data.txt    ← signal matrix  [pixels × time_points]
<root_name>_StDev.txt   ← standard deviation
<root_name>_Time.txt    ← scanner positions (fs)
```

`cfg.root_name` is the prefix **without** the `_Data` / `_StDev` / `_Time` suffix.

---

## Testing on a New PC

Run the test suite to verify the environment and file integrity before processing real data:

```matlab
cd('.../V3/tests')
run_tests
```

A passing run prints `ALL 61 TESTS PASSED`. Failures print an explicit message explaining what is wrong and how to fix it.

---

## Calibration Files

Located in `cailbration/`. Use the file matching your grating centre wavelength:

| File | Use for |
|---|---|
| `center_3200nm.txt` | ~3200 nm centre |
| `center_3300nm.txt` | ~3300 nm centre |
| `center_3500nm.txt` | ~3500 nm centre |

Add new calibration files to this folder as needed and update `cfg.cal_file`.
