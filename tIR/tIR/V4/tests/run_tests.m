function run_tests()
% RUN_TESTS  tIR V3 test suite.
%
% Run this on a new machine before processing real data.
% All tests use the bundled test_data/ directory.
%
% Usage (from any working directory):
%   addpath('/path/to/V3/tests');
%   run_tests
%
% Or: cd into V3/tests and type:  run_tests

close all;

% ── Paths ────────────────────────────────────────────────────────────────────
tests_dir = fileparts(mfilename('fullpath'));
root      = fileparts(tests_dir);
addpath(root, fullfile(root,'utils'));

data_dir = fullfile(root,'test_data','3100nm_50mm_grating_CdS_400_PCE_200u_spacer');
cal_file = fullfile(root,'cailbration','center_3200nm.txt');

% ── Shared test state (accessed by nested functions) ────────────────────────
n_pass   = 0;
n_fail   = 0;
fail_log = {};   % {test_name, message}
name     = '';   % current test name — set before each test block

fprintf('=======================================================\n');
fprintf('  tIR V3  —  Test Suite\n');
fprintf('=======================================================\n');

% ════════════════════════════════════════════════════════════════════════════
%  SECTION 1: Environment
% ════════════════════════════════════════════════════════════════════════════
section('Environment');

name = 'MATLAB R2019b or newer';
try
    assert(~verLessThan('matlab','9.7'), ...
        'Need MATLAB R2019b+ (v9.7). Detected: %s. Features like clim() require R2019b+.', version);
    pass();
catch e; fail(e); end

name = 'Signal Processing Toolbox (needed for ds.filter())';
try
    assert(license('test','Signal_Toolbox') == 1, ...
        'Signal Processing Toolbox not licensed on this machine.\nds.filter() will throw an error. Install the toolbox or avoid filter() calls.');
    pass();
catch e; fail(e); end

for util = {'plotContourData','redblue','wl2wn'}
    name = sprintf('utils/%s.m on path', util{1});
    try
        assert(exist(util{1},'file') == 2, ...
            '%s not found on MATLAB path.\nExpected at: %s\nThe top-level run_tIR_analysis.m adds this automatically; if running manually, call:\n  addpath(root, fullfile(root,''utils''))', ...
            util{1}, fullfile(root,'utils'));
        pass();
    catch e; fail(e); end
end

% ════════════════════════════════════════════════════════════════════════════
%  SECTION 2: Test data integrity
% ════════════════════════════════════════════════════════════════════════════
section('Test data integrity');

name = 'test_data/ directory exists';
try
    assert(isfolder(data_dir), ...
        'test_data not found at:\n  %s\nCopy the test_data/ folder into V3/ before running tests.', data_dir);
    pass();
catch e; fail(e); end

for suf = {'_Data','_StDev','_Time'}
    name = sprintf('*%s.txt present in test_data', suf{1});
    try
        assert(~isempty(dir(fullfile(data_dir,['*' suf{1} '.txt']))), ...
            'No *%s.txt found in:\n  %s\nData files must follow the naming convention: root_name%s.txt', ...
            suf{1}, data_dir, suf{1});
        pass();
    catch e; fail(e); end
end

name = 'probe_*.txt present in test_data';
try
    assert(~isempty(dir(fullfile(data_dir,'probe_*.txt'))), ...
        'No probe_*.txt found in:\n  %s\nProbe normalization tests will fail. Add a probe file or set cfg.probe_file=''none''.', data_dir);
    pass();
catch e; fail(e); end

name = 'calibration file exists';
try
    assert(isfile(cal_file), ...
        'Calibration file not found:\n  %s\nProvide a center_XXXX.txt with one wavelength (nm) per pixel row.', cal_file);
    pass();
catch e; fail(e); end

name = 'calibration file has >=32 positive values';
try
    cal = load(cal_file);
    assert(numel(cal) >= 32, ...
        'Calibration file has %d values, need >=32. File may be truncated:\n  %s', numel(cal), cal_file);
    assert(all(cal > 0), ...
        'Calibration file has non-positive wavelengths. File may be corrupted:\n  %s', cal_file);
    pass();
catch e; fail(e); end

% ════════════════════════════════════════════════════════════════════════════
%  SECTION 3: tIRConfig
% ════════════════════════════════════════════════════════════════════════════
section('tIRConfig');

name = 'defaults() has all required fields';
try
    cfg0 = tIRConfig.defaults();
    req  = {'sample_name','data_dir','cal_file','probe_file','root_name', ...
            'pump_power_nJ','polarisation','time_unit','pixel_region','n_pixels', ...
            'cm_axis','time_zero','bg_subtract','plot_xRange','plot_yRange', ...
            'projection_negate','slice_wavenumbers','slice_times'};
    miss = req(~cellfun(@(f) isfield(cfg0,f), req));
    assert(isempty(miss), ...
        'tIRConfig.defaults() missing: %s\nAdd these fields to the defaults() method.', strjoin(miss,', '));
    pass();
catch e; fail(e); end

name = 'fromFile() loads example_config.m as struct';
try
    c = tIRConfig.fromFile(fullfile(root,'example_config.m'));
    assert(isstruct(c), ...
        'fromFile() returned %s, expected struct.\nCheck that example_config.m defines a variable named ''cfg''.', class(c));
    pass();
catch e; fail(e); end

name = 'validate() warns on empty data_dir';
try
    c2 = tIRConfig.defaults(); c2.root_name='x'; c2.cal_file='x.txt';
    lastwarn('');
    tIRConfig.validate(c2);
    [wmsg,~] = lastwarn();
    assert(~isempty(wmsg), ...
        'validate() issued no warning for empty data_dir.\nThe required field check in validate() may be broken.');
    pass();
catch e; fail(e); end

name = 'applyDefaults fills missing fields in a partial config';
try
    c3 = tIRConfig.fromFile(fullfile(root,'example_config.m'));
    assert(isfield(c3,'n_pixels') && isfield(c3,'polarisation'), ...
        'Fields ''n_pixels'' or ''polarisation'' missing after fromFile(). Check applyDefaults() private method.');
    pass();
catch e; fail(e); end

% ════════════════════════════════════════════════════════════════════════════
%  SECTION 4: load() — data types and shapes
% ════════════════════════════════════════════════════════════════════════════
section('tIRDataset — load() data types and shapes');

cfg = tIRConfig.fromFile(fullfile(root,'example_config.m'));
ds  = tIRDataset(cfg);
ds.load();

name = 'isLoaded = true after load()';
try
    assert(ds.isLoaded, 'ds.isLoaded is still false after load(). load() may have failed silently.');
    pass();
catch e; fail(e); end

name = 'processedData is 2-D real double matrix';
try
    M = ds.processedData;
    assert(isnumeric(M) && isreal(M) && ndims(M)==2 && ~isempty(M), ...
        'processedData: class=%s, isreal=%d, ndims=%d, empty=%d.\nExpected a 2-D real double [pixels x time].', ...
        class(M), isreal(M), ndims(M), isempty(M));
    pass();
catch e; fail(e); end

name = 'processedData has 32 pixel rows (top region, n_pixels=32)';
try
    nr = size(ds.processedData,1);
    assert(nr==32, ...
        'processedData has %d rows, expected 32.\nCheck cfg.n_pixels=%d and cfg.pixel_region=''%s''.', ...
        nr, cfg.n_pixels, cfg.pixel_region);
    pass();
catch e; fail(e); end

name = 'processedData has >1 time columns';
try
    nc = size(ds.processedData,2);
    assert(nc>1, ...
        'processedData has only %d time columns. Data file may be empty or mis-parsed.', nc);
    pass();
catch e; fail(e); end

name = 'rawData equals processedData before any filter';
try
    assert(isequal(ds.rawData, ds.processedData), ...
        'rawData ~= processedData before filter was applied. Unexpected mutation inside load().');
    pass();
catch e; fail(e); end

name = 'timeAxis is numeric row vector [1 x nTime]';
try
    t = ds.timeAxis;
    assert(isnumeric(t) && isrow(t), ...
        'timeAxis: class=%s, size=[%s]. Expected numeric row vector [1 x nTime].', class(t), num2str(size(t)));
    pass();
catch e; fail(e); end

name = 'timeAxis length == processedData columns';
try
    assert(numel(ds.timeAxis)==size(ds.processedData,2), ...
        'timeAxis has %d elements, processedData has %d columns.\nTime file length may not match data file length.', ...
        numel(ds.timeAxis), size(ds.processedData,2));
    pass();
catch e; fail(e); end

name = 'timeAxis is monotonically increasing';
try
    assert(all(diff(ds.timeAxis)>0), ...
        'timeAxis is not monotonically increasing.\nIf scanner runs high→low, load() should negate (t=-t) not flip the array.');
    pass();
catch e; fail(e); end

name = 'waveAxis is numeric row vector [1 x nPixel]';
try
    w = ds.waveAxis;
    assert(isnumeric(w) && isrow(w), ...
        'waveAxis: class=%s, size=[%s]. Expected numeric row vector [1 x nPixel].', class(w), num2str(size(w)));
    pass();
catch e; fail(e); end

name = 'waveAxis length == processedData rows';
try
    assert(numel(ds.waveAxis)==size(ds.processedData,1), ...
        'waveAxis has %d elements, processedData has %d rows.\nCalibration file may have wrong number of values.', ...
        numel(ds.waveAxis), size(ds.processedData,1));
    pass();
catch e; fail(e); end

name = 'waveAxis is monotonically increasing (sorted cm-1)';
try
    assert(all(diff(ds.waveAxis)>0), ...
        'waveAxis is not sorted ascending. The sort+reindex step in load() may be broken.');
    pass();
catch e; fail(e); end

name = 'waveAxis in plausible IR range 1000–8000 cm-1';
try
    assert(min(ds.waveAxis)>1000 && max(ds.waveAxis)<8000, ...
        'waveAxis spans %.0f–%.0f cm-1, outside expected IR range 1000–8000 cm-1.\nCalibration values should be wavelengths in nm, not wavenumbers.', ...
        min(ds.waveAxis), max(ds.waveAxis));
    pass();
catch e; fail(e); end

name = 'stdev is same size as processedData';
try
    assert(isequal(size(ds.stdev), size(ds.processedData)), ...
        'stdev is [%s], processedData is [%s].\nStDev file may be missing or have different dimensions.', ...
        num2str(size(ds.stdev)), num2str(size(ds.processedData)));
    pass();
catch e; fail(e); end

name = 'hasProbe = true (probe_*.txt auto-detected)';
try
    assert(ds.hasProbe, ...
        'hasProbe is false — no probe_*.txt found in data_dir.\nAdd a probe file or set cfg.probe_file=''none'' to skip normalization.');
    pass();
catch e; fail(e); end

name = 'probeRef is [32 x 1] double column vector';
try
    assert(isequal(size(ds.probeRef),[32 1]) && isnumeric(ds.probeRef), ...
        'probeRef is [%s] %s. Expected [32 1] double.\nCheck cfg.probe_col=%d and the probe file column layout.', ...
        num2str(size(ds.probeRef)), class(ds.probeRef), cfg.probe_col);
    pass();
catch e; fail(e); end

name = 'probeRef is all-positive (raw transmitted intensity)';
try
    assert(all(ds.probeRef > 0), ...
        'probeRef has %d non-positive values.\nProbe should be raw transmitted intensity (>0). Wrong column? cfg.probe_col=%d.', ...
        sum(ds.probeRef<=0), cfg.probe_col);
    pass();
catch e; fail(e); end

% ════════════════════════════════════════════════════════════════════════════
%  SECTION 5: normalize()
% ════════════════════════════════════════════════════════════════════════════
section('tIRDataset — normalize()');

ds.normalize();

name = 'dataNorm same size as processedData';
try
    assert(isequal(size(ds.dataNorm), size(ds.processedData)), ...
        'dataNorm is [%s], processedData is [%s].\nnormalize() may have failed silently.', ...
        num2str(size(ds.dataNorm)), num2str(size(ds.processedData)));
    pass();
catch e; fail(e); end

name = 'dataNorm is all-finite (no NaN or Inf)';
try
    n_bad = sum(~isfinite(ds.dataNorm(:)));
    assert(n_bad==0, ...
        'dataNorm has %d non-finite values (NaN/Inf).\nprobeRef may contain zeros (dead pixels). Check probe file.', n_bad);
    pass();
catch e; fail(e); end

name = 'dataNorm differs from processedData (normalization took effect)';
try
    assert(~isequal(ds.dataNorm, ds.processedData), ...
        'dataNorm is identical to processedData — normalization had no effect.\nIs probeRef all-ones? Check probe file values.');
    pass();
catch e; fail(e); end

% ════════════════════════════════════════════════════════════════════════════
%  SECTION 6: filter()
% ════════════════════════════════════════════════════════════════════════════
section('tIRDataset — filter()');

ds_f = tIRDataset(cfg); ds_f.load();

name = 'isFiltered = true after filter()';
try
    ds_f.filter('order',3,'window',7);
    assert(ds_f.isFiltered, 'isFiltered is still false after filter(). The SG filter may not have been applied.');
    pass();
catch e; fail(e); end

name = 'processedData changes after filter()';
try
    assert(~isequal(ds_f.rawData, ds_f.processedData), ...
        'processedData is unchanged after filter(). Window may be too large or data is constant.');
    pass();
catch e; fail(e); end

name = 'filter(apply=false) reverts to rawData';
try
    ds_f.filter('apply',false);
    assert(~ds_f.isFiltered, 'isFiltered is true after filter(apply=false). Reset logic may be broken.');
    assert(isequal(ds_f.processedData, ds_f.rawData), ...
        'processedData did not revert to rawData after filter(apply=false).');
    pass();
catch e; fail(e); end

% ════════════════════════════════════════════════════════════════════════════
%  SECTION 7: waveToPixel()
% ════════════════════════════════════════════════════════════════════════════
section('tIRDataset — waveToPixel()');

name = 'waveToPixel(3000) returns scalar integer in [1 32]';
try
    px = ds.waveToPixel(3000);
    np = size(ds.processedData,1);
    assert(isscalar(px) && isnumeric(px), ...
        'waveToPixel returned non-scalar %s. Expected single integer.', mat2str(px));
    assert(px>=1 && px<=np, ...
        'waveToPixel(3000) returned %d, outside valid range [1 %d].\nwaveAxis spans %.0f–%.0f cm-1 — 3000 cm-1 may be outside range.', ...
        px, np, min(ds.waveAxis), max(ds.waveAxis));
    pass();
catch e; fail(e); end

name = 'waveToPixel on exact axis value returns that index';
try
    px = ds.waveToPixel(ds.waveAxis(10));
    assert(px==10, ...
        'waveToPixel(waveAxis(10)) returned %d, expected 10. Nearest-neighbour lookup may be broken.', px);
    pass();
catch e; fail(e); end

% ════════════════════════════════════════════════════════════════════════════
%  SECTION 8: getResults()
% ════════════════════════════════════════════════════════════════════════════
section('tIRDataset — getResults()');

r = ds.getResults();

req_fields = {'timeAxis_fs','timeAxis_ps','waveAxis','processedData','dataNorm', ...
              'projection','spectralSlices','timeSlices','label','sampleName'};
for i = 1:numel(req_fields)
    f = req_fields{i};
    name = sprintf('getResults() has field: %s', f);
    try
        assert(isfield(r,f), ...
            'getResults() is missing field ''%s''.\nAdd it to getResults() in tIRDataset.m.', f);
        pass();
    catch e; fail(e); end
end

name = 'timeAxis_ps = timeAxis_fs / 1000';
try
    assert(max(abs(r.timeAxis_ps - r.timeAxis_fs/1000)) < 1e-9, ...
        'timeAxis_ps does not equal timeAxis_fs/1000. Unit conversion error in getResults().');
    pass();
catch e; fail(e); end

name = 'projection.signal_norm is a numeric row vector';
try
    s = r.projection.signal_norm;
    assert(isnumeric(s) && isrow(s), ...
        'projection.signal_norm is [%s] %s. Expected numeric row vector.', num2str(size(s)), class(s));
    pass();
catch e; fail(e); end

% ════════════════════════════════════════════════════════════════════════════
%  SECTION 9: Functional scenarios
% ════════════════════════════════════════════════════════════════════════════
section('Functional scenarios');

name = 'S1 — probe=none: dataNorm equals processedData';
try
    c = cfg; c.probe_file = 'none';
    d = tIRDataset(c); d.load(); d.normalize();
    assert(~d.hasProbe, 'hasProbe should be false when probe_file=''none''.');
    assert(isequal(d.dataNorm, d.processedData), ...
        'With no probe, dataNorm should equal processedData (identity normalization fallback).');
    pass();
catch e; fail(e); end

name = 'S2 — pixel_region=bottom: loads 32 pixels';
try
    c = cfg; c.pixel_region = 'bottom';
    d = tIRDataset(c); d.load();
    assert(size(d.processedData,1)==32, ...
        'pixel_region=''bottom'' loaded %d pixels, expected 32.\nData file may have fewer than 64 rows total.', ...
        size(d.processedData,1));
    pass();
catch e; fail(e); end

name = 'S3 — pixel_region=all: loads all rows in the file (>= n_pixels)';
try
    c = cfg; c.pixel_region = 'all';
    d = tIRDataset(c); d.load();
    got = size(d.processedData,1);
    assert(got >= cfg.n_pixels, ...
        'pixel_region=''all'' loaded %d pixels, expected at least n_pixels=%d.\nFor a 64-pixel detector this should be 64; test_data has %d rows.', ...
        got, cfg.n_pixels, got);
    pass();
catch e; fail(e); end

name = 'S4 — time_unit=fs: x-label contains ''fs''';
try
    c = cfg; c.time_unit = 'fs';
    d = tIRDataset(c); d.load(); d.normalize();
    d.plotSlices(cfg.slice_wavenumbers, 'figureNum', 91);
    xl = get(get(gca,'XLabel'),'String');
    assert(contains(xl,'fs'), ...
        'x-label is ''%s'', expected to contain ''fs'' when time_unit=''fs''.', xl);
    close(figure(91));
    pass();
catch e; fail(e); end

name = 'S5 — cm_axis=false: waveAxis is pixel indices 1:32';
try
    c = cfg; c.cm_axis = false;
    d = tIRDataset(c); d.load();
    np = size(d.processedData,1);
    assert(isequal(d.waveAxis, 1:np), ...
        'cm_axis=false should give waveAxis=1:%d, got %.0f:%.0f.', np, min(d.waveAxis), max(d.waveAxis));
    pass();
catch e; fail(e); end

name = 'S6 — bg_subtract=true: reduces peak signal magnitude';
try
    c = cfg; c.bg_subtract = true;
    d_bg = tIRDataset(c);   d_bg.load();
    d_nb = tIRDataset(cfg); d_nb.load();
    after  = max(abs(d_bg.processedData(:)));
    before = max(abs(d_nb.processedData(:)));
    assert(after < before, ...
        'bg_subtract=true did not reduce max signal (before=%.4f, after=%.4f).\nNo pre-t0 frames may exist, or time_zero is at the start of the scan.', ...
        before, after);
    pass();
catch e; fail(e); end

name = 'S7 — coherent peak is within 500 fs of t=0 (time_zero set correctly)';
try
    d = tIRDataset(cfg); d.load();
    prj = mean(abs(d.processedData), 1);
    [~, pk] = max(prj);
    t_peak  = d.timeAxis(pk);
    assert(abs(t_peak) < 500, ...
        'Coherent peak is at %.0f fs, expected within 500 fs of t=0.\nAdjust cfg.time_zero (currently %.1f fs) by reading the peak from ds.plotProjection().', ...
        t_peak, cfg.time_zero);
    pass();
catch e; fail(e); end

name = 'S8 — bad root_name: error message names the missing file';
try
    c = cfg; c.root_name = 'nonexistent_xyz_99';
    d = tIRDataset(c);
    threw = false; emsg = '';
    try; d.load(); catch e2; threw=true; emsg=e2.message; end
    assert(threw, ...
        'load() did not throw for a nonexistent root_name. The missing-file guard may be broken.');
    assert(contains(emsg,'nonexistent_xyz_99'), ...
        'Error message does not name the bad root_name.\nGot: ''%s''\nExpected the message to include ''nonexistent_xyz_99'' and the data_dir path.', emsg);
    pass();
catch e; fail(e); end

name = 'S9 — SG filter: plot title contains ''[SG ord=X win=Y]''';
try
    d = tIRDataset(cfg); d.load(); d.normalize();
    d.filter('order',3,'window',7);
    d.plotProjection('figureNum', 92);
    t = get(get(gca,'Title'),'String');
    assert(contains(t,'SG'), ...
        'plotProjection title ''%s'' does not show SG filter info.\nCheck the plotTitle() override in tIRDataset (protected method).', t);
    close(figure(92));
    pass();
catch e; fail(e); end

% ════════════════════════════════════════════════════════════════════════════
%  FINAL REPORT
% ════════════════════════════════════════════════════════════════════════════
total = n_pass + n_fail;
fprintf('\n=======================================================\n');
if n_fail == 0
    fprintf('  ALL %d TESTS PASSED\n', total);
else
    fprintf('  %d / %d PASSED   |   %d FAILED\n', n_pass, total, n_fail);
    fprintf('\nFailed tests:\n');
    for i = 1:size(fail_log,1)
        fprintf('  [%d] %s\n      → %s\n\n', i, fail_log{i,1}, fail_log{i,2});
    end
    fprintf('Tip: fix the top failure first — later failures may be cascading.\n');
end
fprintf('=======================================================\n');

% ── Nested helpers (share workspace with the parent function) ────────────────
    function pass()
        fprintf('  [PASS] %s\n', name);
        n_pass = n_pass + 1;
    end

    function fail(e)
        fprintf('  [FAIL] %s\n         → %s\n', name, e.message);
        n_fail    = n_fail + 1;
        fail_log(end+1, :) = {name, e.message};
    end

    function section(title)
        fprintf('\n── %s\n', title);
    end

end
