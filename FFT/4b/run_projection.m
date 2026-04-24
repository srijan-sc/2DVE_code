% run_projection.m — absolute FFT projection for 4b and 5a
cd(fileparts(mfilename('fullpath')));

% ── Settings ─────────────────────────────────────────────────────────────────
freq_range  = [0, 800];    % cm^-1
ref_max_4b  = 0.048143;    % 4b peak — common normalisation
font_size   = 16;
line_width  = 2;
output_name = 'FFT_projection_4b_5a';

% ── Load & project 4b ────────────────────────────────────────────────────────
freq_axis_4b = readmatrix('freq_axis.csv');
FFT_4b       = readmatrix('FFT_magnitude.csv');
mask_4b      = freq_axis_4b >= freq_range(1) & freq_axis_4b <= freq_range(2);
freq_4b      = freq_axis_4b(mask_4b);
proj_4b      = sum(abs(FFT_4b(mask_4b, :)) / ref_max_4b, 2);

% ── Load & project 5a ────────────────────────────────────────────────────────
freq_axis_5a = readmatrix('../5a/freq_axis.csv');
FFT_5a       = readmatrix('../5a/FFT_magnitude.csv');
mask_5a      = freq_axis_5a >= freq_range(1) & freq_axis_5a <= freq_range(2);
freq_5a      = freq_axis_5a(mask_5a);
proj_5a      = sum(abs(FFT_5a(mask_5a, :)) / ref_max_4b, 2);

% ── Font ─────────────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');

% ── Figure ───────────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 14 10], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [14 10], ...
             'Color', 'w');

plot(freq_4b, proj_4b, '-', 'Color', [1 0.6 0.7], 'LineWidth', line_width, 'DisplayName', 'Early time'); hold on;
plot(freq_5a, proj_5a, '-', 'Color', [0 0 0],     'LineWidth', line_width/2, 'DisplayName', 'Later time'); hold off;

xlabel('\omega_2/2\pic (cm^{-1})', 'FontSize', font_size, 'FontWeight', 'bold');
ylabel('Projected |FFT| (arb.)',    'FontSize', font_size, 'FontWeight', 'bold');
xlim(freq_range);
legend('FontSize', font_size - 2, 'Box', 'off');
set(gca, 'FontSize', font_size, 'FontWeight', 'bold');
box on;

% ── Export ───────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector');
exportgraphics(fig, [output_name '.png'], 'Resolution', 300);
savefig(fig, [output_name '.fig']);
fprintf('Saved: %s  (.svg / .png / .fig)\n', output_name);
