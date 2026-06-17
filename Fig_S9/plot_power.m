% plot_power.m — MCT power vs t1 for all datasets
cd(fileparts(mfilename('fullpath')));

% ── Settings ─────────────────────────────────────────────────────────────────
output_name = 'plot_power_MCT';
font_size   = 16;
line_width  = 2.5;
marker_size = 5;

% Wong/Tol colorblind-safe palette
colors = {[0.000 0.447 0.698], ...   % blue
          [0.835 0.369 0.000], ...   % vermillion
          [0.000 0.620 0.451], ...   % bluish green
          [0.902 0.624 0.000], ...   % golden yellow
          [0.800 0.475 0.655]};      % reddish purple

% ── Load data ─────────────────────────────────────────────────────────────────
filepath = 'power_t1_MCT.xlsx';
T = readtable(filepath, 'Sheet', 1, 'VariableNamingRule', 'preserve');

sets(1).t    = T.('time(fs)');
sets(1).p    = T.('power');
sets(1).sd   = T.('SD');
sets(1).name = 'Set 1';

sets(2).t    = T.('time(fs)_1');
sets(2).p    = T.('power_1');
sets(2).sd   = T.('SD_1');
sets(2).name = 'Set 2';

sets(3).t    = T.('time(fs)_2');
sets(3).p    = T.('power_2');
sets(3).sd   = T.('SD_2');
sets(3).name = 'Set 3';

sets(4).t    = T.('time(fs)_3');
sets(4).p    = T.('power_3');
sets(4).sd   = T.('SD_3');
sets(4).name = 'Set 4';

sets(5).t    = T.('time(fs)_4');
sets(5).p    = T.('power_4');
sets(5).sd   = T.('SD_4');
sets(5).name = 'Set 5';

% ── Font defaults ─────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');
set(groot, 'defaultAxesColor',   'white');
set(groot, 'defaultAxesXColor',  'black');
set(groot, 'defaultAxesYColor',  'black');
set(groot, 'defaultTextColor',   'black');

% ── Figure ────────────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 20 13], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [20 13], ...
             'Color', [1 1 1]);

ax = axes('Parent', fig);
hold(ax, 'on');

for k = 1:numel(sets)
    t  = sets(k).t;
    p  = sets(k).p;
    sd = sets(k).sd;

    % remove NaN rows
    mask = ~isnan(t) & ~isnan(p) & ~isnan(sd);
    t  = t(mask);
    p  = p(mask);
    sd = sd(mask);

    % shaded SD band
    fill(ax, [t; flipud(t)], [p+sd; flipud(p-sd)], colors{k}, ...
        'FaceAlpha', 0.20, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    % line + markers on top
    plot(ax, t, p, '-o', ...
        'Color',           colors{k}, ...
        'MarkerFaceColor', colors{k}, ...
        'MarkerSize',      marker_size, ...
        'LineWidth',       line_width, ...
        'DisplayName',     sets(k).name);
end

hold(ax, 'off');

% ── Axes styling ──────────────────────────────────────────────────────────────
xlabel(ax, '\tau_2  (fs)', 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
ylabel(ax, 'MCT Power (a.u.)',  'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');

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

% Sparse minor ticks — one per major interval
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

lg = legend(ax, 'FontSize', font_size - 2, 'Box', 'off', ...
    'TextColor', 'black', 'Location', 'best');
lg.ItemTokenSize = [18 9];

% ── Export ────────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.pdf\n', output_name);

exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.svg\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
