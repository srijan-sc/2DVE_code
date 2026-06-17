function plotSpectralSlices(data_time, data_sub, varargin)
    % Parse inputs
    p = inputParser;
    addRequired(p, 'data_time');
    addRequired(p, 'data_sub');
    addParameter(p, 'TimeRange', [-Inf Inf], @(x) isnumeric(x) && length(x)==2);
    addParameter(p, 'tracePix_01_idx', [], @isnumeric);
    addParameter(p, 'tracePix_02_idx', [], @isnumeric);
    addParameter(p, 'name', '', @ischar);
    addParameter(p, 'FigureNum', 8, @isnumeric);
    addParameter(p, 'LineWidth', 2, @isnumeric);
    addParameter(p, 'FontSize', 16, @isnumeric);
    addParameter(p, 'wavelengths', [], @isnumeric);
    addParameter(p, 'wavelength_unit', 'cm^{-1}', @ischar);
    
    parse(p, data_time, data_sub, varargin{:});
    opts = p.Results;
    
    % Find time indices based on TimeRange
    time_mask = data_time >= opts.TimeRange(1) & data_time <= opts.TimeRange(2);
    plot_times = data_time(time_mask);
    
    % Create figure
    figure(opts.FigureNum);
    
    % Plot traces
    plot(plot_times, data_sub(opts.tracePix_01_idx, time_mask), ...
         plot_times, data_sub(opts.tracePix_02_idx, time_mask), ...
         'LineWidth', opts.LineWidth);
    
    % Set axis properties
    axis('tight');
    xlabel('Time (ps)');
    ylabel('Intensity');
    
    % Add title if name is provided
    if ~isempty(opts.name)
        title(opts.name);
    end
    
    % Add zero line
    hold on;
    plot(xlim, [1,1]*0, '--k');
    hold off;
    
    % Set legend with improved wavenumber formatting
    if ~isempty(opts.wavelengths)
        % Format wavenumbers to remove decimal points if they're whole numbers
        wavenumber1 = opts.wavelengths(opts.tracePix_01_idx);
        wavenumber2 = opts.wavelengths(opts.tracePix_02_idx);
        
        if mod(wavenumber1, 1) == 0
            str1 = sprintf('%d %s', wavenumber1, opts.wavelength_unit);
        else
            str1 = sprintf('%.1f %s', wavenumber1, opts.wavelength_unit);
        end
        
        if mod(wavenumber2, 1) == 0
            str2 = sprintf('%d %s', wavenumber2, opts.wavelength_unit);
        else
            str2 = sprintf('%.1f %s', wavenumber2, opts.wavelength_unit);
        end
        
        % Create legend with both pixel and wavenumber information
        legend(sprintf('Pixel %d (%s)', opts.tracePix_01_idx, str1), ...
               sprintf('Pixel %d (%s)', opts.tracePix_02_idx, str2));
    else
        legend(['pixel # ', int2str(opts.tracePix_01_idx)], ...
               ['pixel # ', int2str(opts.tracePix_02_idx)]);
    end
    
    % Set font size and figure color
    ax = gca;
    ax.FontSize = opts.FontSize;
    set(gcf, 'color', 'w');
end