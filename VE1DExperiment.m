classdef VE1DExperiment < handle
% VE1DExperiment  Load, process, and plot 1D vibrational echo T2 scan data.
%
% Usage:
%   exp = VE1DExperiment(dataPath, dataName, probeFile, wlAxisFile);
%   exp.pixelRange = [580, 950];
%   exp.load();
%   exp.filter('order', 5, 'window', 35);
%   exp.plotContour();
%   exp.plotProjection();
%   exp.plotSlices([24000, 25000]);
%   exp.save();

    properties
        rawData         % [pixel × time]  raw normalized data
        processedData   % [pixel × time]  after filtering (or same as raw)
        timeAxis        % [1 × time]      in fs
        waveAxis        % [1 × pixel]     full CCD axis in cm⁻¹
        pixelRange      % [pMin pMax]     display/processing window
        label           % string          derived from dataName
        isLoaded  = false
        isFiltered = false
    end

    properties (Access = private)
        dataPath
        dataName        % char or cell array of chars
        probeData       % raw probe matrix for normalization
        filterOpts      % stored for display in plotTitle
    end

    % ------------------------------------------------------------------ %
    %  Public API
    % ------------------------------------------------------------------ %
    methods

        function obj = VE1DExperiment(dataPath, dataName, probeFile, wlAxisFile)
        % Constructor.  probeFile and wlAxisFile are optional paths.
            obj.dataPath = dataPath;
            obj.dataName = dataName;

            % derive human-readable label
            if iscell(dataName)
                obj.label = strrep(dataName{1}, '_', ' ');
            else
                obj.label = strrep(dataName, '_', ' ');
            end

            % load probe
            if nargin >= 3 && ~isempty(probeFile)
                obj.probeData = load(probeFile);
            else
                obj.probeData = [];
            end

            % load CCD wavelength calibration and convert to wavenumbers
            if nargin >= 4 && ~isempty(wlAxisFile)
                tmp = load(wlAxisFile);
                fields = fieldnames(tmp);
                wl = tmp.(fields{1});   % nm
                obj.waveAxis = 1e7 ./ wl;
            end
        end

        % -------------------------------------------------------------- %

        function load(obj, opts)
        % load()  Read .dat files, average scans, normalize by probe.
        %
        % Optional opts fields:
        %   flipTime  (false)  – negate time axis
        %   flipSign  (false)  – negate data
        %   normalizeByProbe (true if probeData present)
            if nargin < 2, opts = struct(); end
            opts = obj.mergeDefaults(opts, struct( ...
                'flipTime',          false, ...
                'flipSign',          false, ...
                'normalizeByProbe',  ~isempty(obj.probeData)));

            names = obj.cellNames();
            firstData = readmatrix(obj.filePath(names{1}));
            accumData = zeros(size(firstData, 1) - 2, size(firstData, 2));

            for i = 1:length(names)
                fp = obj.filePath(names{i});
                if ~exist(fp, 'file')
                    error('VE1DExperiment:fileNotFound', 'File not found:\n  %s', fp);
                end
                raw = readmatrix(fp);

                tRow = raw(end, :);
                if opts.flipTime, tRow = -tRow; end
                obj.timeAxis = tRow;

                d = raw(1:end-2, :);
                if opts.flipSign, d = -d; end
                if opts.normalizeByProbe && ~isempty(obj.probeData)
                    d = d ./ obj.probeData;
                end
                accumData = accumData + d;
            end

            if length(names) > 1
                accumData = accumData / length(names);
            end

            obj.rawData       = accumData;
            obj.processedData = accumData;
            obj.isLoaded      = true;
            obj.isFiltered    = false;

            fprintf('Loaded %d scan(s): %d pixels × %d time points\n', ...
                length(names), size(accumData, 1), size(accumData, 2));
        end

        % -------------------------------------------------------------- %

        function filter(obj, varargin)
        % filter()  Apply Savitzky-Golay filter along spectral dimension.
        %
        % Parameters (name-value):
        %   order      (5)     polynomial order
        %   window     (11)    window length (auto-rounded to odd)
        %   pixelRange ([1 N]) rows to filter; defaults to obj.pixelRange
        %   dim        (1)     1 = along wavelength, 2 = along time
        %   apply      (true)  set false to revert to raw data
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'order',      5,                       @isnumeric);
            addParameter(p, 'window',     11,                      @isnumeric);
            addParameter(p, 'pixelRange', obj.activePixelRange(),  @isnumeric);
            addParameter(p, 'dim',        1,                       @isnumeric);
            addParameter(p, 'apply',      true,                    @islogical);
            parse(p, varargin{:});
            o = p.Results;

            if ~o.apply
                obj.processedData = obj.rawData;
                obj.isFiltered    = false;
                return;
            end

            if mod(o.window, 2) == 0
                o.window = o.window + 1;
                warning('VE1DExperiment:filter', ...
                    'Window adjusted to %d (must be odd)', o.window);
            end

            pMin = o.pixelRange(1);  pMax = o.pixelRange(2);
            f = obj.rawData;

            if o.dim == 1
                for t = 1:size(f, 2)
                    f(pMin:pMax, t) = sgolayfilt(f(pMin:pMax, t), o.order, o.window);
                end
            else
                for w = pMin:pMax
                    f(w, :) = sgolayfilt(f(w, :), o.order, o.window);
                end
            end

            obj.processedData = f;
            obj.filterOpts    = o;
            obj.isFiltered    = true;
            fprintf('SG filter applied — order %d, window %d\n', o.order, o.window);
        end

        % -------------------------------------------------------------- %

        function plotContour(obj, varargin)
        % plotContour()  Filled contour plot of processedData.
        %
        % Parameters (name-value):
        %   pixelRange   ([pMin pMax])
        %   clevels      (default percentage levels)
        %   colormap     (@redblue_3)
        %   symmetric    (true)   symmetric colorbar around zero
        %   showLines    (true)   overlay contour lines
        %   lineWidth    (0.05)
        %   figureNum    ([])     figure number; empty = new figure
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'pixelRange', obj.activePixelRange(), @isnumeric);
            addParameter(p, 'clevels',    [0.01 0.05 0.1 0.2 0.3 0.4 0.5 ...
                                           0.6  0.7  0.8 0.9 1.0], @isnumeric);
            addParameter(p, 'colormap',   @redblue_3, ...
                @(x) ischar(x) || isa(x, 'function_handle'));
            addParameter(p, 'symmetric',  true,  @islogical);
            addParameter(p, 'showLines',  true,  @islogical);
            addParameter(p, 'lineWidth',  0.05,  @isnumeric);
            addParameter(p, 'figureNum',  [],    @isnumeric);
            parse(p, varargin{:});
            o = p.Results;

            pMin = o.pixelRange(1);  pMax = o.pixelRange(2);
            wax  = obj.waveAxis(pMin:pMax);
            zdat = obj.processedData(pMin:pMax, :);

            scalar = max(abs(zdat(:)));
            levels = scalar * o.clevels;
            if o.symmetric
                levels = [-fliplr(levels), levels];
            end

            obj.openFigure(o.figureNum);
            [X, Y] = meshgrid(obj.timeAxis, wax);
            contourf(X, Y, zdat, levels, 'LineStyle', 'none');

            if o.showLines
                hold on;
                contour(X, Y, zdat, levels, 'LineColor', 'k', 'LineWidth', o.lineWidth);
                hold off;
            end

            if isa(o.colormap, 'function_handle')
                colormap(o.colormap());
            else
                colormap(o.colormap);
            end

            cb = colorbar('Location', 'eastoutside');
            cb.Label.String = '\DeltaA (mOD)';

            if o.symmetric
                maxv = max(abs(zdat(:)));
                caxis([-maxv, maxv]);
            end

            xlabel('Time (fs)');
            ylabel('\omega_3/2\pic (cm^{-1})');
            title(obj.plotTitle());
            set(gca, 'Layer', 'top');
            box on;
        end

        % -------------------------------------------------------------- %

        function plotProjection(obj, varargin)
        % plotProjection()  Mean absolute signal vs time.
        %
        % Parameters (name-value):
        %   pixelRange  ([pMin pMax])
        %   figureNum   ([])
        %   color       ('r')
        %   lineWidth   (2)
        %   fontSize    (18)
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'pixelRange', obj.activePixelRange(), @isnumeric);
            addParameter(p, 'figureNum',  [],   @isnumeric);
            addParameter(p, 'color',      'r',  @(x) ischar(x) || isnumeric(x));
            addParameter(p, 'lineWidth',  2,    @isnumeric);
            addParameter(p, 'fontSize',   18,   @isnumeric);
            parse(p, varargin{:});
            o = p.Results;

            pRange = o.pixelRange(1):o.pixelRange(2);
            obj.openFigure(o.figureNum);
            plot(obj.timeAxis, mean(abs(obj.processedData(pRange, :))), ...
                'Color', o.color, 'LineWidth', o.lineWidth);

            title(['Projection — ', obj.plotTitle()]);
            xlabel('Time (fs)');
            ylabel('Signal (a.u.)');
            ax = gca; ax.FontSize = o.fontSize;
            set(gcf, 'color', 'w');
            grid on;
        end

        % -------------------------------------------------------------- %

        function plotSlices(obj, wavenumbers, varargin)
        % plotSlices(wavenumbers)  Time traces at given wavenumbers (cm⁻¹).
        %
        % Parameters (name-value):
        %   figureNum  ([])
        %   lineWidth  (2)
        %   fontSize   (16)
            obj.requireLoaded();
            if nargin < 2 || isempty(wavenumbers)
                error('VE1DExperiment:missingArg', ...
                    'Provide at least one wavenumber, e.g. exp.plotSlices([24000 25000])');
            end
            p = inputParser;
            addParameter(p, 'figureNum', [], @isnumeric);
            addParameter(p, 'lineWidth', 2,  @isnumeric);
            addParameter(p, 'fontSize',  16, @isnumeric);
            parse(p, varargin{:});
            o = p.Results;

            idx    = arrayfun(@(wn) obj.waveToPixel(wn), wavenumbers);
            colors = lines(length(wavenumbers));

            obj.openFigure(o.figureNum);
            hold on;
            lgd = cell(1, length(wavenumbers));
            for k = 1:length(wavenumbers)
                plot(obj.timeAxis, obj.processedData(idx(k), :), ...
                    'Color', colors(k,:), 'LineWidth', o.lineWidth);
                lgd{k} = sprintf('%d cm^{-1}  (px %d)', ...
                    round(obj.waveAxis(idx(k))), idx(k));
            end
            yline(0, '--k', 'LineWidth', 0.5);
            hold off;

            legend(lgd, 'Location', 'best');
            xlabel('Time (fs)');
            ylabel('\DeltaA (mOD)');
            title(['Spectral Slices — ', obj.plotTitle()]);
            ax = gca; ax.FontSize = o.fontSize;
            set(gcf, 'color', 'w');
            axis tight;
        end

        % -------------------------------------------------------------- %

        function save(obj, varargin)
        % save()  Write processed data to a timestamped .mat file.
        %
        % Parameters (name-value):
        %   dir  (pwd)  destination folder
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'dir', pwd, @ischar);
            parse(p, varargin{:});

            s.label         = obj.label;
            s.time          = obj.timeAxis;
            s.waveAxis      = obj.waveAxis;
            s.pixelRange    = obj.pixelRange;
            s.rawData       = obj.rawData;
            s.processedData = obj.processedData;
            s.isFiltered    = obj.isFiltered;
            if obj.isFiltered
                s.filterOpts = obj.filterOpts;
            end

            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
            fname = fullfile(p.Results.dir, ...
                [strrep(obj.label, ' ', '_'), '_', timestamp, '.mat']);
            save(fname, 's');
            fprintf('Saved: %s\n', fname);
        end

    end % public methods

    % ------------------------------------------------------------------ %
    %  Private helpers
    % ------------------------------------------------------------------ %
    methods (Access = private)

        function requireLoaded(obj)
            if ~obj.isLoaded
                error('VE1DExperiment:notLoaded', 'Call load() before this method.');
            end
        end

        function r = activePixelRange(obj)
            if ~isempty(obj.pixelRange)
                r = obj.pixelRange;
            elseif obj.isLoaded
                r = [1, size(obj.rawData, 1)];
            else
                r = [1, 1024];   % safe fallback before load()
            end
        end

        function t = plotTitle(obj)
            t = obj.label;
            if obj.isFiltered
                t = sprintf('SG (ord=%d, win=%d) — %s', ...
                    obj.filterOpts.order, obj.filterOpts.window, t);
            end
        end

        function idx = waveToPixel(obj, wn)
            [~, idx] = min(abs(obj.waveAxis - wn));
        end

        function names = cellNames(obj)
            if ischar(obj.dataName)
                names = {obj.dataName};
            else
                names = obj.dataName;
            end
        end

        function fp = filePath(obj, name)
            fp = fullfile(obj.dataPath, [name, '.dat']);
        end

        function openFigure(~, num)
            if ~isempty(num)
                figure(num);
            else
                figure;
            end
        end

        function opts = mergeDefaults(~, opts, defaults)
            for f = fieldnames(defaults)'
                if ~isfield(opts, f{1})
                    opts.(f{1}) = defaults.(f{1});
                end
            end
        end

    end % private methods

end % classdef
