# VE1DExperiment — Class Reference

MATLAB handle class for loading, processing, and plotting **1D vibrational echo T2 scan** data from CCD-detected pump-probe experiments.

---

## Files in this folder

| File | Role |
|------|------|
| `VE1DExperiment.m` | The class |
| `ve_1d_t2_scan_workup_sc.m` | Workup script — edit the config block at the top, run the rest unchanged |
| `redblue_3.m` | Blue-white-red colormap function; kept separate because it is passed as `@redblue_3` function handle |

---

## Data format

Raw data files are `.dat` matrices with this layout:

```
row 1 … end-2  →  signal data  [pixel × time]
row end-1       →  (unused row)
row end         →  time axis (fs)
```

The CCD wavelength axis is stored in a separate `.mat` file (e.g. `CCD_Wavelength_Axis_2024_03_06.mat`) and converted to wavenumbers via `1e7 / wavelength_nm`.

Probe normalization: element-wise division of each scan by the transmitted probe `.dat` file.

---

## Properties

### Public (readable from workspace)

| Property | Type | Description |
|----------|------|-------------|
| `rawData` | `[pixel × time]` | Data after loading and probe normalization, before filtering |
| `processedData` | `[pixel × time]` | Data after `filter()`; equals `rawData` if filter not applied |
| `timeAxis` | `[1 × time]` | Time axis in fs, from last row of `.dat` file |
| `waveAxis` | `[1 × pixel]` | Full CCD axis in cm⁻¹, computed as `1e7 / wl_nm` |
| `pixelRange` | `[pMin pMax]` | Active pixel window for plotting and filtering — **set this before calling other methods** |
| `label` | `string` | Human-readable label derived from `dataName` (underscores replaced with spaces) |
| `isLoaded` | `logical` | True after `load()` succeeds |
| `isFiltered` | `logical` | True after `filter()` is applied |

### Private (internal use only)

| Property | Description |
|----------|-------------|
| `dataPath` | Folder path to `.dat` files |
| `dataName` | Scan name(s) — char or cell array |
| `probeData` | Loaded probe matrix for normalization |
| `filterOpts` | Struct of filter parameters used; stored for title display |

---

## Public Methods

### Constructor

```matlab
exp = VE1DExperiment(dataPath, dataName, probeFile, wlAxisFile)
```

| Argument | Required | Description |
|----------|----------|-------------|
| `dataPath` | yes | Folder containing `.dat` scan files |
| `dataName` | yes | Scan name (string) or cell array of names for averaging |
| `probeFile` | no | Full path to probe `.dat` file |
| `wlAxisFile` | no | Full path to CCD wavelength `.mat` file |

The constructor loads `probeData` and `waveAxis` immediately. Scan data is not read until `load()` is called.

---

### `load(opts)`

Reads `.dat` files, accumulates and averages if multiple names given, normalizes by probe.

```matlab
exp.load()                          % defaults
exp.load(struct('flipTime', true))  % with options
```

| opts field | Default | Description |
|------------|---------|-------------|
| `flipTime` | `false` | Negate the time axis |
| `flipSign` | `false` | Negate the data |
| `normalizeByProbe` | `true` if probe present | Divide data by `probeData` |

Sets `rawData`, `processedData`, `timeAxis`, `isLoaded = true`.

---

### `filter(name, value, …)`

Applies Savitzky-Golay smoothing to `rawData`, stores result in `processedData`.

```matlab
exp.filter('order', 5, 'window', 35)         % filter along wavelength (default)
exp.filter('order', 3, 'window', 11, 'dim', 2)  % filter along time
exp.filter('apply', false)                   % revert processedData to rawData
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `order` | `5` | Polynomial order |
| `window` | `11` | Window length (auto-incremented to odd if even) |
| `pixelRange` | `obj.pixelRange` | Rows to filter |
| `dim` | `1` | `1` = along wavelength, `2` = along time |
| `apply` | `true` | `false` reverts to raw data |

---

### `plotContour(name, value, …)`

Filled contour plot (`contourf`) of `processedData` in the active `pixelRange`.
Contour levels are scaled as percentages of the data maximum.

```matlab
exp.plotContour()
exp.plotContour('clevels', [0.1 0.3 0.5 0.7 1.0], 'showLines', false)
exp.plotContour('colormap', 'jet', 'figureNum', 1)
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `pixelRange` | `obj.pixelRange` | Spectral window to display |
| `clevels` | `[0.01 0.05 0.1 … 1.0]` | Contour levels as fraction of max |
| `colormap` | `@redblue_3` | String name or function handle |
| `symmetric` | `true` | Symmetric colorbar centred on zero |
| `showLines` | `true` | Overlay contour lines in black |
| `lineWidth` | `0.05` | Contour line width |
| `figureNum` | `[]` | Target figure; empty = new figure |

---

### `plotProjection(name, value, …)`

Plots mean absolute signal across `pixelRange` vs time — useful for checking signal decay and t=0.

```matlab
exp.plotProjection()
exp.plotProjection('color', 'b', 'figureNum', 4)
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `pixelRange` | `obj.pixelRange` | Rows to average |
| `color` | `'r'` | Line color |
| `lineWidth` | `2` | |
| `fontSize` | `18` | |
| `figureNum` | `[]` | |

---

### `plotSlices(wavenumbers, name, value, …)`

Plots time traces at the pixel(s) closest to the requested wavenumber(s).
Legend shows the actual wavenumber and pixel index for each trace.

```matlab
exp.plotSlices([24000, 25000])
exp.plotSlices([24000, 25000], 'figureNum', 8, 'lineWidth', 1.5)
```

| Argument | Description |
|----------|-------------|
| `wavenumbers` | Vector of wavenumbers in cm⁻¹ |

| Parameter | Default | Description |
|-----------|---------|-------------|
| `figureNum` | `[]` | |
| `lineWidth` | `2` | |
| `fontSize` | `16` | |

---

### `save(name, value, …)`

Saves a struct `s` to a timestamped `.mat` file. Filename is `<label>_YYYYMMDD_HHMMSS.mat`.

```matlab
exp.save()
exp.save('dir', '/path/to/output/')
```

Saved struct fields: `label`, `time`, `waveAxis`, `pixelRange`, `rawData`, `processedData`, `isFiltered`, `filterOpts` (if filtered).

---

## Private Helpers (do not call directly)

| Method | Description |
|--------|-------------|
| `requireLoaded()` | Throws if `load()` has not been called |
| `activePixelRange()` | Returns `pixelRange` if set, otherwise full data range |
| `plotTitle()` | Builds figure title string, prepends filter info if active |
| `waveToPixel(wn)` | Finds pixel index closest to a wavenumber |
| `cellNames()` | Normalises `dataName` to a cell array |
| `filePath(name)` | Builds full `.dat` path from `dataPath` + `name` |
| `openFigure(num)` | Opens a numbered figure or creates new one |
| `mergeDefaults(opts, defaults)` | Fills missing struct fields from defaults |

---

## Typical workflow

```matlab
% One experiment
exp = VE1DExperiment(DATA_PATH, DATA_NAME, PROBE_FILE, WAXIS_FILE);
exp.pixelRange = [580, 950];
exp.load();
exp.filter('order', 5, 'window', 35);
exp.plotContour();
exp.plotProjection();
exp.plotSlices([24000, 25000]);
exp.save();

% Average multiple scans (pass cell array of names)
exp = VE1DExperiment(DATA_PATH, {'scan_051', 'scan_052'}, PROBE_FILE, WAXIS_FILE);
exp.pixelRange = [580, 950];
exp.load();

% Compare two datasets side by side
exp1 = VE1DExperiment(PATH_A, NAME_A, PROBE, WAXIS);
exp2 = VE1DExperiment(PATH_B, NAME_B, PROBE, WAXIS);
exp1.pixelRange = [580 950];  exp2.pixelRange = [580 950];
exp1.load(); exp1.filter('order',5,'window',35);
exp2.load(); exp2.filter('order',5,'window',35);
exp1.plotContour('figureNum', 1);
exp2.plotContour('figureNum', 2);
```

---

## Extension notes

`VE1DExperiment` is a `handle` class — assigning `exp2 = exp1` does **not** copy the data; both variables point to the same object. Use `exp2 = copy(exp1)` (requires implementing `copyElement`) if you need an independent copy.

For 2DVE or 3DVE variants, consider subclassing:
```matlab
classdef VE2DExperiment < VE1DExperiment
    % adds omega1 axis, 2D FFT methods, etc.
end
```
