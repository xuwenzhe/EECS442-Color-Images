% Demo code for alignment of Prokudin-Gorskii images
%
% Your code should be run after you implement alignChannels

% Path to your data directory
dataDir = fullfile('..','data','prokudin-gorskii');

% Path to your output directory (change this to your output directory)
outDir = fullfile('..', 'output', 'prokudin-gorskii');

% List of images
% imageNames = {'00125v.jpg',	'00153v.jpg', '00398v.jpg', '00149v.jpg', '00351v.jpg',	'01112v.jpg'};
imageNames = {'00153v.jpg'};
% Display variable
display = true;

% Set maximum shift to check alignment for
maxShift = [15 15];

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
    
    % Print the alignments
    fprintf('%2i %s shift: B (%2i,%2i) R (%2i,%2i)\n', i, imageNames{i}, predShift(1,:), predShift(2,:));
    
    % Write image output
    outimageName = sprintf([imageNames{i}(1:end-5) '-aligned.jpg']);
    outimageName = fullfile(outDir, outimageName);
    imwrite(colorIm, outimageName);
   
    % Optionally display the results
    if display
        figure(); clf;
        subplot(1,2,1); imagesc(im); axis image off; colormap gray
        title('Input image');
        subplot(1,2,2); imagesc(colorIm); axis image off;
        title('Aligned image');
        pause(1);
    end
end

