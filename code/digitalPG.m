% Path to your data directory
dataDir = fullfile('..','data','prokudin-gorskii');

imageNames = {'00153v.jpg'};

methods = {'baseline', 'nn', 'linear', 'adagrad'};

% Loop over images, untile them into images, align
for i = 1:length(imageNames),
    
    % Read image
    im = imread(fullfile(dataDir, imageNames{i}));
    
    % Convert to double
    im = im2double(im);
    
    % Images are stacked vertically
    % From top to bottom are B, G, R channels (and not RGB)
    imageHeight = floor(size(im,1)/3);
    imageWidth  = size(im,2);
    
    % Allocate memory for the image 
    channels = zeros(imageHeight, imageWidth, 3);
    
    % We are loading the color channels from top to bottom
    % Note the ordering of indices
    channels(:,:,3) = im(1:imageHeight,:);
    channels(:,:,2) = im(imageHeight+1:2*imageHeight,:);
    channels(:,:,1) = im(2*imageHeight+1:3*imageHeight,:);

    % Align the blue and red channels to the green channel
    [colorIm, predShift] = alignChannels(channels, maxShift);
    
    % Create a mosaiced image
    input = mosaicImage(colorIm);
    
    baseline_output = demosaicImage(input, 'baseline');
    nn_output = demosaicImage(input, 'nn');
    linear_output = demosaicImage(input, 'linear');
    adagrad_output = demosaicImage(input, 'adagrad');
    
    figure(1);
    subplot(2,3,1); imagesc(colorIm)                  ; axis image off; title('Aligned');
    subplot(2,3,2); imagesc(input)              ; axis image off; title('mosaic');
    subplot(2,3,3); imagesc(baseline_output); axis image off; title('baseline dmsc');
    subplot(2,3,4); imagesc(nn_output)                  ; axis image off; title('nn dmsc');
    subplot(2,3,5); imagesc(linear_output)              ; axis image off; title('linear dmsc');
    subplot(2,3,6); imagesc(adagrad_output); axis image off; title('adagrad dmsc');
    
    figure(2)
    subplot(2,2,1); imshow(imabsdiff(baseline_output,colorIm)); axis image off; title('baseline error');
    subplot(2,2,2); imshow(imabsdiff(nn_output,colorIm)); axis image off; title('nn error');
    subplot(2,2,3); imshow(imabsdiff(linear_output,colorIm)); axis image off; title('linear error');
    subplot(2,2,4); imshow(imabsdiff(adagrad_output,colorIm)); axis image off; title('adagrad error');
end