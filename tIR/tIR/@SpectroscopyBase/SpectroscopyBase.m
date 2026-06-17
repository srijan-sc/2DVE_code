classdef (Abstract) SpectroscopyBase < handle
% SPECTROSCOPYBASE  Abstract base for 2D spectroscopy experiment classes.
%
% Subclasses must implement load(). All plotting, filtering, and saving
% are inherited and work identically across experiment types (tIR, 1DVE, etc.).
%
% Typical subclass usage:
%   exp = MyExperiment(cfg);
%   exp.pixelRange = [pMin pMax];
%   exp.load();
%   exp.filter('order', 5, 'window', 11);
%   exp.plotContour();
%   exp.plotSlices([2800, 2900]);
%   exp.save();

    properties
        rawData         % [pixel x time]  after load, before filter
        processedData   % [pixel x time]  after filter (equals rawData if unfiltered)
        timeAxis        % [1 x nTime]  fs
        waveAxis        % [1 x nPixel] cm-1 (or pixel index if cm_axis=false)
        pixelRange      % [pMin pMax]  active spectral window; empty = full range
        label      = '' % scan name (root_name)
        sampleName = '' % human label added to all plot titles, e.g. 'CdS 400nm'
        timeUnit   = 'fs' % 'fs' or 'ps' — controls x-axis label and display scaling
        isLoaded   = false
        isFiltered = false
    end

    properties (Access = protected)
        filterOpts = struct()
    end

    % ------------------------------------------------------------------ %
    %  Abstract — subclasses must implement                               %
    % ------------------------------------------------------------------ %
    methods (Abstract)
        load(obj)
    end

    % ------------------------------------------------------------------ %
    %  Public — shared across all experiment types                        %
    % ------------------------------------------------------------------ %
    methods

        function px = waveToPixel(obj, wn)
        % Return pixel index closest to wavenumber wn (cm-1).
            obj.requireLoaded();
            [~, px] = min(abs(obj.waveAxis(:) - wn));
        end

        function filter(obj, varargin)
        % Apply Savitzky-Golay smoothing to rawData -> processedData.
        %
        %   exp.filter('order', 5, 'window', 11)            along wavelength (dim 1)
        %   exp.filter('order', 3, 'window', 11, 'dim', 2)  along time
        %   exp.filter('apply', false)                       revert to rawData
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'order',  5,    @isnumeric);
            addParameter(p, 'window', 11,   @isnumeric);
            addParameter(p, 'dim',    1,    @isnumeric);
            addParameter(p, 'apply',  true, @islogical);
            parse(p, varargin{:});
            opts = p.Results;

            if ~opts.apply
                obj.processedData = obj.rawData;
                obj.isFiltered    = false;
                obj.filterOpts    = struct();
                return
            end

            win = opts.window;
            if mod(win, 2) == 0, win = win + 1; end

            r = obj.activePixelRange();
            d = obj.rawData(r(1):r(2), :);
            obj.processedData               = obj.rawData;
            obj.processedData(r(1):r(2), :) = sgolayfilt(d, opts.order, win, [], opts.dim);
            obj.isFiltered       = true;
            obj.filterOpts       = opts;
            obj.filterOpts.window = win;
        end

        function plotContour(obj, varargin)
        % Filled contour plot of processedData.
        %
        %   exp.plotContour()
        %   exp.plotContour('clevels', [0.1 0.3 0.5 1.0], 'figureNum', 1)
        %   exp.plotContour('xRange', [0 50000], 'yRange', [2900 3100])
        %
        % Contour style follows run_plot.m convention:
        %   - dense fill levels (clevels) with no lines
        %   - sparse overlay lines (lineLevels) at customScalar * scalar * lineLevels
        %   - 'Aptos Body' bold font, 13x10 cm figure
            obj.requireLoaded();
            p = inputParser;
            % Fill levels (fractions of max, positive half — mirrored symmetrically)
            addParameter(p, 'clevels',      [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.85 0.9 0.95 1.0], @isnumeric);
            % Sparse overlay line levels — both signs, fractions of max
            % Skip ±0.1/±0.2 on negative side to reduce noise-floor clutter
            addParameter(p, 'lineLevels',   [-0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9], @isnumeric);
            addParameter(p, 'customScalar', 1.5,            @isnumeric);
            addParameter(p, 'colormap',     @redblue,       @(x) ischar(x)||isa(x,'function_handle'));
            addParameter(p, 'symmetric',    true,           @islogical);
            addParameter(p, 'showLines',    true,           @islogical);
            addParameter(p, 'lineWidth',    2.2,            @isnumeric);
            addParameter(p, 'fontSize',     16,             @isnumeric);
            addParameter(p, 'fontName',     'Aptos Body',   @ischar);
            addParameter(p, 'figWidthCm',   13,             @isnumeric);
            addParameter(p, 'figHeightCm',  10,             @isnumeric);
            addParameter(p, 'cbarLabel',    '\DeltaA (mOD)',@ischar);
            addParameter(p, 'figureNum',    [],             @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'pixelRange',   obj.pixelRange, @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'xRange',       [],             @(x) isempty(x)||(isnumeric(x)&&numel(x)==2));
            addParameter(p, 'yRange',       [],             @(x) isempty(x)||(isnumeric(x)&&numel(x)==2));
            parse(p, varargin{:});
            opts = p.Results;

            r = obj.resolvePixelRange(opts.pixelRange);
            x = obj.dispTime(obj.timeAxis);
            y = obj.waveAxis(r(1):r(2));
            z = obj.processedData(r(1):r(2), :);

            if ~isempty(opts.xRange)
                xi = x >= opts.xRange(1) & x <= opts.xRange(2);
                x  = x(xi);  z = z(:, xi);
            end
            if ~isempty(opts.yRange)
                yi = y >= opts.yRange(1) & y <= opts.yRange(2);
                y  = y(yi);  z = z(yi, :);
            end

            obj.openFigure(opts.figureNum);
            fh = gcf;
            plotContourData(x, y, z, ...
                'FigureHandle',      fh, ...
                'ColorMap',          opts.colormap, ...
                'ContourLevels',     opts.clevels, ...
                'LineLevels',        opts.lineLevels, ...
                'CustomScalar',      opts.customScalar, ...
                'ScaleToMax',        true, ...
                'SymmetricColorbar', opts.symmetric, ...
                'ShowContourLines',  opts.showLines, ...
                'ContourLineWidth',  opts.lineWidth, ...
                'ContourLineColor',  'k', ...
                'XLabel',            obj.timeLabel(), ...
                'YLabel',            '\omega (cm^{-1})', ...
                'ColorbarLabel',     opts.cbarLabel, ...
                'FontSize',          opts.fontSize, ...
                'FontName',          opts.fontName, ...
                'FontBold',          true, ...
                'FigWidthCm',        opts.figWidthCm, ...
                'FigHeightCm',       opts.figHeightCm);
            title(obj.plotTitle(), 'Interpreter', 'none', ...
                'FontSize', opts.fontSize, 'FontName', opts.fontName, 'FontWeight', 'bold');
        end

        function plotSlices(obj, wavenumbers, varargin)
        % Plot time traces at N wavenumbers on the same axes.
        %
        %   exp.plotSlices([2800 2860 2920])
        %   exp.plotSlices([2800 2860], 'figureNum', 5)
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'figureNum', [], @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'lineWidth', 2,  @isnumeric);
            addParameter(p, 'fontSize',  16, @isnumeric);
            addParameter(p, 'fontName',  'Aptos Body', @ischar);
            addParameter(p, 'useNorm',   false, @islogical);
            parse(p, varargin{:});
            opts = p.Results;

            d = obj.selectData(opts.useNorm);
            t = obj.dispTime(obj.timeAxis);

            obj.openFigure(opts.figureNum);
            hold on;
            cmap = lines(numel(wavenumbers));
            lgd  = cell(numel(wavenumbers), 1);
            for i = 1:numel(wavenumbers)
                px     = obj.waveToPixel(wavenumbers(i));
                actual = obj.waveAxis(px);
                plot(t, d(px, :), 'Color', cmap(i,:), 'LineWidth', opts.lineWidth);
                lgd{i} = sprintf('%d cm^{-1}', round(actual));
            end
            yline(0, '--k', 'LineWidth', 1);
            hold off;
            legend(lgd, 'FontSize', opts.fontSize, 'FontName', opts.fontName);
            xlabel(obj.timeLabel());
            ylabel('\DeltaA (mOD)');
            title(obj.plotTitle(), 'Interpreter', 'none');
            obj.applyLineStyle(opts.fontSize, opts.fontName);
        end

        function plotTimeSlices(obj, times, varargin)
        % Plot spectra at N time delays. Times are in the current timeUnit.
        %
        %   exp.plotTimeSlices([0.5 5 50])   % if timeUnit='ps'
        %   exp.plotTimeSlices([500 5000 50000])  % if timeUnit='fs'
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'figureNum',  [], @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'pixelRange', obj.pixelRange, @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'lineWidth',  2,  @isnumeric);
            addParameter(p, 'fontSize',   16, @isnumeric);
            addParameter(p, 'fontName',   'Aptos Body', @ischar);
            addParameter(p, 'useNorm',    false, @islogical);
            parse(p, varargin{:});
            opts = p.Results;

            r = obj.resolvePixelRange(opts.pixelRange);
            d = obj.selectData(opts.useNorm);
            w = obj.waveAxis(r(1):r(2));
            t = obj.dispTime(obj.timeAxis);

            obj.openFigure(opts.figureNum);
            hold on;
            cmap = lines(numel(times));
            lgd  = cell(numel(times), 1);
            for i = 1:numel(times)
                [~, ti] = min(abs(t - times(i)));
                plot(w, d(r(1):r(2), ti), 'Color', cmap(i,:), 'LineWidth', opts.lineWidth);
                lgd{i}  = sprintf('%g %s', times(i), obj.timeUnit);
            end
            yline(0, '--k', 'LineWidth', 1);
            hold off;
            legend(lgd, 'Interpreter', 'none', 'FontSize', opts.fontSize, 'FontName', opts.fontName);
            xlabel('\omega (cm^{-1})');
            ylabel('\DeltaA (mOD)');
            title(obj.plotTitle(), 'Interpreter', 'none');
            obj.applyLineStyle(opts.fontSize, opts.fontName);
        end

        function plotProjection(obj, varargin)
        % Mean absolute signal across pixelRange vs time — use to find t=0.
        % 'negate' flips the sign so a negative-going signal plots as a decay.
        %
        %   exp.plotProjection()
        %   exp.plotProjection('negate', true, 'xRange', [0 50])  % ps
        %   exp.plotProjection('color', 'b', 'figureNum', 4)
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'figureNum',  [],    @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'pixelRange', obj.pixelRange, @(x) isempty(x)||isnumeric(x));
            addParameter(p, 'color',      'r',   @ischar);
            addParameter(p, 'lineWidth',  2,     @isnumeric);
            addParameter(p, 'fontSize',   16,    @isnumeric);
            addParameter(p, 'fontName',   'Aptos Body', @ischar);
            addParameter(p, 'negate',     false, @islogical);
            addParameter(p, 'xRange',     [],    @(x) isempty(x)||(isnumeric(x)&&numel(x)==2));
            parse(p, varargin{:});
            opts = p.Results;

            r   = obj.resolvePixelRange(opts.pixelRange);
            prj = mean(abs(obj.processedData(r(1):r(2), :)), 1);
            t   = obj.dispTime(obj.timeAxis);

            if opts.negate,  prj = -prj; end
            if ~isempty(opts.xRange)
                xi  = t >= opts.xRange(1) & t <= opts.xRange(2);
                t   = t(xi);  prj = prj(xi);
            end

            obj.openFigure(opts.figureNum);
            plot(t, prj, 'Color', opts.color, 'LineWidth', opts.lineWidth);
            yline(0, '--k', 'LineWidth', 1);
            xlabel(obj.timeLabel());
            if opts.negate
                ylabel('Mean -|\DeltaA|');
            else
                ylabel('Mean |\DeltaA|');
            end
            title(['Projection — ' obj.plotTitle()], 'Interpreter', 'none');
            obj.applyLineStyle(opts.fontSize, opts.fontName);
        end

        function save(obj, varargin)
        % Save processed data to a timestamped .mat file.
        %
        %   exp.save()
        %   exp.save('dir', '/path/to/output')
            obj.requireLoaded();
            p = inputParser;
            addParameter(p, 'dir', '', @ischar);
            parse(p, varargin{:});
            opts = p.Results;

            s               = struct();
            s.label         = obj.label;
            s.sampleName    = obj.sampleName;
            s.timeAxis      = obj.timeAxis;
            s.waveAxis      = obj.waveAxis;
            s.pixelRange    = obj.pixelRange;
            s.rawData       = obj.rawData;
            s.processedData = obj.processedData;
            s.isFiltered    = obj.isFiltered;
            if obj.isFiltered, s.filterOpts = obj.filterOpts; end

            timestamp  = datestr(now, 'yyyymmdd_HHMMSS');
            safe_label = matlab.lang.makeValidName(obj.label);
            fname      = sprintf('%s_%s.mat', safe_label, timestamp);
            fpath      = fullfile(opts.dir, fname);

            save(fpath, '-struct', 's');
            fprintf('Saved: %s\n', fpath);
        end

    end

    % ------------------------------------------------------------------ %
    %  Protected helpers — available to subclasses                        %
    % ------------------------------------------------------------------ %
    methods (Access = protected)

        function requireLoaded(obj)
            if ~obj.isLoaded
                error('%s: call load() before using this method.', class(obj));
            end
        end

        function r = activePixelRange(obj)
            if isempty(obj.pixelRange)
                r = [1, size(obj.processedData, 1)];
            else
                r = obj.pixelRange;
            end
        end

        function r = resolvePixelRange(obj, pr)
            if isempty(pr)
                r = obj.activePixelRange();
            else
                r = pr;
            end
        end

        function d = selectData(obj, useNorm)
        % Return processedData; subclasses may override to return dataNorm.
            if nargin < 2 || ~useNorm
                d = obj.processedData;
            else
                d = obj.processedData;  % base fallback; tIRDataset overrides
            end
        end

        function t = dispTime(obj, t_fs)
        % Scale time axis for display according to timeUnit.
            if strcmpi(obj.timeUnit, 'ps')
                t = t_fs / 1000;
            else
                t = t_fs;
            end
        end

        function lbl = timeLabel(obj)
        % Return x-axis label string for the current timeUnit.
            if strcmpi(obj.timeUnit, 'ps')
                lbl = '\tau (ps)';
            else
                lbl = '\tau (fs)';
            end
        end

        function openFigure(~, num)
            if isempty(num)
                figure;
            else
                figure(num);
            end
        end

        function applyLineStyle(~, fontSize, fontName)
        % Apply consistent styling to the current line-plot axes (matching run_plot.m).
            ax = gca;
            set(ax, 'FontSize', fontSize, 'FontName', fontName, 'FontWeight', 'bold', ...
                'TickDir', 'out', 'Layer', 'top', ...
                'Color', [1 1 1], 'XColor', 'black', 'YColor', 'black', 'Box', 'on');
            xl = get(ax, 'XLabel');
            set(xl, 'FontSize', fontSize, 'FontName', fontName, 'FontWeight', 'bold');
            yl = get(ax, 'YLabel');
            set(yl, 'FontSize', fontSize, 'FontName', fontName, 'FontWeight', 'bold');
            tl = get(ax, 'Title');
            set(tl, 'FontSize', fontSize, 'FontName', fontName, 'FontWeight', 'bold');
            set(gcf, 'Color', [1 1 1]);
        end

        function t = plotTitle(obj)
        % Build plot title: "SampleName — label [filter info]"
            if ~isempty(obj.sampleName)
                t = [obj.sampleName ' — ' obj.label];
            else
                t = obj.label;
            end
            if obj.isFiltered && isfield(obj.filterOpts, 'order')
                t = sprintf('%s  [SG ord=%d win=%d]', t, ...
                    obj.filterOpts.order, obj.filterOpts.window);
            end
        end

    end

end
