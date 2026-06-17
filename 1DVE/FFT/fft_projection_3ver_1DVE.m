%% fft_projection_3ver_1DVE.m
% FFT projection vs probe wavenumber for 1DVE data — three FFT variants:
%   abs(fft)  |  abs(real(fft))  |  abs(imag(fft))
% Each panel shows mean +/- std for band_A and band_B plus noise floor.

clear; clc;
here = fileparts(mfilename('fullpath'));

%% ========================= USER PARAMETERS ==========================

probe_range = [24200, 24900];

t_start = 200;
t_end   = 3000;

win_t0_rise  = 400;
win_tau_rise = 80;
win_t0_fall  = 2000;
win_tau_fall = 80;

FFT_size = 2048;

band_A     = [243, 248];
band_B     = [220, 225];
noise_band = [800, 809];

% ========================= END PARAMETERS ============================

%% Load data
data_matrix = readmatrix(fullfile(here, 'data_matrix.csv'));
t           = readmatrix(fullfile(here, 'time_axis.csv'));
wn          = readmatrix(fullfile(here, 'w3_axis.csv'));

t  = t(:)';
wn = wn(:);

if t(1) > t(end),   t = fliplr(t); data_matrix = fliplr(data_matrix); end
if wn(1) > wn(end), wn = flipud(wn); data_matrix = flipud(data_matrix); end

fprintf('Loaded  %d freq x %d time points\n', numel(wn), numel(t));

%% FFT frequency axis
mask_t    = t >= t_start & t <= t_end;
dt_s      = mean(diff(t(mask_t))) * 1e-15;
C_cms     = 2.99792458e10;
freq_axis = linspace(0, 1/(2*dt_s*C_cms), FFT_size/2);

mask_A     = freq_axis >= band_A(1)     & freq_axis <= band_A(2);
mask_B     = freq_axis >= band_B(1)     & freq_axis <= band_B(2);
mask_noise = freq_axis >= noise_band(1) & freq_axis <= noise_band(2);

%% Loop
region_mask = wn >= probe_range(1) & wn <= probe_range(2);
x           = wn(region_mask);
N_probes    = sum(region_mask);

biexp = @(p,tv) p(1)*exp(-tv/abs(p(2))) + p(3)*exp(-tv/abs(p(4))) + p(5);
opts  = optimset('Display','off','MaxFunEvals',20000,'MaxIter',20000, ...
                 'TolFun',1e-14,'TolX',1e-14);

% Storage: [N_probes x 1] for mean/std of each variant x band
mA = zeros(N_probes,3); sA = zeros(N_probes,3);
mB = zeros(N_probes,3); sB = zeros(N_probes,3);
mN = zeros(N_probes,3); sN = zeros(N_probes,3);

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
    raw1  = raw(1:FFT_size/2);

    mags = [abs(raw1), abs(real(raw1)), abs(imag(raw1))];

    for v = 1:3
        m = mags(:,v);
        mA(ii,v) = mean(m(mask_A)); sA(ii,v) = std(m(mask_A));
        mB(ii,v) = mean(m(mask_B)); sB(ii,v) = std(m(mask_B));
        mN(ii,v) = mean(m(mask_noise)); sN(ii,v) = std(m(mask_noise));
    end

    if mod(ii,50)==0, fprintf('  %d / %d\n', ii, N_probes); end
end
fprintf('Done.\n');

%% Plot
titles = {'|FFT|', '|real(FFT)|', '|imag(FFT)|'};

figure('Name','1DVE FFT projection — 3 versions','NumberTitle','off', ...
       'Units','centimeters','Position',[2 2 36 10]);

for v = 1:3
    subplot(1,3,v); hold on;

    fill([x;flipud(x)],[mN(:,v)+sN(:,v);flipud(mN(:,v)-sN(:,v))], ...
        [0.5 0.5 0.5],'FaceAlpha',0.3,'EdgeColor','none');
    plot(x, mN(:,v),'--','Color',[0.4 0.4 0.4],'LineWidth',1.2, ...
        'DisplayName',sprintf('Noise %d-%d cm^{-1}', noise_band(1), noise_band(2)));

    fill([x;flipud(x)],[mA(:,v)+sA(:,v);flipud(mA(:,v)-sA(:,v))], ...
        'b','FaceAlpha',0.2,'EdgeColor','none');
    plot(x, mA(:,v),'b.-','LineWidth',1.3,'MarkerSize',8, ...
        'DisplayName',sprintf('%d-%d cm^{-1}', band_A(1), band_A(2)));

    fill([x;flipud(x)],[mB(:,v)+sB(:,v);flipud(mB(:,v)-sB(:,v))], ...
        'r','FaceAlpha',0.2,'EdgeColor','none');
    plot(x, mB(:,v),'r.-','LineWidth',1.3,'MarkerSize',8, ...
        'DisplayName',sprintf('%d-%d cm^{-1}', band_B(1), band_B(2)));

    xlabel('\omega_3  (cm^{-1})');
    ylabel('|FFT|  (arb.)');
    title(titles{v});
    legend('Location','best');
    grid on; set(gca,'TickDir','out','FontSize',11);
    xlim(probe_range);
end

sgtitle('1DVE FFT projection  |  abs / real / imag', 'FontSize',13,'FontWeight','bold');
