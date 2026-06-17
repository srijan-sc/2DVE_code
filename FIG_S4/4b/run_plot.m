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
fig_width_cm    = 16;
fig_height_cm   = 15;
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

% ── Colormap: white → red (positive-only FFT magnitudes) ─────────────────────
full_cmap = redblue_3(256);
cmap      = full_cmap(129:end, :);

% ── Pre-process ───────────────────────────────────────────────────────────────
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
data      = data / scalar;   % normalise to [0, 1]
scalar    = 1;

% ── Font ─────────────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

% ── Figure ────────────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm]);

% x = freq_crop (omega_2), y = w3_cut (omega_3), Z = data' [n_w3 x n_freq_crop]
plotContourData_sc_v4(freq_crop, w3_cut, data', ...
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
    'SymmetricColorbar', false);

xlim([freq_range(1) freq_range(2)]);
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
caxis(ax, [0  custom_scalar*scalar]);

% Colorbar
cb = ax.Colorbar;
if ~isempty(cb)
    set(cb, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
    cb.Label.FontSize   = font_size;
    cb.Label.FontWeight = 'bold';
    cb.Label.Color      = 'black';
    cb.TickLabels = arrayfun(@(v) sprintf('%.1f', v), cb.Ticks, 'UniformOutput', false);
end

% Overlay contour lines
[X, Y] = meshgrid(freq_crop, w3_cut);
hold on;
contour(X, Y, data', custom_scalar*scalar*line_levels, ...
    'LineColor', 'k', 'LineWidth', line_width);
hold off;

title(ax, '', 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
ax.Title.Units = 'normalized';
ax.Title.Position(2) = ax.Title.Position(2) + 0.06;

% ── Export ────────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.pdf\n', output_name);

exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.svg\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi, 'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
