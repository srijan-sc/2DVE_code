% save_all_tau2_csvs.m
% Saves one CSV per τ₂ point (all 61) with columns: w1_cm, intensity, sd
% w1 range: 2500–3200 cm⁻¹   |   output: tau2_data/
cd(fileparts(mfilename('fullpath')));

DATA_FILE    = '/Users/srijan/Library/CloudStorage/OneDrive-UW/Lab_1/Analysis/HBQ_3D_analysis/data_cube_3DVE.mat';
PIX_RANGE    = [550 1000];
FZSIZE       = 4096;
TIME_AXIS    = 110:15:1015;
W1_WINDOW    = [2500 3200];
SMOOTH_SIGMA = 0.5;
OUT_DIR      = 'tau2_data';

HeNeHalfCycle = 1.0554e-15;
SpeedOfLight  = 2.99792458e10;
freqRes  = (1 / HeNeHalfCycle) / SpeedOfLight / FZSIZE;
freqAxis = (0:FZSIZE-1) .* freqRes;

w1_bins = round(W1_WINDOW ./ freqRes);
w1_axis = freqAxis(w1_bins(1):w1_bins(2))';   % [Nw1 × 1]

fprintf('Loading data cube ... ');
tmp      = load(DATA_FILE);
dataCube = tmp.dataCube2;
fprintf('[%d × %d × %d]\n', size(dataCube,1), size(dataCube,2), size(dataCube,3));

if ~exist(OUT_DIR, 'dir'),  mkdir(OUT_DIR);  end

if SMOOTH_SIGMA > 0
    half = ceil(3 * SMOOTH_SIGMA);
    xk   = -half:half;
    kern = exp(-xk.^2 / (2*SMOOTH_SIGMA^2));
    kern = (kern / sum(kern))';
end

for t_idx = 1:numel(TIME_AXIS)
    actual_t = TIME_AXIS(t_idx);

    slice   = dataCube(PIX_RANGE(1):PIX_RANGE(2), w1_bins(1):w1_bins(2), t_idx);
    abs_sl  = abs(slice);
    w3_mean = mean(abs_sl, 1)';
    w3_std  = std(abs_sl,  0, 1)';

    if SMOOTH_SIGMA > 0
        w3_mean = conv(w3_mean, kern, 'same');
        w3_std  = conv(w3_std,  kern, 'same');
    end

    T = table(w1_axis, w3_mean, w3_std, ...
        'VariableNames', {'w1_cm', 'intensity', 'sd'});

    writetable(T, fullfile(OUT_DIR, sprintf('%dfs_HBQ.csv', actual_t)));
    fprintf('  %d fs\n', actual_t);
end

fprintf('Done — %d CSVs saved to %s/\n', numel(TIME_AXIS), OUT_DIR);
