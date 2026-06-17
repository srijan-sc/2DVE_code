% plot_2DVE.m — 2D vibrational echo contour plots from matrix-format CSVs
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣

% {csv_file, figure_label}  — output goes to HBQ_fig/<label>/plot_<label>
files = {
    'csv/300fs_HBQ.csv',  '300 fs';
    'csv/400fs_HBQ.csv',  '400 fs';
    'csv/800fs_HBQ.csv',  '800 fs';
};

use_absorbance  = true;        % true → convert ΔT/T to ΔA = −log10(1 + ΔT/T)

% Colormap range (asymmetric; keep cmin < 0 < cmax)
caxis_lim       = [-0.1  0.2];

% Contour levels (positive half, as fraction of peak; negatives are mirrored)
clevels     = [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.85 0.9 0.95 1.0];
line_levels = [-0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9];
custom_scalar   = 1.5;
line_width      = 2.2;

% Smoothing / noise gate (set to 0 to disable)
smooth_sigma    = 0;
noise_threshold = 0;

% Figure
fig_width_cm  = 13;
fig_height_cm = 10;
font_size     = 16;
png_dpi       = 300;

% ╚══════════════════════════════════════════════════════════════════════════╝

% ── Font defaults ─────────────────────────────────────────────────────────
set(groot, 'defaultAxesFontName', 'Aptos Body');
set(groot, 'defaultTextFontName', 'Aptos Body');
set(groot, 'defaultAxesColor',    'white');
set(groot, 'defaultAxesXColor',   'black');
set(groot, 'defaultAxesYColor',   'black');
set(groot, 'defaultTextColor',    'black');

% ── Asymmetric colormap ───────────────────────────────────────────────────
cmap_sym = redblue_3(255);
n_total  = size(cmap_sym, 1);
n_blue   = round(n_total * abs(caxis_lim(1)) / diff(caxis_lim));
n_red    = n_total - n_blue;
half     = ceil(n_total / 2);
cmap = [
    interp1(linspace(0,1,half),           cmap_sym(1:half,:),   linspace(0,1,n_blue));
    interp1(linspace(0,1,n_total-half+1), cmap_sym(half:end,:), linspace(0,1,n_red))
];

% ── Batch loop ────────────────────────────────────────────────────────────
for fi = 1:size(files, 1)
    csv_file  = files{fi, 1};
    fig_label = files{fi, 2};
    tag       = strrep(fig_label, ' ', '');          % '300 fs' → '300fs'
    output_name = fullfile('HBQ_fig', tag, ['plot_' tag]);

    % ── Load CSV ──────────────────────────────────────────────────────────
    raw = readcell(csv_file);
    w3  = cell2mat(raw(1, 2:end));          % [1 × Nw3]

    w1_col = raw(2:end, 1);
    w1 = zeros(1, numel(w1_col));
    for i = 1:numel(w1_col)
        tok   = regexp(char(string(w1_col{i})), '[\d.]+$', 'match');
        w1(i) = str2double(tok{1});
    end                                     % [1 × Nw1]

    data = cell2mat(raw(2:end, 2:end));     % [Nw1 × Nw3]
    if use_absorbance
        data = -log10(1 + data);
    end

    % ── Pre-process ───────────────────────────────────────────────────────
    if smooth_sigma > 0
        hw = ceil(3 * smooth_sigma);
        [gx, gy] = meshgrid(-hw:hw, -hw:hw);
        kern = exp(-(gx.^2 + gy.^2) / (2 * smooth_sigma^2));
        data = conv2(data, kern / sum(kern(:)), 'same');
    end

    scalar = max(abs(data(:)));
    if noise_threshold > 0
        data(abs(data) < noise_threshold * scalar) = 0;
    end

    % ── Figure ────────────────────────────────────────────────────────────
    fig = figure('Units',     'centimeters', ...
                 'Position',  [2 2 fig_width_cm fig_height_cm], ...
                 'PaperUnits','centimeters', ...
                 'PaperSize', [fig_width_cm fig_height_cm], ...
                 'Color',     'w');

    cb_label = '\DeltaA';
    if ~use_absorbance,  cb_label = '\DeltaT/T';  end

    plotContourData_sc_v4(w1, w3, data', ...
        'FigureHandle',      fig, ...
        'XLabel',            '\omega_1/2\pic (cm^{-1})', ...
        'YLabel',            '\omega_3/2\pic (cm^{-1})', ...
        'ColorbarLabel',     cb_label, ...
        'ColorMap',          cmap, ...
        'ContourLevels',     clevels, ...
        'ScaleToMax',        true, ...
        'ScalarMultiplier',  scalar, ...
        'ShowContourLines',  false, ...
        'CustomScalar',      custom_scalar, ...
        'SymmetricColorbar', false);

    ax = gca;
    xlim(ax, [min(w1) max(w1)]);
    axis(ax, 'square');
    caxis(ax, caxis_lim);
    colormap(ax, cmap);
    set(ax, 'FontSize', font_size, 'FontWeight', 'bold', ...
            'Color', 'w', 'XColor', 'k', 'YColor', 'k');
    xlabel(get(ax.XLabel, 'String'), 'FontSize', font_size, 'FontWeight', 'bold');
    ylabel(get(ax.YLabel, 'String'), 'FontSize', font_size, 'FontWeight', 'bold');
    title(ax, fig_label,             'FontSize', font_size, 'FontWeight', 'bold');

    cb = ax.Colorbar;
    if ~isempty(cb)
        set(cb, 'FontSize', font_size, 'FontWeight', 'bold', 'Color', 'k');
        cb.Label.FontSize   = font_size;
        cb.Label.FontWeight = 'bold';
        cb.Label.Color      = 'k';
    end

    [X, Y] = meshgrid(w1, w3);
    hold(ax, 'on');
    contour(X, Y, data', custom_scalar * scalar * line_levels, ...
        'LineColor', 'k', 'LineWidth', line_width);
    hold(ax, 'off');

    % ── Export ────────────────────────────────────────────────────────────
    out_dir = fileparts(output_name);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir'),  mkdir(out_dir);  end

    exportgraphics(fig, [output_name '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig, [output_name '.svg'], 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig, [output_name '.png'], 'Resolution', png_dpi,   'BackgroundColor', 'white');
    savefig(fig, [output_name '.fig']);
    fprintf('Saved: %s  (.pdf / .svg / .png / .fig)\n', output_name);

    close(fig);
end
