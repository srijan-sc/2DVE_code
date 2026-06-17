% plot_theory.m — Theory absorption: no excitation, with excitation, difference
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
theory_file   = 'Theory.csv';
output_name   = 'plot_theory';

x_range       = [22000 32000];   % cm⁻¹ display range

fig_width_cm  = 18;
fig_height_cm = 14;
png_dpi       = 300;
font_size     = 16;
line_width    = 1.5;

color_noexc   = [0.00, 0.00, 0.00];   % black  — no excitation
color_exc     = [0.00, 0.45, 0.70];   % blue — with excitation
color_diff    = [0.00, 0.45, 0.70];   % blue — difference line
fill_alpha    = 0.30;                  % transparency of filled area
% ╚══════════════════════════════════════════════════════════════════════════╝

set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

% ── Load & crop data ──────────────────────────────────────────────────────
raw     = readmatrix(theory_file);
freq    = raw(:, 1);
no_exc  = raw(:, 2);
with_exc = raw(:, 4);
diff_sp  = raw(:, 6);

mask     = freq >= x_range(1) & freq <= x_range(2);
freq     = freq(mask);
no_exc   = no_exc(mask)   / 1e4;   % scale to ×10⁴ units
with_exc = with_exc(mask) / 1e4;
diff_sp  = diff_sp(mask)  / 1e4;

% ── Figure ────────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', 'w');

% Subplot positions [left bottom width height] in normalised units
left_margin = 0.18;
right_edge  = 0.93;
w           = right_edge - left_margin;

ax1 = axes('Parent', fig, 'Position', [left_margin, 0.71, w, 0.20], 'Color', 'w');
ax2 = axes('Parent', fig, 'Position', [left_margin, 0.18, w, 0.49], 'Color', 'w');

% ── Top panel: difference ─────────────────────────────────────────────────
hold(ax1, 'on');
plot(ax1, freq, diff_sp, '-', ...
    'Color', color_diff, 'LineWidth', line_width, 'DisplayName', 'difference');
yline(ax1, 0, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8, 'HandleVisibility', 'off');
hold(ax1, 'off');

xlim(ax1, x_range);
set(ax1, 'FontSize', font_size - 5, 'FontWeight', 'bold', 'XTickLabel', {});
box(ax1, 'on');
legend(ax1, 'Location', 'northeast', 'FontSize', font_size - 4, 'Box', 'off');

% ── Bottom panel: no excitation + with excitation filled ──────────────────
hold(ax2, 'on');

% Filled area for with_excitation (below the curve, down to zero)
x_patch = [freq; flipud(freq)];
y_patch = [with_exc; zeros(size(with_exc))];
fill(ax2, x_patch, y_patch, color_exc, ...
    'FaceAlpha', fill_alpha, 'EdgeColor', color_exc, 'LineWidth', 0.8, ...
    'DisplayName', 'with excitation');

% No excitation line on top
plot(ax2, freq, no_exc, '-', ...
    'Color', color_noexc, 'LineWidth', line_width, 'DisplayName', 'no excitation');

hold(ax2, 'off');

xlim(ax2, x_range);
ylim(ax2, [0 Inf]);
xlabel(ax2, 'wavenumber (cm^{-1})', 'FontSize', font_size, 'FontWeight', 'bold');
ylabel(ax2, 'Intensity (a.u.)', 'FontSize', font_size, 'FontWeight', 'bold');
set(ax2, 'FontSize', font_size, 'FontWeight', 'bold');
box(ax2, 'on');
legend(ax2, 'Location', 'northeast', 'FontSize', font_size - 2, 'Box', 'off');

% Link x-axes so zoom is synchronised
linkaxes([ax1, ax2], 'x');

fig.Color = 'w';

% ── Export ────────────────────────────────────────────────────────────────
% Add padding so nothing is clipped on export
set(fig, 'Units', 'centimeters');
fig.Position = [2 2 fig_width_cm fig_height_cm];

exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', ...
    'BackgroundColor', 'white', 'Padding', 0.5);
fprintf('Saved: %s.pdf\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi, ...
    'BackgroundColor', 'white', 'Padding', 60);
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
