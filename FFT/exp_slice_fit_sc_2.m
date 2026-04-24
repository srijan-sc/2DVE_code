function [fits, residuals_cell, residuals_matrix, fit_params] = exp_slice_fit_sc(time_data, data_matrix)
% EXP_SLICE_FIT_SC Performs parallel bi-exponential fitting on time-shifted data
%
% Inputs:
%   time_data    - Time points vector [1 x T] or [T x 1]
%   data_matrix  - Matrix containing data [T x N] where T is time points
%                 and N is number of pixels

    % Print input dimensions
    fprintf('Input dimensions:\n');
    fprintf('time_data: %d x %d\n', size(time_data, 1), size(time_data, 2));
    fprintf('data_matrix: %d x %d\n', size(data_matrix, 1), size(data_matrix, 2));

    % Convert time_data to column vector
    time_data = time_data(:);
    
    fprintf('After conversion:\n');
    fprintf('time_data: %d x %d\n', size(time_data, 1), size(time_data, 2));
    
    % Input validation
    validateattributes(time_data, {'numeric'}, {'vector'});
    validateattributes(data_matrix, {'numeric'}, {'2d'});
    
    [num_time_points_input, num_pixels] = size(data_matrix);
    if num_time_points_input ~= length(time_data)
        error('Time vector length (%d) must match data matrix rows (%d)', ...
              length(time_data), num_time_points_input);
    end
    
    % Find the starting point (closest to t=0)
    [min_time_val, time_zero_index] = min(abs(time_data));
    fprintf('Time zero index: %d (time value: %g)\n', time_zero_index, min_time_val);
    start_index = 1 ;%time_zero_index;
    
    % Initialize output arrays
    num_time_points = length(time_data) - start_index + 1;
    fprintf('Points for fitting: %d (from index %d to %d)\n', ...
            num_time_points, start_index, length(time_data));
    
    fits = cell(num_pixels, 1);
    residuals_cell = cell(num_pixels, 1);
    residuals_matrix = zeros(num_time_points, num_pixels);
    fit_params = zeros(num_pixels, 5);
    
    % Prepare time vector starting from t≈0
    time_for_fit = time_data(start_index:end);
    
    % Define bi-exponential model function
    fitting_function = @(params, t) params(1) * exp(-t/params(2)) + ...
                                   params(3) * exp(-t/params(4)) + ...
                                   params(5);
    
    % Define objective function for optimization
    objective_function = @(params, t, y) sum((fitting_function(params, t) - y).^2);
    
    % Set parameter bounds (we'll handle them manually in the optimization)
    lb = [-Inf, 0, -Inf, 0, -Inf];
    ub = [Inf, Inf, Inf, Inf, Inf];
    
    % Store expected dimensions
    expected_length = length(time_for_fit);
    fprintf('Expected length of each fit: %d\n', expected_length);
    
    % Check for problematic pixels
    problem_pixels = [846, 860, 861];
    for p = problem_pixels
        if p <= size(data_matrix, 2)
            slice = data_matrix(start_index:end, p);
            fprintf('Pixel %d slice length: %d\n', p, length(slice));
            if any(isnan(slice)) || any(isinf(slice))
                fprintf('Pixel %d contains NaN or Inf values\n', p);
            end
        end
    end
    
    % Parallel fitting for each pixel
    parfor i = 1:num_pixels
        try
            % Get data for current pixel
            slice_data = data_matrix(start_index:end, i);
            
            % Additional check for problematic pixels
            if any(i == problem_pixels)
                if length(slice_data) ~= expected_length
                    warning('Pixel %d: Length mismatch. Expected %d, got %d', ...
                            i, expected_length, length(slice_data));
                end
            end
            
            % Set initial parameter guess
            initial_guess = [
                max(slice_data),    % a1: maximum amplitude
                80,                 % tau1: fast time constant (fs)
                max(slice_data)/4,  % a2: half of maximum amplitude
                8000,               % tau2: slow time constant (fs, ~8 ps)
                min(slice_data)     % c: baseline offset
            ];
            
            % Ensure slice_data is a column vector
            slice_data = slice_data(:);
            
            % Perform optimization using fminsearch (part of base MATLAB)
            % With parameter bound constraints handled manually
            options = optimset('Display', 'off', 'MaxFunEvals', 1000, 'MaxIter', 1000);
            
            % Define constrained objective function
            constrained_obj_fun = @(params) objective_function(constrain_params(params, lb, ub), time_for_fit, slice_data);
            
            % Perform the optimization
            [params_unconstrained, fval] = fminsearch(constrained_obj_fun, initial_guess, options);
            
            % Apply constraints to final parameters
            params = constrain_params(params_unconstrained, lb, ub);
            
            % Calculate fitted curve
            fit_curve = fitting_function(params, time_for_fit);
            
            % Calculate residuals
            residual = fit_curve - slice_data;
            
            % Store results
            fits{i} = fit_curve;
            residuals_cell{i} = residual;
            residuals_matrix(:, i) = residual;
            fit_params(i, :) = params;
            
        catch ME
            warning('Fitting failed for pixel %d: %s\nTrace: %s', ...
                    i, ME.message, getReport(ME, 'basic'));
            fits{i} = nan(expected_length, 1);
            residuals_cell{i} = nan(expected_length, 1);
            residuals_matrix(:, i) = nan(expected_length, 1);
            fit_params(i, :) = nan(1, 5);
        end
    end
end

% Helper function to manually constrain parameters
function params_constrained = constrain_params(params, lb, ub)
    % Apply lower bounds
    for i = 1:length(params)
        if ~isnan(lb(i)) && params(i) < lb(i)
            params(i) = lb(i);
        end
        if ~isnan(ub(i)) && params(i) > ub(i)
            params(i) = ub(i);
        end
    end
    params_constrained = params;
end