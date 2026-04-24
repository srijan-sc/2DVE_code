function plotContourData_sc(x_data, y_data, z_data, varargin)
    % Parse inputs
    p = inputParser;
    addRequired(p, 'x_data');
    addRequired(p, 'y_data');
    addRequired(p, 'z_data');
    addParameter(p, 'Title', '', @ischar);
    addParameter(p, 'XLabel', '', @ischar);
    addParameter(p, 'YLabel', '', @ischar);
    addParameter(p, 'ColorbarLabel', '', @ischar);
    addParameter(p, 'ColorMap', 'jet', @(x) ischar(x) || isa(x, 'function_handle') || ...
        (isnumeric(x) && size(x,2)==3));
    addParameter(p, 'NumContours', 40, @isnumeric);
    addParameter(p, 'ContourLevels', [], @isnumeric);
    addParameter(p, 'ScaleToMax', false, @islogical);
    addParameter(p, 'SymmetricColorbar', false, @islogical);
    addParameter(p, 'CLim', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
    addParameter(p, 'PlotType', 'contourf', @(x) ismember(x, {'contourf', 'pcolor'}));
    addParameter(p, 'FigureHandle', [], @(x) isempty(x) || ishandle(x));
    addParameter(p, 'LineStyle', 'none', @ischar);
    addParameter(p, 'LineWidth', 0.5, @isnumeric);
    addParameter(p, 'ColorbarLocation', 'eastoutside', @ischar);
    addParameter(p, 'DataRange', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==4));
    % Existing parameters
    addParameter(p, 'ScalarMultiplier', 1, @isnumeric);  % Multiply the scalar by this value
    addParameter(p, 'ShowContourLines', false, @islogical);  % Option to show contour lines
    addParameter(p, 'ContourLineWidth', 0.5, @isnumeric);  % Width of contour lines
    addParameter(p, 'ContourLineColor', 'k', @ischar);  % Color of contour lines
    % NEW PARAMETER: Custom scalar input
    addParameter(p, 'CustomScalar', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0));
    
    parse(p, x_data, y_data, z_data, varargin{:});
    opts = p.Results;
    
    % Create or use existing figure
    if isempty(opts.FigureHandle)
        figure;
    else
        figure(opts.FigureHandle);
    end
    
    % Create meshgrid if vectors provided
    if isvector(x_data) && isvector(y_data)
        [X, Y] = meshgrid(x_data, y_data);
    else
        X = x_data;
        Y = y_data;
    end
    
    % Handle contour levels
    if ~isempty(opts.ContourLevels)
        if opts.ScaleToMax
            % Use custom scalar if provided, otherwise calculate from data
            if ~isempty(opts.CustomScalar)
                scalar = opts.CustomScalar;
            else
                if ~isempty(opts.DataRange)
                    pixMin = opts.DataRange(1);
                    pixMax = opts.DataRange(2);
                    Tmin_idx = opts.DataRange(3);
                    Tmax_idx = opts.DataRange(4);
                    scalar = max(max(abs(z_data(pixMin:pixMax, Tmin_idx:Tmax_idx))));
                else
                    scalar = max(abs(z_data(:)));
                end
            end
            % Apply scalar multiplier
            scalar = scalar * opts.ScalarMultiplier;
            contour_levels = scalar * opts.ContourLevels;
            
            if opts.SymmetricColorbar
                contour_levels = [-fliplr(contour_levels) contour_levels];
            end
        else
            contour_levels = opts.ContourLevels;
        end
    else
        contour_levels = opts.NumContours;
    end
    
    % Create the filled contour plot
    [~, h] = contourf(X, Y, z_data, contour_levels, ...
        'LineStyle', opts.LineStyle, ...
        'LineWidth', opts.LineWidth);
    
    % Add contour lines if requested
    if opts.ShowContourLines
        hold on;
        [~, h2] = contour(X, Y, z_data, contour_levels, ...
            'LineColor', opts.ContourLineColor, ...
            'LineWidth', opts.ContourLineWidth);
        hold off;
    end
    
    % Set colormap
    if ischar(opts.ColorMap)
        colormap(opts.ColorMap);
    elseif isa(opts.ColorMap, 'function_handle')
        colormap(opts.ColorMap());
    else
        colormap(opts.ColorMap);
    end
    
    % Create colorbar
    c = colorbar('Location', opts.ColorbarLocation);
    if ~isempty(opts.ColorbarLabel)
        c.Label.String = opts.ColorbarLabel;
    end
    
    % Handle color scaling
    if ~isempty(opts.CLim)
        caxis(opts.CLim);
    elseif opts.SymmetricColorbar
        max_abs_val = max(abs(z_data(:)));
        caxis([-max_abs_val max_abs_val]);
    end
    
    % Set labels and title
    xlabel(opts.XLabel);
    ylabel(opts.YLabel);
    title(opts.Title);
    
    % Make plot look nice
    set(gca, 'Layer', 'top');
    box on;
end