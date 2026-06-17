% plot_projection.m — w3 projection (sum |data| along w1) for multiple time points
cd(fileparts(mfilename('fullpath')));

% ── Settings ─────────────────────────────────────────────────────────────────
files      = {'300fs_HBQ.csv', '500fs_HBQ.csv', '800fs_HBQ.csv'};
labels     = {'300 fs', '500 fs', '800 fs'};
colors     = {[0.122 0.306 0.631], ...   % deep blue
              [0.835 0.243 0.310], ...   % crimson
              [0.145 0.565 0.380]};      % forest green
font_size  = 16;
line_width = 2.2;
output_name = 'projection_w3';

% ── Load axes ────────────────────────────────────────────────────────────────
w1 = readmatrix('w1.csv');
w3 = readmatrix('w3.csv');

% ── Groot defaults ───────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');
set(groot, 'defaultAxesColor',   'white');
set(groot, 'defaultAxesXColor',  'black');
set(groot, 'defaultAxesYColor',  'black');
set(groot, 'defaultTextColor',   'black');

% ── Figure ───────────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 20 13], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [20 13], ...
             'Color', [1 1 1]);

ax = axes('Parent', fig);
hold(ax, 'on');

for k = 1:numel(files)
    raw  = readmatrix(files{k});
    data = raw(2:end, 2:end);
    proj = sum(abs(data), 1);
    plot(ax, w3, proj, '-', ...
        'Color', colors{k}, ...
        'LineWidth', line_width, ...
        'DisplayName', labels{k});
end

hold(ax, 'off');

% ── Axes styling ─────────────────────────────────────────────────────────────
xlim(ax, [24100 25000]);
xlabel(ax, '\omega_3 / 2\pic (cm^{-1})', 'FontSize', font_size, 'FontWeight', 'bold', 'FontName', 'Aptos Body');
ylabel(ax, 'Intensity (a.u.)',   'FontSize', font_size, 'FontWeight', 'bold', 'FontName', 'Aptos Body');

set(ax, ...
    'FontSize',       font_size, ...
    'FontWeight',     'bold', ...
    'FontName',       'Aptos Body', ...
    'TickDir',        'in', ...
    'TickLength',     [0.015 0.015], ...
    'XMinorTick',     'on', ...
    'YMinorTick',     'on', ...
    'Box',            'on', ...
    'Color',          'white', ...
    'XColor',         'black', ...
    'YColor',         'black');

% Sparse minor ticks — one per major interval
yticks_major = get(ax, 'YTick');
if numel(yticks_major) >= 2
    step = yticks_major(2) - yticks_major(1);
    ax.YAxis.MinorTickValues = yticks_major(1:end-1) + step/2;
end
xticks_major = get(ax, 'XTick');
if numel(xticks_major) >= 2
    step = xticks_major(2) - xticks_major(1);
    ax.XAxis.MinorTickValues = xticks_major(1:end-1) + step/2;
end

% Legend — bottom-left where data is sparse
lg = legend(ax, 'FontSize', font_size - 2, 'Box', 'off', ...
    'TextColor', 'black', 'Location', 'northwest');
lg.ItemTokenSize = [18 9];

% ── Export ───────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.pdf\n', output_name);

exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.svg\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
