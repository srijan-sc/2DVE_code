%% fft_phase_1DVE.m
% FFT phase + magnitude projection vs probe wavenumber for 1DVE data.
% Same pipeline as fft_projection_1DVE: bi-exp subtract, htan window, FFT.
% Extracts phase (angle) and magnitude over two frequency bands and plots
% phase (solid, left axis) + magnitude (dashed, right axis).

clear; clc;
here = fileparts(mfilename('fullpath'));

%% ========================= USER PARAMETERS ==========================

probe_range = [24200, 24900];  % cm-1

t_start = 200;
t_end   = 3000;

win_t0_rise  = 400;
win_tau_rise = 80;
win_t0_fall  = 2000;
win_tau_fall = 80;

FFT_size = 2048;

band_A = [243, 248];   % ~248 cm-1 mode
band_B = [220, 225];   % ~220 cm-1 mode

% ========================= END PARAMETERS ============================

%% Load data
data_matrix = readmatrix(fullfile(here, 'data_matrix.csv'));
t           = readmatrix(fullfile(here, 'time_axis.csv'));
wn          = readmatrix(fullfile(here, 'w3_axis.csv'));

t  = t(:)';
wn = wn(:);

if t(1) > t(end),  t = fliplr(t); data_matrix = fliplr(data_matrix); end
if wn(1) > wn(end), wn = flipud(wn); data_matrix = flipud(data_matrix); end

fprintf('Loaded  %d freq x %d time points\n', numel(wn), numel(t));

%% FFT frequency axis
mask_t    = t >= t_start & t <= t_end;
dt_s      = mean(diff(t(mask_t))) * 1e-15;
C_cms     = 2.99792458e10;
freq_axis = linspace(0, 1/(2*dt_s*C_cms), FFT_size/2);

mask_A = freq_axis >= band_A(1) & freq_axis <= band_A(2);
mask_B = freq_axis >= band_B(1) & freq_axis <= band_B(2);

fprintf('Band A: %.1f - %.1f cm-1  (%d bins)\n', ...
    freq_axis(find(mask_A,1)), freq_axis(find(mask_A,1,'last')), sum(mask_A));
fprintf('Band B: %.1f - %.1f cm-1  (%d bins)\n\n', ...
    freq_axis(find(mask_B,1)), freq_axis(find(mask_B,1,'last')), sum(mask_B));

%% Loop over probe wavenumbers
region_mask = wn >= probe_range(1) & wn <= probe_range(2);
x_wn        = wn(region_mask);
N_probes    = sum(region_mask);

biexp = @(p,tv) p(1)*exp(-tv/abs(p(2))) + p(3)*exp(-tv/abs(p(4))) + p(5);
opts  = optimset('Display','off','MaxFunEvals',20000,'MaxIter',20000, ...
                 'TolFun',1e-14,'TolX',1e-14);

mean_phA  = zeros(N_probes,1); std_phA  = zeros(N_probes,1);
mean_phB  = zeros(N_probes,1); std_phB  = zeros(N_probes,1);
mean_magA = zeros(N_probes,1); std_magA = zeros(N_probes,1);
mean_magB = zeros(N_probes,1); std_magB = zeros(N_probes,1);

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
    win_c = rise .* fall;
    raw   = fft(osc_c .* win_c, FFT_size);

    ph  = angle(raw(1:FFT_size/2));
    mag = abs(raw(1:FFT_size/2));

    mean_phA(ii)  = mean(ph(mask_A));  std_phA(ii)  = std(ph(mask_A));
    mean_phB(ii)  = mean(ph(mask_B));  std_phB(ii)  = std(ph(mask_B));
    mean_magA(ii) = mean(mag(mask_A)); std_magA(ii) = std(mag(mask_A));
    mean_magB(ii) = mean(mag(mask_B)); std_magB(ii) = std(mag(mask_B));

    if mod(ii,50)==0, fprintf('  %d / %d\n', ii, N_probes); end
end
fprintf('Done.\n');

%% Plot
figure('Name','1DVE FFT phase + magnitude','NumberTitle','off');

% Left axis — phase
yyaxis left; hold on;
fill([x_wn; flipud(x_wn)], [mean_phA+std_phA; flipud(mean_phA-std_phA)], ...
    [0.2 0.4 0.9],'FaceAlpha',0.25,'EdgeColor','none');
plot(x_wn, mean_phA, '.-','Color',[0.2 0.4 0.9],'LineWidth',1.3,'MarkerSize',8, ...
    'DisplayName',sprintf('Phase %d-%d cm^{-1}', band_A(1), band_A(2)));

fill([x_wn; flipud(x_wn)], [mean_phB+std_phB; flipud(mean_phB-std_phB)], ...
    [0.9 0.2 0.2],'FaceAlpha',0.25,'EdgeColor','none');
plot(x_wn, mean_phB, '.-','Color',[0.9 0.2 0.2],'LineWidth',1.3,'MarkerSize',8, ...
    'DisplayName',sprintf('Phase %d-%d cm^{-1}', band_B(1), band_B(2)));

yline(0,'--','Color',[0.5 0.5 0.5],'HandleVisibility','off');
ylabel('Phase (rad)');
ylim([-pi pi]);
set(gca,'YTick',[-pi -pi/2 0 pi/2 pi], ...
        'YTickLabel',{'-\pi','-\pi/2','0','\pi/2','\pi'}, ...
        'YColor',[0.2 0.2 0.2]);

% Right axis — magnitude
yyaxis right;
fill([x_wn; flipud(x_wn)], [mean_magA+std_magA; flipud(mean_magA-std_magA)], ...
    [0.2 0.4 0.9],'FaceAlpha',0.12,'EdgeColor','none','HandleVisibility','off');
plot(x_wn, mean_magA, '--','Color',[0.2 0.4 0.9],'LineWidth',1.5, ...
    'DisplayName',sprintf('|FFT| %d-%d cm^{-1}', band_A(1), band_A(2)));

fill([x_wn; flipud(x_wn)], [mean_magB+std_magB; flipud(mean_magB-std_magB)], ...
    [0.9 0.2 0.2],'FaceAlpha',0.12,'EdgeColor','none','HandleVisibility','off');
plot(x_wn, mean_magB, '--','Color',[0.9 0.2 0.2],'LineWidth',1.5, ...
    'DisplayName',sprintf('|FFT| %d-%d cm^{-1}', band_B(1), band_B(2)));

ylabel('|FFT|  (arb.)');
set(gca,'YColor',[0.2 0.2 0.2]);

xlim(probe_range);
xlabel('\omega_3  (cm^{-1})');
title(sprintf('1DVE FFT phase (solid) + magnitude (dashed)  |  %d-%d cm^{-1}', ...
    probe_range(1), probe_range(2)));
legend('Location','best');
set(gca,'TickDir','out','FontSize',12); grid on;
