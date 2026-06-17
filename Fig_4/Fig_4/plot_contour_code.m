

% Get the full red-blue colormap
full_map = redblue_3(256);
% Use only the white-to-red portion (second half)
white_to_red = full_map(129:end, :);  % Takes from middle (white) to end (red)



figure
plotContourData_sc_v3(w1, w3,integrated_data, ...
    'XLabel', '\omega_1/2\pic (cm^{-1})', ...
    'YLabel', '\omega_3/2\pic (cm^{-1})', ...
    'ColorbarLabel', '\DeltaA (mOD)', ...
    'ColorMap',white_to_red , ...
    'ContourLevels', clevels, ...
    'ScaleToMax', true, ...
    'ScalarMultiplier',scalar, ...    % Double the scalar
    'ShowContourLines', true, ...    % Show contour lines 
    'CustomScalar', 1.5, ...  % define based on input
    'ContourLineWidth', 0.3, ...     % Thick lines
    'ContourLineColor', 'k', ...     % Black lines
    'SymmetricColorbar', false);
 title("cut at 248 cm^{-1}");