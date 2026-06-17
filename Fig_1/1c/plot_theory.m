% plot_theory.m — Theory absorption: no excitation, with excitation, difference
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
theory_file   = 'Theory.csv';
output_name   = 'fig/plot_theory';

x_range       = [22000 32000];   % cm⁻¹ display range

fig_width_cm  = 18;
fig_height_cm = 14;
png_dpi       = 300;
font_size     = 16;
line_width    = 2.4;

color_noexc   = [0.00, 0.00, 0.00];   % black  — no excitation
color_exc     = [0.22, 0.45, 0.69];   % muted blue — with excitation (shared palette)
color_diff    = [0.22, 0.45, 0.69];   % muted blue — difference line (shared palette)
fill_alpha    = 0.40;                  % transparency of filled area
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

ax1 = axes('Parent', fig, 'Position', [left_margin, 0.69, w, 0.22], 'Color', 'w');
ax2 = axes('Parent', fig, 'Position', [left_margin, 0.14, w, 0.52], 'Color', 'w');

% ── Top panel: difference ─────────────────────────────────────────────────
hold(ax1, 'on');
plot(ax1, freq, diff_sp, '-', ...
    'Color', color_diff, 'LineWidth', line_width, 'DisplayName', 'difference');
yline(ax1, 0, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8, 'HandleVisibility', 'off');
hold(ax1, 'off');

xlim(ax1, x_range);
ylabel(ax1, 'Difference', 'FontSize', font_size - 2, 'FontWeight', 'bold');
set(ax1, 'FontSize', font_size - 2, 'FontWeight', 'bold', 'XTickLabel', {}, ...
    'TickDir', 'in', 'TickLength', [0.015 0.015]);
box(ax1, 'on');
legend(ax1, 'Location', 'northeast', 'FontSize', font_size - 3, 'Box', 'off');

% ── Bottom panel: no excitation + with excitation filled ──────────────────
hold(ax2, 'on');

% Gradient fill: color_exc at curve top → white at baseline
n_pts   = numel(freq);
x_verts = [freq; flipud(freq)];
y_verts = [with_exc; zeros(size(with_exc))];
c_verts = [repmat(color_exc, n_pts, 1); repmat([1 1 1], n_pts, 1)];
p_fill  = patch(ax2, x_verts, y_verts, 'b', 'HandleVisibility', 'off');
p_fill.FaceVertexCData = c_verts;
p_fill.FaceColor = 'interp';
p_fill.EdgeColor = 'none';
p_fill.FaceAlpha = fill_alpha;
% Invisible proxy so legend shows a flat colour swatch
fill(ax2, NaN, NaN, color_exc, 'FaceAlpha', fill_alpha, 'EdgeColor', 'none', ...
    'DisplayName', 'with excitation');

% No excitation — thinner, dark gray so it recedes
plot(ax2, freq, no_exc, '-', ...
    'Color', [0.60 0.60 0.60], 'LineWidth', line_width - 0.5, 'DisplayName', 'no excitation');

% With excitation line on top — primary highlight
plot(ax2, freq, with_exc, '-', ...
    'Color', color_exc, 'LineWidth', line_width, 'HandleVisibility', 'off');

hold(ax2, 'off');

xlim(ax2, x_range);
ylim(ax2, [0 Inf]);
xlabel(ax2, 'wavenumber (cm^{-1})', 'FontSize', font_size, 'FontWeight', 'bold');
ylabel(ax2, 'Intensity (a.u.)',     'FontSize', font_size, 'FontWeight', 'bold');
set(ax2, 'FontSize', font_size, 'FontWeight', 'bold', ...
    'TickDir', 'in', 'TickLength', [0.010 0.010]);
box(ax2, 'on');
legend(ax2, 'Location', 'northeast', 'FontSize', font_size - 2, 'Box', 'off');

% Link x-axes so zoom is synchronised
linkaxes([ax1, ax2], 'x');

fig.Color = 'w';

% ── Export ────────────────────────────────────────────────────────────────
out_dir = fileparts(output_name);
if ~isempty(out_dir) && ~exist(out_dir, 'dir'),  mkdir(out_dir);  end
set(fig, 'Units', 'centimeters');
fig.Position = [2 2 fig_width_cm fig_height_cm];

exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', ...
    'BackgroundColor', 'white', 'Padding', 0.5);
fprintf('Saved: %s.pdf\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi, ...
    'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
