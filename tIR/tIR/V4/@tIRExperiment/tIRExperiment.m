classdef tIRExperiment < handle
% TIREXPERIMENT  Container for multiple tIRDataset objects (e.g. power series).
%
% Usage:
%   % Single config, multiple root_names:
%   base_cfg = tIRConfig.defaults();
%   base_cfg.data_dir = '/path/to/data';
%   base_cfg.cal_file = '/path/to/cal.txt';
%
%   cfgs = tIRExperiment.buildConfigs(base_cfg, ...
%       {'25nJ_scan_01', '50nJ_scan_02', '100nJ_scan_03'}, ...
%       [25, 50, 100]);
%
%   exp = tIRExperiment(cfgs);
%   exp.loadAll();
%   exp.compare([2800 2900]);
%   [pwr, amp] = exp.extractAmplitude(2850, 5000);

    properties
        datasets    % cell array of tIRDataset
        configs     % cell array of config structs (one per dataset)
    end

    methods

        % -------------------------------------------------------------- %
        %  Constructor                                                     %
        % -------------------------------------------------------------- %
        function obj = tIRExperiment(configs)
        % configs: single struct or cell array of structs.
            if isstruct(configs)
                obj.configs = {configs};
            else
                obj.configs = configs;
            end
            obj.datasets = {};
        end

        % -------------------------------------------------------------- %
        %  loadAll                                                         %
        % -------------------------------------------------------------- %
        function loadAll(obj)
        % Load and normalize every dataset. Errors in individual datasets are
        % caught and reported without stopping the rest.
            n = numel(obj.configs);
            obj.datasets = cell(n, 1);
            for i = 1:n
                cfg = obj.configs{i};
                fprintf('\n=== Dataset %d/%d: %s ===\n', i, n, cfg.root_name);
                try
                    ds = tIRDataset(cfg);
                    ds.load();
                    ds.normalize();
                    obj.datasets{i} = ds;
                catch ME
                    warning('tIRExperiment.loadAll: failed on ''%s'' — %s', cfg.root_name, ME.message);
                    obj.datasets{i} = [];
                end
            end
            n_ok = sum(~cellfun(@isempty, obj.datasets));
            fprintf('\nLoaded %d/%d datasets successfully.\n', n_ok, n);
        end

        % -------------------------------------------------------------- %
        %  compare — overlay time traces across datasets                  %
        % -------------------------------------------------------------- %
        function compare(obj, wavenumbers, varargin)
        % Overlay time traces at given wavenumbers across all loaded datasets.
        %
        %   exp.compare(2850)
        %   exp.compare([2800 2900], 'useNorm', true, 'figureNum', 5)
            p = inputParser;
            addParameter(p, 'figureNum', [],   @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'useNorm',   true, @islogical);
            addParameter(p, 'lineWidth', 2,    @isnumeric);
            addParameter(p, 'fontSize',  14,   @isnumeric);
            parse(p, varargin{:});
            opts = p.Results;

            if isempty(opts.figureNum), figure; else, figure(opts.figureNum); end
            hold on;
            for i = 1:numel(obj.datasets)
                ds = obj.datasets{i};
                if isempty(ds), continue; end
                d = ds.selectDataPublic(opts.useNorm);
                for j = 1:numel(wavenumbers)
                    px     = ds.waveToPixel(wavenumbers(j));
                    actual = ds.waveAxis(px);
                    plot(ds.timeAxis, d(px,:), 'LineWidth', opts.lineWidth, ...
                        'DisplayName', sprintf('%s @ %d cm^{-1}', ds.label, round(actual)));
                end
            end
            yline(0, '--k', 'HandleVisibility', 'off');
            hold off;
            legend('show', 'Interpreter', 'none');
            xlabel('\tau (fs)');
            ylabel('\DeltaA (mOD)');
            title(sprintf('Comparison at %s cm^{-1}', mat2str(round(wavenumbers))));
            set(gca, 'FontSize', opts.fontSize);
            set(gcf, 'Color', 'w');
        end

        % -------------------------------------------------------------- %
        %  compareSpectra — overlay spectra at given time delays          %
        % -------------------------------------------------------------- %
        function compareSpectra(obj, times_fs, varargin)
        % Overlay spectra at given time delays across all loaded datasets.
        %
        %   exp.compareSpectra([500 5000 50000])
            p = inputParser;
            addParameter(p, 'figureNum', [],   @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'useNorm',   true, @islogical);
            addParameter(p, 'lineWidth', 2,    @isnumeric);
            addParameter(p, 'fontSize',  14,   @isnumeric);
            parse(p, varargin{:});
            opts = p.Results;

            if isempty(opts.figureNum), figure; else, figure(opts.figureNum); end
            hold on;
            cmap = lines(numel(obj.datasets) * numel(times_fs));
            k = 0;
            for i = 1:numel(obj.datasets)
                ds = obj.datasets{i};
                if isempty(ds), continue; end
                d = ds.selectDataPublic(opts.useNorm);
                for j = 1:numel(times_fs)
                    [~, ti] = min(abs(ds.timeAxis - times_fs(j)));
                    k = k + 1;
                    plot(ds.waveAxis, d(:, ti), 'Color', cmap(k,:), ...
                        'LineWidth', opts.lineWidth, ...
                        'DisplayName', sprintf('%s, %d fs', ds.label, round(ds.timeAxis(ti))));
                end
            end
            yline(0, '--k', 'HandleVisibility', 'off');
            hold off;
            legend('show', 'Interpreter', 'none');
            xlabel('\omega (cm^{-1})');
            ylabel('\DeltaA (mOD)');
            set(gca, 'FontSize', opts.fontSize);
            set(gcf, 'Color', 'w');
        end

        % -------------------------------------------------------------- %
        %  extractAmplitude — power dependence                            %
        % -------------------------------------------------------------- %
        function [powers, amplitudes] = extractAmplitude(obj, wavenumber, time_delay)
        % Extract amplitude at (wavenumber, time_delay) from each dataset.
        % Returns arrays sorted by pump_power_nJ for power dependence plots.
        %
        %   [pwr, amp] = exp.extractAmplitude(2850, 5000);
        %   figure; plot(pwr, amp, 'o-');
            n          = numel(obj.datasets);
            powers     = NaN(n, 1);
            amplitudes = NaN(n, 1);

            for i = 1:n
                ds = obj.datasets{i};
                if isempty(ds), continue; end
                px     = ds.waveToPixel(wavenumber);
                [~,ti] = min(abs(ds.timeAxis - time_delay));
                d      = ds.selectDataPublic(true);
                amplitudes(i) = d(px, ti);
                powers(i)     = ds.config.pump_power_nJ;
            end

            valid      = ~isnan(powers);
            [powers, idx] = sort(powers(valid));
            amps_valid    = amplitudes(valid);
            amplitudes    = amps_valid(idx);
        end

        % -------------------------------------------------------------- %
        %  save                                                            %
        % -------------------------------------------------------------- %
        function save(obj, varargin)
        % Save all datasets individually.
            for i = 1:numel(obj.datasets)
                if ~isempty(obj.datasets{i})
                    obj.datasets{i}.save(varargin{:});
                end
            end
        end

    end

    methods (Static)

        function cfgs = buildConfigs(base_cfg, root_names, pump_powers_nJ)
        % Build a cell array of configs from a shared base and a list of scan names.
        %
        %   cfgs = tIRExperiment.buildConfigs(base_cfg, ...
        %       {'25nJ_scan', '50nJ_scan'}, [25 50]);
            if nargin < 3
                pump_powers_nJ = nan(size(root_names));
            end
            cfgs = cell(numel(root_names), 1);
            for i = 1:numel(root_names)
                c              = base_cfg;
                c.root_name    = root_names{i};
                c.pump_power_nJ = pump_powers_nJ(i);
                cfgs{i}        = c;
            end
        end

    end

end
