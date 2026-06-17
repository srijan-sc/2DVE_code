% run_plot.m — contour plot of integrated FFT data
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
% ║  Data                                                                   ║
data_file    = 'integrated_data_246_250.csv';  % CSV file to plot
fig_label    = 'cut at 248 cm^{-1}';          % figure title
output_name  = 'plot_248';                 % base name for saved files (no extension)
% ║                                                                         ║
% ║  Contour & scaling                                                      ║
clevels      = [0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]; % fill levels
line_levels  = [0.2 0.3 0.4 0.5 0.7 0.9 1.0];   % contour LINES drawn only at these levels
custom_scalar   = 1.5;          % vertical stretch on contour levels
line_width      = 0.8;          % contour line thickness
% ║                                                                         ║
% ║  Noise / smoothing                                                      ║
noise_threshold = 0.08;  % zero data below this fraction of peak (0 = off)
smooth_sigma    = 1.0;   % Gaussian smooth radius in pixels (0 = off)
% ║                                                                         ║
% ║  Figure size & export                                                   ║
fig_width_cm    = 10;    % cm
fig_height_cm   = 12;    % cm
png_dpi         = 300;
font_size       = 16;
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Data ─────────────────────────────────────────────────────────────────────
w1              = csvread('w1.csv');
w3              = csvread('w3.csv');
integrated_data = csvread(data_file) / 4;   % normalize by integration width (246→250 = 4 steps)

% ── Colormap ─────────────────────────────────────────────────────────────────
full_map     = redblue_3(256);
white_to_red = full_map(129:end, :);   % white → red

% ── Pre-process data ─────────────────────────────────────────────────────────
data = integrated_data;

if smooth_sigma > 0
    k = ceil(3 * smooth_sigma);
    [gx, gy] = meshgrid(-k:k, -k:k);
    kernel = exp(-(gx.^2 + gy.^2) / (2 * smooth_sigma^2));
    kernel = kernel / sum(kernel(:));
    data = conv2(data, kernel, 'same');
end

scalar    = max(max(abs(data)));
threshold = noise_threshold * scalar;
data(abs(data) < threshold) = 0;

% ── Font ─────────────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

% ── Figure & axes ────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', 'white');

% Color fill with all clevels, no lines (lines added manually below)
plotContourData_sc_v4(w1, w3, data, ...
    'FigureHandle',     fig, ...
    'XLabel',           '\omega_1/2\pic (cm^{-1})', ...
    'YLabel',           '\omega_3/2\pic (cm^{-1})', ...
    'ColorbarLabel',    'Intensity (a.u.)', ...
    'ColorMap',         white_to_red, ...
    'ContourLevels',    clevels, ...
    'ScaleToMax',       true, ...
    'ScalarMultiplier', scalar, ...
    'ShowContourLines', false, ...
    'CustomScalar',     custom_scalar, ...
    'SymmetricColorbar', false);

% Overlay contour lines only at the specified higher levels
[X, Y] = meshgrid(w1, w3);
actual_line_levels = custom_scalar * scalar * line_levels;
hold on;
contour(X, Y, data, actual_line_levels, ...
    'LineColor', 'k', 'LineWidth', line_width);
hold off;

ax = gca;
ax.Color  = [1 1 1];
ax.XColor = 'black';
ax.YColor = 'black';
fig.Color = [1 1 1];
axis(ax, 'square');
set(ax, 'FontSize', font_size - 2, 'FontWeight', 'bold');
set(ax, 'XTick', 2500:100:2900);
ax.YAxis.SecondaryLabel.FontSize = (font_size - 2) / 2;
xlabel(ax, get(ax.XLabel, 'String'), 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
ylabel(ax, get(ax.YLabel, 'String'), 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
cb = ax.Colorbar;
if ~isempty(cb)
    set(cb, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
    cb.Label.FontSize   = font_size;
    cb.Label.FontWeight = 'bold';
    cb.Label.Color      = 'black';
end
title(ax, fig_label, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
ax.Title.Units = 'normalized';
ax.Title.Position(2) = ax.Title.Position(2) + 0.06;

% ── Export ───────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.pdf\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi, 'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);

exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.svg\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
