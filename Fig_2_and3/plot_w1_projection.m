% plot_w1_projection.m — ω₁ projection line plots with FTIR overlay
%   data_source = 'csv'  → reads pre-computed 3-column CSVs from tau2_data/
%   data_source = 'cube' → slices the 3D data cube on-the-fly
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣

% Data source: 'csv' or 'cube'
data_source = 'csv';

% τ₂ time points to plot (fs)
%   csv mode  — must match filenames in csv_dir exactly
%   cube mode — nearest grid point is used automatically
query_times = [125 200 515];

% ── CSV mode ──────────────────────────────────────────────────────────────
csv_dir = 'tau2_data';          % folder containing {t}fs_HBQ.csv files

% ── Cube mode ─────────────────────────────────────────────────────────────
data_file  = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Analysis/HBQ_3D_analysis/data_cube_3DVE.mat';
waxis_file = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Lab_pc_backup/CCD_Wavelength_Axis_2024_03_06.mat';
time_axis  = 110:15:1015;       % full τ₂ grid in fs (must match cube dim 3)
FTsize     = 4096;
pix_range  = [550 1000];        % CCD pixel rows for w3
smooth_sigma = 0.5;             % Gaussian smooth along w1 (0 = off)

% ── Shared ────────────────────────────────────────────────────────────────
ftir_file   = 'csv/FTIR.csv';
w1_window   = [2500 3000];      % cm⁻¹ display range
output_name = 'figures/plot_w1_projection';

% Standalone FTIR figure
plot_ftir_fig = true;
ftir_window   = [2400 3200];    % cm⁻¹ range for FTIR-only plot

% Plot style
shade_alpha   = 0.18;
fig_width_cm  = 14;
fig_height_cm = 9;
png_dpi       = 300;
font_size     = 16;
line_width    = 3;
ftir_color    = [0.50 0.50 0.50];
colors = [
    0.22, 0.45, 0.69;   % muted blue
    0.80, 0.40, 0.00;   % burnt orange
    0.17, 0.49, 0.36;   % teal green
];

% ╚══════════════════════════════════════════════════════════════════════════╝

set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

% ── Load cube (once, if needed) ───────────────────────────────────────────
if strcmp(data_source, 'cube')
    HeNeHalfCycle = 1.0554e-15;
    SpeedOfLight  = 2.99792458e10;
    freqRes  = (1 / HeNeHalfCycle) / SpeedOfLight / FTsize;
    freqAxis = (0:FTsize-1) .* freqRes;
    w1_bins  = round(w1_window ./ freqRes);
    w1_axis  = freqAxis(w1_bins(1):w1_bins(2));   % [1 × Nw1]

    fprintf('Loading CCD axis ... ');
    tmp    = load(waxis_file);
    fprintf('done\n');

    fprintf('Loading data cube ... ');
    tmp2     = load(data_file);
    dataCube = tmp2.dataCube2;   % [Nw3_full × Nw1_full × Nt]
    fprintf('[%d × %d × %d]\n', size(dataCube,1), size(dataCube,2), size(dataCube,3));

    if size(dataCube, 3) ~= numel(time_axis)
        error('time_axis has %d points but cube dim 3 has %d.', ...
              numel(time_axis), size(dataCube,3));
    end

    if smooth_sigma > 0
        hw   = ceil(3 * smooth_sigma);
        xk   = -hw:hw;
        kern = exp(-xk.^2 / (2 * smooth_sigma^2));
        kern = kern / sum(kern);
    end
end

% ── Main figure ───────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', 'w');
ax = axes('Parent', fig, 'Color', 'w');
hold(ax, 'on');

h_lines = gobjects(numel(query_times), 1);

% ── Per-time trace ────────────────────────────────────────────────────────
for idx = 1:numel(query_times)
    c = colors(idx, :);

    if strcmp(data_source, 'csv')
        t = query_times(idx);
        T = readtable(fullfile(csv_dir, sprintf('%dfs_HBQ.csv', t)));
        w1_axis = T.w1_cm';
        w3_mean = T.intensity';
        w3_std  = T.sd';
        label   = sprintf('%d fs', t);

    else  % cube
        [~, t_idx] = min(abs(time_axis - query_times(idx)));
        actual_t   = time_axis(t_idx);
        label      = sprintf('%d fs', actual_t);

        slice    = dataCube(pix_range(1):pix_range(2), w1_bins(1):w1_bins(2), t_idx);
        abs_sl   = abs(slice);
        w3_mean  = mean(abs_sl, 1);
        w3_std   = std(abs_sl, 0, 1);

        if smooth_sigma > 0
            w3_mean = conv(w3_mean, kern, 'same');
            w3_std  = conv(w3_std,  kern, 'same');
        end

        fprintf('τ₂ = %d fs  (grid %d fs, idx %d)\n', query_times(idx), actual_t, t_idx);
    end

    x_patch = [w1_axis, fliplr(w1_axis)];
    y_patch = [w3_mean + w3_std, fliplr(w3_mean - w3_std)];
    fill(ax, x_patch, y_patch, c, ...
         'FaceAlpha', shade_alpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');

    h_lines(idx) = plot(ax, w1_axis, w3_mean, '-', ...
        'Color', c, 'LineWidth', line_width, 'DisplayName', label);
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

legend(ax, [h_lines; h_ftir], 'Location', 'best', 'FontSize', font_size - 2, 'Box', 'off');
fig.Color = 'w';

% ── Export main figure ────────────────────────────────────────────────────
if ~exist(fileparts(output_name), 'dir') && ~isempty(fileparts(output_name))
    mkdir(fileparts(output_name));
end
exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi,   'BackgroundColor', 'white');
savefig(fig, [output_name '.fig']);
fprintf('Saved: %s  (.pdf / .svg / .png / .fig)\n', output_name);

% ── Standalone FTIR figure ────────────────────────────────────────────────
if plot_ftir_fig
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

    % Gradient fill 2500–3000: sage green at top → white at baseline (pump colour)
    m  = fx >= 2500 & fx <= 3000;
    xr = fx(m);  yr = fy(m);  n = numel(xr);
    p  = patch(ax_ftir, [xr fliplr(xr)], [yr zeros(1,n)], 'g', 'HandleVisibility', 'off');
    p.FaceVertexCData = [repmat([0.62 0.82 0.64], n, 1); repmat([1 1 1], n, 1)];
    p.FaceColor = 'interp';
    p.EdgeColor = 'none';

    plot(ax_ftir, fx, fy, '-', 'Color', 'k', 'LineWidth', 1.8);

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
        'Box', 'on', 'TickLength', [0 0], 'LineWidth', 1.2, 'YTick', [0 0.5 1]);
    ax_ftir.XAxis.Color = 'k';
    ax_ftir.YAxis.Color = 'k';

    if ~exist('ftir_fig', 'dir'),  mkdir('ftir_fig');  end
    ftir_out = fullfile('ftir_fig', 'plot_ftir');
    exportgraphics(fig_ftir, [ftir_out '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig_ftir, [ftir_out '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig_ftir, [ftir_out '.png'], 'Resolution', png_dpi,   'BackgroundColor', 'white');
    savefig(fig_ftir, [ftir_out '.fig']);
    fprintf('Saved: %s  (.pdf / .svg / .png / .fig)\n', ftir_out);
end
