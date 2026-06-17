clear all; clc
set(0, 'DefaultFigureWindowStyle', 'docked');

%% ===== USER CONFIG (edit only this section) =====

HERE       = fileparts(mfilename('fullpath'));
DATA_PATH  = fullfile(HERE, 'CCD_time_scans');
DATA_NAME  = 've_1D_dmso_d6_150u_1arm_z_10_05_off_4_test_041';   % change per scan

PROBE_FILE = fullfile(HERE, 'CCD_time_scans', 'probe_zzzz_dmso.dat');
WAXIS_FILE = fullfile(HERE, 'CCD_Wavelength_Axis_2024_03_06.mat');

PIXEL_RANGE     = [580, 950];
DESIRED_WAVENUM = [24000, 25000];

SAVE_RESULT = false;

%% ===================================================

exp = VE1DExperiment(DATA_PATH, DATA_NAME, PROBE_FILE, WAXIS_FILE);
exp.pixelRange = PIXEL_RANGE;

exp.load();
exp.filter('order', 5, 'window', 35);

exp.plotContour();
exp.plotProjection();
exp.plotSlices(DESIRED_WAVENUM);

if SAVE_RESULT
    exp.save();
end
