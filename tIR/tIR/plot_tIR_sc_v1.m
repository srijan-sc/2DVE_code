clear all
% clc
close all
newpath = 'C:\Users\khalilgr\Documents\MATLAB';
userpath(newpath)
addpath(genpath('C:\Users\khalilgr\Documents\MATLAB\code_library_rbw\'));
set(0,'DefaultFigureWindowStyle','docked')
% newpath = '/Users/Caroline/Documents/MATLAB/';
% userpath(newpath)
% addpath(genpath('/Users/Caroline/Documents/MATLAB/code_library_rbw/'));
set(0,'DefaultFigureWindowStyle','docked')
set(0,'defaultfigurecolor',[1 1 1])
set(groot, 'defaultAxesTickDir', 'out');
set(groot,'defaultAxesFontSize',14)
set(groot,'defaultAxesYGrid','on')
set(groot,'defaultAxesXGrid','on')

 
%% Input section 

% File directory 
%direct = uigetdir('C:\Data\Srijan\2025\2025_05\2025_05_07\tIR\grating_50gpmm_3700nm_CdS_400_PCE\');
direct = uigetdir('C:\Data\Srijan\2025\2025_07\2025_07_09\tIR\3300nm_50mm_grating_CdS_400_PCE_200u_spacer\');


userpath(direct)
%load calibration axis
Cal_axis=load('C:\Data\Srijan\calibration\tIR\06_12_2025\center_3300nm.txt');
%%%% load probe spectra 
%transmitted_probe = load('C:\Data\Srijan\2025\2025_05\2025_05_07\tIR\grating_50gpmm_3700nm_CdS_400_PCE\probe_01_ReferenceScan.txt');
transmitted_probe = load('C:\Data\Srijan\2025\2025_07\2025_07_09\tIR\3300nm_50mm_grating_CdS_400_PCE_200u_spacer\probe_01_SampleReverence.txt');
%%%% file name indicator 
root_name = '50nJ_time_scan_02';
% calibration on/off
cm_axis = 1;

normaliser = 1  ; %wheather to probe normalise or not 
probe_processing = 1;   %% If your reference have both pixel and intensity data 
                        %%% keep it on then 

time_zero_idx = 2;% adjust this to change the time zero 


slice_Wavenumbers=[2800,2900] ;  %%% axis values where you want a  slice spectrum along t2

slice_time  =[50000,300000];   %% time value in fs 

%%% index for data , time and Std deviation , no need to change unless
%%% there is a change in labview code 
data_idx = 1;   time_idx = 3;   stdev_idx = 2;



%% NO need to change after this line 

matfiles = dir(fullfile(direct,[root_name '*.txt']));
nfiles = size(matfiles,1);

%%% load all the file in a data structure 
for aa = 1:nfiles
    datastructure{aa,1} = matfiles(aa).name;
    datastructure{aa,2} = load([direct '/' matfiles(aa).name]);
    labels{aa} = num2str(aa);
end

time_files = 3*[1:nfiles/3]; 



times_all = cat(1,datastructure{time_idx,2}); %concatenate multiple rows
% time1 = times_all;
%times_all = cat(3,datastructure{time_idx,2});

% time1=(flipud(times_all));
time1=((times_all));
stdev_all = cat(3,datastructure{stdev_idx,2});
data_all = cat(3,datastructure{data_idx,2});

% data =fliplr(data_all(1:32,:));

data =(data_all(1:32,:));
%%
zero_val = max(sum(abs(data)));
%time_zero_idx=find(sum(abs(data))==zero_val)+4;
 
figure(1); plot((time1),sum(abs(data)));

%%%%% correct time axis 
time_offset = time1(time_zero_idx);
time_ax = -1*((time1) - time_offset);

figure(2); plot(time_ax,abs(sum((data))));
title('ABS Projection of Signal')

if cm_axis
    pixels = (10^7)./Cal_axis;
else
    pixels = 1:1:32;
end
 
%%% probe processing
if probe_processing == 1
    Ref_IR = transmitted_probe(1:32,2);
else
    Ref_IR = transmitted_probe(1:32,1);
end

   



%% Figure 
clevels = [0.1 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0];
% Example 3: Combine both with custom scaling
plotContourData_sc(time_ax, pixels, data, ...
    'XLabel', '\tau_1 (fs)', ...
    'YLabel', '\omega_3/2\pic (cm^{-1})', ...
    'ColorbarLabel', '\DeltaA (mOD)', ...
    'ColorMap', @redblue_1, ...
    'ContourLevels', clevels, ...
    'ScaleToMax', true, ...
    'ScalarMultiplier', 1.5, ...    % Double the scalar
    'ShowContourLines', true, ...    % Show contour lines
    'ContourLineWidth', 0.2, ...     % Thick lines
    'ContourLineColor', 'k', ...     % Black lines
    'SymmetricColorbar', true);
ax = gca;
set(gca,'tickdir','out')
 title("tIR plot");
subtitle(num2str(clevels),'FontSize',10)



 if normaliser == 1
     data_norm = data ./ Ref_IR;
     % Example 3: Combine both with custom scaling
     plotContourData_sc(time_ax, pixels, data_norm, ...
         'XLabel', '\tau_1 (fs)', ...
         'YLabel', '\omega_3/2\pic (cm^{-1})', ...
         'ColorbarLabel', '\DeltaA (mOD)', ...
         'ColorMap', @redblue_1, ...
         'ContourLevels', clevels, ...
         'ScaleToMax', true, ...
         'ScalarMultiplier', 1.5, ...    % Double the scalar
         'ShowContourLines', true, ...    % Show contour lines
         'ContourLineWidth', 0.05, ...     % Thick lines
         'ContourLineColor', 'k', ...     % Black lines
         'SymmetricColorbar', true);
     ax = gca;
     set(gca,'tickdir','out')
     title("tIR plot");
     subtitle(num2str(clevels),'FontSize',10)
     
 end



figure(11); plot(time_ax,abs(sum((data_norm))));
title('ABS Projection of Signal probe normalised ')

hh=[];
hh=abs(sum((data_norm)));


% Find indices for desired wavenumbers

[~, tracePix_01_idx] = min(abs(pixels - slice_Wavenumbers(1)));
[~, tracePix_02_idx] = min(abs(pixels - slice_Wavenumbers(2)));

% Plot with correct parameter name 
plotSpectralSlices(time_ax, abs(data_norm), ... 
    'tracePix_01_idx', tracePix_01_idx, ...
    'tracePix_02_idx', tracePix_02_idx, ...
    'wavelengths', pixels, ...  
    'wavelength_unit', 'cm^{-1}', ...
    'name', 'Spectral Slices tIR Difference Signal abs value');


% Find indices for desired time slice 

[~, traceTime_01_idx] = min(abs(time_ax - slice_time(1)));
[~, traceTime_02_idx] = min(abs(time_ax - slice_time(2)));

% Plot with correct parameter name 
plotSpectralSlices(pixels, abs(data_norm'), ... 
    'tracePix_01_idx', traceTime_01_idx, ...
    'tracePix_02_idx', traceTime_02_idx, ...
    'wavelengths', time_ax, ...  
    'wavelength_unit', 'time(fs)', ...
    'FigureNum', 12 , ...
    'name', 'Spectral Slices in time tIR Difference Signal abs value');
 xlabel('w_3(cm^{-1})');
