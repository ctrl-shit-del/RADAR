% ========================================================================= 
% PHASE III: Advanced Spatial Deep Learning (U-Net Architecture)
% Goal: Journal-Level Semantic Segmentation of Glacier Facies
% =========================================================================

disp('Initializing Phase III: U-Net Spatial Deep Learning Architecture...');

% --- SAFETY CHECK ---
if ~exist('X_cnn', 'var') || ~exist('pseudo_labels', 'var')
    error('Workspace empty! Please run read_alos_slc.m first to load the radar stack.');
end

%% 1. Extract Spatial Patches (The 4D-Datastore Fix)
disp('Extracting 128x128 spatial patches...');

patch_size = 128;
num_patches = 800; % Number of patches to train on

% THE FIX: Use a pure 4D array and pre-cast to 'single' for the Neural Network
X_4D = zeros(patch_size, patch_size, 4, num_patches, 'single');

% Create a temporary folder for the Labels
if exist('temp_labels', 'dir')
    rmdir('temp_labels', 's');
end
mkdir('temp_labels');

[max_row, max_col, ~] = size(X_cnn);

for i = 1:num_patches
    r = randi([1, max_row - patch_size + 1]);
    c = randi([1, max_col - patch_size + 1]);
    
    % 1. Store the radar patch directly into the 4D array
    X_4D(:,:,:,i) = single(X_cnn(r:(r+patch_size-1), c:(c+patch_size-1), :));
    
    % 2. Write the label patch to disk
    label_patch = pseudo_labels(r:(r+patch_size-1), c:(c+patch_size-1));
    imwrite(uint8(label_patch), sprintf('temp_labels/patch_%04d.png', i));
end

% Wrap the 4D array in an arrayDatastore, slicing exactly along Dimension 4
dsX = arrayDatastore(X_4D, 'IterationDimension', 4);

% Wrap the Disk data in the official pixelLabelDatastore
classNames = ["Smooth Ice", "Snow Volume", "Meltwater", "Crevassed Ice"];
pixelValues = [1, 2, 3, 4];
dsY = pixelLabelDatastore('temp_labels', classNames, pixelValues);

% FUSE THEM
train_data = combine(dsX, dsY);

%% 2. Define the U-Net Architecture
disp('Constructing the U-Net Encoder-Decoder Architecture...');

num_classes = 4;
input_size = [patch_size patch_size 4];

% MATLAB's built-in U-Net generator
lgraph = unetLayers(input_size, num_classes, 'EncoderDepth', 2);

%% 3. Define Training Options
options = trainingOptions('adam', ...
    'InitialLearnRate', 0.001, ...
    'MaxEpochs', 10, ... 
    'MiniBatchSize', 8, ... 
    'Shuffle', 'every-epoch', ...
    'Plots', 'training-progress', ...
    'Verbose', false);

%% 4. Train the U-Net
disp('Training the U-Net (This will take a few minutes)...');
% We pass the combined datastore. No nested cells. Pure semantic segmentation!
trained_UNet = trainNetwork(train_data, lgraph, options);

%% 5. AI Inference: Predict the Entire Glacier
disp('Executing Spatial Inference on the 3000x3000 ROI...');

% MATLAB's semanticseg function handles patching the giant image
UNet_Prediction = semanticseg(X_cnn, trained_UNet, 'MiniBatchSize', 4);

%% 6. Visualization: The Next-Gen AI Map
% Convert the categorical prediction to numeric and plot it!
figure('Name', 'Phase III: U-Net Spatial Segmentation', 'Position', [500, 200, 800, 700]);
custom_cmap = [0 1 1; 1 1 1; 0 0.2 0.8; 1 0 1];

% THE FIX: Wrap UNet_Prediction in double() and set limits [1 4]
imagesc(double(UNet_Prediction), [1 4]); 

colormap(custom_cmap);
axis image;
title('Phase III: U-Net Spatial Glacier Facies Classification');

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

disp('PHASE III COMPLETE: Journal-Level U-Net Intelligence Executed.');

% Clean up the temporary disk files so your hard drive stays clean
rmdir('temp_labels', 's');