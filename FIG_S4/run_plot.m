% run_plot.m — 1DVE contour plot: τ₂ (time) × ω₃ (frequency)
% Data source: VE1DExperiment .mat struct (see data_structure.md)
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
% ║  Data                                                                   ║
mat_file     = 've_1D_HBQ_100mM_dmso_d6_150u_1arm_z_10_05_off_4_test_051_20260423_181059.mat';
fig_label    = 'HBQ 1DVE';
output_name  = 'plot_1DVE_HBQ';     % base name for saved files (no extension)
% ║                                                                         ║
% ║  Contour & scaling                                                      ║
clevels         = [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]; % fill levels (fraction of color axis)
line_levels     = [-0.7 -0.2 -0.08 -0.05 0.05 0.08 0.2 0.8]; % contour LINES (fraction of DATA peak)
custom_scalar   = 0.6;          % color-axis = custom_scalar × peak  (compress to reveal oscillations)
line_width      = 0.5;          % contour line thickness
% ║                                                                         ║
% ║  Noise / smoothing                                                      ║
noise_threshold = 0.05;  % zero data below this fraction of peak (0 = off)
smooth_sigma    = 0;     % Gaussian smooth radius in pixels (0 = off)
% ║                                                                         ║
% ║  Figure size & export                                                   ║
fig_width_cm    = 18;    % cm — wide to accommodate τ₂ range
fig_height_cm   = 11;    % cm
png_dpi         = 300;
font_size       = 14;    % axis tick & label font size
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Load struct ───────────────────────────────────────────────────────────────
f    = load(mat_file);
s    = f.s;

% Axes
t2   = s.time / 1000;                   % [1 × Nt]  τ₂ in ps
pMin = s.pixelRange(1);
pMax = s.pixelRange(2);
w3   = s.waveAxis(pMin:pMax);           % [1 × Nw]  ω₃ in cm⁻¹

% Data slice restricted to active pixel window  [Nw × Nt]
data = -s.processedData(pMin:pMax, :);   % negate: transmittance → absorption

% ── Colormap ──────────────────────────────────────────────────────────────────
cmap = redblue_3(256);   % blue → white → red

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
data      = data / scalar;   % normalise to [-1, 1]
scalar    = 1;

% ── Font ──────────────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

% ── Figure ────────────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', 'w');

% Filled contour (no lines here — added manually below)
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
xlabel('');
ylabel('');
caxis(ax, [-custom_scalar*scalar  custom_scalar*scalar]);

cb = ax.Colorbar;
if ~isempty(cb)
    set(cb, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
    cb.Label.FontSize   = font_size;
    cb.Label.FontWeight = 'bold';
    cb.Label.Color      = 'black';
    cb.Label.Rotation   = 270;
    cb.Label.VerticalAlignment = 'bottom';
    % Explicit tick levels across the full color axis
    clim_val = custom_scalar * scalar;
    cb.Ticks = linspace(-clim_val, clim_val, 9);
    cb.TickLabels = arrayfun(@(v) sprintf('%.1f', v), cb.Ticks, 'UniformOutput', false);
end

% Overlay contour lines spanning the full data peak (independent of color axis)
[X, Y] = meshgrid(t2, w3);
actual_line_levels = scalar * line_levels;   % relative to true peak, not color axis
hold on;
contour(X, Y, data, actual_line_levels, 'LineColor', 'k', 'LineWidth', line_width);
hold off;

xlim([-1 2]);
title(ax, fig_label, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
ax.Title.Units = 'normalized';
ax.Title.Position(2) = ax.Title.Position(2) + 0.06;

% ── Outer bold axis labels (matching reference layout) ────────────────────────
% Expand axes margins to make room for outer labels without overlap
% Fix axes to a centred position leaving white margins on all sides
ax.Position = [0.18  0.18  0.60  0.70];

% Invisible full-figure overlay axes for text in normalised figure coordinates
ax_outer = axes('Position', [0 0 1 1], 'Visible', 'off', 'HitTest', 'off', ...
                'Parent', fig);
uistack(ax_outer, 'bottom');

text(ax_outer, 0.032, 0.52, '\omega_3  (cm^{-1})', ...
    'Units', 'normalized', 'FontSize', font_size + 4, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Rotation', 90, 'Interpreter', 'tex', 'Color', 'black');

text(ax_outer, 0.47, 0.05, '\tau_2  (ps)', ...
    'Units', 'normalized', 'FontSize', font_size + 4, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'Interpreter', 'tex', 'Color', 'black');

% ── Export ────────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.pdf\n', output_name);

exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.svg\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi, 'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
