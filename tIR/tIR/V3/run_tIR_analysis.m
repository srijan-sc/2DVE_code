% run_tIR_analysis.m
% Top-level script. Edit CONFIG_FILE to point at your config, then run.
clear; close all;

%% ---- Setup ----------------------------------------------------------
base = fileparts(mfilename('fullpath'));
addpath(base, fullfile(base,'utils'));

CONFIG_FILE = fullfile(base, 'example_config.m');  % <-- change this

%% ---- Load config and validate --------------------------------------
cfg = tIRConfig.fromFile(CONFIG_FILE);
tIRConfig.validate(cfg);

%% ---- Load dataset --------------------------------------------------
ds = tIRDataset(cfg);
ds.load();

% Fig 1: Full-range projection — always shows everything so you can find t=0.
% Read the peak position from this plot, set cfg.time_zero, and re-run.
ds.plotProjection('figureNum', 1, 'negate', cfg.projection_negate);
title('Projection — full range (set cfg.time_zero to peak, then re-run)', 'Interpreter', 'none');

%% ---- Normalize and set active pixel window -------------------------
ds.normalize();
ds.pixelRange = [];     % [] = full range; or e.g. [5 28] to crop noisy edge pixels

%% ---- Contour plots -------------------------------------------------
% Fig 2: Full-range raw contour — complete picture of the scan
ds.plotContour('figureNum', 2);
title('Raw data — full range');

% Fig 3: Zoomed + normalised contour — uses cfg.plot_xRange / cfg.plot_yRange
if ds.hasProbe
    ds.plotContour('useNorm', true, 'figureNum', 3, ...
        'xRange', cfg.plot_xRange, ...
        'yRange', cfg.plot_yRange);
    title('Probe-normalised');
end

%% ---- Spectral slices (time traces at fixed wavenumbers) ------------
if ~isempty(cfg.slice_wavenumbers)
    ds.plotSlices(cfg.slice_wavenumbers, 'figureNum', 4);
end

%% ---- Time slices (spectra at fixed delays) -------------------------
% slice_times are always in fs, regardless of cfg.time_unit
if ~isempty(cfg.slice_times)
    t_display = cfg.slice_times;
    if strcmpi(cfg.time_unit, 'ps')
        t_display = cfg.slice_times / 1000;   % convert to ps for plotTimeSlices
    end
    ds.plotTimeSlices(t_display, 'figureNum', 5);
end

%% ---- Results struct (for custom plotting outside the class) --------
results = ds.getResults();
% results.timeAxis_fs / timeAxis_ps  — full time axis
% results.waveAxis                   — wavenumber axis
% results.processedData              — [pixel x time]
% results.dataNorm                   — probe-normalised [pixel x time]
% results.projection.signal_norm     — mean |ΔA| vs time
% results.spectralSlices.wn_XXXX    — time trace at wavenumber XXXX cm-1
% results.timeSlices.t_XXX_fs       — spectrum at time delay XXX fs

%% ---- Optional: filter, re-plot, export, save -----------------------
% ds.filter('order', 5, 'window', 11);
% ds.plotContour('figureNum', 10);
% ds.export('csv');
% ds.save();

%% ---- Optional: power dependence across multiple scans --------------
% base_cfg = cfg;
% cfgs = tIRExperiment.buildConfigs(base_cfg, ...
%     {'25nJ_scan_01', '50nJ_scan_02', '100nJ_scan_03'}, ...
%     [25, 50, 100]);
% exp = tIRExperiment(cfgs);
% exp.loadAll();
% exp.compare(cfg.slice_wavenumbers, 'figureNum', 20);
% [pwr, amp] = exp.extractAmplitude(2850, 5000);
% figure(21); plot(pwr, amp, 'o-'); xlabel('Power (nJ)'); ylabel('\DeltaA');
