



% Process all datasets using config file
process_multiple_tIR_datasets_sc_v2('tir_config_v2.m');


% Load the results
load('processed_results.mat');

% Get all dataset field names
dataset_names = fieldnames(results);

% Get dimensions from first dataset
first_dataset = results.(dataset_names{1});
[n_spectral, n_time] = size(first_dataset.data_norm);
n_datasets = length(dataset_names);

% Initialize 3D cube (spectral x time x datasets)
data_cube = zeros(n_spectral, n_time, n_datasets);

% Fill the cube
for i = 1:n_datasets
    data_cube(:,:,i) = results.(dataset_names{4}).data_norm;
end


% Reshape axes to column vectors and match dimensions with data_3D
w1_subset_fixed = results.x38nJ_time_scan_15.pixels;  % 32x1
w3_subset_fixed =results.x38nJ_time_scan_15.time_ax;  % 101x1
file_name = (1:4)';             % 4x1
% Create the slicer object with correct dimension ordering
slicer = DataSlicer(data_cube, {w1_subset_fixed, w3_subset_fixed, file_name});


% Integrate along a dimension within a range
[integrated_data, int_axes] = fft_slicer.integrateAlongDimension(3, [386, 405]);


% Get a cut by value
[cut_data2, cut_axes2] = slicer.getCut(3, 243, 'value');  % Cut along 1st dimension at value 2750








