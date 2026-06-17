% run_plot.m — contour plot of difference data (file_a - file_b)
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
% ║  Data                                                                   ║
raw = readmatrix('450fs_HBQ.csv');  % data matrix (451 x 66)
fig_label    = '450 fs';
output_name  = 'plot_450fs_HBQ'; % base name for saved files (no extension)
% ║                                                                         ║
% ║  Contour & scaling                                                      ║
clevels      = [0.2 0.3 0.4 0.5 0.7 0.8 0.9 0.95 1.0]; % positive half — SymmetricColorbar mirrors to negatives
line_levels  = [-0.9 -0.7 -0.6 -0.5 -0.4 -0.3 0.3  0.4 0.5 0.7 0.9];  % contour LINES at these levels (both signs)
custom_scalar   = 1.5;          % vertical stretch on contour levels
line_width      = 2.2;          % contour line thickness
% ║                                                                         ║
% ║  Noise / smoothing                                                      ║
noise_threshold = 0.1;  % zero data below this fraction of peak (0 = off)
smooth_sigma    = 0;   % Gaussian smooth radius in pixels (0 = off)
white_band      = 0.02; % fraction of colormap on each side of zero forced to white
% ║                                                                         ║
% ║  Figure size & export                                                   ║
fig_width_cm    = 16;    % cm
fig_height_cm   = 13;    % cm
png_dpi         = 300;
font_size       = 16;    % axis tick & label font size
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Data ─────────────────────────────────────────────────────────────────────
w1 = readmatrix('w1.csv');   % 1 x 66
w3 = readmatrix('w3.csv');   % 1 x 451
% Convert ΔT/T → ΔA: ΔA = −ΔT/T / ln(10)
integrated_data = raw / log(10);

% ── Colormap ─────────────────────────────────────────────────────────────────
cmap = redblue_3(255);   % odd count: white sits exactly at center index 128
% Widen the white zone around zero using white_band from settings above
n_cmap    = size(cmap, 1);
half_band = round(n_cmap * white_band);
center    = ceil(n_cmap / 2);
cmap(center-half_band : center+half_band, :) = 1;

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
set(groot, 'defaultAxesColor',        'white');
set(groot, 'defaultAxesXColor',       'black');
set(groot, 'defaultAxesYColor',       'black');
set(groot, 'defaultTextColor',        'black');

% ── Figure & axes ────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', [1 1 1]);

% Color fill with all clevels, no lines (lines added manually below)
plotContourData_sc_v4(w1, w3, data, ...
    'FigureHandle',      fig, ...
    'XLabel',            '\omega_1/2\pic (cm^{-1})', ...
    'YLabel',            '\omega_3/2\pic (cm^{-1})', ...
    'ColorbarLabel',     '\DeltaA/A', ...
    'ColorMap',          cmap, ...
    'ContourLevels',     clevels, ...
    'ScaleToMax',        true, ...
    'ScalarMultiplier',  scalar, ...
    'ShowContourLines',  false, ...
    'CustomScalar',      custom_scalar, ...
    'SymmetricColorbar', true);
xlim([min(w1) max(w1)]);
ax = gca;
ax.Color      = [1 1 1];
ax.XColor     = 'black';
ax.YColor     = 'black';
fig.Color     = [1 1 1];
axis(ax, 'square');
set(ax, 'FontSize', font_size, 'FontWeight', 'bold');
xlabel(get(ax.XLabel,'String'), 'FontSize', font_size, 'FontWeight', 'bold');
ylabel(get(ax.YLabel,'String'), 'FontSize', font_size, 'FontWeight', 'bold');
% Force caxis to match contour level range so zero = white
caxis(ax, [-custom_scalar*scalar  custom_scalar*scalar]);
colormap(ax, cmap);
cb = ax.Colorbar;
if ~isempty(cb)
    set(cb, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
    cb.Label.FontSize   = font_size;
    cb.Label.FontWeight = 'bold';
    cb.Label.Color      = 'black';
end

% Overlay contour lines only at the specified levels
[X, Y] = meshgrid(w1, w3);
actual_line_levels = custom_scalar * scalar * line_levels;
hold on;
contour(X, Y, data, actual_line_levels, ...
    'LineColor', 'k', 'LineWidth', line_width);
hold off;

title(fig_label, 'FontSize', font_size);

% ── Export ───────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi);
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);

exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector');
fprintf('Saved: %s.svg\n', output_name);
fprintf('Saved: %s.fig\n', output_name);
