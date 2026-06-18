% plot_spheres.m — 4 spheres with Phong shading, weak → strong red
cd(fileparts(mfilename('fullpath')));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                        USER SETTINGS                                    ║
% ╠══════════════════════════════════════════════════════════════════════════╣
output_dir  = 'sphere_fig';
fig_size_cm = 8;
png_dpi     = 300;
N           = 600;      % grid resolution

% Peak red shades weak → strong (redblue palette red end)
red_peak = [
    1.00, 0.80, 0.80;   % weak   — pale blush
    0.96, 0.52, 0.52;   % soft   — light red
    0.84, 0.18, 0.18;   % medium — mid red
    0.65, 0.00, 0.05;   % strong — deep crimson
];
labels = {'1_weak', '2_soft', '3_medium', '4_strong'};

% Phong lighting parameters
light_dir   = [-0.50, -0.55, 1.00];   % upper-left, toward viewer
k_ambient   = 0.10;
k_diffuse   = 0.65;
k_specular  = 0.55;
shininess   = 38;
% ╚══════════════════════════════════════════════════════════════════════════╝

if ~exist(output_dir, 'dir'), mkdir(output_dir); end

% ── Sphere geometry & lighting (same for all 4) ───────────────────────────
[X, Y] = meshgrid(linspace(-1, 1, N), linspace(-1, 1, N));
R2   = X.^2 + Y.^2;
mask = R2 < 1;

Nz = sqrt(max(0, 1 - R2));   % surface normal z-component (Nx=X, Ny=Y)

Lv     = light_dir / norm(light_dir);
dot_LN = X*Lv(1) + Y*Lv(2) + Nz*Lv(3);
Id     = max(0, dot_LN);                  % diffuse term

Rz = 2*dot_LN.*Nz - Lv(3);              % reflected-ray z toward viewer
Is = max(0, Rz).^shininess;              % specular term

I      = k_ambient + k_diffuse*Id + k_specular*Is;
I(~mask) = NaN;

% ── Per-sphere rendering ──────────────────────────────────────────────────
for k = 1:4
    rc = red_peak(k, :);
    dark_c = 0.08 * rc;   % shadow = very dark version of base colour

    sphere_img = zeros(N, N, 3);
    for ch = 1:3
        % I in [0, t_base] → shadow → base colour
        t_base = 0.65;
        t1 = min(max(I / t_base, 0), 1);
        channel = dark_c(ch)*(1 - t1) + rc(ch)*t1;

        % I in [t_base, 1] → base colour → white (specular highlight)
        t2 = min(max((I - t_base) / (1 - t_base), 0), 1);
        channel = channel.*(1 - t2) + t2;

        channel(~mask) = 1;           % white outside (will be masked)
        sphere_img(:,:,ch) = channel;
    end

    fig = figure('Units', 'centimeters', ...
                 'Position', [2 2 fig_size_cm fig_size_cm], ...
                 'PaperUnits', 'centimeters', ...
                 'PaperSize', [fig_size_cm fig_size_cm], ...
                 'Color', 'w');
    ax = axes('Parent', fig, 'Color', 'w', 'Position', [0 0 1 1]);
    image(ax, sphere_img);
    axis(ax, 'equal', 'off', 'tight');
    ax.LooseInset = [0 0 0 0];

    out = fullfile(output_dir, ['sphere_' labels{k}]);

    % Export square, then apply circular alpha mask
    exportgraphics(fig, [out '.png'], 'Resolution', png_dpi, 'BackgroundColor', 'white');
    img = imread([out '.png']);
    [h, w, ~] = size(img);
    cx = w/2;  cy = h/2;  r = min(h,w)/2 - 1;
    [Xm, Ym] = meshgrid(1:w, 1:h);
    alpha_ch = double(((Xm-cx).^2 + (Ym-cy).^2) <= r^2);
    imwrite(img, [out '.png'], 'Alpha', alpha_ch);

    exportgraphics(fig, [out '.pdf'], 'ContentType', 'image', ...
        'Resolution', png_dpi, 'BackgroundColor', 'white');
    fprintf('Saved: %s\n', out);
    close(fig);
end
