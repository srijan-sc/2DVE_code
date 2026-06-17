% Step-by-Step Simulation of the Vibrational Conical Intersection
% Based on Hamm & Stock, PRL 109, 173201 (2012)
clear; clc; close all;

%% STEP 1 & 4: Define System Parameters
% Bypassing the ab initio calculations of the raw cubic expansion 
% coefficients (fnm,j) and directly importing the derived parameters (Table I).
omega1  = 2800;     % HF OH stretch [cm^-1]
omega2  = 1650;     % HF ring mode [cm^-1]
Omega1  = 290;      % LF coupling mode freq [cm^-1]  (Table I)
Omega2  = 200;      % LF tuning mode freq [cm^-1]    (Table I)
lambda  = 200;      % Coupling constant [cm^-1]       (Table I)
kappa10 = 210;      % Tuning for |10> along Q2 [cm^-1] (Table I, sign places CI at Q2~-2.25)
kappa01 = -300;     % Tuning for |01> along Q2 [cm^-1] (Table I)
kappa00 = 0;

%% STEP 2: Define the Coordinate Grid
q1_range = linspace(-0.8, 0.8, 100);
q2_range = linspace(-3.2, -1.3, 100);
[Q1_grid, Q2_grid] = meshgrid(q1_range, q2_range);

% Pre-allocate arrays to store the resulting adiabatic surfaces
W_ground = zeros(size(Q1_grid)); % Corresponds to |00> adiabatic
W_minus  = zeros(size(Q1_grid)); % First excited state (Lower CI cone)
W_plus   = zeros(size(Q1_grid)); % Second excited state (Upper CI cone)

%% STEP 3 & 5: Assemble and Diagonalize the Diabatic Matrix (Eq. 3)
% We iterate over every point in our spatial grid to build the 3x3 matrix
for i = 1:size(Q1_grid, 1)
    for j = 1:size(Q1_grid, 2)
        
        Q1 = Q1_grid(i, j);
        Q2 = Q2_grid(i, j);
        
        % The harmonic potential energy of the LF modes (h0 term)
        % Note: We ignore the kinetic energy operator (P^2) here because 
        % we are calculating static potential energy surfaces, not dynamics.
        V_harm = (Omega1/2) * Q1^2 + (Omega2/2) * Q2^2;
        
        % Initialize the 3x3 Diabatic Matrix (H)
        H = zeros(3, 3);
        
        % Diagonal Elements (Energy of the states modulated by the tuning mode Q2)
        H(1,1) = V_harm + kappa00 * Q2;              % State |00>
        H(2,2) = V_harm + omega1 + kappa10 * Q2;     % State |10>
        H(3,3) = V_harm + omega2 + kappa01 * Q2;     % State |01>
        
        % Off-Diagonal Elements (Coupling between |10> and |01> modulated by Q1)
        H(2,3) = lambda * Q1;
        H(3,2) = lambda * Q1;
        
        % Numerical Diagonalization
        % This converts the diabatic matrix into the adiabatic representation
        eigenvalues = eig(H);
        
        % Sort eigenvalues to ensure consistent surface assignment
        eigenvalues = sort(eigenvalues);
        
        % Store the adiabatic energies for this (Q1, Q2) point
        W_ground(i,j) = eigenvalues(1);
        W_minus(i,j)  = eigenvalues(2);
        W_plus(i,j)   = eigenvalues(3);
        
    end
end

%% Plotting the Adiabatic Surfaces
fig = figure('Color', 'w', 'Position', [100, 100, 680, 560]);
hold on;

% Upper adiabatic surface only — deep teal
surf(Q1_grid, Q2_grid, W_plus, ...
    'FaceColor', [0.08 0.45 0.48], 'EdgeColor', 'none', 'FaceAlpha', 0.95);

view([-42 20]);
lighting gouraud;
camlight('left');
material([0.4 0.7 0.3 10]);

ax = gca;
ax.FontSize    = 15;
ax.FontName    = 'Helvetica';
ax.LineWidth   = 1.4;
ax.Box         = 'on';
ax.BoxStyle    = 'full';
ax.GridAlpha   = 0;
ax.XColor      = [0.15 0.15 0.15];
ax.YColor      = [0.15 0.15 0.15];
ax.ZColor      = [0.15 0.15 0.15];
ax.Color       = [0.97 0.97 0.97];

xlim([-0.8 0.8]);
ylim([-3.2 -1.3]);
zlim([2600 3400]);

set(ax, 'XTick', [], 'YTick', [], 'ZTick', []);

xlabel('Q_{coupling}', 'FontSize', 16, 'FontWeight', 'bold', 'FontName', 'Helvetica');
ylabel('Q_{tuning}',   'FontSize', 16, 'FontWeight', 'bold', 'FontName', 'Helvetica');
zlabel('Energy',       'FontSize', 16, 'FontWeight', 'bold', 'FontName', 'Helvetica');

hold off;
axtoolbar(ax, {});

%% Save
out_path = fullfile(fileparts(mfilename('fullpath')), 'CI_PES_OH_stretch.png');
exportgraphics(fig, out_path, 'Resolution', 300, 'BackgroundColor', 'white');