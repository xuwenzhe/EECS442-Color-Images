% Path to your data directory
dataDir = fullfile('..','data','prokudin-gorskii');

% Path to your output directory (change this to your output directory)
outDir = fullfile('..', 'output', 'prokudin-gorskii');

% List of images
% imageNames = {'00125v.jpg',	'00153v.jpg', '00398v.jpg', '00149v.jpg', '00351v.jpg',	'01112v.jpg'};
imageNames = {'00153v.jpg'};
% Display variable
display = false;

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

    I = channels;
    I1 = impyramid(I, 'reduce');
    I2 = impyramid(I1, 'reduce');
    I3 = impyramid(I2, 'reduce');
    I4 = impyramid(I3, 'reduce');
    
    % Align the blue and red channels to the green channel from coarse to
    % fine image
    tic % start counting time
    [~, predShift] = alignChannelsSpeed(I, [-15,15;-15,15],[-15,15;-15,15]);
    disp(predShift)
    nopyramid = toc % time elapsed for non-Faster alignment 13.4273 sec
    
    radius = [7,7]; % user pre-defined search region.
    [~, predShift] = alignChannelsSpeed(I4, ...
        gSR([0,0],radius),gSR([0,0],radius));
    disp(predShift);
    [~, predShift] = alignChannelsSpeed(I3, ...
        gSR(predShift(1,:),radius),gSR(predShift(2,:),radius));
    disp(predShift);
    [~, predShift] = alignChannelsSpeed(I2, ...
        gSR(predShift(1,:),radius),gSR(predShift(2,:),radius));
    disp(predShift);
    [~, predShift] = alignChannelsSpeed(I1, ...
        gSR(predShift(1,:),radius),gSR(predShift(2,:),radius));
    disp(predShift);
    [~, predShift] = alignChannelsSpeed(I, ...
        gSR(predShift(1,:),radius),gSR(predShift(2,:),radius));
    disp(predShift);
    
    pyramid = toc - nopyramid % time elapsed for Faster alignment 6.8738 sec
    
    
end

% generate Search Region
function searchRegion = gSR(center,radius)
    % generate a rectangular search region based on center (1x2) and
    % radius(1x2)
    searchRegion = zeros(2,2);
    searchRegion(1,1) = center(1,1) - radius(1,1);
    searchRegion(1,2) = center(1,1) + radius(1,1);
    searchRegion(2,1) = center(1,2) - radius(1,2);
    searchRegion(2,2) = center(1,2) + radius(1,2);
end

function [imShift, predShift] = alignChannelsSpeed(im, searchRegion2, searchRegion3)
% ALIGNCHANNELS align channels in an image.
%   [IMSHIFT, PREDSHIFT] = ALIGNCHANNELS(IM, MAXSHIFT) aligns the channels in an
%   NxMx3 image IM. The first channel is fixed and the remaining channels
%   are aligned to it within the maximum displacement range of MAXSHIFT (in
%   both directions). The code returns the aligned image IMSHIFT after
%   performing this alignment. The optimal shifts are returned as in
%   PREDSHIFT a 2x2 array. PREDSHIFT(1,:) is the shifts  in I (the first) 
%   and J (the second) dimension of the second channel, and PREDSHIFT(2,:)
%   are the same for the third channel.


% Sanity check
assert(size(im,3) == 3);

% 2018-01-21 RGB channel alignment, EECS442hw1 part1
channelb = im(:,:,1); % channel1 is the "base" channel
channel2 = im(:,:,2);
channel3 = im(:,:,3);


[cShift2, pShift2] = alignc(channel2, searchRegion2); 
[cShift3, pShift3] = alignc(channel3, searchRegion3);

predShift = [pShift2;pShift3];
imShift = im;
imShift(:,:,2) = cShift2;
imShift(:,:,3) = cShift3;

% boundary trim
imShift = trim(imShift, predShift);
% imShift = crop(imShift);


    % nested function to help call for channel2 and channel3
    function [cShift, pShift] = alignc(channel,searchRegion)
        % pShift is a 1x2 array, 
        % pShift(1,1) is first dimension shift
        % pShift(1,2) is second dimension shift
        % searchRegion is 2x2, 
        % search row from sR(1,1) to sR(1,2)
        % search col from sR(2,1) to sR(2,2)
        ref = double(edge(channelb,'Canny'));
        error = realmax;
        for i = searchRegion(1,1):searchRegion(1,2)
            for j = searchRegion(2,1):searchRegion(2,2)
                tmpShift = circshift(channel,[i,j]);
                % immse needs image processing lib
                % rmse measurement
                error_tmp = immse(double(edge(tmpShift,'Canny')),ref); 
                if error_tmp < error
                    error = error_tmp;
                    cShift = tmpShift;
                    pShift(1,1) = i;
                    pShift(1,2) = j;
                end
            end
        end
    end
    
    % 2018-01-22, EECS442 hw1 p1
    % find overlap among rectangles
    function trimed = trim(imShift, predShift)
        shift2i = predShift(1,1);
        shift2j = predShift(1,2);
        shift3i = predShift(2,1);
        shift3j = predShift(2,2);
        ulI = max([1, shift2i, shift3i]);
        ulJ = max([1, shift2j, shift3j]);
        [brI, brJ] = size(imShift(:,:,1));
        brI = min([brI, brI+shift2i, brI+shift3i]);
        brJ = min([brJ, brJ+shift2j, brJ+shift3j]);
        trimed = imShift;
        color = 1; % 1 for white, 0 for black;
        for c = 1:3
            trimed(1:ulI,:,c) = color;
            trimed(brI+1:end,:,c) = color;
            trimed(:,1:ulJ,c) = color;
            trimed(:,brJ+1:end,c) = color;
        end
    end

    % 2018-01-22, EECS 442 hw1 p1
    % crop the 5 percent border
    function cropped = crop(imShift)
        [brI, brJ] = size(imShift(:,:,1));
        ulI = uint16(0.05*brI);
        ulJ = uint16(0.05*brJ);
        brI = uint16(0.95*brI);
        brJ = uint16(0.95*brJ);
        cropped = imShift;
        color = 1; % 1 for white, 0 for black;
        for c = 1:3
            cropped(1:ulI,:,c) = color;
            cropped(brI+1:end,:,c) = color;
            cropped(:,1:ulJ,c) = color;
            cropped(:,brJ+1:end,c) = color;
        end
    end
end

    

