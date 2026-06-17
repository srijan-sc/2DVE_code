% VE3D.m — 3DVE contour plot using VE3DExperiment
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                         USER SETTINGS                                   ║
% ╠══════════════════════════════════════════════════════════════════════════╣
% ║  Paths                                                                  ║
% ║    data_file  — .mat file containing the 3D data cube                  ║
% ║                 Must have a variable named 'dataCube2' [px × FT × t]   ║
% ║    waxis_file — .mat file with the CCD wavelength axis                 ║
% ║                 Must have a variable named 'CCD_wavelength_axis'        ║
data_file   = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Analysis/HBQ_3D_analysis/data_cube_3DVE.mat';
waxis_file  = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Lab_pc_backup/CCD_Wavelength_Axis_2024_03_06.mat';
% ║                                                                         ║
% ║  Output                                                                 ║
output_name = 'plot_3DVE';
% ║                                                                         ║
% ║  Time slice                                                             ║
% ║    time_index — index along dim 3 of the data cube (1 to Nt)           ║
time_index  = 7;   % 200 fs
% ║                                                                         ║
% ║  Spectral window  [w1_min  w1_max  pix_min  pix_max]                   ║
% ║    w1_min/max  — MCT frequency range to display (cm⁻¹)                 ║
% ║    pix_min/max — CCD pixel rows to use as ω₃ axis                      ║
ax2d        = [2500 3000 550 1000];
% ║                                                                         ║
% ║  FFT & filter                                                           ║
% ║    FTsize       — must match the size used when building the data cube  ║
% ║    filterOrder  — Savitzky-Golay polynomial order                       ║
% ║    filterWindow — Savitzky-Golay window length (odd)                    ║
FTsize       = 4096;
filterOrder  = 5;
filterWindow = 15;
% ║                                                                         ║
% ║  Plot style                                                             ║
% ║    CustomScalar — colorbar stretch (1.0 = tight, 1.5 = some headroom)  ║
% ║    fig_title    — title string shown on the plot ('' = no title)        ║
custom_scalar = 1.5;
fig_title     = '';
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Run ───────────────────────────────────────────────────────────────────────
ve3d = VE3DExperiment(data_file, waxis_file);
ve3d.ax2d         = ax2d;
ve3d.FTsize       = FTsize;
ve3d.filterOrder  = filterOrder;
ve3d.filterWindow = filterWindow;

ve3d.load();
ve3d.prepare(time_index);
ve3d.plot('CustomScalar', custom_scalar, 'Title', fig_title);
ve3d.export(output_name);
