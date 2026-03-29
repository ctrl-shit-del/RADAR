% =========================================================================
% PHASE II: True Temporal Change Detection & Mass Loss (Delta SWE)
% Datasets: Cycle 1 (Winter) vs. Cycle 2 (Summer Melt)
% =========================================================================

clear; clc; close all;

%% 1. Define File Paths for BOTH Cycles
% Cycle 1: Winter Baseline (Orbit 23317)
dir_cycle1 = 'C:\Users\harsh\Harsh\VIT\sem6\radar\ALPSRP233170990-H1.1__A';
HH_file_1  = fullfile(dir_cycle1, 'IMG-HH-ALPSRP233170990-H1.1__A');
HV_file_1  = fullfile(dir_cycle1, 'IMG-HV-ALPSRP233170990-H1.1__A');

% Cycle 2: Summer Melt (Orbit 25257 - 4.5 Months Later)
dir_cycle2 = 'C:\Users\harsh\Harsh\VIT\sem6\radar\ALPSRP252570990-H1.1__A';
HH_file_2  = fullfile(dir_cycle2, 'IMG-HH-ALPSRP252570990-H1.1__A');
HV_file_2  = fullfile(dir_cycle2, 'IMG-HV-ALPSRP252570990-H1.1__A');

% ROI Dimensions (Same as Phase 1)
num_lines = 18432; num_samples = 4640;
row_start = 8000; row_end = 10999;
col_start = 1000; col_end = 3999;

%% 2. Process Both Datasets (Using Automated Function)
disp('Processing Cycle 1 (Winter Baseline)...');
[depth_1, amp_1] = get_snow_depth(HH_file_1, HV_file_1, num_lines, num_samples, row_start, row_end, col_start, col_end);

disp('Processing Cycle 2 (Summer Melt)...');
[depth_2, amp_2] = get_snow_depth(HH_file_2, HV_file_2, num_lines, num_samples, row_start, row_end, col_start, col_end);

%% 3. Image Co-Registration (Mathematical Alignment)
disp('Aligning Cycle 2 to Cycle 1 (Phase Correlation)...');
% We use the amplitude images to find the exact pixel shift between the two orbits
[optimizer, metric] = imregconfig('monomodal');

% Calculate the spatial transformation required to align the summer image to the winter image
tform = imregtform(amp_2, amp_1, 'translation', optimizer, metric);

% Apply the shift to the Cycle 2 Depth Map so the pixels perfectly overlap
depth_2_aligned = imwarp(depth_2, tform, 'OutputView', imref2d(size(depth_1)));

%% 4. Calculate Snow Water Equivalent (SWE) and Mass Loss
disp('Calculating Climate Metrics (Delta SWE)...');
firn_density = 400; % Average density of packed snow/firn in kg/m^3

SWE_1 = depth_1 * firn_density;
SWE_2 = depth_2_aligned * firn_density;

% Calculate the actual mass change: Winter SWE minus Summer SWE
% Positive values = Mass Loss (Melting). Negative values = Mass Gain (Accumulation).
delta_SWE = SWE_1 - SWE_2;

% Filter out extreme mathematical outliers for a clean climate map
delta_SWE(delta_SWE > 4000) = 4000; 
delta_SWE(delta_SWE < -1000) = -1000;

%% 5. Visualization: The Climate Change Map
figure('Name', 'Phase II: Real Temporal Mass Loss (\Delta SWE)', 'Position', [200, 200, 1200, 500]);

% Subplot 1: Cycle 1 SWE
subplot(1,3,1);
imagesc(SWE_1, [0 6000]); colormap(gca, 'parula');
title('Cycle 1: Winter Mass (SWE)'); axis image; axis off;

% Subplot 2: Cycle 2 SWE
subplot(1,3,2);
imagesc(SWE_2, [0 6000]); colormap(gca, 'parula');
title('Cycle 2: Summer Mass (SWE)'); axis image; axis off;

% Subplot 3: Delta SWE (The Melt Map)
subplot(1,3,3);
% Use a divergent colormap: Red/Yellow = Melt/Loss, Blue/Cyan = Accumulation
imagesc(delta_SWE, [-1000 3000]); 
colormap(gca, jet); colorbar;
title('Real \Delta SWE (Mass Loss in kg/m^2)'); axis image; axis off;

disp('PHASE II COMPLETE: True Temporal Change Detection successful!');

% =========================================================================
% HELPER FUNCTION: Automated PolInSAR Processing Pipeline
% =========================================================================
function [snow_depth, hh_amp] = get_snow_depth(HH_file, HV_file, tot_lines, tot_samples, r_start, r_end, c_start, c_end)
    % 1. Read Complex Data
    S_HH = read_ceos_slc(HH_file, tot_lines, tot_samples, r_start, r_end, c_start, c_end);
    S_HV = read_ceos_slc(HV_file, tot_lines, tot_samples, r_start, r_end, c_start, c_end);
    
    hh_amp = abs(S_HH); % Extract amplitude for alignment later
    
    % 2. Covariance Matrix
    C11_raw = abs(S_HH).^2;           
    C22_raw = abs(S_HV).^2;           
    C12_raw = S_HH .* conj(S_HV);     
    
    % 3. Macroscopic PolInSAR Coherence (35x35 Window)
    macro_window = 35;
    macro_kernel = ones(macro_window) / (macro_window^2);
    C11_macro = imfilter(C11_raw, macro_kernel, 'replicate');
    C22_macro = imfilter(C22_raw, macro_kernel, 'replicate');
    C12_macro = imfilter(C12_raw, macro_kernel, 'replicate');
    
    macro_coherence = abs(C12_macro ./ sqrt(C11_macro .* C22_macro + eps));
    
    % 4. RVoG Volumetric Inversion
    inc_angle = deg2rad(34.3); 
    kappa_e = 0.12; 
    
    vol_mask = macro_coherence < 0.90; 
    snow_depth = zeros(size(macro_coherence));
    snow_depth(vol_mask) = -log(macro_coherence(vol_mask)) ./ (2 * kappa_e / cos(inc_angle));
    
    % Clean up mathematical artifacts
    snow_depth(snow_depth > 15) = 15; 
    snow_depth(snow_depth < 0) = 0;   
    snow_depth = imgaussfilt(snow_depth, 4); 
end

% =========================================================================
% HELPER FUNCTION: Read CEOS L1.1 SLC Format
% =========================================================================
function cplx_data = read_ceos_slc(filename, total_lines, total_samples, r_start, r_end, c_start, c_end)
    fid = fopen(filename, 'r', 'ieee-be'); 
    if fid == -1
        error('Cannot open file: %s', filename);
    end
    
    bytes_per_pixel = 8; 
    header_offset = 720; 
    line_prefix = 412;   
    
    roi_lines = r_end - r_start + 1;
    roi_samples = c_end - c_start + 1;
    cplx_data = zeros(roi_lines, roi_samples);
    
    bytes_per_line = line_prefix + (total_samples * bytes_per_pixel);
    start_byte = header_offset + ((r_start - 1) * bytes_per_line);
    fseek(fid, start_byte, 'bof');
    
    for i = 1:roi_lines
        fseek(fid, line_prefix + ((c_start - 1) * bytes_per_pixel), 'cof'); 
        raw_iq = fread(fid, roi_samples * 2, 'float32'); 
        cplx_data(i, :) = complex(raw_iq(1:2:end), raw_iq(2:2:end));
        
        skip_end = (total_samples - c_end) * bytes_per_pixel;
        fseek(fid, skip_end, 'cof');
    end
    fclose(fid);
end