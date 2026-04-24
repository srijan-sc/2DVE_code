function [FT_filter_norm] = hyperbolicTanWindow2(t, t0_1, tau_1, t0_2, tau_2, offset, doPlot)
% HYPERBOLICTANWINDOW Creates a hyperbolic tangent window function
%
% Inputs:
% t - Time axis vector (fs)
% t0_1 - Center of first transition (rising edge) (fs)
% tau_1 - Steepness of first transition (fs)
% t0_2 - Center of second transition (falling edge) (fs)
% tau_2 - Steepness of second transition (fs)
% offset - Offset adjustment (default: 0)
% doPlot - Boolean to control plotting (default: false)
%
% Outputs:
% FT_filter_norm - Normalized window function

% Input validation
if nargin < 6
    offset = 0;
end
if nargin < 7
    doPlot = false;
end

% Ensure t is a row vector
t = t(:)';

% Validate input dimensions
if isempty(t) || ~isnumeric(t)
    error('Time vector must be numeric and non-empty');
end
if ~isscalar(t0_1) || ~isscalar(tau_1) || ~isscalar(t0_2) || ~isscalar(tau_2)
    error('Window parameters must be scalar values');
end

% Calculate window with transitions at t0_1 and t0_2
rising_edge = 0.5 * (1 + tanh((t - t0_1) / tau_1));
falling_edge = 0.5 * (1 - tanh((t - t0_2) / tau_2));

% Combine the edges to form the window
FT_filter = rising_edge .* falling_edge;

% Apply offset if needed
if offset > 0
    FT_filter = FT_filter(1:end-offset);
    t = t(1:end-offset);
end

% Normalize window (though it should already be approximately normalized)
FT_filter_norm = FT_filter ./ max(FT_filter);

% Optional plotting
if doPlot
    figure;
    plot(t, FT_filter_norm, 'k', 'LineWidth', 2);
    xlabel('\tau_2 (fs)', 'FontSize', 12);
    ylabel('Intensity (normalized)', 'FontSize', 12);
    title('Hyperbolic Tangent Window', 'FontSize', 14);
    grid on;
    box on;
    set(gca, 'FontSize', 11);
    
    % Add markers for transition centers
    hold on;
    plot([t0_1 t0_1], [0 1], 'r--', 'LineWidth', 1);
    plot([t0_2 t0_2], [0 1], 'r--', 'LineWidth', 1);
    legend('Window Function', 'Transition Centers');
    hold off;
end
end