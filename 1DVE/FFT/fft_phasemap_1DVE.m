%% fft_phasemap_1DVE.m
% 2D phase map: probe wavenumber (x) vs oscillation frequency (y).
% Color = wrapped phase from angle(FFT).

clear; clc;
here = fileparts(mfilename('fullpath'));

%% ========================= USER PARAMETERS ==========================

probe_range = [24200, 25000];  % cm-1

osc_range = [220, 260];        % cm-1  — y-axis of map

t_start = 200;
t_end   = 3000;

win_t0_rise  = 400;
win_tau_rise = 80;
win_t0_fall  = 2000;
win_tau_fall = 80;

FFT_size = 2048;

% ========================= END PARAMETERS ============================

%% Load data
data_matrix = readmatrix(fullfile(here, 'data_matrix.csv'));
t           = readmatrix(fullfile(here, 'time_axis.csv'));
wn          = readmatrix(fullfile(here, 'w3_axis.csv'));

t  = t(:)';
wn = wn(:);

if t(1) > t(end),   t = fliplr(t); data_matrix = fliplr(data_matrix); end
if wn(1) > wn(end), wn = flipud(wn); data_matrix = flipud(data_matrix); end

%% FFT frequency axis
mask_t    = t >= t_start & t <= t_end;
dt_s      = mean(diff(t(mask_t))) * 1e-15;
C_cms     = 2.99792458e10;
freq_axis = linspace(0, 1/(2*dt_s*C_cms), FFT_size/2);

mask_osc  = freq_axis >= osc_range(1) & freq_axis <= osc_range(2);
freq_crop = freq_axis(mask_osc);   % y-axis of map
N_freq    = sum(mask_osc);

fprintf('Osc freq bins: %.1f - %.1f cm-1  (%d bins)\n', ...
    freq_crop(1), freq_crop(end), N_freq);

%% Loop over probe wavenumbers
region_mask = wn >= probe_range(1) & wn <= probe_range(2);
x_wn        = wn(region_mask);
N_probes    = sum(region_mask);

fprintf('Probe pixels: %d  (%.1f - %.1f cm-1)\n\n', N_probes, x_wn(1), x_wn(end));

biexp = @(p,tv) p(1)*exp(-tv/abs(p(2))) + p(3)*exp(-tv/abs(p(4))) + p(5);
opts  = optimset('Display','off','MaxFunEvals',20000,'MaxIter',20000, ...
                 'TolFun',1e-14,'TolX',1e-14);

phase_map = zeros(N_freq, N_probes);  % [freq x probe]

for ii = 1:N_probes
    tr   = data_matrix(region_mask, :);
    tr   = tr(ii,:)';

    t_r  = t(mask_t)';   tr_r = tr(mask_t);
    ok   = isfinite(tr_r);
    t_s  = t_r(ok);      tr_s = tr_r(ok);

    amp = max(abs(tr_s));
    bl  = mean(tr_s(end-4:end));
    if ~isfinite(bl), bl = 0; end
    pf = fminsearch(@(p) sum((biexp(p,t_s)-tr_s).^2), [amp,150,amp/4,3000,bl], opts);

    osc_c = tr_s - biexp(pf, t_s);
    rise  = 0.5*(1 + tanh((t_s - win_t0_rise)./win_tau_rise));
    fall  = 0.5*(1 - tanh((t_s - win_t0_fall)./win_tau_fall));
    raw   = fft(osc_c .* (rise .* fall), FFT_size);

    phase_map(:, ii) = angle(raw(mask_osc));

    if mod(ii,50)==0, fprintf('  %d / %d\n', ii, N_probes); end
end
fprintf('Done.\n');

%% Cyclic colormap — anchors: black(-pi) blue(-pi/2) white(0) red(pi/2) black(pi)
N = 256; q = N/4;
%          -pi->-pi/2   -pi/2->0    0->pi/2     pi/2->pi
r = [linspace(0,0,q),  linspace(0,1,q),  linspace(1,1,q),  linspace(1,0,q)]';
g = [linspace(0,0,q),  linspace(0,1,q),  linspace(1,0,q),  linspace(0,0,q)]';
b = [linspace(0,1,q),  linspace(1,1,q),  linspace(1,0,q),  linspace(0,0,q)]';
cyclic_cmap = [r, g, b];

%% Plot
figure('Name','1DVE phase map','NumberTitle','off', ...
       'Units','centimeters','Position',[2 2 18 11]);

imagesc(x_wn, freq_crop, phase_map);
axis xy;
colormap(cyclic_cmap);
cb = colorbar;
cb.Label.String = 'Phase (rad)';
cb.Label.FontSize = 12;
caxis([-pi pi]);
cb.Ticks = [-pi, -pi/2, 0, pi/2, pi];
cb.TickLabels = {'-\pi', '-\pi/2', '0', '\pi/2', '\pi'};
cb.FontSize = 11;

xlabel('\omega_3  (cm^{-1})', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('\omega_2 / 2\pic  (cm^{-1})', 'FontSize', 13, 'FontWeight', 'bold');
title(sprintf('FFT phase map  |  \\omega_3 = %d\x2013%d cm^{-1}', probe_range(1), probe_range(2)), ...
    'FontSize', 13, 'FontWeight', 'bold');
set(gca,'TickDir','out','FontSize',12,'FontWeight','bold','Box','on');
xlim(probe_range);
ylim(osc_range);
