% VE3D_schematic.m — illustrative 2DVE blob (no real data)
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                         USER SETTINGS                                   ║
% ╠══════════════════════════════════════════════════════════════════════════╣
w1_center  = 2743;    % cm⁻¹ — blob centre along ω₁  (mid of 2492–2994)
w3_center  = 24557;   % cm⁻¹ — blob centre along ω₃  (mid of 24024–25089)
sigma_w1   = 350;     % cm⁻¹ — wide enough to fill the ω₁ window
sigma_w3   = 750;     % cm⁻¹ — wide enough to fill the ω₃ window
n_clevels  = 3;       % very few levels → smooth featureless look
output_name = 'schematic_2DVE';
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Axes (match real data window) ─────────────────────────────────────────
w1 = linspace(2492, 2994, 200);
w3 = linspace(24024, 25089, 200);
[W1, W3] = meshgrid(w1, w3);

% ── Synthetic blob ─────────────────────────────────────────────────────────
data = exp( -( (W1 - w1_center).^2 / (2*sigma_w1^2) ...
             + (W3 - w3_center).^2 / (2*sigma_w3^2) ) );

% ── Colormap: white → red (positive-only) ─────────────────────────────────
n_colors = 256;
cmap = [linspace(1, 0.85, n_colors)', ...
        linspace(1, 0.07, n_colors)', ...
        linspace(1, 0.07, n_colors)'];

% ── Figure ─────────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

fig = figure('Units', 'centimeters', 'Position', [2 2 13 10], ...
             'Color', [1 1 1]);

levels = linspace(1/n_clevels, 1, n_clevels);

contourf(w1, w3, data, levels, 'LineStyle', 'none');
colormap(cmap);
clim([0 1]);

hold on;
% one thin contour line at half-max for definition
contour(w1, w3, data, [0.5 0.5], 'LineColor', [0.6 0 0], 'LineWidth', 1.2);
hold off;

ax = gca;
set(ax, 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'white', ...
        'XColor', 'black', 'YColor', 'black', 'LineWidth', 1.2);
xlabel('\omega_1/2\pic (cm^{-1})', 'FontSize', 16, 'FontWeight', 'bold');
ylabel('\omega_3/2\pic (cm^{-1})', 'FontSize', 16, 'FontWeight', 'bold');
xlim([min(w1) max(w1)]);
ylim([min(w3) max(w3)]);

cb = colorbar;
set(cb, 'FontSize', 14, 'FontWeight', 'bold');
cb.Label.String   = '\DeltaA (norm.)';
cb.Label.FontSize = 14;
cb.Label.FontWeight = 'bold';
cb.Ticks = [0 0.5 1];

% ── Export ─────────────────────────────────────────────────────────────────
ax.Toolbar = [];
exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
exportgraphics(fig, [output_name '.png'], 'Resolution', 300, 'BackgroundColor', 'white');
fprintf('Saved: %s.pdf / .png\n', output_name);
