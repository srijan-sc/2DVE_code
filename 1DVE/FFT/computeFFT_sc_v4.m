function [FFT_magnitude, freq_axis] = computeFFT_sc_v4(time_fs, osc_matrix, filter_norm, FFT_size, apply_filter, doPlot)
% computeFFT_sc_v4  One-sided FFT of oscillatory residuals with optional windowing
%
% Inputs:
%   time_fs      - Time axis [1 x Nt] or [Nt x 1]  in fs
%   osc_matrix   - Oscillation matrix [Nt x Npix]  (data - fit)
%   filter_norm  - Normalised window  [1 x Nt] or [Nt x 1]  (from hyperbolicTanWindow2)
%   FFT_size     - Zero-padded FFT length (even integer, e.g. 2048)
%   apply_filter - true / false
%   doPlot       - true / false
%
% Outputs:
%   FFT_magnitude - [FFT_size/2 x Npix]  one-sided magnitude spectrum (not normalised)
%   freq_axis     - [1 x FFT_size/2]     frequency axis in cm^-1

% ── Input checks ─────────────────────────────────────────────────────────────
validateattributes(FFT_size,     {'numeric'}, {'scalar','positive','even'});
validateattributes(apply_filter, {'logical'}, {'scalar'});
validateattributes(doPlot,       {'logical'}, {'scalar'});

time_fs = time_fs(:);           % ensure column
Nt      = length(time_fs);

if size(osc_matrix, 1) ~= Nt
    error('osc_matrix rows (%d) must match length of time_fs (%d)', size(osc_matrix,1), Nt);
end

% ── Frequency axis ────────────────────────────────────────────────────────────
% dt in seconds → Nyquist in cm^-1
C_cms   = 2.99792458e10;            % speed of light  cm/s
dt_s    = abs(time_fs(2) - time_fs(1)) * 1e-15;   % fs → s
f_max   = 1 / (2 * dt_s * C_cms);  % Nyquist  cm^-1
freq_axis = linspace(0, f_max, FFT_size/2);   % [1 x FFT_size/2]

% ── Apply window ──────────────────────────────────────────────────────────────
if apply_filter
    if isempty(filter_norm)
        error('filter_norm is empty but apply_filter is true');
    end
    win = filter_norm(:);                          % column
    signal = osc_matrix .* win;                    % broadcast across pixels
else
    signal = osc_matrix;
end

% ── FFT ───────────────────────────────────────────────────────────────────────
% Zero-pad to FFT_size, take one-sided magnitude
raw_fft       = fft(signal, FFT_size, 1);          % [FFT_size x Npix]
one_sided      = raw_fft(1:FFT_size/2, :);          % positive freqs only
FFT_magnitude  = abs(real(one_sided));              % real-part magnitude

% ── Optional plot ─────────────────────────────────────────────────────────────
if doPlot
    proj_spec = sum(abs(FFT_magnitude), 2);   % summed projection across pixels

    figure;
    subplot(2,1,1);
    plot(freq_axis, proj_spec, 'k', 'LineWidth', 1.3);
    xlabel('\omega_2 / 2\pic  (cm^{-1})');
    ylabel('\Sigma|FFT|');
    title('Absolute value projection (sum across pixels)');
    grid on;

    subplot(2,1,2);
    imagesc(1:size(FFT_magnitude,2), freq_axis, FFT_magnitude);
    axis xy;
    xlabel('Pixel index'); ylabel('\omega_2 / 2\pic  (cm^{-1})');
    title('FFT magnitude map  [freq \times pixels]');
    colorbar; colormap(hot);

    sgtitle(sprintf('FFT  |  dt=%.1f fs  |  Nyquist=%.0f cm^{-1}  |  N_{pad}=%d', ...
        dt_s*1e15, f_max, FFT_size));
end
end
