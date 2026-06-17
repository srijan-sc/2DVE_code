% plot_w1_projection_cube.m — |data| averaged over w3, plotted vs w1
%   Loads any τ₂ slice directly from the 3D data cube (.mat).
%   Replaces the CSV-per-time-point workflow in plot_w1_projection.m.
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
% Paths
data_file  = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Analysis/HBQ_3D_analysis/data_cube_3DVE.mat';
waxis_file = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Lab_pc_backup/CCD_Wavelength_Axis_2024_03_06.mat';
ftir_file  = 'FTIR.csv';
output_name = 'plot_w1_projection_cube';

% τ₂ time points to overlay (fs) — nearest grid point is used automatically
query_times = [200 500 600];

% Set true to also save a standalone FTIR figure
plot_ftir_fig  = true;
ftir_window    = [2400 3200];   % cm⁻¹ range for standalone FTIR plot
ftir_fill_color = [0.18 0.42 0.68];   % deep blue line + fill

% Full τ₂ grid in fs — must match size(dataCube2, 3)
time_axis = 110:15:1015;

% FT size used when building the cube
FTsize = 4096;

% Spectral window
pix_range = [550 1000];    % CCD pixel rows for w3
w1_window = [2500 3000];   % cm⁻¹ limits for w1 axis

% Plot style
smooth_sigma   = 0.5;
shade_alpha    = 0.18;
fig_width_cm   = 14;
fig_height_cm  = 9;
png_dpi        = 300;
font_size      = 16;
line_width     = 2;
ftir_color     = [0.50 0.50 0.50];
colors = [
    0.22, 0.45, 0.69;   % muted blue
    0.80, 0.40, 0.00;   % burnt orange
    0.17, 0.49, 0.36;   % teal green
];
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Build w1 frequency axis from HeNe calibration ─────────────────────────
HeNeHalfCycle = 1.0554e-15;       % s
SpeedOfLight  = 2.99792458e10;    % cm/s
freqRes  = (1 / HeNeHalfCycle) / SpeedOfLight / FTsize;   % cm⁻¹ per bin
freqAxis = (0:FTsize-1) .* freqRes;                        % [1 × FTsize]

w1_bins  = round(w1_window ./ freqRes);                    % [lo_bin, hi_bin]
w1_axis  = freqAxis(w1_bins(1):w1_bins(2));                % [1 × Nw1] in cm⁻¹

% ── Load CCD wavelength axis → w3 in cm⁻¹ ────────────────────────────────
fprintf('Loading CCD axis ... ');
tmp    = load(waxis_file);
CCD_cm = 1e7 ./ tmp.CCD_wavelength_axis;
fprintf('w3: %.0f–%.0f cm⁻¹  (%d pts)\n', ...
    CCD_cm(pix_range(1)), CCD_cm(pix_range(2)), diff(pix_range)+1);

% ── Load 3D data cube ─────────────────────────────────────────────────────
fprintf('Loading data cube ... ');
tmp      = load(data_file);
dataCube = tmp.dataCube2;   % [Nw3_full × Nw1_full × Nt]
sz       = size(dataCube);
fprintf('[%d × %d × %d]  (w3 × w1 × τ₂)\n', sz(1), sz(2), sz(3));

if sz(3) ~= numel(time_axis)
    error('time_axis has %d points but cube dim 3 has %d — adjust time_axis.', ...
          numel(time_axis), sz(3));
end

% ── Figure ────────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', 'w');
ax = axes('Parent', fig, 'Color', 'w');
hold(ax, 'on');

h_lines = gobjects(numel(query_times), 1);

% ── Per-time projection ───────────────────────────────────────────────────
for idx = 1:numel(query_times)
    [~, t_idx]  = min(abs(time_axis - query_times(idx)));
    actual_t    = time_axis(t_idx);
    label       = sprintf('%d fs', actual_t);
    c           = colors(idx, :);

    % Slice cube at this τ₂: [Nw3_sub × Nw1_sub]
    slice     = dataCube(pix_range(1):pix_range(2), w1_bins(1):w1_bins(2), t_idx);
    abs_slice = abs(slice);

    % Average over w3 (dim 1) → [1 × Nw1]
    w3_mean = mean(abs_slice, 1);
    w3_std  = std(abs_slice, 0, 1);

    % Optional Gaussian smooth along w1
    if smooth_sigma > 0
        half = ceil(3 * smooth_sigma);
        xk   = -half:half;
        kern = exp(-xk.^2 / (2 * smooth_sigma^2));
        kern = kern / sum(kern);
        w3_mean = conv(w3_mean, kern, 'same');
        w3_std  = conv(w3_std,  kern, 'same');
    end

    % Shaded ±1 std band
    x_patch = [w1_axis, fliplr(w1_axis)];
    y_patch = [w3_mean + w3_std, fliplr(w3_mean - w3_std)];
    fill(ax, x_patch, y_patch, c, ...
         'FaceAlpha', shade_alpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');

    h_lines(idx) = plot(ax, w1_axis, w3_mean, '-', ...
        'Color', c, 'LineWidth', line_width, 'DisplayName', label);

    fprintf('τ₂ = %d fs  (grid point %d fs, idx %d)\n', query_times(idx), actual_t, t_idx);
end
hold(ax, 'off');

xlim(ax, w1_window);
xlabel(ax, '\omega_1/2\pic (cm^{-1})', 'FontSize', font_size, 'FontWeight', 'bold');
ylabel(ax, 'Intensity (a.u.)',          'FontSize', font_size, 'FontWeight', 'bold');
set(ax, 'FontSize', font_size, 'FontWeight', 'bold', 'YColor', 'k');
box(ax, 'on');

% ── FTIR on right y-axis ──────────────────────────────────────────────────
ftir_raw  = readmatrix(ftir_file);
ftir_freq = ftir_raw(:, 1)';
ftir_int  = ftir_raw(:, 2)';

ax2 = axes('Position', ax.Position, 'Color', 'none', ...
           'YAxisLocation', 'right', 'XAxisLocation', 'top', ...
           'XTick', [], 'FontName', 'Aptos Body');
hold(ax2, 'on');
h_ftir = plot(ax2, ftir_freq, ftir_int, '-', ...
    'Color', ftir_color, 'LineWidth', 2.5, 'DisplayName', 'FTIR');
hold(ax2, 'off');
xlim(ax2, w1_window);
ylabel(ax2, 'Intensity', 'FontSize', font_size, 'FontWeight', 'bold', 'Color', ftir_color);
set(ax2, 'FontSize', font_size, 'FontWeight', 'bold', 'YColor', ftir_color);
ax2.XAxis.Visible = 'off';

% ── Legend ────────────────────────────────────────────────────────────────
legend(ax, [h_lines; h_ftir], 'Location', 'best', 'FontSize', font_size - 2, 'Box', 'off');

% ── Standalone FTIR figure ────────────────────────────────────────────────
if plot_ftir_fig
    % Crop and normalise to [0, 1] within the window
    mask = ftir_freq >= ftir_window(1) & ftir_freq <= ftir_window(2);
    fx   = ftir_freq(mask);
    fy   = ftir_int(mask);
    fy   = (fy - min(fy)) / (max(fy) - min(fy));

    fig_ftir = figure('Units', 'centimeters', ...
                      'Position', [2 2 fig_width_cm fig_height_cm], ...
                      'PaperUnits', 'centimeters', ...
                      'PaperSize',  [fig_width_cm fig_height_cm], ...
                      'Color', 'w');
    ax_ftir = axes('Parent', fig_ftir, 'Color', 'w');
    hold(ax_ftir, 'on');

    % Gradient fill 2500–3000: soft blue at curve top → white at baseline
    m  = fx >= 2500 & fx <= 3000;
    xr = fx(m);  yr = fy(m);  n = numel(xr);
    c_top = [0.55 0.76 0.94];   % soft blue
    c_bot = [1.00 1.00 1.00];   % white
    px = [xr,  fliplr(xr)];
    py = [yr,  zeros(1, n)];
    vc = [repmat(c_top, n, 1); repmat(c_bot, n, 1)];
    p  = patch(ax_ftir, px, py, 'b', 'HandleVisibility', 'off');
    p.FaceVertexCData = vc;
    p.FaceColor       = 'interp';
    p.EdgeColor       = 'none';

    % Black FTIR line over full window
    plot(ax_ftir, fx, fy, '-', 'Color', 'k', 'LineWidth', 1.8);

    % Vertical dashed lines at window boundaries
    ymax = 1.08;
    plot(ax_ftir, [2500 2500], [0 ymax], '--', 'Color', [0.45 0.45 0.45], ...
         'LineWidth', 1.2, 'HandleVisibility', 'off');
    plot(ax_ftir, [3000 3000], [0 ymax], '--', 'Color', [0.45 0.45 0.45], ...
         'LineWidth', 1.2, 'HandleVisibility', 'off');

    hold(ax_ftir, 'off');
    xlim(ax_ftir, ftir_window);
    ylim(ax_ftir, [0 ymax]);
    xlabel(ax_ftir, '\omega_1/2\pic  (cm^{-1})', 'FontSize', font_size, 'FontWeight', 'bold');
    ylabel(ax_ftir, 'Absorbance (norm.)',          'FontSize', font_size, 'FontWeight', 'bold');
    set(ax_ftir, 'FontSize', font_size, 'FontWeight', 'bold', ...
        'Box', 'on', 'TickLength', [0 0], 'LineWidth', 1.2, ...
        'YTick', [0 0.5 1]);
    ax_ftir.XAxis.Color = 'k';
    ax_ftir.YAxis.Color = 'k';

    if ~exist('ftir_fig', 'dir'),  mkdir('ftir_fig');  end
    ftir_out = fullfile('ftir_fig', 'plot_ftir');
    exportgraphics(fig_ftir, [ftir_out '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig_ftir, [ftir_out '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig_ftir, [ftir_out '.png'], 'Resolution', png_dpi,   'BackgroundColor', 'white');
    savefig(fig_ftir, [ftir_out '.fig']);
    fprintf('Saved: %s.pdf / .svg / .png / .fig\n', ftir_out);
end

% ── Export main figure (commented out) ────────────────────────────────────
% exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
% fprintf('Saved: %s.svg\n', output_name);
% exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi, 'BackgroundColor', 'white');
% fprintf('Saved: %s.png\n', output_name);
% savefig(fig, [output_name '.fig']);
% fprintf('Saved: %s.fig\n', output_name);
