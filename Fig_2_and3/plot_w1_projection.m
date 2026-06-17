% plot_w1_projection.m — ω₁ projection traces from pre-computed CSVs
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
files = {
    'tau2_data/125fs_HBQ.csv',  '125 fs';
    'tau2_data/200fs_HBQ.csv',  '200 fs';
    'tau2_data/515fs_HBQ.csv',  '515 fs';
};
output_name    = 'figures/plot_w1_projection';
w1_range       = [2500 3000];
shade_alpha    = 0.18;
fig_width_cm   = 14;
fig_height_cm  = 9;
png_dpi        = 300;
font_size      = 16;
line_width     = 3;

ftir_file  = 'FTIR.csv';
ftir_color = [0.50, 0.50, 0.50];

colors = [
    0.22, 0.45, 0.69;
    0.80, 0.40, 0.00;
    0.17, 0.49, 0.36;
];
% ╚══════════════════════════════════════════════════════════════════════════╝

set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', 'w');
ax = axes('Parent', fig, 'Color', 'w');
hold(ax, 'on');

h_lines = gobjects(size(files, 1), 1);

for k = 1:size(files, 1)
    T     = readtable(files{k, 1});
    label = files{k, 2};
    c     = colors(k, :);

    w1      = T.w1_cm';
    w3_mean = T.intensity';
    w3_std  = T.sd';

    x_patch = [w1, fliplr(w1)];
    y_patch = [w3_mean + w3_std, fliplr(w3_mean - w3_std)];
    fill(ax, x_patch, y_patch, c, ...
         'FaceAlpha', shade_alpha, 'EdgeColor', 'none', 'HandleVisibility', 'off');

    h_lines(k) = plot(ax, w1, w3_mean, '-', ...
        'Color', c, 'LineWidth', line_width, 'DisplayName', label);

end
hold(ax, 'off');

xlim(ax, w1_range);
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
xlim(ax2, w1_range);
ylabel(ax2, 'Intensity', 'FontSize', font_size, 'FontWeight', 'bold', 'Color', ftir_color);
set(ax2, 'FontSize', font_size, 'FontWeight', 'bold', 'YColor', ftir_color);
ax2.XAxis.Visible = 'off';

legend(ax, [h_lines; h_ftir], 'Location', 'best', 'FontSize', font_size - 2, 'Box', 'off');
fig.Color = 'w';

% ── Export ────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.svg\n', output_name);
exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi, 'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);
savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
