% run_lineplot.m — line plot of spectral slices at a fixed w2 (vibrational) frequency
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
% ║  Data files and legend labels                                           ║
data_files  = {'cut_data_2500.csv', 'cut_data_2650.csv', 'cut_data_2700.csv', 'cut_data_2950.csv'};
line_labels = {'2500 cm^{-1}', '2650 cm^{-1}', '2700 cm^{-1}', '2950 cm^{-1}'};
% ║                                                                         ║
% ║  Slice position on the w2 (vibrational) axis                           ║
cut_w2      = 248;   % cm^{-1} — closest point in w2 will be used
% ║                                                                         ║
% ║  Stacking & smoothing                                                   ║
offset_step  = 0;     % 0 = auto (110% of max peak-to-peak); set manually to override
smooth_sigma = 1.0;   % Gaussian smooth radius in pixels (0 = off)
fill_alpha   = 0.20;  % transparency of the filled area under each curve
% ║                                                                         ║
% ║  Figure labels & export                                                 ║
fig_label    = sprintf('Spectral Intensity at %d cm^{-1}', cut_w2);
output_name  = sprintf('plot_linecut_%d', cut_w2);
% ║                                                                         ║
% ║  Figure size & styling                                                  ║
fig_width_cm  = 12;   % cm
fig_height_cm = 10;   % cm
png_dpi       = 300;
font_size     = 16;
line_width    = 1.5;
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Okabe-Ito colormap (colorblind-safe, publication standard) ───────────────
okabe = [  0,  114,  178;   % blue
         230,  159,    0;   % orange
           0,  158,  115;   % bluish green
         213,   94,    0] / 255;  % vermilion

% ── Data ─────────────────────────────────────────────────────────────────────
w2 = csvread('w2.csv');   % 1×516  LF
w3 = csvread('w3.csv');   % 1×451  electronic detection axis

[~, idx] = min(abs(w2 - cut_w2));
fprintf('Cutting at w2 = %.1f cm^{-1} (index %d, actual = %.2f cm^{-1})\n', ...
    cut_w2, idx, w2(idx));

% ── Pre-load & smooth all slices; compute auto offset ────────────────────────
slices = zeros(numel(w3), numel(data_files));
for i = 1:numel(data_files)
    mat   = csvread(data_files{i});
    s     = mat(:, idx);
    if smooth_sigma > 0
        k      = ceil(3 * smooth_sigma);
        kernel = exp(-((-k:k).^2) / (2 * smooth_sigma^2));
        kernel = kernel / sum(kernel);
        s      = conv(s, kernel(:), 'same');
    end
    slices(:, i) = s;
end

% Auto offset: each curve gets headroom = 110% of the max peak-to-peak range
if offset_step <= 0
    ranges     = max(slices) - min(slices);
    offset_step = max(ranges) * 1.1;
    fprintf('Auto offset_step = %.3f\n', offset_step);
end

% ── Font ─────────────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

% ── Figure & axes ────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', 'w');

ax = axes(fig);
set(ax, 'Color', 'w');
hold(ax, 'on');

for i = 1:numel(data_files)
    offset  = (i - 1) * offset_step;
    color   = okabe(i, :);
    w3c     = w3(:);
    slicec  = slices(:, i) + offset;
    base    = offset * ones(size(w3c));

    % Fill: clip fill floor to baseline (no bleed below)
    fill_top = slicec;
    fill_bot = max(slicec, base);   % only fill above baseline
    fill_bot(slicec >= base) = base(slicec >= base);

    fill(ax, [w3c; flipud(w3c)], [slicec; flipud(base)], color, ...
        'FaceAlpha', fill_alpha, 'EdgeColor', 'none');

    % Line on top
    plot(ax, w3c, slicec, 'Color', color, 'LineWidth', line_width, ...
        'DisplayName', line_labels{i});
end

hold(ax, 'off');

% ── Formatting ───────────────────────────────────────────────────────────────
set(ax, 'FontSize', font_size, 'FontWeight', 'bold');
xlabel(ax, '\omega_2/2\pic (cm^{-1})', 'FontSize', font_size, 'FontWeight', 'bold');
title(ax, fig_label, 'FontSize', font_size);

% Y-axis: remove ticks (values are offset-stacked, not absolute)
set(ax, 'YTick', [], 'YColor', 'k');
ylabel(ax, '');   % no y-label; scale bar serves that purpose

% Legend only for the data line handles (captured before scale bar is drawn)
ch = get(ax, 'Children');
line_handles = ch(strcmp(get(ch, 'Type'), 'line'));
leg = legend(ax, flipud(line_handles), fliplr(line_labels), ...
    'Location', 'northoutside', 'FontSize', font_size - 6, ...
    'Orientation', 'horizontal');
leg.ItemTokenSize = [12, 9];   % shorter line swatch

% % Scale bar — drawn after legend so it's excluded from legend entries
% scale_bar_val = round(offset_step * 0.8, 1);   % mOD
% xl = xlim(ax);  yl = ylim(ax);
% sb_x  = xl(1) - 0.01*(xl(2)-xl(1));   % just left of axis
% sb_y0 = yl(1) + 0.05*(yl(2)-yl(1));   % near bottom
% sb_y1 = sb_y0 + scale_bar_val;
% line(ax, [sb_x sb_x], [sb_y0 sb_y1], 'Color','k', 'LineWidth', 2, ...
%     'Clipping','off', 'HandleVisibility','off');
% text(ax, sb_x - 0.005*(xl(2)-xl(1)), (sb_y0+sb_y1)/2, ...
%     sprintf('%g mOD', scale_bar_val), ...
%     'HorizontalAlignment','right', 'VerticalAlignment','middle', ...
%     'FontSize', font_size-6, 'FontWeight','bold', 'Clipping','off');

box(ax, 'on');

% ── Export ───────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector');
fprintf('Saved: %s.svg\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi);
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
