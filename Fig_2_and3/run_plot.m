% run_plot.m — contour plot of difference data (file_a - file_b)
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
% ║  Data                                                                   ║
if ~exist('csv_file','var'),       csv_file       = '500fs_HBQ.csv'; end
if ~exist('fig_label','var'),      fig_label      = '500 fs'; end
if ~exist('output_name','var'),    output_name    = 'plot_500fs_HBQ'; end
if ~exist('use_absorbance','var'), use_absorbance = true; end
raw = readcell(csv_file);
% ║                                                                         ║
% ║  Contour & scaling                                                      ║
clevels      = [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.85 0.9 0.95 1.0]; % positive half — SymmetricColorbar mirrors to negatives
% line_levels  = [-0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9];  % 500 fs (18 lines)
line_levels  = [-0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9];              % 300/400/800 fs (15 lines)
custom_scalar   = 1.5;          % vertical stretch on contour levels
line_width      = 2.2;          % contour line thickness
% ║                                                                         ║
% ║  Noise / smoothing                                                      ║
noise_threshold = 0;    % zero data below this fraction of peak (0 = off)
smooth_sigma    = 0;    % Gaussian smooth radius in pixels (0 = off)
white_band      = 0.02; % fraction of colormap on each side of zero forced to white
% ║                                                                         ║
% ║  Figure size & export                                                   ║
fig_width_cm    = 13;    % cm
fig_height_cm   = 10;    % cm
png_dpi         = 300;
font_size       = 16;    % axis tick & label font size
% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Data ─────────────────────────────────────────────────────────────────────


% w3: first row, columns 2 onward
w3 = cell2mat(raw(1, 2:end));   % 1 x N row vector

% w1: first column, rows 2 onward — cells are like "2→2592.63594"
w1_col = raw(2:end, 1);
w1 = zeros(length(w1_col), 1);
for i = 1:length(w1_col)
    s = char(string(w1_col{i}));
    tok = regexp(s, '[\d.]+$', 'match');
    w1(i) = str2double(tok{1});
end
w1 = w1';   % 1 x M row vector

% data: rows 2 onward, columns 2 onward (size: M x N)
raw_data = cell2mat(raw(2:end, 2:end));
if use_absorbance
    integrated_data = -log10(1 + raw_data);   % ΔA = −log10(T/T0)
else
    integrated_data = raw_data;                % ΔT/T
end

% ── Colormap ─────────────────────────────────────────────────────────────────
% Asymmetric blue-white-red: blue covers negative range, red covers positive
cmin_val = -0.1;
cmax_val =  0.2;
n_total  = 255;
n_blue   = round(n_total * abs(cmin_val) / (cmax_val - cmin_val));  % ~85
n_red    = n_total - n_blue;                                          % ~170

cmap_sym  = redblue_3(255);
half      = ceil(size(cmap_sym,1) / 2);
cmap_blue = interp1(linspace(0,1,half),                      cmap_sym(1:half,:),   linspace(0,1,n_blue));
cmap_red  = interp1(linspace(0,1,size(cmap_sym,1)-half+1),  cmap_sym(half:end,:), linspace(0,1,n_red));
cmap = [cmap_blue; cmap_red];

% ── Pre-process data ─────────────────────────────────────────────────────────
data = integrated_data;

if smooth_sigma > 0
    k = ceil(3 * smooth_sigma);
    [gx, gy] = meshgrid(-k:k, -k:k);
    kernel = exp(-(gx.^2 + gy.^2) / (2 * smooth_sigma^2));
    kernel = kernel / sum(kernel(:));
    data = conv2(data, kernel, 'same');
end

scalar    = max(max(abs(data)));
threshold = noise_threshold * scalar;
data(abs(data) < threshold) = 0;

if use_absorbance
    conditional_label = '\DeltaA';
else
    conditional_label = '\DeltaT/T';
end

% ── Font ─────────────────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');
set(groot, 'defaultAxesColor',   'white');
set(groot, 'defaultAxesXColor',  'black');
set(groot, 'defaultAxesYColor',  'black');
set(groot, 'defaultTextColor',   'black');

% ── Figure & axes ────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', [1 1 1]);

% Color fill with all clevels, no lines (lines added manually below)
plotContourData_sc_v4(w1, w3, data', ...
    'FigureHandle',      fig, ...
    'XLabel',            '\omega_1/2\pic (cm^{-1})', ...
    'YLabel',            '\omega_3/2\pic (cm^{-1})', ...
    'ColorbarLabel',     conditional_label, ...
    'ColorMap',          cmap, ...
    'ContourLevels',     clevels, ...
    'ScaleToMax',        true, ...
    'ScalarMultiplier',  scalar, ...
    'ShowContourLines',  false, ...
    'CustomScalar',      custom_scalar, ...
    'SymmetricColorbar', false);
xlim([min(w1) max(w1)]);
ax = gca;
ax.Color      = [1 1 1];
ax.XColor     = 'black';
ax.YColor     = 'black';
fig.Color     = [1 1 1];
axis(ax, 'square');
set(ax, 'FontSize', font_size, 'FontWeight', 'bold');
xlabel(get(ax.XLabel,'String'), 'FontSize', font_size, 'FontWeight', 'bold');
ylabel(get(ax.YLabel,'String'), 'FontSize', font_size, 'FontWeight', 'bold');
% Force caxis to match contour level range so zero = white
caxis(ax, [-0.1  0.2]);
colormap(ax, cmap);
cb = ax.Colorbar;
if ~isempty(cb)
    set(cb, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'black');
    cb.Label.FontSize   = font_size;
    cb.Label.FontWeight = 'bold';
    cb.Label.Color      = 'black';
end

% Overlay contour lines only at the specified levels
[X, Y] = meshgrid(w1, w3);
actual_line_levels = custom_scalar * scalar * line_levels;
hold on;
contour(X, Y, data', actual_line_levels, ...
    'LineColor', 'k', 'LineWidth', line_width);
hold off;

title(fig_label, 'FontSize', font_size);

% ── Export ───────────────────────────────────────────────────────────────────
exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi);
fprintf('Saved: %s.png\n', output_name);

exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector');
fprintf('Saved: %s.svg\n', output_name);

savefig(fig, [output_name '.fig']);
fprintf('Saved: %s.fig\n', output_name);
