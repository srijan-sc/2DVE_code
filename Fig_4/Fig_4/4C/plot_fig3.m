% =========================================================
% USER OPTIONS
smooth_on     = true;   % true = smooth 230 & 248, false = raw
smooth_window = 5;      % smoothing window (odd number, larger = smoother)
% =========================================================

% Read data (skip first row which is comment/header)
data = readtable('projection_plot.xlsx', 'VariableNamingRule', 'preserve');

ftir_freq  = data{:,1};
ftir_int   = data{:,2};
w3_freq    = data{:,3};
mode_230   = data{:,4};
mode_248   = data{:,5};

% Figure setup
fig = figure;
set(fig, 'Units', 'inches', 'Position', [1 1 3.5 2.5], ...
    'Color', 'white', 'PaperPositionMode', 'auto');

% Left y-axis: FTIR
yyaxis left
plot(ftir_freq, ftir_int, 'Color', [0.25 0.25 0.25], 'LineWidth', 1.5);
ylabel('FTIR intensity (a.u)', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black');
ylim([0.3 1.0]);
ax = gca;
ax.YColor = 'black';

% Apply optional smoothing
if smooth_on
    mode_230 = smooth(mode_230, smooth_window);
    mode_248 = smooth(mode_248, smooth_window);
end

% Right y-axis: projections
yyaxis right
hold on
% Marker spacing: show a ball every N points
N = 8;
idx = 1:N:length(w3_freq);

plot(w3_freq, mode_230, '-o', 'Color', [1 0 1], 'LineWidth', 1.5, ...
    'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', [1 0 1], ...
    'MarkerIndices', idx);

plot(w3_freq, mode_248, '-o', 'Color', [0 0.6 0], 'LineWidth', 1.5, ...
    'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', [0 0.6 0], ...
    'MarkerIndices', idx);

ylabel('LF projection (a.u)', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black');
ylim([0.4 1.05]);
ax.YColor = 'black';
hold off

% Common axes settings
xlim([2500 3000]);
xlabel('Frequency (cm^{-1})', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'black');
ax.FontSize    = 10;
ax.FontName    = 'Arial';
ax.FontWeight  = 'bold';
ax.LineWidth   = 1.2;
ax.TickDir     = 'in';
ax.TickLength  = [0.02 0.02];
ax.Box         = 'on';
ax.Color       = 'white';
ax.XColor      = 'black';

% Legend
legend({'FTIR', '230', '248'}, 'Location', 'northeast', ...
    'FontSize', 9, 'FontWeight', 'bold', 'Box', 'off', 'TextColor', 'black');

% Export
exportgraphics(fig, 'figure.png', 'Resolution', 300, 'BackgroundColor', 'white');
print(fig, 'figure.svg', '-dsvg');
disp('Saved figure.png and figure.svg');
