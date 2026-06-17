function [shiftedTime, shiftedData] = timeShift(time, data, offset, doPlot)
% TIMESHIFT Shifts time axis and corresponding data matrix by removing data before offset
%
% Inputs:
%   time   - Time axis vector
%   data   - Data matrix (rows correspond to time points)
%   offset - Time value to shift to the start (in same units as time)
%   doPlot - Optional boolean for plotting (default: false)
%
% Outputs:
%   shiftedTime - Time axis shifted so offset point is at start
%   shiftedData - Data matrix shifted to maintain alignment with time

    % Input validation
    validateattributes(time, {'numeric'}, {'vector'});
    validateattributes(data, {'numeric'}, {'2d'});
    validateattributes(offset, {'numeric'}, {'scalar'});
    
    % Set default for plotting
    if nargin < 4
        doPlot = false;
    end
    
    if size(data, 1) ~= length(time)
        error('Data matrix rows must match length of time vector');
    end
    
    % Find the index of the element closest to the offset
    [minVal, offsetIndex] = min(abs(time - offset));
    
    % Extract data from offset index onwards
    shiftedTime = time(offsetIndex:end) ;
    shiftedData = data(offsetIndex:end, :);
    
    % Optional: Add warning if offset point isn't exactly matched
    if abs(time(offsetIndex) - offset) > eps(offset)*100
        warning('Closest time point to offset %.3f is %.3f', ...
                offset, time(offsetIndex));
    end
    
    % Optional plotting
    if doPlot
        % Calculate mean of absolute values
        meanAbsOriginal = mean(abs(data), 2);  % mean across columns for each time point
        meanAbsShifted = mean(abs(shiftedData), 2);
        
        figure;
        
        % Create subplot for original data
        subplot(2,1,1);
        plot(time, meanAbsOriginal, 'LineWidth', 1.5);
        title('Original Data - Mean Absolute Value');
        xlabel('Time');
        ylabel('Mean |Amplitude|');
        grid on;
        % Add vertical line at offset
        hold on;
        xline(offset, '--r', ['Offset = ' num2str(offset)], 'LineWidth', 1.5);
        
        % Create subplot for shifted data
        subplot(2,1,2);
        plot(shiftedTime, meanAbsShifted, 'LineWidth', 1.5);
        title('Shifted Data - Mean Absolute Value');
        xlabel('Time');
        ylabel('Mean |Amplitude|');
        grid on;
        % Add vertical line at new zero point
        hold on;
        xline(0, '--r', 'New Origin', 'LineWidth', 1.5);
        
        % Adjust figure
        sgtitle(['Time Shift Analysis - Mean Absolute Value (Offset = ' num2str(offset) ')']);
        
        % Optional: add standard deviation bands
        if size(data, 2) > 1
            hold(subplot(2,1,1), 'on');
            stdOriginal = std(abs(data), 0, 2);
            patch([time, fliplr(time)], ...
                  [meanAbsOriginal' + stdOriginal', fliplr(meanAbsOriginal' - stdOriginal')], ...
                  'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
            
            hold(subplot(2,1,2), 'on');
            stdShifted = std(abs(shiftedData), 0, 2);
            patch([shiftedTime, fliplr(shiftedTime)], ...
                  [meanAbsShifted' + stdShifted', fliplr(meanAbsShifted' - stdShifted')], ...
                  'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
            
            legend({'Mean |Amplitude|', 'Offset', '±1 std'});
        end
    end
end