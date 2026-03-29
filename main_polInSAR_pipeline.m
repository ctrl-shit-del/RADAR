% =========================================================================
% Group 6: Polar Ice Monitoring via Polarimetric SAR 
% Phase 1: Data Ingestion (Amplitude Data / Mosaic)
% Sensor: ALOS PALSAR (Cycle 35) - FBD Mode (HH, HV)
% =========================================================================

clear; clc; close all;

%% 1. Define File Paths
base_dir = 'C:\Users\harsh\Harsh\VIT\sem6\radar\cycle35\cycle35\RAW';

img_HH_file = fullfile(base_dir, 'ALPSR-ASD-BRS_ARCTICPOLE201005FBD343HH0ALL_001_IMG');
img_HV_file = fullfile(base_dir, 'ALPSR-ASD-BRS_ARCTICPOLE201005FBD343HV0ALL_001_IMG');

%% 2. Data Dimensions (Derived from HDR)
num_samples = 33700; % Columns (Width)
num_lines   = 37400; % Rows (Height)
data_type   = 'uint16'; % 16-bit unsigned integer

%% 3. Memory Mapping the Massive Binary Files
% This creates a pointer to the file without crashing your RAM
disp('Mapping HH and HV binary files to memory...');

map_HH = memmapfile(img_HH_file, 'Format', {data_type, [num_samples, num_lines], 'data'});
map_HV = memmapfile(img_HV_file, 'Format', {data_type, [num_samples, num_lines], 'data'});

%% 3.5 The Swath Finder (Find the Ice!)
disp('Generating low-resolution thumbnail of the entire 2.5 GB dataset...');

step_size = 50; % Read every 50th pixel

% Define the original coordinate vectors so the graph axes match your file
cols_orig = 1:step_size:num_samples;
rows_orig = 1:step_size:num_lines;

% Extract the thumbnail and transpose it
thumb_HH = double(map_HH.Data.data(1:step_size:end, 1:step_size:end)');

% Plot the massive map
figure('Name', 'Mosaic Swath Finder', 'Position', [100, 100, 800, 800]);
imagesc(cols_orig, rows_orig, thumb_HH.^0.25); 
colormap('gray'); 
title('Full Mosaic Thumbnail - Look for the bright swath!');
xlabel('Column Coordinates (col_start / col_end)');
ylabel('Row Coordinates (row_start / row_end)');
axis image; 
grid on; set(gca, 'GridColor', 'r', 'GridAlpha', 0.5);

disp('Thumbnail generated! Hover your mouse over the bright ice to find good coordinates.');

%% 4. Extracting the Region of Interest (ROI)
% Extracting from the thick southern swath identified via the thumbnail
row_start = 24000; row_end = 26000;
col_start = 15000; col_end = 17000;

disp('Extracting Region of Interest (ROI)...');

% Extract and transpose
S_HH_roi = double(map_HH.Data.data(col_start:col_end, row_start:row_end)');
S_HV_roi = double(map_HV.Data.data(col_start:col_end, row_start:row_end)');

% --- SAFETY CHECK ---
if max(S_HH_roi(:)) == 0
    error('ROI contains only zeros. The coordinates landed outside the satellite swath.');
else
    fprintf('Data found! Max value in ROI: %f\n', max(S_HH_roi(:)));
end

%% 5. Quick Visualization Check
figure('Name', 'ALOS PALSAR Cycle 35 - ROI Preview', 'Position', [100, 100, 1200, 500]);

subplot(1,2,1);
% Using imagesc with a standard SAR display scaling (e.g., power ^ 0.25)
imagesc(S_HH_roi.^0.25); 
colormap('gray'); colorbar;
title('HH Channel (Amplitude)');
axis image;

subplot(1,2,2);
imagesc(S_HV_roi.^0.25); 
colormap('gray'); colorbar;
title('HV Channel (Amplitude)');
axis image;

disp('Data ingestion complete. Ready for Step 2: Radiometric Calibration.');

%% 6. Radiometric Calibration (Level 1.5 Amplitude to Sigma Naught)
disp('Applying Radiometric Calibration to Cycle 35 Mosaic...');

CF = -83.0; % ALOS PALSAR absolute calibration factor

% ALOS Level 1.5 Calibration Formula: Sigma0 = 10*log10(DN^2) + CF
% We add 'eps' to prevent mathematically undefined log10(0) errors
HH_sigma0_dB = 10 * log10((S_HH_roi.^2) + eps) + CF;
HV_sigma0_dB = 10 * log10((S_HV_roi.^2) + eps) + CF;

%% 7. Visualize Calibrated Regional Map (Smart Masking)
figure('Name', 'Cycle 35 Mosaic - Calibrated Backscatter (dB)', 'Position', [150, 150, 1000, 500]);

% Create a logical mask of valid pixels (where the raw data is not zero)
valid_pixels = S_HH_roi > 0;

% Calculate percentiles ONLY on the valid ice data
hh_lims = [prctile(HH_sigma0_dB(valid_pixels), 2), prctile(HH_sigma0_dB(valid_pixels), 98)];
hv_lims = [prctile(HV_sigma0_dB(valid_pixels), 2), prctile(HV_sigma0_dB(valid_pixels), 98)];

% Force the no-data gaps to stay pure black in the visualization
HH_sigma0_dB(~valid_pixels) = -Inf;
HV_sigma0_dB(~valid_pixels) = -Inf;

subplot(1,2,1);
imagesc(HH_sigma0_dB, hh_lims);
colormap('gray'); colorbar;
title(sprintf('Calibrated HH (dB): [%.1f to %.1f]', hh_lims(1), hh_lims(2)));
axis image;

subplot(1,2,2);
imagesc(HV_sigma0_dB, hv_lims);
colormap('gray'); colorbar;
title(sprintf('Calibrated HV (dB): [%.1f to %.1f]', hv_lims(1), hv_lims(2)));
axis image;

disp('Cycle 35 Mosaic Calibration Complete!');