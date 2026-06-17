% plot_fft.m — FFT spectra of HBQ and DMSO, publication quality
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
fft_file       = 'FFT_data.csv';
output_name    = 'plot_fft';

freq_range     = [0 1200];     % cm⁻¹ display range ([] = auto)
smooth_sigma   = 1.5;          % Gaussian smooth in data points (0 = off)

fig_width_cm   = 14;
fig_height_cm  = 9;
png_dpi        = 300;
font_size      = 16;
line_width     = 2;

% High-impact vivid palette — strong contrast, print & screen safe
color_HBQ  = [0.00, 0.45, 0.70];   % vivid cerulean blue   (IBM / Wong)
color_DMSO = [0.84, 0.06, 0.11];   % vivid crimson red
% ╚══════════════════════════════════════════════════════════════════════════╝

set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

% ── Load data ─────────────────────────────────────────────────────────────
raw  = readmatrix(fft_file);        % skip header automatically
freq = raw(:, 1);                   % Freq_ax column
hbq  = raw(:, 2);                   % HBQ column
dmso = raw(:, 4);                   % dmso column

% ── Optional frequency crop ───────────────────────────────────────────────
if ~isempty(freq_range)
    mask = freq >= freq_range(1) & freq <= freq_range(2);
    freq = freq(mask);
    hbq  = hbq(mask);
    dmso = dmso(mask);
end

% ── Optional Gaussian smooth ──────────────────────────────────────────────
if smooth_sigma > 0
    k_half = ceil(3 * smooth_sigma);
    x_k    = -k_half:k_half;
    kernel = exp(-x_k.^2 / (2 * smooth_sigma^2));
    kernel = kernel / sum(kernel);
    hbq  = conv(hbq,  kernel, 'same');
    dmso = conv(dmso, kernel, 'same');
end

y_label = 'FFT Intensity (a.u.)';

% ── Figure ────────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', 'w');
ax = axes('Parent', fig, 'Color', 'w');
hold(ax, 'on');

plot(ax, freq, dmso, '-', ...
    'Color', color_DMSO, 'LineWidth', line_width, 'DisplayName', 'DMSO');
plot(ax, freq, hbq,  '-', ...
    'Color', color_HBQ,  'LineWidth', line_width, 'DisplayName', 'HBQ');

hold(ax, 'off');

% ── Axes formatting ───────────────────────────────────────────────────────
if ~isempty(freq_range)
    xlim(ax, freq_range);
end
ylim(ax, [0 Inf]);

xlabel(ax, '\omega/2\pic (cm^{-1})', 'FontSize', font_size, 'FontWeight', 'bold');
ylabel(ax, y_label,                  'FontSize', font_size, 'FontWeight', 'bold');
set(ax, 'FontSize', font_size, 'FontWeight', 'bold', 'YColor', 'k');
box(ax, 'on');

legend(ax, 'Location', 'best', 'FontSize', font_size - 2, 'Box', 'off');

fig.Color = 'w';

% ── Export ────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.svg\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi, 'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
