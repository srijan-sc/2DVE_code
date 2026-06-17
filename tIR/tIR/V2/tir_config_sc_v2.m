% Configuration file for tIR data processing
% Save this as 'tir_config.m' or any name you prefer

% Define configuration structure
config = struct();

%% Dataset Information
% List of root names for datasets to process
config.root_names = {
    '38nJ_time_scan_15',
    '500nJ_time_scan_14',
    '960nJ_time_scan_16',
    '853nJ_time_scan_18'
    % Add more dataset names here
};

%% Directory and File Paths
% Base directory containing your data
config.base_directory = 'C:\Data\Srijan\2025\2025_07\2025_07_22\tIR\3100nm_50mm_grating_CdS_400_PCE_200u_spacer\';

% Calibration file path
config.cal_file = 'C:\Data\Srijan\calibration\tIR\07_15_2025\center_3100nm.txt';

% Probe file path (leave empty for auto-detection)
config.probe_file = '';  % Will auto-detect probe_*.txt files
% Or specify explicitly:
% config.probe_file = 'C:\Data\Srijan\2025\2025_07\2025_07_22\tIR\3100nm_50mm_grating_CdS_400_PCE_200u_spacer\probe_02_SampleReverence.txt';

%% Processing Parameters
% Use wavenumber axis (1) or pixel axis (0)
config.cm_axis = 1;

% Normalize to probe (1) or not (0)
config.normaliser = 1;

% Process probe data (1) or use raw (0)
config.probe_processing = 1;

% Time zero index (adjust to set time zero position)
config.time_zero_idx = 1;

%% Analysis Ranges
% Wavenumber range for spectral slicing [min, max] in cm^-1
config.slice_wavenumbers = [2750, 3100];

% Time range for temporal slicing [min, max] in fs
config.slice_time = [0, 12000];

%% Output Options
% Save processed results (true/false)
config.save_results = true;

%% Optional: Dataset-specific parameters
% If different datasets need different parameters, you can define them here
% and modify the main script to use them

% Example for dataset-specific time zero corrections:
% config.dataset_specific.time_zero_idx = containers.Map(...
%     {'38nJ_time_scan_15', '50nJ_time_scan_10'}, ...
%     {1, 3});

fprintf('Configuration loaded successfully!\n');
fprintf('Will process %d datasets\n', length(config.root_names));
fprintf('Base directory: %s\n', config.base_directory);