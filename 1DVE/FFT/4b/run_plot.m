% run_plot.m — 1DVE HBQ FFT contour plot
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
freq_range      = [220, 260];   % cm^-1  — Fourier frequency window
clevels         = [0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0];
line_levels     = [0.3 0.5 0.7 0.9];
custom_scalar   = 1.0;
line_width      = 1.5;
noise_threshold = 0.05;         % zero data below this fraction of peak (0 = off)
smooth_sigma    = 0;            % Gaussian smooth radius in pixels (0 = off)
fig_width_cm    = 10;
fig_height_cm   = 12;
png_dpi         = 300;
font_size       = 16;
output_name     = '1DVE_HBQ';
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Load data ─────────────────────────────────────────────────────────────────
freq_axis     = readmatrix('freq_axis.csv');      % [1 x n_freq]  cm^-1
w3_cut        = readmatrix('w3_cut.csv');         % [1 x n_w3]    cm^-1
FFT_magnitude = readmatrix('FFT_magnitude.csv');  % [n_freq x n_w3]

% ── Crop to frequency range ───────────────────────────────────────────────────
freq_mask = freq_axis >= freq_range(1) & freq_axis <= freq_range(2);
freq_crop = freq_axis(freq_mask);
data      = FFT_magnitude(freq_mask, :);   % [n_freq_crop x n_w3]

% ── Colormap: white → red ─────────────────────────────────────────────────────
full_map     = redblue_3(256);
white_to_red = full_map(129:end, :);

% ── Pre-process ───────────────────────────────────────────────────────────────
if smooth_sigma > 0
    k = ceil(3 * smooth_sigma);
    [gx, gy] = meshgrid(-k:k, -k:k);
    kernel = exp(-(gx.^2 + gy.^2) / (2 * smooth_sigma^2));
    kernel = kernel / sum(kernel(:));
    data = conv2(data, kernel, 'same');
end

scalar    = max(max(abs(data)));
data      = data / scalar;          % normalise so max = 1
scalar    = 1;
threshold = noise_threshold * scalar;
data(abs(data) < threshold) = 0;

% ── Font ─────────────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

% ── Figure & axes ─────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', 'w');

plotContourData_sc_v4(freq_crop, w3_cut, data', ...
    'FigureHandle',      fig, ...
    'XLabel',            '\omega_2/2\pic (cm^{-1})', ...
    'YLabel',            '\omega_3/2\pic (cm^{-1})', ...
    'ColorbarLabel',     '|FFT| (arb.)', ...
    'ColorMap',          white_to_red, ...
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
cb = ax.Colorbar;
if ~isempty(cb)
    set(cb, 'FontSize', font_size, 'FontWeight', 'bold');
    cb.Label.FontSize   = font_size;
    cb.Label.FontWeight = 'bold';
end

% Overlay contour lines
[X, Y] = meshgrid(freq_crop, w3_cut);
actual_line_levels = custom_scalar * scalar * line_levels;
hold on;
contour(X, Y, data', actual_line_levels, ...
    'LineColor', 'k', 'LineWidth', line_width);
hold off;

title('1DVE HBQ', 'FontSize', font_size);

% ── Export ────────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector');
exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi);
savefig(fig, [output_name '.fig']);
fprintf('Saved: %s  (.svg / .png / .fig)\n', output_name);
