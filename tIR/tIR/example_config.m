% tIR experiment configuration
% Copy this file, rename it (e.g. my_experiment.m), fill in the paths below.
% Then open run_tIR_analysis.m and point it at this file.

cfg = tIRConfig.defaults();

%% ---- Identity (shown in all plot titles) ----------------------------
cfg.sample_name = 'CdS 400nm';   % e.g. 'CdS 400nm', 'HBQ in CDCl3'

%% ---- Paths (required) -----------------------------------------------
cfg.data_dir  = '/Users/srijan/Downloads/vscode/HBQ_3DVE/tIR/tIR/test_data/3100nm_50mm_grating_CdS_400_PCE_200u_spacer';
cfg.cal_file  = '/Users/srijan/Downloads/vscode/HBQ_3DVE/tIR/tIR/cailbration/center_3200nm.txt';

cfg.probe_file = '';  % probe reference file
                      %   ''     -> auto-detect probe_*.txt inside data_dir
                      %   'none' -> skip probe normalization entirely
                      %   '/full/path/probe_01.txt' -> use this specific file

%% ---- Dataset --------------------------------------------------------
cfg.root_name     = '50nJ_time_scan_01_Row0';
cfg.pump_power_nJ = 50;
cfg.polarisation  = 'ZZZZ';   % e.g. 'ZZZZ', 'ZZYY', 'ZYYZ' — shown in plot title

%% ---- Detector -------------------------------------------------------
cfg.pixel_region = 'top';  % 'top'    -> rows 1:n_pixels  (default)
                            % 'bottom' -> rows n_pixels+1 : 2*n_pixels
                            % 'all'    -> all rows in the file
cfg.n_pixels = 32;          % pixels per half-array

%% ---- Time axis ------------------------------------------------------
% Run once with time_zero = 0, then call ds.plotProjection() to find the
% peak of the coherent artifact. Set that scanner position here and re-run.
cfg.time_zero = 27195.5;    % absolute scanner position of t=0 (fs)

%% ---- Axes -----------------------------------------------------------
cfg.cm_axis = true;         % true  -> wavenumber axis (cm-1) using cal_file
                            % false -> pixel index axis

%% ---- Processing -----------------------------------------------------
cfg.bg_subtract = false;    % true -> subtract mean of all pre-t0 frames

%% ---- Time display --------------------------------------------------
cfg.time_unit = 'ps';  % 'fs' or 'ps' — all x-axes and slice_times use this unit

%% ---- Contour plot display range ------------------------------------
cfg.plot_xRange = [];   % time range to display, e.g. [0 50000] fs; [] = full range
cfg.plot_yRange = [];   % wavenumber range to display, e.g. [2900 3100]; [] = full range

%% ---- Projection options --------------------------------------------
cfg.projection_negate = false;  % true -> flip sign so negative signal plots as decay

%% ---- Quick-look slice positions -------------------------------------
cfg.slice_wavenumbers = [2950 3000 3050 3100];  % wavenumbers in cm-1
cfg.slice_times       = [0 500 2000 10000];     % time delays in fs (always fs, regardless of time_unit)
