%% 1DVE_fft_projection.m
% FFT intensity projection across probe wavenumbers for 1DVE data.
% Loads time_axis.csv / w3_axis.csv / data_matrix.csv, loops over probe
% wavenumbers, fits bi-exponential background, subtracts, applies
% hyperbolic-tangent window, computes FFT, plots mean +/- std of two
% frequency bands vs probe wavenumber.

clear; clc;
here = fileparts(mfilename('fullpath'));

%% ========================= USER PARAMETERS ==========================

% Probe wavenumber region to scan (cm-1)
probe_range = [24200, 24900];

% Time window for analysis (fs)
t_start = 200;
t_end   = 3000;

% Hyperbolic-tangent window (fs)
win_t0_rise  = 400;
win_tau_rise = 80;
win_t0_fall  = 2000;
win_tau_fall = 80;

% FFT zero-padding length
FFT_size = 2048;

% Signal frequency bands (cm-1)
band_A = [243, 248];   % ~248 cm-1 mode
band_B = [220, 225];   % ~220 cm-1 mode

% Noise reference band (cm-1)
noise_band = [800, 809];

% ========================= END PARAMETERS ============================

%% Load data
data_matrix = readmatrix(fullfile(here, 'data_matrix.csv'));  % [Nw x Nt]
t           = readmatrix(fullfile(here, 'time_axis.csv'));    % [1 x Nt] fs
wn          = readmatrix(fullfile(here, 'w3_axis.csv'));      % [1 x Nw] cm-1

t  = t(:)';
wn = wn(:);

% Ensure time axis is increasing
if t(1) > t(end)
    t           = fliplr(t);
    data_matrix = fliplr(data_matrix);
end

% Ensure wavenumber axis is increasing
if wn(1) > wn(end)
    wn          = flipud(wn);
    data_matrix = flipud(data_matrix);
end

fprintf('Loaded  %d freq x %d time points\n', numel(wn), numel(t));
fprintf('Freq:   %.1f - %.1f cm-1\n', min(wn), max(wn));
fprintf('Time:   %.1f - %.1f fs\n\n',  min(t),  max(t));

%% Build FFT frequency axis
mask_t   = t >= t_start & t <= t_end;
dt_s     = mean(diff(t(mask_t))) * 1e-15;
C_cms    = 2.99792458e10;
freq_axis = linspace(0, 1/(2*dt_s*C_cms), FFT_size/2);

mask_A     = freq_axis >= band_A(1)     & freq_axis <= band_A(2);
mask_B     = freq_axis >= band_B(1)     & freq_axis <= band_B(2);
mask_noise = freq_axis >= noise_band(1) & freq_axis <= noise_band(2);

fprintf('Band A: %.1f - %.1f cm-1  (%d bins)\n', ...
    freq_axis(find(mask_A,1)), freq_axis(find(mask_A,1,'last')), sum(mask_A));
fprintf('Band B: %.1f - %.1f cm-1  (%d bins)\n', ...
    freq_axis(find(mask_B,1)), freq_axis(find(mask_B,1,'last')), sum(mask_B));
fprintf('Noise:  %.1f - %.1f cm-1  (%d bins)\n\n', ...
    freq_axis(find(mask_noise,1)), freq_axis(find(mask_noise,1,'last')), sum(mask_noise));

%% Loop over probe wavenumbers
region_mask = wn >= probe_range(1) & wn <= probe_range(2);
x           = wn(region_mask);
N_probes    = sum(region_mask);

biexp = @(p,tv) p(1)*exp(-tv/abs(p(2))) + p(3)*exp(-tv/abs(p(4))) + p(5);
opts  = optimset('Display','off','MaxFunEvals',20000,'MaxIter',20000, ...
                 'TolFun',1e-14,'TolX',1e-14);

mean_A        = zeros(N_probes,1); std_A        = zeros(N_probes,1);
mean_B        = zeros(N_probes,1); std_B        = zeros(N_probes,1);
noise_eq_mean = zeros(N_probes,1); noise_eq_std = zeros(N_probes,1);

for ii = 1:N_probes
    tr   = data_matrix(region_mask, :);
    tr   = tr(ii,:)';

    t_r  = t(mask_t)';   tr_r = tr(mask_t);
    ok   = isfinite(tr_r);
    t_s  = t_r(ok);      tr_s = tr_r(ok);

    amp = max(abs(tr_s));
    bl  = mean(tr_s(end-4:end));
    if ~isfinite(bl), bl = 0; end
    p0  = [amp, 150, amp/4, 3000, bl];
    pf  = fminsearch(@(p) sum((biexp(p,t_s)-tr_s).^2), p0, opts);

    osc_c = tr_s - biexp(pf, t_s);
    rise  = 0.5*(1 + tanh((t_s - win_t0_rise)./win_tau_rise));
    fall  = 0.5*(1 - tanh((t_s - win_t0_fall)./win_tau_fall));
    win_c = rise .* fall;
    mag_c = abs(fft(osc_c .* win_c, FFT_size));
    mag_c = mag_c(1:FFT_size/2);

    mean_A(ii)        = mean(mag_c(mask_A));     std_A(ii)        = std(mag_c(mask_A));
    mean_B(ii)        = mean(mag_c(mask_B));     std_B(ii)        = std(mag_c(mask_B));
    noise_eq_mean(ii) = mean(mag_c(mask_noise)); noise_eq_std(ii) = std(mag_c(mask_noise));

    if mod(ii,50)==0, fprintf('  %d / %d\n', ii, N_probes); end
end
fprintf('Done.\n');

%% Plot
figure('Name','1DVE FFT projection','NumberTitle','off'); hold on;

fill([x;flipud(x)],[noise_eq_mean+noise_eq_std;flipud(noise_eq_mean-noise_eq_std)], ...
    [0.5 0.5 0.5],'FaceAlpha',0.3,'EdgeColor','none');
plot(x, noise_eq_mean,'--','Color',[0.4 0.4 0.4],'LineWidth',1.2, ...
    'DisplayName',sprintf('Noise (%d-%d cm^{-1})', noise_band(1), noise_band(2)));

fill([x;flipud(x)],[mean_A+std_A;flipud(mean_A-std_A)],'b','FaceAlpha',0.2,'EdgeColor','none');
plot(x, mean_A,'b.-','LineWidth',1.3,'MarkerSize',8, ...
    'DisplayName',sprintf('%d-%d cm^{-1}', band_A(1), band_A(2)));

fill([x;flipud(x)],[mean_B+std_B;flipud(mean_B-std_B)],'r','FaceAlpha',0.2,'EdgeColor','none');
plot(x, mean_B,'r.-','LineWidth',1.3,'MarkerSize',8, ...
    'DisplayName',sprintf('%d-%d cm^{-1}', band_B(1), band_B(2)));

xlabel('\omega_3  (cm^{-1})');
ylabel('|FFT|  (arb.)');
title(sprintf('1DVE FFT projection  |  %d-%d cm^{-1}', probe_range(1), probe_range(2)));
legend('Location','best');
grid on; set(gca,'TickDir','out','FontSize',12);
xlim(probe_range);
