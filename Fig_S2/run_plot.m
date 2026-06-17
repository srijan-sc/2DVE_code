% run_plot.m — 1DVE contour plot: τ₂ (time) × ω₃ (frequency)
% Requires exp object already loaded by ve_1d_workup.m
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
if ~exist('fig_label',   'var'), fig_label   = 'Solvent 1DVE'; end
if ~exist('output_name', 'var'), output_name = 'plot_1DVE_dmso'; end
% ║                                                                         ║
% ║  Contour & scaling                                                      ║
clevels         = [0.02 0.04 0.06 0.08 0.1 0.2 0.3 0.5 0.7 1.0];
line_levels     = [-0.5 -0.08 -0.06 -0.04 -0.02 0.02 0.04 0.06 0.08 0.5];
custom_scalar   = 1.2;
line_width      = 0.5;
% ║                                                                         ║
% ║  Noise / smoothing                                                      ║
noise_threshold = 0.02;
smooth_sigma    = 0;
% ║                                                                         ║
% ║  Figure size & export                                                   ║
fig_width_cm    = 18;
fig_height_cm   = 11;
png_dpi         = 300;
font_size       = 14;
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Extract from exp object ───────────────────────────────────────────────
pMin = exp.pixelRange(1);
pMax = exp.pixelRange(2);
t2   = exp.timeAxis / 1000;                    % fs → ps
w3   = exp.waveAxis(pMin:pMax);
data = exp.processedData(pMin:pMax, :) / 4;

% ── Colormap ─────────────────────────────────────────────────────────────
cmap = redblue_3(256);

% ── Pre-process ──────────────────────────────────────────────────────────
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

% ── Font ─────────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

% ── Figure ───────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', 'w');

plotContourData_sc_v4(t2, w3, data, ...
    'FigureHandle',      fig, ...
    'XLabel',            '', ...
    'YLabel',            '', ...
    'ColorbarLabel',     '\DeltaA/A (mOD)', ...
    'ColorMap',          cmap, ...
    'ContourLevels',     clevels, ...
    'ScaleToMax',        true, ...
    'ScalarMultiplier',  custom_scalar, ...
    'ShowContourLines',  false, ...
    'SymmetricColorbar', true);

ax = gca;
ax.Color  = [1 1 1];
ax.XColor = 'black';
ax.YColor = 'black';
fig.Color = [1 1 1];
set(ax, 'FontSize', font_size, 'FontWeight', 'bold');
caxis(ax, [-custom_scalar*scalar  custom_scalar*scalar]);

cb = ax.Colorbar;
if ~isempty(cb)
    set(cb, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
    cb.Label.FontSize   = font_size;
    cb.Label.FontWeight = 'bold';
    cb.Label.Color      = 'black';
    cb.Label.Rotation   = 270;
    cb.Label.VerticalAlignment = 'bottom';
    clim_val = custom_scalar * scalar;
    cb.Ticks = linspace(-clim_val, clim_val, 9);
    cb.TickLabels = arrayfun(@(v) sprintf('%.1f', v), cb.Ticks, 'UniformOutput', false);
end

% Overlay contour lines
[X, Y] = meshgrid(t2, w3);
hold on;
contour(X, Y, data, scalar * line_levels, 'LineColor', 'k', 'LineWidth', line_width);
hold off;

xlim([-1 2]);
title(ax, fig_label, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
ax.Title.Units = 'normalized';
ax.Title.Position(2) = ax.Title.Position(2) + 0.06;

% Outer axis labels
ax.Position = [0.18  0.18  0.60  0.70];
ax_outer = axes('Position', [0 0 1 1], 'Visible', 'off', 'HitTest', 'off', 'Parent', fig);
uistack(ax_outer, 'bottom');

text(ax_outer, 0.032, 0.52, '\omega_3  (cm^{-1})', ...
    'Units', 'normalized', 'FontSize', font_size + 4, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Rotation', 90, 'Interpreter', 'tex', 'Color', 'black');

text(ax_outer, 0.47, 0.05, '\tau_2  (ps)', ...
    'Units', 'normalized', 'FontSize', font_size + 4, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Interpreter', 'tex', 'Color', 'black');

% ── Export ───────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.pdf\n', output_name);

exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.svg\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi, 'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
