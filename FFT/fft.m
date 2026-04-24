%% Load data from CSV
% All files are in the same folder as this script
here        = fileparts(mfilename('fullpath'));
time_axis   = readmatrix(fullfile(here, 'time_axis.csv'));    % [1 x 401]  fs
w3_axis     = readmatrix(fullfile(here, 'w3_axis.csv'));      % [1 x 371]  cm^-1 (decreasing)
data_matrix = readmatrix(fullfile(here, 'data_matrix.csv'));  % [371 x 401]  [Nw x Nt]

%% Select w3 sub-range (cm^-1)
% w3_axis is decreasing, so high cm^-1 maps to a lower index
w3_range = [24200, 24900];   % [low, high] cm^-1 — adjust as needed

[~, ax_2d(1)] = min(abs(w3_axis - w3_range(2)));  % high cm^-1 → first index
[~, ax_2d(2)] = min(abs(w3_axis - w3_range(1)));  % low  cm^-1 → last  index

data_1D = data_matrix(ax_2d(1):ax_2d(2), :)';     % [Nt x Nw_cut]
w3_cut  = w3_axis(ax_2d(1):ax_2d(2));              % [1  x Nw_cut] cm^-1

fprintf('w3 cut: %.1f – %.1f cm^-1  (%d pixels)\n', ...
    w3_cut(end), w3_cut(1), numel(w3_cut));

%% Time shift
offset = 180;   % fs  (= 0.18 ps)
[shiftedTime, shiftedData] = timeShift(time_axis, data_1D, offset, true);

%% Exponential fitting on shifted data
% Fits bi-exponential: a1*exp(-t/tau1) + a2*exp(-t/tau2) + c  per pixel
% Returns residuals = fit - data  (oscillatory component)
[fits, residuals_cell, residuals_matrix, fit_params] = exp_slice_fit_sc_2(shiftedTime, shiftedData);

%% ---- subsequent steps (windowing, FFT) go below this line ----
