clear all; clc
set(0, 'DefaultFigureWindowStyle', 'docked');

%% ===== USER CONFIG (edit only this section) =====

HERE       = fileparts(mfilename('fullpath'));   % folder containing this script
DATA_PATH  = fullfile(HERE, 'example_data');
DATA_NAME  = 've_1D_HBQ_100mM_dmso_d6_150u_1arm_z_10_05_off_4_test_051';

PROBE_FILE = fullfile(HERE, 'example_data', 'probe_zzzz_HBQ_dmso.dat');
WAXIS_FILE = fullfile(HERE, 'example_data', 'CCD_Wavelength_Axis_2024_03_06.mat');

PIXEL_RANGE     = [580, 950];       % display/processing window [pMin pMax]
DESIRED_WAVENUM = [24000, 25000];   % wavenumbers (cm⁻¹) for slice plot

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
