% run_plot.m — contour plot of difference data (file_a - file_b)
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
% ║  Data                                                                   ║
if ~exist('file_a',      'var'), file_a      = 'cut_data_2950.csv';   end
if ~exist('file_b',      'var'), file_b      = 'cut_data_2700.csv';   end
if ~exist('fig_label',   'var'), fig_label   = '2950 - 2700 cm^{-1}'; end
if ~exist('output_name', 'var'), output_name = 'plot_diff_2950_2700'; end
% ║                                                                         ║
% ║  Contour & scaling                                                      ║
clevels      = [0.2 0.3 0.5 0.7 0.9 1.0]; % positive half — SymmetricColorbar mirrors to negatives
line_levels  = [-0.9 -0.7 -0.5 -0.4 -0.3 0.3  0.4 0.5 0.7 0.9];  % contour LINES at these levels (both signs)
custom_scalar   = 1.5;          % vertical stretch on contour levels
line_width      = 0.8;          % contour line thickness
% ║                                                                         ║
% ║  Noise / smoothing                                                      ║
noise_threshold = 0.20;  % zero data below this fraction of peak (0 = off)
smooth_sigma    = 1.0;   % Gaussian smooth radius in pixels (0 = off)
% ║                                                                         ║
% ║  Figure size & export                                                   ║
fig_width_cm    = 13;    % cm
fig_height_cm   = 15;    % cm
png_dpi         = 300;
font_size       = 16;    % axis tick & label font size
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Data ─────────────────────────────────────────────────────────────────────
w2              = readmatrix('w2.csv');
w3              = readmatrix('w3.csv');
integrated_data = readmatrix(file_a) - readmatrix(file_b);   % difference

% ── Colormap ─────────────────────────────────────────────────────────────────
cmap = redblue_3(256);   % full blue → white → red

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
             'Color', 'w');

% Color fill with all clevels, no lines (lines added manually below)
plotContourData_sc_v4(w2, w3, data, ...
    'FigureHandle',      fig, ...
    'XLabel',            '\omega_2/2\pic (cm^{-1})', ...
    'YLabel',            '\omega_3/2\pic (cm^{-1})', ...
    'ColorbarLabel',     'Intensity (a.u.)', ...
    'ColorMap',          cmap, ...
    'ContourLevels',     clevels, ...
    'ScaleToMax',        true, ...
    'ScalarMultiplier',  scalar, ...
    'ShowContourLines',  false, ...
    'CustomScalar',      custom_scalar, ...
    'SymmetricColorbar', true);
xlim([150 400]);
ax = gca;
ax.Color  = [1 1 1];
ax.XColor = 'black';
ax.YColor = 'black';
fig.Color = [1 1 1];
axis(ax, 'square');
set(ax, 'FontSize', font_size, 'FontWeight', 'bold');
ax.YAxis.SecondaryLabel.FontSize = font_size / 2;
xlabel(ax, get(ax.XLabel,'String'), 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
ylabel(ax, get(ax.YLabel,'String'), 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
% Force caxis to match contour level range so zero = white
caxis(ax, [-custom_scalar*scalar  custom_scalar*scalar]);
cb = ax.Colorbar;
if ~isempty(cb)
    set(cb, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
    cb.Label.FontSize   = font_size;
    cb.Label.FontWeight = 'bold';
    cb.Label.Color      = 'black';
end

% Overlay contour lines only at the specified levels
[X, Y] = meshgrid(w2, w3);
actual_line_levels = custom_scalar * scalar * line_levels;
hold on;
contour(X, Y, data, actual_line_levels, ...
    'LineColor', 'k', 'LineWidth', line_width);
hold off;

title(ax, fig_label, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
ax.Title.Units = 'normalized';
ax.Title.Position(2) = ax.Title.Position(2) + 0.06;

% ── Export ───────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.pdf\n', output_name);

exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.svg\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi, 'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
