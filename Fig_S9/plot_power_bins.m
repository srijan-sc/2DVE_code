% plot_power_bins.m — MCT power over sequential bins (sheet 2)
cd(fileparts(mfilename('fullpath')));

% ── Settings ─────────────────────────────────────────────────────────────────
output_name = 'plot_power_bins';
font_size   = 16;
line_width  = 1.2;

color = [0.000 0.447 0.698];   % blue

% ── Load data ─────────────────────────────────────────────────────────────────
T = readtable('power_t1_MCT.xlsx', 'Sheet', 2, 'VariableNamingRule', 'preserve');
power = T{:,1};
bins  = (1:numel(power))';

% ── Font defaults ─────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');
set(groot, 'defaultAxesColor',   'white');
set(groot, 'defaultAxesXColor',  'black');
set(groot, 'defaultAxesYColor',  'black');
set(groot, 'defaultTextColor',   'black');

% ── Figure ────────────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 20 11], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [20 11], ...
             'Color', [1 1 1]);

ax = axes('Parent', fig);
plot(ax, bins, power, '-', 'Color', color, 'LineWidth', line_width);

% ── Axes styling ──────────────────────────────────────────────────────────────
xlabel(ax, 'Bin',             'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
ylabel(ax, 'MCT Power (a.u.)', 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');

set(ax, ...
    'FontSize',   font_size, ...
    'FontWeight', 'bold', ...
    'FontName',   'Aptos Body', ...
    'TickDir',    'in', ...
    'TickLength', [0.015 0.015], ...
    'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'Box',        'on', ...
    'Color',      'white', ...
    'XColor',     'black', ...
    'YColor',     'black');

xticks_major = get(ax, 'XTick');
if numel(xticks_major) >= 2
    step = xticks_major(2) - xticks_major(1);
    ax.XAxis.MinorTickValues = xticks_major(1:end-1) + step/2;
end
yticks_major = get(ax, 'YTick');
if numel(yticks_major) >= 2
    step = yticks_major(2) - yticks_major(1);
    ax.YAxis.MinorTickValues = yticks_major(1:end-1) + step/2;
end

xlim(ax, [1 numel(power)]);

% vertical marker at bin 400
yL = ylim(ax);
hold(ax, 'on');
plot(ax, [400 400], yL, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5);
hold(ax, 'off');
ylim(ax, yL);

% ── Export ────────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.pdf\n', output_name);

exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.svg\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
