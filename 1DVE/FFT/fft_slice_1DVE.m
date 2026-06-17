%% fft_slice_1DVE.m
% FFT analysis at a single probe wavenumber for 1DVE data.
% Bi-exp subtract → htan window → FFT → 3-panel plot.

clear; clc;
here = fileparts(mfilename('fullpath'));

%% ========================= USER PARAMETERS ==========================

probe_wn = 24800;   % cm-1

t_start = 200;
t_end   = 3000;

win_t0_rise  = 400;
win_tau_rise = 80;
win_t0_fall  = 2000;
win_tau_fall = 80;

FFT_size        = 2048;
freq_plot_range = [0, 800];   % cm-1

% ========================= END PARAMETERS ============================

%% Load data
data_matrix = readmatrix(fullfile(here, 'data_matrix.csv'));
t           = readmatrix(fullfile(here, 'time_axis.csv'));
wn          = readmatrix(fullfile(here, 'w3_axis.csv'));

t  = t(:)';
wn = wn(:);

if t(1) > t(end),   t = fliplr(t); data_matrix = fliplr(data_matrix); end
if wn(1) > wn(end), wn = flipud(wn); data_matrix = flipud(data_matrix); end

%% Extract slice
[~, idx]   = min(abs(wn - probe_wn));
actual_wn  = wn(idx);
trace_full = data_matrix(idx, :)';

fprintf('Requested %.1f cm-1 -> using %.1f cm-1 (row %d)\n', probe_wn, actual_wn, idx);

%% Clip to time window
mask      = t >= t_start & t <= t_end;
t_raw     = t(mask)';
trace_raw = trace_full(mask);
ok        = isfinite(trace_raw);
t_fit     = t_raw(ok);
trace_fit = trace_raw(ok);

fprintf('Fit range: %.1f - %.1f fs  (%d points)\n', t_fit(1), t_fit(end), numel(t_fit));

%% Bi-exponential fit
biexp = @(p,tv) p(1)*exp(-tv/abs(p(2))) + p(3)*exp(-tv/abs(p(4))) + p(5);
opts  = optimset('Display','off','MaxFunEvals',20000,'MaxIter',20000, ...
                 'TolFun',1e-14,'TolX',1e-14);
amp = max(abs(trace_fit));
bl  = mean(trace_fit(max(1,end-5):end));
if ~isfinite(bl), bl = 0; end
p_fit = fminsearch(@(p) sum((biexp(p,t_fit)-trace_fit).^2), [amp,150,amp/4,3000,bl], opts);

fit_curve = biexp(p_fit, t_fit);
osc       = trace_fit - fit_curve;
R2 = 1 - sum(osc.^2)/sum((trace_fit - mean(trace_fit)).^2);

fprintf('tau1=%.0f fs  tau2=%.0f fs  R2=%.4f\n\n', abs(p_fit(2)), abs(p_fit(4)), R2);

%% Window
rise  = 0.5*(1 + tanh((t_fit - win_t0_rise)./win_tau_rise));
fall  = 0.5*(1 - tanh((t_fit - win_t0_fall)./win_tau_fall));
win   = rise .* fall;

%% FFT
C_cms     = 2.99792458e10;
dt_s      = mean(diff(t_fit)) * 1e-15;
freq_axis = linspace(0, 1/(2*dt_s*C_cms), FFT_size/2);

fft_raw = fft(osc .* win, FFT_size);
fft_mag = abs(fft_raw(1:FFT_size/2));

%% Plot
fig = figure('Name', sprintf('1DVE slice %.0f cm-1', actual_wn), 'NumberTitle','off');

ax1 = subplot(3,1,1);
plot(t, trace_full, 'Color',[0.75 0.75 0.75], 'LineWidth',0.8); hold on;
plot(t_fit, trace_fit, 'b', 'LineWidth',1.2);
plot(t_fit, fit_curve, 'r--', 'LineWidth',1.8);
xline(t_start,'--k','t_{start}','LabelVerticalAlignment','bottom','LineWidth',1);
xline(t_end,  '--k','t_{end}',  'LabelVerticalAlignment','bottom','LineWidth',1);
legend('Full','Fit region','Bi-exp','Location','best');
ylabel('\DeltaA');
title(sprintf('%.1f cm^{-1}  |  R^2=%.4f  |  \\tau_1=%.0f fs  \\tau_2=%.0f fs', ...
    actual_wn, R2, abs(p_fit(2)), abs(p_fit(4))));
grid on; set(ax1,'TickDir','out');

ax2 = subplot(3,1,2);
yyaxis left;
plot(t_fit, osc, 'k', 'LineWidth',1.2);
yline(0,'--','Color',[0.5 0.5 0.5]);
ylabel('\DeltaA_{osc}');
yyaxis right;
plot(t_fit, win, '--','Color',[0.85 0.33 0.1],'LineWidth',1.5);
ylabel('Window'); ylim([-0.1 1.2]);
xlabel('\tau (fs)');
title('Oscillatory residuals + window');
grid on; set(ax2,'TickDir','out');

ax3 = subplot(3,1,3);
fmask = freq_axis >= freq_plot_range(1) & freq_axis <= freq_plot_range(2);
plot(freq_axis(fmask), fft_mag(fmask), 'k', 'LineWidth',1.3);
xline(220,'--r','220','LabelVerticalAlignment','bottom','LabelHorizontalAlignment','left');
xline(248,'--b','248','LabelVerticalAlignment','bottom','LabelHorizontalAlignment','left');
xlabel('\omega_2/2\pic  (cm^{-1})');
ylabel('|FFT|  (arb.)');
title(sprintf('FFT  |  %d-%d cm^{-1}', freq_plot_range(1), freq_plot_range(2)));
grid on; set(ax3,'TickDir','out');

sgtitle(sprintf('1DVE — %.1f cm^{-1}', actual_wn), 'FontSize',13,'FontWeight','bold');

%% Second figure: abs / real / imag side by side
mags   = {abs(fft_raw(1:FFT_size/2)), abs(real(fft_raw(1:FFT_size/2))), abs(imag(fft_raw(1:FFT_size/2)))};
labels = {'abs(FFT)', 'abs(real(FFT))', 'abs(imag(FFT))'};
colors = {[0 0 0], [0.2 0.4 0.9], [0.85 0.33 0.1]};

figure('Name', sprintf('1DVE FFT 3ver %.0f cm-1', actual_wn), 'NumberTitle','off', ...
       'Units','centimeters','Position',[2 2 36 8]);

for v = 1:3
    m = mags{v};
    subplot(1,3,v);
    plot(freq_axis(fmask), m(fmask), 'Color', colors{v}, 'LineWidth', 1.3);
    xline(220,'--r','220','LabelVerticalAlignment','bottom','LabelHorizontalAlignment','left');
    xline(248,'--b','248','LabelVerticalAlignment','bottom','LabelHorizontalAlignment','left');
    xlim(freq_plot_range);
    xlabel('\omega_2/2\pic  (cm^{-1})');
    ylabel('|FFT|  (arb.)');
    title(labels{v});
    grid on; set(gca,'TickDir','out','FontSize',11);
end
sgtitle(sprintf('1DVE FFT — %.1f cm^{-1} probe', actual_wn), 'FontSize',13,'FontWeight','bold');
