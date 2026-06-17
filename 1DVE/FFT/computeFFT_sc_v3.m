function [freq_projection, freq_axis, FFT_magnitude, FFT_error] = computeFFT_sc_v3(time_axis, residuals, filter_norm, FFT_size, apply_filter, plot_results)
% computeFFT: Perform FFT on a signal with optional filtering, error analysis, and plotting
%
% Parameters:
%   time_axis (array): Time array in seconds
%   residuals (array): Matrix containing residual signal data
%   filter_norm (array): Normalized filter to apply if filtering is enabled
%   FFT_size (int): Size of the FFT to compute
%   apply_filter (bool): Set to true to enable filtering
%   plot_results (bool): Set to true to display plots
%
% Returns:
%   freq_projection (array): Summed FFT magnitudes from midpoint onward
%   freq_axis (array): Frequency axis in wavenumber units
%   FFT_magnitude (array): Full FFT magnitudes (absolute real part)
%   FFT_error (array): Standard error estimates for FFT magnitudes

% Input validation
validateattributes(FFT_size, {'numeric'}, {'scalar', 'positive', 'even'});
validateattributes(apply_filter, {'logical'}, {'scalar'});
validateattributes(plot_results, {'logical'}, {'scalar'});

% Constants and initial setup
SPEED_OF_LIGHT = 2.99792458E10;  % Speed of light in cm/s
time_fs = time_axis * 1E3;       % Convert time to fs
signal_data = residuals;

% Calculate frequency parameters
time_step_s = abs(diff(time_fs(1:2))) * 1E-15;  % Time step in seconds
max_freq = 1 / (2 * time_step_s * SPEED_OF_LIGHT);  % Nyquist frequency in wavenumber
freq_axis = linspace(0, max_freq, FFT_size/2);

% Preprocess signal
if apply_filter
    if isempty(filter_norm)
        error('Filter required when apply_filter is true');
    end
    processed_data = (signal_data ./ max(signal_data)) .* filter_norm';
else
    processed_data = signal_data ./ max(signal_data);
end

% Compute FFT
fft_results = fftshift(fft(processed_data, FFT_size));
FFT_magnitude = abs(real(fft_results));

% Bootstrap error analysis
n_bootstrap = 1000;
bootstrap_ffts = zeros(FFT_size, n_bootstrap);

parfor i = 1:n_bootstrap
    sample_indices = randi(size(processed_data, 2), size(processed_data, 2), 1);
    bootstrap_sample = processed_data(:, sample_indices);
    bootstrap_fft = fftshift(fft(bootstrap_sample, FFT_size));
    bootstrap_ffts(:, i) = mean(abs(real(bootstrap_fft)), 2);
end

FFT_error = std(bootstrap_ffts, 0, 2);
freq_projection = sum(FFT_magnitude, 2);

% Extract post-midpoint data
midpoint = FFT_size/2 + 1;
FFT_magnitude = FFT_magnitude(midpoint:end, :);
FFT_error = FFT_error(midpoint:end);
freq_projection = freq_projection(midpoint:end);

if plot_results
    createAnalysisPlots(freq_axis, FFT_magnitude, FFT_error, freq_projection, ...
        time_fs, processed_data, signal_data, filter_norm, apply_filter);
end
end

function createAnalysisPlots(freq_axis, FFT_magnitude, FFT_error, freq_projection, ...
    time_fs, processed_data, original_data, filter_norm, apply_filter)
    
    fig = figure('Name', 'FFT Analysis Results', 'Position', [100, 100, 1400, 1000]);
    
    % Plot 1: Mean FFT magnitude with error region
    subplot(2, 2, 1);
    plotFFTMagnitude(freq_axis, FFT_magnitude, FFT_error);
    
    % Plot 2: Contour plot of FFT magnitudes
    subplot(2, 2, 2);
    plotFFTContour(freq_axis, FFT_magnitude);
    
    % Plot 3: Signal comparison
    subplot(2, 2, 3);
    plotSignalComparison(time_fs, original_data, processed_data, filter_norm, apply_filter);
    
    % Plot 4: Frequency projection with noise analysis
    subplot(2, 2, 4);
    plotNoiseAnalysis(freq_axis, freq_projection);
    
    % Format figure
    formatFigure(fig);
end

function plotFFTMagnitude(freq_axis, FFT_magnitude, FFT_error)
    mean_fft = mean(FFT_magnitude, 2);
    
    hold on;
    % Plot mean line and error region
    fillErrorRegion(freq_axis, mean_fft, FFT_error, 'b');
    mainLine = plot(freq_axis, mean_fft, 'b-', 'LineWidth', 1.5);
    
    xlabel('Frequency (wavenumber)');
    ylabel('FFT Magnitude');
    title('Average FFT Magnitude with 1? Confidence Region');
    set(gca, 'YScale', 'log');
    grid on;
    legend(mainLine, 'Mean FFT', 'Location', 'best');
    hold off;
end

function plotFFTContour(freq_axis, FFT_magnitude)
    % Create measurement axis
    meas_axis = 1:size(FFT_magnitude, 2);
    
    % Create contour plot with logarithmic scaling
    contourf(freq_axis, meas_axis, log10(FFT_magnitude'), 20, 'LineColor', 'none');
    
    colormap(jet);
    c = colorbar;
    c.Label.String = 'log??(Magnitude)';
    
    xlabel('Frequency (wavenumber)');
    ylabel('Measurement Number');
    title('FFT Magnitude Contour Map');
end

function plotSignalComparison(time_fs, original_data, processed_data, filter_norm, apply_filter)
    hold on;
    
    % Plot middle measurement
    idx = round(size(original_data, 2)/2);
    time_points = length(time_fs);
    
    % Normalize and plot original signal
    orig_signal = original_data(:, idx) / max(abs(original_data(:, idx)));
    plot(time_fs(1:time_points), orig_signal, 'b-', 'LineWidth', 1.5, ...
        'DisplayName', 'Original Signal');
    
    if apply_filter
        % Plot window function and processed signal
        window = adjustWindowLength(filter_norm, length(orig_signal));
        plot(time_fs(1:time_points), window, 'k--', 'LineWidth', 1.2, ...
            'DisplayName', 'Window Function');
        
        processed_signal = processed_data(:, idx) / max(abs(processed_data(:, idx)));
        plot(time_fs(1:time_points), processed_signal, 'r-', 'LineWidth', 1.2, ...
            'DisplayName', 'Processed Signal');
    end
    
    xlabel('Time (ms)');
    ylabel('Normalized Amplitude');
    title(sprintf('Signal Comparison (Measurement %d)', idx));
    grid on;
    legend('Location', 'best');
    ylim([-1.2 1.2]);
    hold off;
end

function plotNoiseAnalysis(freq_axis, freq_projection)
    hold on;
    
    % Calculate noise floors
    n_tail = round(length(freq_axis) * 0.1);
    noise_floors = calculateNoiseFloors(freq_projection, n_tail);
    
    % Plot projection and noise floors
    h_main = plot(freq_axis, freq_projection, 'r-', 'LineWidth', 1.5);
    
    % Plot noise floors and get handles
    [h1, h2, h3, h4] = plotNoiseFloors(freq_axis, freq_projection, noise_floors);
    
    % Calculate and display SNR
    snr_db = 20 * log10(max(freq_projection) / noise_floors.rms);
    
    xlabel('Frequency (wavenumber)');
    ylabel('Projected Magnitude');
    title({sprintf('Frequency Projection with Noise Floor Analysis'), ...
        sprintf('SNR: %.1f dB', snr_db)});
    grid on;
    % Remove this line to use linear scale: set(gca, 'YScale', 'log');
    
    % Combine all legends with values
    legend([h_main, h1, h2, h3, h4], ...
        {'Frequency Projection', ...
        sprintf('Median Noise Floor (%.2e)', noise_floors.median), ...
        sprintf('RMS Noise Floor (%.2e)', noise_floors.rms), ...
        'Dynamic Noise Floor', ...
        sprintf('Statistical Noise Floor (%.2e)', noise_floors.statistical)}, ...
        'Location', 'best');
    hold off;
end
function [h1, h2, h3, h4] = plotNoiseFloors(freq_axis, freq_projection, noise_floors)
    % Plot different noise floor estimates
    h1 = plot(freq_axis, ones(size(freq_axis)) * noise_floors.median, '--k', ...
        'LineWidth', 1.2);
    h2 = plot(freq_axis, ones(size(freq_axis)) * noise_floors.rms, ':b', ...
        'LineWidth', 1.2);
    h3 = plot(freq_axis, noise_floors.dynamic, '-.g', ...
        'LineWidth', 1.2);
    h4 = plot(freq_axis, ones(size(freq_axis)) * noise_floors.statistical, '--m', ...
        'LineWidth', 1.2);
end

function noise_floors = calculateNoiseFloors(freq_projection, n_tail)
    tail_data = freq_projection(end-n_tail:end);
    
    noise_floors.median = median(tail_data);
    noise_floors.rms = sqrt(mean(tail_data.^2));
    noise_floors.dynamic = movmean(freq_projection, round(length(freq_projection) * 0.05));
    noise_floors.statistical = mean(tail_data) + 3 * std(tail_data);
end

function window = adjustWindowLength(filter_norm, target_length)
    if length(filter_norm) ~= target_length
        window = interp1(linspace(1, target_length, length(filter_norm)), ...
            filter_norm, 1:target_length, 'linear', 'extrap');
    else
        window = filter_norm;
    end
    window = window / max(abs(window));
end

function fillErrorRegion(x, y, error, color)
    % Ensure x is a column vector
    x = x(:);
    y = y(:);
    error = error(:);
    
    % Create coordinates for fill
    x_coords = [x; flipud(x)];
    y_coords = [y + error; flipud(y - error)];
    
    % Create and plot fill
    fill(x_coords, y_coords, color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
end

function formatFigure(fig)
    sgtitle('FFT Analysis Results Overview');
    set(fig, 'Color', 'white');
    set(findall(fig, 'Type', 'axes'), 'Box', 'on');
    
    % Adjust subplot spacing
    spacing = 0.05;
    for i = 1:4
        pos = get(subplot(2,2,i), 'Position');
        set(subplot(2,2,i), 'Position', [pos(1), pos(2), pos(3)-spacing, pos(4)-spacing]);
    end
end