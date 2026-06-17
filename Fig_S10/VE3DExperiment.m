classdef VE3DExperiment < handle
% VE3DExperiment  Object-oriented pipeline for 3DVE spectroscopy plots.
%
%   ve3d = VE3DExperiment(dataFile, waxisFile)
%   ve3d.load()
%   ve3d.prepare(24)
%   ve3d.plot('Title', '450 fs')
%   ve3d.export('plot_3DVE')

    % ── Public properties (configure before load/prepare) ─────────────────
    properties
        dataFile             % path to data_cube_3DVE.mat
        waxisFile            % path to CCD_Wavelength_Axis_*.mat

        ax2d          = [2500 3000 550 1000]  % [w1_min w1_max pix_min pix_max]
        FTsize        = 4096
        filterOrder   = 5
        filterWindow  = 15

        % Computed after load()
        w1Axis                % [1 × Nw1]  MCT frequency axis (cm⁻¹)
        w3Axis                % [1 × Nw3]  CCD wavenumber axis (cm⁻¹)

        % Computed after prepare()
        plotArea              % [Nw3 × Nw1] processed 2D data
        timeIndex             % current time slice index

        fig                   % current figure handle
    end

    % ── Private storage ───────────────────────────────────────────────────
    properties (Access = private)
        dataCube              % [pixels × FTbins × timePoints]
        CCDWavelengthAxis     % [1 × pixels] in nm
        freqAxis              % [1 × FTsize] full MCT frequency axis
        MCTRange              % [1 × 2]      bin indices for w1 window
    end

    properties (Constant, Access = private)
        HeNeHalfCycle = 1.0554e-15    % s
        SpeedOfLight  = 2.99792458e10 % cm/s
    end

    % ── Public methods ────────────────────────────────────────────────────
    methods

        function obj = VE3DExperiment(dataFile, waxisFile)
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
            fprintf('[%d × %d × %d]\n', sz(1), sz(2), sz(3));

            obj.buildAxes();
            fprintf('w1: %.0f–%.0f cm⁻¹ (%d pts)   w3: %.0f–%.0f cm⁻¹ (%d pts)\n', ...
                obj.w1Axis(1), obj.w1Axis(end), numel(obj.w1Axis), ...
                obj.w3Axis(1), obj.w3Axis(end), numel(obj.w3Axis));
        end

        function prepare(obj, timeIndex)
        % prepare  Extract and filter one time slice.
            obj.timeIndex = timeIndex;

            slice2d = obj.dataCube(:, :, timeIndex);  % [pixels × FTbins]

            pixMin = obj.ax2d(3);
            pixMax = obj.ax2d(4);
            w1Min  = obj.MCTRange(1);
            w1Max  = obj.MCTRange(2);

            data = slice2d(pixMin:pixMax, w1Min:w1Max);  % [Nw3 × Nw1]
            obj.plotArea = obj.sgFilter(data);

            fprintf('Prepared slice %d  →  plotArea [%d × %d]  |  range [%.3f, %.3f]\n', ...
                timeIndex, size(obj.plotArea,1), size(obj.plotArea,2), ...
                min(obj.plotArea(:)), max(obj.plotArea(:)));
        end

        function plot(obj, varargin)
        % plot  Contour plot using the Fig_2_and3 scheme.
        %
        %   ve3d.plot()
        %   ve3d.plot('Title','450 fs','CustomScalar',1.2,'FontSize',14)
        %
        %   Name-Value options:
        %     Title        — figure title string (default '')
        %     Clevels      — fill contour levels, positive half (default as below)
        %     LineLevels   — contour line levels, both signs     (default as below)
        %     CustomScalar — colorbar stretch factor             (default 1.5)
        %     LineWidth    — contour line thickness              (default 2.2)
        %     WhiteBand    — fraction of cmap forced white       (default 0.02)
        %     FontSize     — axis/label font size                (default 16)
        %     FigWidth     — figure width in cm                  (default 13)
        %     FigHeight    — figure height in cm                 (default 10)
            if isempty(obj.plotArea)
                error('Call prepare(timeIndex) before plot().');
            end

            p = inputParser;
            addParameter(p, 'Title',        '');
            addParameter(p, 'Clevels',      [0.1 0.2 0.3 0.4 0.5 0.7 0.8 0.9 0.95 1.0]);
            addParameter(p, 'LineLevels',   [-0.9 -0.7 -0.6 -0.5 -0.4 -0.3 0.3 0.4 0.5 0.7 0.9]);
            addParameter(p, 'CustomScalar', 1.5);
            addParameter(p, 'LineWidth',    2.2);
            addParameter(p, 'WhiteBand',    0.02);
            addParameter(p, 'FontSize',     16);
            addParameter(p, 'FigWidth',     13);
            addParameter(p, 'FigHeight',    10);
            parse(p, varargin{:});
            o = p.Results;

            data   = obj.plotArea;
            w1     = obj.w1Axis;
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

            plotContourData_sc_v4(w1, w3, data, ...
                'FigureHandle',      obj.fig, ...
                'XLabel',            '\omega_1/2\pic (cm^{-1})', ...
                'YLabel',            '\omega_3/2\pic (cm^{-1})', ...
                'ColorbarLabel',     '\DeltaA (mOD)', ...
                'ColorMap',          cmap, ...
                'ContourLevels',     o.Clevels, ...
                'ScaleToMax',        true, ...
                'ScalarMultiplier',  scalar, ...
                'ShowContourLines',  false, ...
                'CustomScalar',      o.CustomScalar, ...
                'SymmetricColorbar', true);

            xlim([min(w1) max(w1)]);
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
                set(cb, 'FontSize', o.FontSize, 'FontWeight', 'bold', 'Color', 'black');
                cb.Label.FontSize   = o.FontSize;
                cb.Label.FontWeight = 'bold';
                cb.Label.Color      = 'black';
            end

            [X, Y] = meshgrid(w1, w3);
            hold on;
            contour(X, Y, data, o.CustomScalar * scalar * o.LineLevels, ...
                'LineColor', 'k', 'LineWidth', o.LineWidth);
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
            % Remove axes toolbars so SVG export does not embed/invalidate them
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
        % buildAxes  Build w1 (MCT) and w3 (CCD) axes from loaded data.
            freqRes       = (1/obj.HeNeHalfCycle) / obj.SpeedOfLight / obj.FTsize;
            obj.freqAxis  = (0:obj.FTsize-1) .* freqRes;
            obj.MCTRange  = round(obj.ax2d(1:2) ./ freqRes, 0);
            obj.w1Axis    = obj.freqAxis(obj.MCTRange(1):obj.MCTRange(2));

            pixMin      = obj.ax2d(3);
            pixMax      = obj.ax2d(4);
            CCD_cm      = (1e7) ./ obj.CCDWavelengthAxis;
            obj.w3Axis  = CCD_cm(pixMin:pixMax);
        end

        function data = sgFilter(obj, data)
        % sgFilter  Savitzky-Golay smoothing along w3 (columns), no toolbox needed.
            order    = obj.filterOrder;
            framelen = obj.filterWindow;
            half     = (framelen - 1) / 2;

            % Build SG coefficients via least-squares
            x = (-half:half)';
            A = zeros(framelen, order+1);
            for k = 0:order
                A(:, k+1) = x .^ k;
            end
            coeffs = pinv(A);
            coeffs = coeffs(1, :);  % row 1 = central-point estimator

            n = size(data, 1);
            for col = 1:size(data, 2)
                y    = data(:, col);
                filt = zeros(n, 1);
                for i = 1:n
                    i0  = max(1, i - half);
                    i1  = min(n, i + half);
                    win = y(i0:i1);
                    if length(win) < framelen
                        if i <= half
                            win = [repmat(y(1),   half - i + 1,     1); win];
                        else
                            win = [win; repmat(y(end), i + half - n, 1)];
                        end
                    end
                    filt(i) = coeffs * win;
                end
                data(:, col) = filt;
            end
        end

        function cmap = makeColormap(~, whiteBand)
        % makeColormap  redblue_3 with a white band forced around zero.
            cmap     = redblue_3(255);
            n        = size(cmap, 1);
            halfBand = round(n * whiteBand);
            center   = ceil(n / 2);
            cmap(center - halfBand : center + halfBand, :) = 1;
        end

    end
end
