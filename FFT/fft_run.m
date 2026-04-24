%% Load data from CSV
% All files are in the same folder as this script
here        = fileparts(mfilename('fullpath'));
time_axis   = readmatrix(fullfile(here, 'time_axis.csv'));    % [1 x 401]  fs
w3_axis     = readmatrix(fullfile(here, 'w3_axis.csv'));      % [1 x 371]  cm^-1 (decreasing)
data_matrix = readmatrix(fullfile(here, 'data_matrix.csv'));  % [371 x 401]  [Nw x Nt]

%% Select w3 sub-range (cm^-1)
% w3_axis is decreasing, so high cm^-1 maps to a lower index
w3_range = [24200, 24900];   % [low, high] cm^-1

[~, ax_2d(1)] = min(abs(w3_axis - w3_range(2)));  % high cm^-1 -> first index
[~, ax_2d(2)] = min(abs(w3_axis - w3_range(1)));  % low  cm^-1 -> last  index

data_1D = data_matrix(ax_2d(1):ax_2d(2), :)';     % [Nt x Nw_cut]
w3_cut  = w3_axis(ax_2d(1):ax_2d(2));              % [1  x Nw_cut] cm^-1

fprintf('w3 cut: %.1f - %.1f cm^-1  (%d pixels)\n', ...
    w3_cut(end), w3_cut(1), numel(w3_cut));
fprintf('data_1D size: [%d x %d]  (time x pixels)\n', size(data_1D,1), size(data_1D,2));

%% Time shift
offset = 180;   % fs
[shiftedTime, shiftedData] = timeShift(time_axis, data_1D, offset, true);

fprintf('shiftedTime range: %.1f to %.1f fs  (%d points)\n', ...
    shiftedTime(1), shiftedTime(end), numel(shiftedTime));
fprintf('shiftedData size:  [%d x %d]\n', size(shiftedData,1), size(shiftedData,2));

%% Exponential fitting
% Bi-exponential: a1*exp(-t/tau1) + a2*exp(-t/tau2) + c  per pixel
% residuals_matrix = fit - data  (oscillatory component for FFT)
[fits, residuals_cell, residuals_matrix, fit_params] = exp_slice_fit_sc_2(shiftedTime, shiftedData);

fprintf('fit_params size:       [%d x %d]  (pixels x 5 params)\n', size(fit_params,1), size(fit_params,2));
fprintf('residuals_matrix size: [%d x %d]  (time x pixels)\n', size(residuals_matrix,1), size(residuals_matrix,2));

%% R² across all pixels — always plotted
osc_matrix = -residuals_matrix;   % oscillation = data - fit

ss_res = sum(residuals_matrix.^2, 1);
ss_tot = sum((shiftedData - mean(shiftedData, 1)).^2, 1);
R2     = 1 - ss_res ./ ss_tot;

figure;
plot(w3_cut, R2, 'k', 'LineWidth', 1.2); hold on;
yline(0.90, '--r',  'R²=0.90', 'LabelHorizontalAlignment','left');
yline(0.70, '--',   'R²=0.70', 'Color', [0.85 0.55 0], 'LabelHorizontalAlignment','left');
scatter(w3_cut(R2 == max(R2)), max(R2), 60, 'g', 'filled', 'DisplayName', sprintf('best R²=%.2f', max(R2)));
scatter(w3_cut(R2 == min(R2)), min(R2), 60, 'r', 'filled', 'DisplayName', sprintf('worst R²=%.2f', min(R2)));
xlabel('\omega_3 (cm^{-1})'); ylabel('R²');
title(sprintf('Fit quality R²  |  median=%.2f  min=%.2f  max=%.2f', median(R2), min(R2), max(R2)));
legend('R²','','','best','worst','Location','best'); grid on; ylim([0 1]);

%% Inspect fit at specific w3 values  ← change these to probe good/bad regions
inspect_w3 = [24400];   % cm^-1 — add any values, e.g. [24400, 24600, 24800]

figure;
nP = numel(inspect_w3);
for k = 1:nP
    [~, pix_idx] = min(abs(w3_cut - inspect_w3(k)));
    actual_w3    = w3_cut(pix_idx);
    r2_val       = R2(pix_idx);

    % row 1: data + fit
    subplot(nP, 3, (k-1)*3 + 1);
    plot(shiftedTime, shiftedData(:,pix_idx), 'b', 'LineWidth', 1.2); hold on;
    plot(shiftedTime, fits{pix_idx}, 'r--', 'LineWidth', 1.5);
    legend('Data','Fit','Location','best'); grid on;
    ylabel('\DeltaA');
    title(sprintf('\\omega_3=%.1f  R²=%.3f', actual_w3, r2_val));

    % row 2: oscillatory component full time
    subplot(nP, 3, (k-1)*3 + 2);
    plot(shiftedTime, osc_matrix(:,pix_idx), 'k', 'LineWidth', 1.1);
    yline(0,'--','Color',[0.5 0.5 0.5]); grid on;
    ylabel('\DeltaA_{osc}'); xlabel('Time (fs)');
    title('Oscillation (data - fit)');

    % row 3: oscillatory component early time only
    subplot(nP, 3, (k-1)*3 + 3);
    early = shiftedTime < 1500;
    plot(shiftedTime(early), osc_matrix(early,pix_idx), 'k', 'LineWidth', 1.1);
    yline(0,'--','Color',[0.5 0.5 0.5]); grid on;
    ylabel('\DeltaA_{osc}'); xlabel('Time (fs)');
    title('Oscillation — first 1500 fs');
end
sgtitle('Fit inspection per \omega_3  |  [data+fit | osc full | osc early]');

%% Hyperbolic tangent window
% All parameters in fs — shiftedTime is already in fs
t0_1  = 380;   % rising edge center  (fs)  — after coherent artifact
tau_1 = 80;    % rising edge steepness (fs)
t0_2  = 1820;  % falling edge center  (fs)  — 0-2 ps signal window
tau_2 = 80;    % falling edge steepness (fs) — matched to tau_1

filter_norm = hyperbolicTanWindow2(shiftedTime, t0_1, tau_1, t0_2, tau_2, 0, true);

%% FFT
FFT_size     = 2048;
apply_filter = true;

[FFT_magnitude, freq_axis] = computeFFT_sc_v4(shiftedTime, osc_matrix, filter_norm, FFT_size, apply_filter, true);

fprintf('freq_axis     : 0 to %.1f cm^-1  (%d points)\n', freq_axis(end), numel(freq_axis));
fprintf('FFT_magnitude : [%d x %d]  (freq x pixels)\n', size(FFT_magnitude,1), size(FFT_magnitude,2));

%% Save FFT data for standalone plot in 4b/
out_4b = fullfile(here, '4b');
writematrix(freq_axis,     fullfile(out_4b, 'freq_axis.csv'));
writematrix(w3_cut,        fullfile(out_4b, 'w3_cut.csv'));
writematrix(FFT_magnitude, fullfile(out_4b, 'FFT_magnitude.csv'));
fprintf('Saved FFT data to 4b/\n');

%% Contour plot — FFT map (run_plot.m style)
% ── Crop frequency axis to region of interest ────────────────────────────────
freq_range   = [220, 260];   % cm^-1
freq_mask    = freq_axis >= freq_range(1) & freq_axis <= freq_range(2);
freq_crop    = freq_axis(freq_mask);          % [1 x n_freq_crop]
FFT_crop     = FFT_magnitude(freq_mask, :);   % [n_freq_crop x n_w3]

% ── Plot settings (mirrors run_plot.m) ────────────────────────────────────────
clevels         = [0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0];
line_levels     = [0.3 0.5 0.7 0.9];
custom_scalar   = 1.0;
line_width      = 1.5;
noise_threshold = 0.05;   % zero data below this fraction of peak
smooth_sigma    = 0;
fig_width_cm    = 10;
fig_height_cm   = 12;
font_size       = 16;

% ── Colormap: white-to-red (positive only, FFT magnitudes) ───────────────────
full_cmap  = redblue_3(256);
cmap       = full_cmap(129:end, :);   % white → red half only

% ── Pre-process ───────────────────────────────────────────────────────────────
data = FFT_crop;   % [n_freq_crop x n_w3]

if smooth_sigma > 0
    k = ceil(3 * smooth_sigma);
    [gx, gy] = meshgrid(-k:k, -k:k);
    kernel = exp(-(gx.^2 + gy.^2) / (2 * smooth_sigma^2));
    kernel = kernel / sum(kernel(:));
    data = conv2(data, kernel, 'same');
end

scalar    = max(abs(data(:)));
threshold = noise_threshold * scalar;
data(abs(data) < threshold) = 0;

% ── Figure ────────────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm]);

% x = freq_crop (omega_2), y = w3_cut (omega_3), Z passed as data' = [n_w3 x n_freq_crop]
plotContourData_sc_v4(freq_crop, w3_cut, data', ...
    'FigureHandle',      fig, ...
    'XLabel',            '\omega_2/2\pic (cm^{-1})', ...
    'YLabel',            '\omega_3/2\pic (cm^{-1})', ...
    'ColorbarLabel',     '|FFT| (arb.)', ...
    'ColorMap',          cmap, ...
    'ContourLevels',     clevels, ...
    'ScaleToMax',        true, ...
    'ScalarMultiplier',  scalar, ...
    'ShowContourLines',  false, ...
    'CustomScalar',      custom_scalar, ...
    'SymmetricColorbar', false);

xlim([freq_range(1) freq_range(2)]);
ax = gca;
set(ax, 'FontSize', font_size, 'FontWeight', 'bold');
xlabel(get(ax.XLabel,'String'), 'FontSize', font_size, 'FontWeight', 'bold');
ylabel(get(ax.YLabel,'String'), 'FontSize', font_size, 'FontWeight', 'bold');
caxis(ax, [0  custom_scalar*scalar]);

% Colorbar — 2 decimal places
cb = ax.Colorbar;
if ~isempty(cb)
    set(cb, 'FontSize', font_size, 'FontWeight', 'bold');
    cb.Label.FontSize   = font_size;
    cb.Label.FontWeight = 'bold';
    cb.TickLabels = arrayfun(@(v) sprintf('%.2f', v), cb.Ticks, 'UniformOutput', false);
end

% Overlay contour lines
[X, Y] = meshgrid(freq_crop, w3_cut);
hold on;
contour(X, Y, data', custom_scalar*scalar*line_levels, ...
    'LineColor', 'k', 'LineWidth', line_width);
hold off;

title(sprintf('1DVE FFT  |  \\omega_2 = %d-%d cm^{-1}', freq_range(1), freq_range(2)), ...
    'FontSize', font_size);

% ── Export ────────────────────────────────────────────────────────────────────
output_name = fullfile(here, sprintf('1DVE_FFT_%d_%dcm', freq_range(1), freq_range(2)));
exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector');
exportgraphics(fig, [output_name '.png'], 'Resolution', 300);
savefig(fig, [output_name '.fig']);
fprintf('Saved: %s  (.svg / .png / .fig)\n', output_name);
