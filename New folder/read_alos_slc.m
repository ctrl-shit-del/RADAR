% =========================================================================
% Group 6: Polar Ice Monitoring via Polarimetric SAR 
% Phase 1: L1.1 SLC Data Ingestion to CNN Intelligence Pipeline
% Sensor: ALOS PALSAR - FBD Mode (HH, HV)
% =========================================================================

clear; clc; close all;

%% 1. Define File Paths
base_dir = 'C:\Users\harsh\Harsh\VIT\sem6\radar\ALPSRP233170990-H1.1__A';
summary_file = fullfile(base_dir, 'summary.txt');
img_HH_file  = fullfile(base_dir, 'IMG-HH-ALPSRP233170990-H1.1__A');
img_HV_file  = fullfile(base_dir, 'IMG-HV-ALPSRP233170990-H1.1__A');

%% 2. Data Dimensions (Hardcoded from summary.txt)
num_lines = 18432;   % Pdi_NoOfLines
num_samples = 4640;  % Pdi_NoOfPixels
fprintf('Dimensions Set: %d Rows x %d Columns\n', num_lines, num_samples);

%% 3. Define Region of Interest (ROI)
row_start = 8000; row_end = 10999;
col_start = 1000; col_end = 3999;
roi_lines = row_end - row_start + 1;
roi_samples = col_end - col_start + 1;

%% 4. Read Complex CEOS Data (Handling Headers and Big-Endian)
disp('Ingesting HH & HV Complex Data...');
S_HH = read_ceos_slc(img_HH_file, num_lines, num_samples, row_start, row_end, col_start, col_end);
S_HV = read_ceos_slc(img_HV_file, num_lines, num_samples, row_start, row_end, col_start, col_end);

%% 5. Visualization: Amplitude and Phase
figure('Name', 'ALOS PALSAR L1.1 SLC - ROI Preview', 'Position', [100, 100, 1200, 800]);
subplot(2,2,1); imagesc(abs(S_HH).^0.3); colormap('gray'); colorbar; title('HH Amplitude'); axis image;
subplot(2,2,2); imagesc(angle(S_HH)); colormap('hsv'); colorbar; title('HH Phase (Radians)'); axis image;
subplot(2,2,3); imagesc(abs(S_HV).^0.3); colormap('gray'); colorbar; title('HV Amplitude'); axis image;
subplot(2,2,4); imagesc(angle(S_HV)); colormap('hsv'); colorbar; title('HV Phase (Radians)'); axis image;

%% 6. Covariance Matrix Generation
disp('Generating Covariance Matrix Elements...');
C11_raw = abs(S_HH).^2;           % HH Intensity
C22_raw = abs(S_HV).^2;           % HV Intensity
C12_raw = S_HH .* conj(S_HV);     % Complex Cross-Correlation

%% 7. Multilooking (Basic Speckle Filtering)
disp('Applying 5x5 Multilook Filter to suppress speckle...');
window_size = 5;
kernel = ones(window_size) / (window_size^2);
C11_ml = imfilter(C11_raw, kernel, 'replicate');
C22_ml = imfilter(C22_raw, kernel, 'replicate');
C12_ml = imfilter(C12_raw, kernel, 'replicate');

%% 8. Radiometric Calibration (Digital Numbers to Sigma Naught)
disp('Applying Radiometric Calibration (CF = -83.0 dB)...');
CF = -83.0;
C11_dB = 10 * log10(C11_ml + eps) + CF;
C22_dB = 10 * log10(C22_ml + eps) + CF;

%% 9. Plot the Filtered Geographic Results (Auto-Scaled)
figure('Name', 'Calibrated Covariance Data (Dynamic Contrast)', 'Position', [150, 150, 1000, 500]);
hh_lims = [prctile(C11_dB(:), 2), prctile(C11_dB(:), 98)];
hv_lims = [prctile(C22_dB(:), 2), prctile(C22_dB(:), 98)];
subplot(1,2,1); imagesc(C11_dB, hh_lims); colormap('gray'); colorbar; title(sprintf('HH (dB) Auto-Scaled: [%.1f to %.1f]', hh_lims(1), hh_lims(2))); axis image;
subplot(1,2,2); imagesc(C22_dB, hv_lims); colormap('gray'); colorbar; title(sprintf('HV (dB) Auto-Scaled: [%.1f to %.1f]', hv_lims(1), hv_lims(2))); axis image;

%% 10. Dual-Pol Pseudo-Pauli RGB Composite (Physics Kernel)
disp('Generating Dual-Pol RGB Composite (Physics Kernel)...');
R = C11_ml; 
G = C22_ml; 
B = C11_ml ./ (C22_ml + eps); 

r_lim = prctile(R(:), 98);
g_lim = prctile(G(:), 98);
b_lim = prctile(B(:), 95); 

R_norm = min(max(R / r_lim, 0), 1);
G_norm = min(max(G / g_lim, 0), 1);
B_norm = min(max(B / b_lim, 0), 1);
RGB_Composite = cat(3, R_norm, G_norm, B_norm);

%% 11. Plot the Physics-Based Classification Image
figure('Name', 'Dual-Pol Scattering Composite (Pseudo-Pauli)', 'Position', [200, 200, 800, 800]);
imshow(RGB_Composite);
title('Scattering Mechanisms: Red (HH), Green (HV), Blue (HH/HV)');

%% 12. PolInSAR Complex Coherence Calculation
disp('Calculating Polarimetric Coherence (HH-HV)...');
coherence_complex = C12_ml ./ sqrt(C11_ml .* C22_ml + eps);
coherence_mag = abs(coherence_complex); 
coherence_phase = angle(coherence_complex); 

%% 13. Plot the Coherence Maps
figure('Name', 'PolInSAR Coherence (HH-HV)', 'Position', [250, 250, 1000, 500]);
subplot(1,2,1); imagesc(coherence_mag, [0 1]); colormap('parula'); colorbar; title('Coherence Magnitude (\gamma)'); axis image;
subplot(1,2,2); imagesc(coherence_phase); colormap('hsv'); colorbar; title('Coherence Phase (Radians)'); axis image;

%% 14. Section 6.1: 3D Volumetric Inversion (Smoothed RVoG Model)
disp('Estimating Macroscopic Snow Depth via RVoG...');
inc_angle = deg2rad(34.3); 
kappa_e = 0.12; 

macro_window = 35;
macro_kernel = ones(macro_window) / (macro_window^2);
C11_macro = imfilter(C11_raw, macro_kernel, 'replicate');
C22_macro = imfilter(C22_raw, macro_kernel, 'replicate');
C12_macro = imfilter(C12_raw, macro_kernel, 'replicate');
macro_coherence = abs(C12_macro ./ sqrt(C11_macro .* C22_macro + eps));

vol_mask = macro_coherence < 0.90; 
snow_depth = zeros(size(macro_coherence));
snow_depth(vol_mask) = -log(macro_coherence(vol_mask)) ./ (2 * kappa_e / cos(inc_angle));
snow_depth(snow_depth > 15) = 15; 
snow_depth(snow_depth < 0) = 0;   
snow_depth = imgaussfilt(snow_depth, 4); 

%% 15. Plot the 3D Snow Depth Map
figure('Name', '3D Volumetric Inversion (Snow Depth)', 'Position', [300, 300, 800, 600]);
imagesc(snow_depth); colormap('jet'); c = colorbar;
c.Label.String = 'Estimated Penetration Depth (Meters)';
title('Section 6.1: PolInSAR Volumetric Inversion (Snow Depth)'); axis image;

%% 16. Section 6.2: Tomographic Subsurface Profiling
disp('Extracting Subsurface "X-Ray" Profile Slice...');
transect_row = 1500;
surface_intensity = C11_dB(transect_row, :);
profile_depth = snow_depth(transect_row, :);
pixel_spacing = 9.3; 
distance_km = (1:roi_samples) * pixel_spacing / 1000;

%% 17. Plot the CT-Scan Cross Section
figure('Name', 'Subsurface Tomographic Profile', 'Position', [150, 150, 1200, 500]);
yyaxis left
area(distance_km, -profile_depth, 'FaceColor', [0.8 0.9 1], 'EdgeColor', [0 0.4 0.8]);
ylabel('Penetration Depth (Meters)'); ylim([-15 0]); set(gca, 'YColor', [0 0.4 0.8]);
yyaxis right
plot(distance_km, surface_intensity, 'r', 'LineWidth', 1.2);
ylabel('Internal Backscatter (\sigma^0 dB)'); ylim([-25 0]); set(gca, 'YColor', 'r');
title(sprintf('Section 6.2: Tomographic "X-Ray" Cross-Section (Row %d)', transect_row));
xlabel('Distance across glacier (Kilometers)'); grid on;

%% 18. Section 6.3: Coherent AI (CNN) Implementation
disp('Initializing Convolutional Neural Network (CNN)...');

% 1. Create the Deep Data Stack (Input Features)
X_cnn = cat(3, R_norm, G_norm, B_norm, macro_coherence);

% 2. Generate Pseudo-Labels for Training (Dynamic Self-Supervised)
disp('Generating dynamic pseudo-labels for CNN training...');
pseudo_labels = ones(roi_lines, roi_samples); % Default: Zone 1 (Smooth Ice)

% Use dynamic percentiles to GUARANTEE every class has data to learn from
coh_thresh = prctile(macro_coherence(:), 40); % Bottom 40% coherence
b_thresh   = prctile(B_norm(:), 85);          % Top 15% blue ratio
r_thresh   = prctile(R_norm(:), 90);          % Top 10% red roughness

pseudo_labels(macro_coherence < coh_thresh) = 2; % Zone 2: Snow Volume 
pseudo_labels(B_norm > b_thresh) = 3;            % Zone 3: Meltwater 
pseudo_labels(R_norm > r_thresh) = 4;            % Zone 4: Rough/Crevassed 

% 3. Format Data & Balance Classes (Corrected Memory Layout)
disp('Formatting data and Balancing Classes for CNN...');
num_pixels = roi_lines * roi_samples;

% THE FIX: Permute the 3D matrix BEFORE reshaping. 
% This guarantees the 4 physical channels stay locked to the correct pixel.
X_perm = permute(X_cnn, [3, 1, 2]); 
X_all = reshape(X_perm, [1, 1, 4, num_pixels]);

% Ensure pseudo_labels is a 1D column vector
labels_1D = reshape(pseudo_labels, [num_pixels, 1]);
Y_all = categorical(labels_1D, 1:4, {'Smooth Ice', 'Snow Volume', 'Meltwater', 'Crevassed Ice'});

% --- CLASS BALANCING STRATEGY ---
idx_1 = find(labels_1D == 1);
idx_2 = find(labels_1D == 2);
idx_3 = find(labels_1D == 3);
idx_4 = find(labels_1D == 4);

min_class_size = min([length(idx_1), length(idx_2), length(idx_3), length(idx_4)]);
samples_per_class = min(min_class_size, 5000); % Cap at 5000 for speed

fprintf('Balancing dataset: Training on %d pixels per class to prevent AI bias...\n', samples_per_class);

% Randomly sample EQUALLY from all 4 zones
samp_1 = idx_1(randperm(length(idx_1), samples_per_class));
samp_2 = idx_2(randperm(length(idx_2), samples_per_class));
samp_3 = idx_3(randperm(length(idx_3), samples_per_class));
samp_4 = idx_4(randperm(length(idx_4), samples_per_class));

% Combine and shuffle the balanced dataset
balanced_idx = [samp_1; samp_2; samp_3; samp_4];
balanced_idx = balanced_idx(randperm(length(balanced_idx)));

X_train = X_all(:,:,:,balanced_idx);
Y_train = Y_all(balanced_idx);

% 4. Define the 1x1 Convolutional Neural Network
disp('Building CNN Layers...');
num_classes = 4;
cnn_layers = [
    % THE FIX: Set Normalization to 'none' so we don't divide by zero!
    imageInputLayer([1 1 4], 'Name', 'input_stack', 'Normalization', 'none')
    
    convolution2dLayer(1, 24, 'Name', 'conv_1')
    batchNormalizationLayer('Name', 'bn_1')
    reluLayer('Name', 'relu_1')
    
    convolution2dLayer(1, 48, 'Name', 'conv_2')
    batchNormalizationLayer('Name', 'bn_2')
    reluLayer('Name', 'relu_2')
    
    fullyConnectedLayer(num_classes, 'Name', 'fc_out')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'class_labels')
];

% 5. Define Training Options
options = trainingOptions('adam', ...
    'InitialLearnRate', 0.001, ... % Lowered to 0.001 for highly stable learning
    'MaxEpochs', 15, ... 
    'MiniBatchSize', 2048, ... 
    'Shuffle', 'every-epoch', ...
    'Plots', 'training-progress', ...
    'Verbose', false);

% 6. Train the CNN
disp('Training the CNN (A training window will pop up)...');
trained_CNN = trainNetwork(X_train, Y_train, cnn_layers, options);

%% 19. CNN Prediction & Final Visualization
disp('Executing CNN Inference on the full 9-million pixel glacier stack...');

% Classify the entire image using the trained CNN
% We use a large mini-batch size to make prediction incredibly fast
[CNN_Prediction_1D, ~] = classify(trained_CNN, X_all, 'MiniBatchSize', 8192);

% Reshape the 1D prediction back into our 2D image map
CNN_Prediction = reshape(CNN_Prediction_1D, [roi_lines, roi_samples]);

% Plot the AI's Output
figure('Name', 'Final: CNN Spatial Glacier Classification', 'Position', [450, 250, 800, 700]);

custom_cmap = [0 1 1; 1 1 1; 0 0.2 0.8; 1 0 1];
% We convert to double and set limits [1 4] to guarantee colors map perfectly
imagesc(double(CNN_Prediction), [1 4]);
colormap(custom_cmap);
axis image;
title('Section 6.3: CNN-Based Glacier Facies Classification');

% Create custom legend
hold on;
h = zeros(4, 1);
h(1) = plot(NaN,NaN,'s','MarkerFaceColor',custom_cmap(1,:),'MarkerEdgeColor','k','MarkerSize',15);
h(2) = plot(NaN,NaN,'s','MarkerFaceColor',custom_cmap(2,:),'MarkerEdgeColor','k','MarkerSize',15);
h(3) = plot(NaN,NaN,'s','MarkerFaceColor',custom_cmap(3,:),'MarkerEdgeColor','k','MarkerSize',15);
h(4) = plot(NaN,NaN,'s','MarkerFaceColor',custom_cmap(4,:),'MarkerEdgeColor','k','MarkerSize',15);
legend(h, {'Zone 1: Smooth/Refrozen Ice', 'Zone 2: Dry Firn/Snow Volume', ...
           'Zone 3: Meltwater/Wet Snow', 'Zone 4: Rough/Crevassed Ice'}, ...
       'Location', 'bestoutside', 'FontSize', 12);

disp('PHASE I FINAL COMPLETE: Full pipeline from Raw Binary to CNN Intelligence successfully executed.');

% =========================================================================
% Helper Function: Read CEOS L1.1 SLC Format
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