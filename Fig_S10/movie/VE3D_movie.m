% VE3D_movie.m — loop over all time slices and export as MP4 + GIF
cd(fileparts(mfilename('fullpath')));
addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% ╔══════════════════════════════════════════════════════════════════════════╗
% ║                         USER SETTINGS                                   ║
% ╠══════════════════════════════════════════════════════════════════════════╣
data_file   = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Analysis/HBQ_3D_analysis/data_cube_3DVE.mat';
waxis_file  = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Lab_pc_backup/CCD_Wavelength_Axis_2024_03_06.mat';
% ║                                                                         ║
ax2d         = [2500 3000 550 1000];
FTsize       = 4096;
filterOrder  = 5;
filterWindow = 15;
custom_scalar = 1.5;
% ║                                                                         ║
output_name  = 'VE3D_movie';   % output filename (no extension)
frame_rate   = 2;              % fps for MP4 and GIF
fig_width    = 16;             % cm — slightly wider to give title room
fig_height   = 11;             % cm
% ╚══════════════════════════════════════════════════════════════════════════╝

time_fs = 110:15:1015;   % 61 time points
Nt      = numel(time_fs);

% ── Load data once ─────────────────────────────────────────────────────────
ve3d = VE3DExperiment(data_file, waxis_file);
ve3d.ax2d         = ax2d;
ve3d.FTsize       = FTsize;
ve3d.filterOrder  = filterOrder;
ve3d.filterWindow = filterWindow;
ve3d.load();

% ── Set up VideoWriter (MP4) ───────────────────────────────────────────────
vw           = VideoWriter(output_name, 'MPEG-4');
vw.FrameRate = frame_rate;
vw.Quality   = 95;
open(vw);

gif_file = [output_name '.gif'];
gif_delay = 1 / frame_rate;

% ── Loop over time slices ──────────────────────────────────────────────────
for k = 1:Nt
    t = time_fs(k);
    fprintf('Frame %d/%d  (%d fs)\n', k, Nt, t);

    ve3d.prepare(k);
    ve3d.plot( ...
        'Title',        sprintf('\\itt_2\\rm = %d fs', t), ...
        'CustomScalar', custom_scalar, ...
        'FigWidth',     fig_width, ...
        'FigHeight',    fig_height);

    drawnow;

    % ── Capture frame at screen resolution ────────────────────────────────
    frame = getframe(ve3d.fig);

    % MP4
    writeVideo(vw, frame);

    % GIF
    [img, cmap] = rgb2ind(frame.cdata, 256);
    if k == 1
        imwrite(img, cmap, gif_file, 'gif', ...
            'LoopCount', Inf, 'DelayTime', gif_delay);
    else
        imwrite(img, cmap, gif_file, 'gif', ...
            'WriteMode', 'append', 'DelayTime', gif_delay);
    end

    close(ve3d.fig);
end

close(vw);
fprintf('\nDone.\n');
fprintf('Saved: %s.mp4  (embed in PPT as video)\n', output_name);
fprintf('Saved: %s.gif  (insert as picture in PPT)\n', output_name);
