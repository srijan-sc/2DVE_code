% plot_sphere_panel.m — 4-panel figure with Phong-shaded gradient spheres
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
output_dir    = 'sphere_fig';
fig_width_cm  = 20;
fig_height_cm = 10;
png_dpi       = 300;
N             = 500;            % sphere grid resolution

bg_color      = [0.97 0.95 0.93];   % warm cream
divider_color = [0.08 0.22 0.35];   % dark teal
divider_lw    = 2.5;

sphere_r      = 0.30;           % sphere radius as fraction of panel height
sphere_y      = [0.33 0.47 0.60 0.74];   % diagonal low → high

% Red shades weak → strong (redblue palette)
red_peak = [
    1.00, 0.80, 0.80;
    0.96, 0.52, 0.52;
    0.84, 0.18, 0.18;
    0.65, 0.00, 0.05;
];

% Phong parameters
light_dir  = [-0.50, -0.55, 1.00];
k_ambient  = 0.10;
k_diffuse  = 0.65;
k_specular = 0.55;
shininess  = 38;
% ╚══════════════════════════════════════════════════════════════════════════╝

if ~exist(output_dir, 'dir'), mkdir(output_dir); end

% ── Sphere geometry & lighting (shared) ───────────────────────────────────
[X, Y] = meshgrid(linspace(-1,1,N), linspace(-1,1,N));
R2   = X.^2 + Y.^2;
mask = R2 < 1;
Nz   = sqrt(max(0, 1 - R2));

Lv     = light_dir / norm(light_dir);
dot_LN = X*Lv(1) + Y*Lv(2) + Nz*Lv(3);
Id     = max(0, dot_LN);
Rz     = 2*dot_LN.*Nz - Lv(3);
Is     = max(0, Rz).^shininess;
I      = k_ambient + k_diffuse*Id + k_specular*Is;

% ── Figure ────────────────────────────────────────────────────────────────
fig = figure('Units', 'centimeters', ...
             'Position', [2 2 fig_width_cm fig_height_cm], ...
             'PaperUnits', 'centimeters', ...
             'PaperSize',  [fig_width_cm fig_height_cm], ...
             'Color', bg_color);

panel_w = 1 / 4;

for k = 1:4
    rc     = red_peak(k, :);
    dark_c = 0.08 * rc;

    % Build per-pixel RGB; outside sphere = bg_color (seamless blend)
    sphere_img = zeros(N, N, 3);
    for ch = 1:3
        t_base = 0.65;
        t1 = min(max(I / t_base, 0), 1);
        channel = dark_c(ch)*(1 - t1) + rc(ch)*t1;

        t2 = min(max((I - t_base) / (1 - t_base), 0), 1);
        channel = channel.*(1 - t2) + t2;

        channel(~mask) = bg_color(ch);
        sphere_img(:,:,ch) = channel;
    end

    % Panel axes
    px = (k-1) * panel_w;
    ax = axes('Parent', fig, ...
              'Position',  [px, 0, panel_w, 1], ...
              'Color',     bg_color, ...
              'XColor',    'none', ...
              'YColor',    'none', ...
              'XLim',      [0 1], ...
              'YLim',      [0 1], ...
              'YDir',      'normal');

    imagesc(ax, ...
        [0.5 - sphere_r, 0.5 + sphere_r], ...
        [sphere_y(k) - sphere_r, sphere_y(k) + sphere_r], ...
        sphere_img);
    set(ax, 'YDir', 'normal', 'XLim', [0 1], 'YLim', [0 1]);
end

% Vertical dividers
for k = 1:3
    xp = k * panel_w;
    annotation(fig, 'line', [xp xp], [0 1], ...
        'Color', divider_color, 'LineWidth', divider_lw);
end

% ── Export ────────────────────────────────────────────────────────────────
out = fullfile(output_dir, 'sphere_panel');
exportgraphics(fig, [out '.pdf'], 'ContentType', 'vector', 'BackgroundColor', bg_color);
exportgraphics(fig, [out '.png'], 'Resolution', png_dpi,   'BackgroundColor', bg_color);
fprintf('Saved: %s  (.pdf / .png)\n', out);
