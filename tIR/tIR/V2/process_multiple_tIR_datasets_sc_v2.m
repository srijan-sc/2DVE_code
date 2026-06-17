function process_multiple_tIR_datasets(config_file_or_params, varargin)
% PROCESS_MULTIPLE_TIR_DATASETS - Process multiple time-resolved IR datasets
%
% Usage:
%   process_multiple_tIR_datasets('config.m')  % Load from config file
%   process_multiple_tIR_datasets(root_names, 'param', value, ...)  % Direct parameters
%
% Input:
%   config_file_or_params - either:
%     1) String path to config file (e.g., 'tir_config.m')
%     2) Cell array of root names (for backward compatibility)
%
% Config file should define a structure 'config' with fields:
%   config.root_names - cell array of dataset names
%   config.base_directory - base data directory
%   config.cal_file - calibration file path
%   config.probe_file - probe reference file path (optional)
%   config.cm_axis - use wavenumber axis (1) or pixel (0)
%   config.normaliser - normalize to probe
%   config.probe_processing - process probe data
%   config.time_zero_idx - time zero index
%   config.slice_wavenumbers - wavenumber range for slicing
%   config.slice_time - time range for slicing in fs
%   config.save_results - save processed data

% Check if first argument is a config file or root names
if ischar(config_file_or_params) || isstring(config_file_or_params)
    % Load from config file
    config_file = char(config_file_or_params);
    fprintf('Loading configuration from: %s\n', config_file);
    
    % Run the config file to load parameters
    run(config_file);
    
    % Check if config structure exists
    if ~exist('config', 'var')
        error('Config file must define a structure named "config"');
    end
    
    % Extract parameters
    params = config;
    
    % Validate required fields
    if ~isfield(params, 'root_names')
        error('Config must specify root_names field');
    end
    
else
    % Backward compatibility - parse as before
    root_names = config_file_or_params;
    
    % Parse input arguments
    p = inputParser;
    addRequired(p, 'root_names', @iscell);
    addParameter(p, 'base_directory', '', @ischar);
    addParameter(p, 'cal_file', 'C:\Data\Srijan\calibration\tIR\07_15_2025\center_3100nm.txt', @ischar);
    addParameter(p, 'probe_file', '', @ischar);
    addParameter(p, 'cm_axis', 1, @isnumeric);
    addParameter(p, 'normaliser', 1, @isnumeric);
    addParameter(p, 'probe_processing', 1, @isnumeric);
    addParameter(p, 'time_zero_idx', 1, @isnumeric);
    addParameter(p, 'slice_wavenumbers', [2750,3100], @isnumeric);
    addParameter(p, 'slice_time', [0,12000], @isnumeric);
    addParameter(p, 'save_results', true, @islogical);
    
    parse(p, root_names, varargin{:});
    params = p.Results;
end

% Set default values for missing fields
default_params = struct(...
    'base_directory', '', ...
    'cal_file', 'C:\Data\Srijan\calibration\tIR\07_15_2025\center_3100nm.txt', ...
    'probe_file', '', ...
    'cm_axis', 1, ...
    'normaliser', 1, ...
    'probe_processing', 1, ...
    'time_zero_idx', 1, ...
    'slice_wavenumbers', [2750,3100], ...
    'slice_time', [0,12000], ...
    'save_results', true);

% Fill in missing parameters with defaults
field_names = fieldnames(default_params);
for i = 1:length(field_names)
    field = field_names{i};
    if ~isfield(params, field)
        params.(field) = default_params.(field);
    end
end

% Get base directory if not provided
if isempty(params.base_directory)
    params.base_directory = uigetdir('C:\Data\Srijan\', 'Select base data directory');
    if params.base_directory == 0
        error('No directory selected');
    end
end

% Load calibration axis
fprintf('Loading calibration file: %s\n', params.cal_file);
Cal_axis = load(params.cal_file);

% Initialize results structure
results = struct();

% Process each dataset
for i = 1:length(params.root_names)
    current_root = params.root_names{i};
   fprintf('\n=== Processing dataset %d/%d: %s ===\n', i, length(params.root_names), current_root);
    
    try
        % Process single dataset
        dataset_result = process_single_dataset(current_root, params, Cal_axis);
        results.(matlab.lang.makeValidName(current_root)) = dataset_result;
        
        fprintf('Successfully processed: %s\n', current_root);
        
    catch ME
        fprintf('Error processing %s: %s\n', current_root, ME.message);
        results.(matlab.lang.makeValidName(current_root)) = [];
    end
end

% Save results if requested
if params.save_results
    save_path = fullfile(params.base_directory, 'processed_results.mat');
    save(save_path, 'results', 'params');
    fprintf('\nResults saved to: %s\n', save_path);
end

fprintf('\n=== Processing Complete ===\n');
end

function dataset_result = process_single_dataset(root_name, params, Cal_axis)
% Process a single dataset

% Set up paths
direct = params.base_directory;
userpath(direct);

% Auto-detect probe file if not specified
if isempty(params.probe_file)
    probe_files = dir(fullfile(direct, 'probe_*.txt'));
    if ~isempty(probe_files)
        probe_file = fullfile(direct, probe_files(1).name);
    else
        error('No probe file found for %s', root_name);
    end
else
    probe_file = params.probe_file;
end

% Load probe spectra
fprintf('Loading probe file: %s\n', probe_file);
transmitted_probe = load(probe_file);

% Find data files
matfiles = dir(fullfile(direct, [root_name '*.txt']));
nfiles = size(matfiles, 1);

if nfiles == 0
    error('No files found with root name: %s', root_name);
end

fprintf('Found %d files for %s\n', nfiles, root_name);

% Load all files into data structure
datastructure = cell(nfiles, 2);
labels = cell(nfiles, 1);

for aa = 1:nfiles
    datastructure{aa,1} = matfiles(aa).name;
    datastructure{aa,2} = load(fullfile(direct, matfiles(aa).name));
    labels{aa} = num2str(aa);
end

% Data indices (assuming standard format)
data_idx = 1; time_idx = 3; stdev_idx = 2;

% Process data
time_files = 3*[1:nfiles/3];
times_all = cat(1, datastructure{time_idx,2});
time1 = times_all;
stdev_all = cat(3, datastructure{stdev_idx,2});
data_all = cat(3, datastructure{data_idx,2});
data = data_all(1:32,:);

% Time zero correction
zero_val = max(sum(abs(data)));
time_offset = time1(params.time_zero_idx);
time_ax = -1*((time1) - time_offset);

% Set up wavelength/wavenumber axis
if params.cm_axis
    pixels = (10^7)./Cal_axis;
else
    pixels = 1:1:32;
end

% Process probe
if params.probe_processing == 1
    Ref_IR = transmitted_probe(1:32,2);
else
    Ref_IR = transmitted_probe(1:32,1);
end

% % Create plots if requested
% if params.plot_results
%     create_plots(root_name, time1, time_ax, data, pixels);
% end

% Store results - WHAT IS BEING SAVED:
% For each dataset, the following processed data is saved:
dataset_result = struct();
dataset_result.root_name = root_name;                    % Original dataset name
dataset_result.data = data;                              % Processed spectral data (32 x time_points)
dataset_result.data_norm = data ./ Ref_IR;
dataset_result.time_ax = time_ax;                        % Time-zero corrected time axis (fs)
dataset_result.pixels = pixels;                          % Wavelength/wavenumber axis (cm^-1 or pixels)
dataset_result.Ref_IR = Ref_IR;                          % Processed probe reference spectrum
dataset_result.stdev_all = stdev_all;                    % Standard deviation data
dataset_result.processing_params = params;               % All processing parameters used
dataset_result.nfiles = nfiles;                          % Number of files processed

end

% function create_plots(root_name, time1, time_ax, data, pixels)
% % Create diagnostic plots - REMOVED FOR EFFICIENCY
% end
% 
% % Example usage function
% function example_usage()
% % Example of how to use the multi-dataset processor
% 
% % Define your datasets
% datasets = {
%     '38nJ_time_scan_15',
%     '50nJ_time_scan_10', 
%     '25nJ_time_scan_20'
%     % Add more dataset names here
% };

% % Process with default parameters
% process_multiple_tIR_datasets(datasets);
% 
% % Or process with custom parameters
% process_multiple_tIR_datasets(datasets, ...
%     'base_directory', 'C:\Data\Srijan\2025\2025_07\2025_07_22\tIR\3100nm_50mm_grating_CdS_400_PCE_200u_spacer\', ...
%     'time_zero_idx', 5, ...
%     'slice_wavenumbers', [2800, 3050], ...
%     'plot_results', true, ...
%     'save_results', true);
% 
% end