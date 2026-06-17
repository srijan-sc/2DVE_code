% project.m — w1 projection of 3DVE data cube → w3 × w2 contour map
cd(fileparts(mfilename('fullpath')));
addpath('..');   % plotContourData_sc_v4, redblue_3

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                         USER SETTINGS                                   ║
% ╠══════════════════════════════════════════════════════════════════════════╣
% ║  Paths                                                                  ║
% ║    data_file  — .mat file containing the 3D data cube                  ║
% ║                 Must have a variable named 'dataCube2' [px × FT × t]   ║
% ║    waxis_file — .mat file with the CCD wavelength axis                 ║
% ║                 Must have a variable named 'CCD_wavelength_axis'        ║
data_file  = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Analysis/HBQ_3D_analysis/data_cube_3DVE.mat';
waxis_file = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Lab_pc_backup/CCD_Wavelength_Axis_2024_03_06.mat';
% ║                                                                         ║
% ║  Output                                                                 ║
output_name = 'plot_projection';
% ║                                                                         ║
% ║  Spectral window  [w1_min  w1_max  pix_min  pix_max]                   ║
% ║    w1_min/max  — MCT frequency range to integrate over (cm⁻¹)          ║
% ║    pix_min/max — CCD pixel rows to use as ω₃ axis                      ║
ax2d = [2500 3000 550 1000];
% ║                                                                         ║
% ║  FFT size — must match the size used when building the data cube        ║
FTsize = 4096;
% ║                                                                         ║
% ║  Time axis — τ₂ values in fs (dim 3 of the data cube)                  ║
% ║    Must have the same number of elements as size(dataCube2, 3)          ║
time_axis = 110:15:1015;
% ║                                                                         ║
% ║  Plot style                                                             ║
custom_scalar = 1.5;
white_band    = 0.005;
fig_title     = '';
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Run ───────────────────────────────────────────────────────────────────
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
