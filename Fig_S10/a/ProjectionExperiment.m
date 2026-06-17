classdef ProjectionExperiment < handle
% ProjectionExperiment  Load a 3DVE data cube and project over w1 → w3×w2 map.
%
%   proj = ProjectionExperiment(dataFile, waxisFile)
%   proj.load()
%   proj.project()
%   proj.plot()
%   proj.export('plot_projection')

    % ── Public properties ─────────────────────────────────────────────────
    properties
        dataFile
        waxisFile

        ax2d         = [2500 3000 550 1000]  % [w1_min w1_max pix_min pix_max]
        FTsize       = 4096

        % Computed after load()
        w3Axis                % [1 × Nw3]  CCD wavenumber axis (cm⁻¹)

        timeAxis              % [1 × Nt]   τ₂ values in fs (set before project())

        % Computed after project()
        w2Axis                % [1 × Nt]   time axis used for plotting
        plotArea              % [Nw3 × Nt] projected data

        fig
    end

    % ── Private storage ───────────────────────────────────────────────────
    properties (Access = private)
        dataCube
        CCDWavelengthAxis
        freqAxis
        MCTRange
    end

    properties (Constant, Access = private)
        HeNeHalfCycle = 1.0554e-15
        SpeedOfLight  = 2.99792458e10
    end

    % ── Public methods ────────────────────────────────────────────────────
    methods

        function obj = ProjectionExperiment(dataFile, waxisFile)
            obj.dataFile  = dataFile;
            obj.waxisFile = waxisFile;
        end

        function load(obj)
        % load  Load data cube and CCD wavelength axis, build frequency axes.
            tmp = load(obj.waxisFile);
            obj.CCDWavelengthAxis = tmp.CCD_wavelength_axis;

            fprintf('Loading data cube ... ');
            tmp = load(obj.dataFile);
            obj.dataCube = tmp.dataCube2;
            sz = size(obj.dataCube);
            fprintf('[%d × %d × %d]  (w3 × w1 × w2)\n', sz(1), sz(2), sz(3));

            obj.buildAxes();
            fprintf('w1 window: %.0f–%.0f cm⁻¹   w3: %.0f–%.0f cm⁻¹ (%d pts)\n', ...
                obj.ax2d(1), obj.ax2d(2), ...
                obj.w3Axis(1), obj.w3Axis(end), numel(obj.w3Axis));
        end

        function project(obj)
        % project  Sum over w1 dimension to produce a w3 × w2 map.
            pixMin = obj.ax2d(3);
            pixMax = obj.ax2d(4);
            w1Min  = obj.MCTRange(1);
            w1Max  = obj.MCTRange(2);

            % dataCube: [pixels(w3) × FTbins(w1) × timePoints(w2)]
            data = obj.dataCube(pixMin:pixMax, w1Min:w1Max, :);  % [Nw3 × Nw1 × Nt]
            obj.plotArea = squeeze(sum(data, 2));                 % [Nw3 × Nt]
            Nt = size(obj.plotArea, 2);
            if ~isempty(obj.timeAxis) && numel(obj.timeAxis) == Nt
                obj.w2Axis = obj.timeAxis;
            else
                obj.w2Axis = 1:Nt;
            end

            fprintf('Projection done → plotArea [%d × %d]  |  range [%.3f, %.3f]\n', ...
                size(obj.plotArea,1), size(obj.plotArea,2), ...
                min(obj.plotArea(:)), max(obj.plotArea(:)));
        end

        function plot(obj, varargin)
        % plot  Contour plot of the w3 × w2 projection.
        %
        %   proj.plot()
        %   proj.plot('Title','projection','CustomScalar',1.5,'FontSize',16)
        %
        %   Name-Value options:
        %     Title         — figure title string            (default '')
        %     ColorbarLabel — colorbar label string          (default '\DeltaA/A')
        %     Clevels       — fill contour levels, pos half  (default as below)
        %     LineLevels    — line contour levels, ±         (default as below)
        %     CustomScalar  — colorbar stretch factor        (default 1.5)
        %     LineWidth     — contour line thickness         (default 0.8)
        %     WhiteBand     — fraction of cmap forced white  (default 0.02)
        %     FontSize      — axis/label font size           (default 16)
        %     FigWidth      — figure width in cm             (default 18)
        %     FigHeight     — figure height in cm            (default 11)
        %     NumCbTicks    — number of colorbar tick marks  (default 11)
            if isempty(obj.plotArea)
                error('Call project() before plot().');
            end

            p = inputParser;
            addParameter(p, 'Title',         '');
            addParameter(p, 'ColorbarLabel', '\DeltaA/A');
            addParameter(p, 'Clevels',       [0.02 0.04 0.06 0.08 0.1 0.2 0.3 0.5 0.7 1.0]);
            addParameter(p, 'LineLevels',    [-0.5 -0.08 -0.06 -0.04 -0.02 0.02 0.04 0.06 0.08 0.5]);
            addParameter(p, 'CustomScalar',  1.5);
            addParameter(p, 'LineWidth',     0.8);
            addParameter(p, 'WhiteBand',     0.02);
            addParameter(p, 'FontSize',      16);
            addParameter(p, 'FigWidth',      18);
            addParameter(p, 'FigHeight',     11);
            addParameter(p, 'NumCbTicks',    11);
            parse(p, varargin{:});
            o = p.Results;

            data   = obj.plotArea;
            w2     = obj.w2Axis;
            w3     = obj.w3Axis;
            scalar = max(abs(data(:)));
            cmap   = obj.makeColormap(o.WhiteBand);

            set(groot, 'defaultAxesFontName', 'Aptos Body');
            set(groot, 'defaultTextFontName', 'Aptos Body');
            set(groot, 'defaultAxesColor',    'white');
            set(groot, 'defaultAxesXColor',   'black');
            set(groot, 'defaultAxesYColor',   'black');
            set(groot, 'defaultTextColor',    'black');

            obj.fig = figure('Units',     'centimeters', ...
                             'Position',  [2 2 o.FigWidth o.FigHeight], ...
                             'PaperUnits','centimeters', ...
                             'PaperSize', [o.FigWidth o.FigHeight], ...
                             'Color',     [1 1 1]);

            plotContourData_sc_v4(w2, w3, data, ...
                'FigureHandle',      obj.fig, ...
                'XLabel',            '\tau_2  (fs)', ...
                'YLabel',            '\omega_3/2\pic (cm^{-1})', ...
                'ColorbarLabel',     '\DeltaA (a.u.)', ...
                'ColorMap',          cmap, ...
                'ContourLevels',     o.Clevels, ...
                'ScaleToMax',        true, ...
                'ScalarMultiplier',  scalar, ...
                'ShowContourLines',  false, ...
                'CustomScalar',      o.CustomScalar, ...
                'SymmetricColorbar', true);

            ax = gca;
            ax.Color      = [1 1 1];
            ax.XColor     = 'black';
            ax.YColor     = 'black';
            obj.fig.Color = [1 1 1];
            set(ax, 'FontSize', o.FontSize, 'FontWeight', 'bold');
            xlabel(get(ax.XLabel,'String'), 'FontSize', o.FontSize, 'FontWeight', 'bold', 'Color', 'black');
            ylabel(get(ax.YLabel,'String'), 'FontSize', o.FontSize, 'FontWeight', 'bold', 'Color', 'black');
            caxis(ax, [-o.CustomScalar*scalar  o.CustomScalar*scalar]);
            colormap(ax, cmap);

            cb = ax.Colorbar;
            if ~isempty(cb)
                clim_val = o.CustomScalar * scalar;
                set(cb, 'FontSize', o.FontSize, 'FontWeight', 'bold', 'Color', 'black');
                step          = 10;
                cb.Ticks      = (ceil(-clim_val/step)*step : step : floor(clim_val/step)*step);
                cb.TickLabels = arrayfun(@(v) sprintf('%.0f', v), cb.Ticks, 'UniformOutput', false);
                cb.Label.String     = o.ColorbarLabel;
                cb.Label.FontSize   = o.FontSize;
                cb.Label.FontWeight = 'bold';
                cb.Label.Color      = 'black';
            end

            [X, Y] = meshgrid(w2, w3);
            lineLevels = o.CustomScalar * scalar * o.LineLevels;
            lineLevels = lineLevels(lineLevels > min(data(:)) & lineLevels < max(data(:)));
            hold on;
            if ~isempty(lineLevels)
                contour(X, Y, data, lineLevels, 'LineColor', 'k', 'LineWidth', o.LineWidth);
            end
            hold off;

            if ~isempty(o.Title)
                title(ax, o.Title, 'FontSize', o.FontSize, 'FontWeight', 'bold', 'Color', 'black');
            end
        end

        function export(obj, outputName)
        % export  Save figure as PDF, SVG, PNG, and .fig.
            if isempty(obj.fig) || ~isgraphics(obj.fig, 'figure')
                error('No figure to export. Call plot() first.');
            end
            axList = findobj(obj.fig, 'Type', 'axes');
            for k = 1:numel(axList)
                axList(k).Toolbar = [];
            end
            exportgraphics(obj.fig, [outputName '.pdf'], 'ContentType', 'vector',  'BackgroundColor', 'white');
            fprintf('Saved: %s.pdf\n', outputName);
            exportgraphics(obj.fig, [outputName '.svg'], 'ContentType', 'vector',  'BackgroundColor', 'white');
            fprintf('Saved: %s.svg\n', outputName);
            exportgraphics(obj.fig, [outputName '.png'], 'Resolution', 300, 'BackgroundColor', 'white');
            fprintf('Saved: %s.png\n', outputName);
            savefig(obj.fig, [outputName '.fig']);
            fprintf('Saved: %s.fig\n', outputName);
        end

    end

    % ── Private methods ───────────────────────────────────────────────────
    methods (Access = private)

        function buildAxes(obj)
            freqRes      = (1/obj.HeNeHalfCycle) / obj.SpeedOfLight / obj.FTsize;
            obj.freqAxis = (0:obj.FTsize-1) .* freqRes;
            obj.MCTRange = round(obj.ax2d(1:2) ./ freqRes, 0);

            pixMin     = obj.ax2d(3);
            pixMax     = obj.ax2d(4);
            CCD_cm     = (1e7) ./ obj.CCDWavelengthAxis;
            obj.w3Axis = CCD_cm(pixMin:pixMax);
        end

        function cmap = makeColormap(~, whiteBand)
            cmap     = redblue_3(255);
            n        = size(cmap, 1);
            halfBand = round(n * whiteBand);
            center   = ceil(n / 2);
            cmap(center - halfBand : center + halfBand, :) = 1;
        end

    end
end
