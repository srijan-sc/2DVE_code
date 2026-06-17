% save_csv_for_FFT.m
% Loads the 1DVE .mat struct and exports three CSVs into ./FFT/
%   time_axis.csv   — [1 × Nt]   τ₂ in fs
%   w3_axis.csv     — [1 × Nw]   ω₃ in cm⁻¹  (active pixel window only)
%   data_matrix.csv — [Nw × Nt]  processedData (active window)

cd(fileparts(mfilename('fullpath')));

mat_file = 've_1D_HBQ_100mM_dmso_d6_150u_1arm_z_10_05_off_4_test_051_20260423_181059.mat';

% ── Load ──────────────────────────────────────────────────────────────────────
f = load(mat_file);
s = f.s;

pMin = s.pixelRange(1);
pMax = s.pixelRange(2);

t2   = s.time;                          % [1 × Nt]  fs
w3   = s.waveAxis(pMin:pMax);           % [1 × Nw]  cm⁻¹
data = s.processedData(pMin:pMax, :);   % [Nw × Nt]

% ── Output folder ─────────────────────────────────────────────────────────────
out_dir = 'FFT';
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

% ── Save CSVs ─────────────────────────────────────────────────────────────────
writematrix(t2,   fullfile(out_dir, 'time_axis.csv'));
writematrix(w3,   fullfile(out_dir, 'w3_axis.csv'));
writematrix(data, fullfile(out_dir, 'data_matrix.csv'));

fprintf('Saved to %s/\n', out_dir);
fprintf('  time_axis.csv   [1 x %d]  fs\n',   numel(t2));
fprintf('  w3_axis.csv     [1 x %d]  cm-1\n', numel(w3));
fprintf('  data_matrix.csv [%d x %d]\n',       size(data,1), size(data,2));
