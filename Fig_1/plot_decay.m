% plot_decay.m — 1D decay data + bi-exponential fit, publication quality
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
decay_file     = '1D decay.csv';
output_name    = 'plot_decay';

t_shift        = 0.05;         % ps — positive shifts t→earlier (peak at −0.05 ps → t=0)
t_range        = [0 4];        % ps — plot/fit window AFTER shift
fit_start      = 0.0;          % ps — fit from t=0 to capture early time

% Bi-exponential model (normalised data): A1*exp(-t/tau1) + A2*exp(-t/tau2) + offset
% Initial guesses [A1, tau1, A2, tau2, offset]
x0             = [0.40,  0.15,  0.55,  1.8,  0.05];
lb             = [0,     0.01,  0,     0.2, -0.1];
ub             = [1.0,   0.5,   1.0,   5.0,  0.3];

fig_width_cm   = 14;
fig_height_cm  = 9;
png_dpi        = 300;
font_size      = 16;
line_width     = 2;

% Colors
color_data = [0.90, 0.40, 0.55];   % rose pink  — data markers
color_fit  = [0.80, 0.02, 0.13];   % vivid crimson — fit line
% ╚══════════════════════════════════════════════════════════════════════════╝

set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

% ── Load, shift & crop data ───────────────────────────────────────────────
raw  = readmatrix(decay_file);
t    = raw(:, 1) + t_shift;   % apply time-zero correction
sig  = raw(:, 2);

mask_plot = t >= t_range(1) & t <= t_range(2);
t_plot    = t(mask_plot);
sig_plot  = sig(mask_plot);

% ── Normalise to peak within plot window ──────────────────────────────────
sig_max  = max(sig_plot);
sig_plot = sig_plot / sig_max;

% ── Bi-exponential fit on normalised data ─────────────────────────────────
mask_fit  = t >= fit_start & t <= t_range(2);
t_fit     = t(mask_fit);
sig_fit   = sig(mask_fit) / sig_max;   % same normalisation

biexp = @(p, x) p(1).*exp(-x./p(2)) + p(3).*exp(-x./p(4)) + p(5);

opts = optimoptions('lsqcurvefit', 'Display', 'off');
p_opt = lsqcurvefit(biexp, x0, t_fit, sig_fit, lb, ub, opts);

t_fine   = linspace(t_range(1), t_range(2), 2000);
fit_line = biexp(p_opt, t_fine);

fprintf('\n--- Fit results ---\n');
fprintf('A1 = %.4f,  tau1 = %.3f ps\n', p_opt(1), p_opt(2));
fprintf('A2 = %.4f,  tau2 = %.3f ps\n', p_opt(3), p_opt(4));
fprintf('offset = %.5f\n\n', p_opt(5));

% ── Figure ────────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', 'w');
ax = axes('Parent', fig, 'Color', 'w');
hold(ax, 'on');

% Data — solid line
plot(ax, t_plot, sig_plot, '-', ...
    'Color',       color_data, ...
    'LineWidth',   line_width, ...
    'DisplayName', 'HBQ');

% Fit — solid line on top
plot(ax, t_fine, fit_line, '-', ...
    'Color',       color_fit, ...
    'LineWidth',   line_width + 0.5, ...
    'DisplayName', 'Fitted data');

hold(ax, 'off');

% ── Axes formatting ───────────────────────────────────────────────────────
xlim(ax, t_range);

xlabel(ax, 'Delay time (ps)',     'FontSize', font_size, 'FontWeight', 'bold');
ylabel(ax, 'Normalised \DeltaA/A (a.u.)', 'FontSize', font_size, 'FontWeight', 'bold');
set(ax, 'FontSize', font_size, 'FontWeight', 'bold');
ax.XColor = 'black';
ax.YColor = 'black';
box(ax, 'on');

lg_main = legend(ax, 'Location', 'northwest', 'FontSize', font_size - 2, 'Box', 'off', 'NumColumns', 1);
set(lg_main, 'TextColor', 'black');

% ── FFT inset ─────────────────────────────────────────────────────────────
fft_raw  = readmatrix('FFT_data.csv');
fft_freq = fft_raw(:, 1);
fft_hbq  = fft_raw(:, 2);
fft_dmso = fft_raw(:, 4);

% Gaussian smooth
smooth_sigma_fft = 1.5;
k_half = ceil(3 * smooth_sigma_fft);
x_k    = -k_half:k_half;
kernel = exp(-x_k.^2 / (2 * smooth_sigma_fft^2));
kernel = kernel / sum(kernel);
fft_hbq  = conv(fft_hbq,  kernel, 'same');
fft_dmso = conv(fft_dmso, kernel, 'same');

% Crop to 0–600 cm⁻¹
fft_mask = fft_freq >= 0 & fft_freq <= 600;
fft_freq = fft_freq(fft_mask);
fft_hbq  = fft_hbq(fft_mask);
fft_dmso = fft_dmso(fft_mask);

% Inset axes
ax_in = axes('Parent', fig, ...
    'Position', [0.56 0.55 0.32 0.32], ...   % moved inset further left: [left bottom width height]
    'Color', 'w', 'Box', 'on', ...
    'XColor', 'black', 'YColor', 'black', ...
    'FontName', 'Aptos Body', 'FontSize', font_size - 4, 'FontWeight', 'bold');
hold(ax_in, 'on');
plot(ax_in, fft_freq, fft_dmso, '-', ...
    'Color', [0.13, 0.55, 0.13], 'LineWidth', line_width - 0.5, 'DisplayName', 'DMSO');
plot(ax_in, fft_freq, fft_hbq,  '-', ...
    'Color', [0 0 0],            'LineWidth', line_width - 0.5, 'DisplayName', 'HBQ');
hold(ax_in, 'off');
xlim(ax_in, [0 600]);
ylim(ax_in, [0 Inf]);
xlabel(ax_in, '\omega_2/2\pic (cm^{-1})', 'FontSize', font_size - 5, 'FontWeight', 'bold', 'Color', 'black');
ylabel(ax_in, 'FFT Int. (a.u.)',          'FontSize', font_size - 5, 'FontWeight', 'bold', 'Color', 'black');
lg = legend(ax_in, 'Location', 'northeast', 'FontSize', font_size - 6, 'Box', 'off', 'NumColumns', 1);
set(lg, 'TextColor', 'black');

fig.Color = 'w';

% ── Export ────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
fprintf('Saved: %s.pdf\n', output_name);

exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi, 'BackgroundColor', 'white');
fprintf('Saved: %s.png\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
