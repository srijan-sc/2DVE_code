function plotContourData(x_data, y_data, z_data, varargin)
% PLOTCONTOURDATA  Filled contour plot for 2D spectroscopy data.
%
% plotContourData(x, y, z, 'Param', value, ...)
%
% Parameters:
%   Axes          — uiaxes or axes handle; when provided, FigureHandle is ignored
%   XLabel, YLabel, ColorbarLabel  — axis labels
%   ColorMap      — string name, function handle, or Nx3 matrix (default: @redblue)
%   ContourLevels — vector of levels as fractions of max (requires ScaleToMax true)
%                   or absolute values (ScaleToMax false)
%   LineLevels    — separate sparse levels for overlay contour lines (fractions or abs).
%                   If empty, uses ContourLevels for lines when ShowContourLines=true.
%   CustomScalar  — extra multiplier applied only to LineLevels scaling (default 1.0)
%   NumContours   — number of auto levels when ContourLevels is empty (default 40)
%   ScaleToMax    — scale ContourLevels as fraction of data max (default false)
%   ScalarMultiplier — multiply the scalar before applying ContourLevels (default 1)
%   SymmetricColorbar — mirror levels around zero; CLim derived from levels (default false)
%   ShowContourLines  — overlay contour lines (default false)
%   ContourLineWidth  — (default 2.2)
%   ContourLineColor  — (default 'k')
%   FigureHandle  — target figure handle; ignored when Axes is provided
%   DataRange     — [pixMin pixMax tMin tMax] restrict scalar computation to subregion
%   FontSize      — axis and label font size (default 16)
%   FontName      — font name (default 'Aptos Body')
%   FontBold      — bold axis labels and tick labels (default true)
%   FigWidthCm    — figure width in cm (default 13); ignored when Axes is provided
%   FigHeightCm   — figure height in cm (default 10); ignored when Axes is provided

p = inputParser;
addRequired(p, 'x_data');
addRequired(p, 'y_data');
addRequired(p, 'z_data');
addParameter(p, 'Axes',            [],         @(x) isempty(x)||isa(x,'matlab.graphics.axis.AbstractAxes'));
addParameter(p, 'XLabel',          '',         @ischar);
addParameter(p, 'YLabel',          '',         @ischar);
addParameter(p, 'ColorbarLabel',   '',         @ischar);
addParameter(p, 'ColorMap',        @redblue,   @(x) ischar(x)||isa(x,'function_handle')||isnumeric(x));
addParameter(p, 'NumContours',     40,         @isnumeric);
addParameter(p, 'ContourLevels',   [],         @isnumeric);
addParameter(p, 'LineLevels',      [],         @isnumeric);
addParameter(p, 'CustomScalar',    1.0,        @isnumeric);
addParameter(p, 'ScaleToMax',      false,      @islogical);
addParameter(p, 'ScalarMultiplier',1,          @isnumeric);
addParameter(p, 'SymmetricColorbar', false,    @islogical);
addParameter(p, 'ShowContourLines',  false,    @islogical);
addParameter(p, 'ContourLineWidth',  2.2,      @isnumeric);
addParameter(p, 'ContourLineColor',  'k',      @ischar);
addParameter(p, 'FigureHandle',    [],         @(x) isempty(x)||ishandle(x));
addParameter(p, 'DataRange',       [],         @(x) isempty(x)||(isnumeric(x)&&numel(x)==4));
addParameter(p, 'FontSize',        16,         @isnumeric);
addParameter(p, 'FontName',        'Aptos Body', @ischar);
addParameter(p, 'FontBold',        true,       @islogical);
addParameter(p, 'FigWidthCm',      13,         @isnumeric);
addParameter(p, 'FigHeightCm',     10,         @isnumeric);

parse(p, x_data, y_data, z_data, varargin{:});
opts = p.Results;

% Resolve target axes
if ~isempty(opts.Axes)
    ax = opts.Axes;
    cla(ax);
else
    if ~isempty(opts.FigureHandle)
        fig = opts.FigureHandle;
    else
        fig = gcf;
    end
    set(fig, 'Units', 'centimeters', ...
        'Position', [2 2 opts.FigWidthCm opts.FigHeightCm], ...
        'PaperUnits', 'centimeters', ...
        'PaperSize',  [opts.FigWidthCm opts.FigHeightCm], ...
        'Color', [1 1 1]);
    figure(fig);
    ax = gca;
end

% Build meshgrid if vectors provided
if isvector(x_data) && isvector(y_data)
    [X, Y] = meshgrid(x_data, y_data);
else
    X = x_data;
    Y = y_data;
end

% Compute scalar for level scaling
if opts.ScaleToMax
    if ~isempty(opts.DataRange)
        r = opts.DataRange;
        scalar = max(max(abs(z_data(r(1):r(2), r(3):r(4)))));
    else
        scalar = max(abs(z_data(:)));
    end
    scalar = scalar * opts.ScalarMultiplier;
else
    scalar = 1;
end

% Compute fill contour levels
if ~isempty(opts.ContourLevels)
    if opts.ScaleToMax
        pos_levels = scalar * opts.ContourLevels;
    else
        pos_levels = opts.ContourLevels;
    end
    if opts.SymmetricColorbar
        contour_levels = [-fliplr(pos_levels), pos_levels];
    else
        contour_levels = pos_levels;
    end
else
    contour_levels = opts.NumContours;
end

% contourf/contour can spawn a stray traditional figure when ax is a
% uiaxes — capture existing figures beforehand and close any new ones.
figs_before = get(groot, 'Children');

% Filled contour plot (no lines)
contourf(ax, X, Y, z_data, contour_levels, 'LineStyle', 'none');

% Overlay contour lines
if opts.ShowContourLines
    if ~isempty(opts.LineLevels)
        if opts.ScaleToMax
            actual_line_levels = opts.CustomScalar * scalar * opts.LineLevels;
        else
            actual_line_levels = opts.LineLevels;
        end
    else
        actual_line_levels = contour_levels;
    end
    hold(ax, 'on');
    contour(ax, X, Y, z_data, actual_line_levels, ...
        'LineColor', opts.ContourLineColor, ...
        'LineWidth',  opts.ContourLineWidth);
    hold(ax, 'off');
end

% Close any stray figures that contourf/contour created
figs_after = get(groot, 'Children');
stray = setdiff(figs_after, figs_before);
if ~isempty(stray)
    close(stray(isa(stray, 'matlab.ui.Figure') | isprop(stray, 'Number')));
end

% Colormap
if ischar(opts.ColorMap)
    colormap(ax, opts.ColorMap);
elseif isa(opts.ColorMap, 'function_handle')
    colormap(ax, opts.ColorMap());
else
    colormap(ax, opts.ColorMap);
end

% Colorbar
cb = colorbar(ax);
if ~isempty(opts.ColorbarLabel)
    cb.Label.String = opts.ColorbarLabel;
end

% CLim
if opts.SymmetricColorbar && isnumeric(contour_levels) && numel(contour_levels) > 1
    lim = max(abs(contour_levels));
    clim(ax, [-lim, lim]);
end

% Styling
fw = 'normal';
if opts.FontBold, fw = 'bold'; end

set(ax, 'Layer', 'top', 'TickDir', 'out', ...
    'FontSize', opts.FontSize, 'FontName', opts.FontName, 'FontWeight', fw, ...
    'Color', [1 1 1], 'XColor', 'black', 'YColor', 'black');
box(ax, 'on');

xlabel(ax, opts.XLabel, 'FontSize', opts.FontSize, 'FontName', opts.FontName, 'FontWeight', fw);
ylabel(ax, opts.YLabel, 'FontSize', opts.FontSize, 'FontName', opts.FontName, 'FontWeight', fw);

set(cb, 'FontSize', opts.FontSize, 'FontName', opts.FontName, 'FontWeight', fw, 'Color', 'black');
cb.Label.FontSize   = opts.FontSize;
cb.Label.FontName   = opts.FontName;
cb.Label.FontWeight = fw;
cb.Label.Color      = 'black';
end
