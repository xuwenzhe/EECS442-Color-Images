function output = demosaicImage(im, method)
% DEMOSAICIMAGE computes the color image from mosaiced input
%   OUTPUT = DEMOSAICIMAGE(IM, METHOD) computes a demosaiced OUTPUT from
%   the input IM. The choice of the interpolation METHOD can be 
%   'baseline', 'nn', 'linear', 'adagrad'. 

switch lower(method)
    case 'baseline'
        output = demosaicBaseline(im);
    case 'nn'
        output = demosaicNN(im);         % Implement this
    case 'linear'
        output = demosaicLinear(im);     % Implement this
    case 'adagrad'
        output = demosaicAdagrad(im);    % Implement this
end

%--------------------------------------------------------------------------
%                          Baseline demosaicing algorithm. 
%                          The algorithm replaces missing values with the
%                          mean of each color channel.
%--------------------------------------------------------------------------
function mosim = demosaicBaseline(im)
mosim = repmat(im, [1 1 3]); % Create an image by stacking the input
[imageHeight, imageWidth] = size(im);

% Red channel (odd rows and columns);
redValues = im(1:2:imageHeight, 1:2:imageWidth);
meanValue = mean(mean(redValues));
mosim(:,:,1) = meanValue;
mosim(1:2:imageHeight, 1:2:imageWidth,1) = im(1:2:imageHeight, 1:2:imageWidth);

% Blue channel (even rows and colums);
blueValues = im(2:2:imageHeight, 2:2:imageWidth);
meanValue = mean(mean(blueValues));
mosim(:,:,3) = meanValue;
mosim(2:2:imageHeight, 2:2:imageWidth,3) = im(2:2:imageHeight, 2:2:imageWidth);

% Green channel (remaining places)
% We will first create a mask for the green pixels (+1 green, -1 not green)
mask = ones(imageHeight, imageWidth);
mask(1:2:imageHeight, 1:2:imageWidth) = -1;
mask(2:2:imageHeight, 2:2:imageWidth) = -1;
greenValues = mosim(mask > 0);
meanValue = mean(greenValues);
% For the green pixels we copy the value
greenChannel = im;
greenChannel(mask < 0) = meanValue;
mosim(:,:,2) = greenChannel;


% 2018-01-21 EECS442hw1p2
% this is modified version of "padarray" with symmetric method
% but the reflection axis is adjusted.
% padding scheme: 
%
%
%    f   e f g h
%      ---------
%    b | a b c d
%    f | e f g h
%
%
%
function padded = pad(im)
[imageHeight, imageWidth] = size(im);
padded = zeros(imageHeight+2, imageWidth+2);
padded(2:end-1,2:end-1) = im;
padded(1,:) = padded(3,:);
padded(end,:) = padded(end-2,:);
padded(:,1) = padded(:,3);
padded(:,end) = padded(:,end-2);

%--------------------------------------------------------------------------
%                           Nearest neighbour algorithm
%--------------------------------------------------------------------------
function mosim = demosaicNN(im)
% 2018-01-21 EECS442hw1p2
mosim = repmat(im, [1 1 3]);
[imageHeight, imageWidth] = size(im);

% R G
% G B
mask_ul = -1*ones(imageHeight,imageWidth);
mask_ur = -1*ones(imageHeight,imageWidth);
mask_bl = -1*ones(imageHeight,imageWidth);
mask_br = -1*ones(imageHeight,imageWidth);
mask_ul(1:2:imageHeight, 1:2:imageWidth) = 1;
mask_ur(1:2:imageHeight, 2:2:imageWidth) = 1;
mask_bl(2:2:imageHeight, 1:2:imageWidth) = 1;
mask_br(2:2:imageHeight, 2:2:imageWidth) = 1;
padim = pad(im);
padsize = 1;

% Red channel
v_ur = conv2(padim,[0 0 0 ; 0 0 1 ; 0 0 0]);
v_ur = v_ur(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_bl = conv2(padim,[0 0 0 ; 0 0 0 ; 0 1 0]);
v_bl = v_bl(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_br = conv2(padim,[0 0 0 ; 0 0 0 ; 0 0 1]);
v_br = v_br(2+padsize:end-1-padsize,2+padsize:end-1-padsize);

% For the red pixels we copy the value
redChannel = im;
redChannel(mask_ur > 0) = v_ur(mask_ur > 0);
redChannel(mask_bl > 0) = v_bl(mask_bl > 0);
redChannel(mask_br > 0) = v_br(mask_br > 0);
mosim(:,:,1) = redChannel;

% Blue channel
v_ur = conv2(padim,[0 0 0 ; 0 0 0 ; 0 1 0]);
v_ur = v_ur(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_bl = conv2(padim,[0 0 0 ; 0 0 1 ; 0 0 0]);
v_bl = v_bl(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_ul = conv2(padim,[0 0 0 ; 0 0 0 ; 0 0 1]);
v_ul = v_ul(2+padsize:end-1-padsize,2+padsize:end-1-padsize);

% For the blue pixels we copy the value
blueChannel = im;
blueChannel(mask_ur > 0) = v_ur(mask_ur > 0);
blueChannel(mask_bl > 0) = v_bl(mask_bl > 0);
blueChannel(mask_ul > 0) = v_ul(mask_ul > 0);
mosim(:,:,3) = blueChannel;

% Green channel
v_ul = conv2(padim,[0 0 0 ; 0 0 1 ; 0 0 0]);
v_ul = v_ul(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_br = conv2(padim,[0 0 0 ; 0 0 1 ; 0 0 0]);
v_br = v_br(2+padsize:end-1-padsize,2+padsize:end-1-padsize);

% For the green pixels we copy the value
greenChannel = im;
greenChannel(mask_ul > 0) = v_ul(mask_ul > 0);
greenChannel(mask_br > 0) = v_br(mask_br > 0);
mosim(:,:,2) = greenChannel;



%--------------------------------------------------------------------------
%                           Linear interpolation
%--------------------------------------------------------------------------
function mosim = demosaicLinear(im)
% 2018-01-21 EECS442hw1p2
mosim = repmat(im, [1 1 3]);
[imageHeight, imageWidth] = size(im);

% R G
% G B
mask_ul = -1*ones(imageHeight,imageWidth);
mask_ur = -1*ones(imageHeight,imageWidth);
mask_bl = -1*ones(imageHeight,imageWidth);
mask_br = -1*ones(imageHeight,imageWidth);
mask_ul(1:2:imageHeight, 1:2:imageWidth) = 1;
mask_ur(1:2:imageHeight, 2:2:imageWidth) = 1;
mask_bl(2:2:imageHeight, 1:2:imageWidth) = 1;
mask_br(2:2:imageHeight, 2:2:imageWidth) = 1;
padim = pad(im);
padsize = 1;

% Red channel
v_ur = conv2(padim,[0 0 0 ; 1 0 1 ; 0 0 0]*0.5);
v_ur = v_ur(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_bl = conv2(padim,[0 1 0 ; 0 0 0 ; 0 1 0]*0.5);
v_bl = v_bl(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_br = conv2(padim,[1 0 1 ; 0 0 0 ; 1 0 1]*0.25);
v_br = v_br(2+padsize:end-1-padsize,2+padsize:end-1-padsize);

% For the red pixels we copy the value
redChannel = im;
redChannel(mask_ur > 0) = v_ur(mask_ur > 0);
redChannel(mask_bl > 0) = v_bl(mask_bl > 0);
redChannel(mask_br > 0) = v_br(mask_br > 0);
mosim(:,:,1) = redChannel;

% Blue channel
v_ur = conv2(padim,[0 1 0 ; 0 0 0 ; 0 1 0]*0.5);
v_ur = v_ur(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_bl = conv2(padim,[0 0 0 ; 1 0 1 ; 0 0 0]*0.5);
v_bl = v_bl(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_ul = conv2(padim,[1 0 1 ; 0 0 0 ; 1 0 1]*0.25);
v_ul = v_ul(2+padsize:end-1-padsize,2+padsize:end-1-padsize);

% For the blue pixels we copy the value
blueChannel = im;
blueChannel(mask_ur > 0) = v_ur(mask_ur > 0);
blueChannel(mask_bl > 0) = v_bl(mask_bl > 0);
blueChannel(mask_ul > 0) = v_ul(mask_ul > 0);
mosim(:,:,3) = blueChannel;

% Green channel
v_ul = conv2(padim,[0 1 0 ; 1 0 1 ; 0 1 0]*0.25);
v_ul = v_ul(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_br = conv2(padim,[0 1 0 ; 1 0 1 ; 0 1 0]*0.25);
v_br = v_br(2+padsize:end-1-padsize,2+padsize:end-1-padsize);

% For the green pixels we copy the value
greenChannel = im;
greenChannel(mask_ul > 0) = v_ul(mask_ul > 0);
greenChannel(mask_br > 0) = v_br(mask_br > 0);
mosim(:,:,2) = greenChannel;


%--------------------------------------------------------------------------
%                           Adaptive gradient
%--------------------------------------------------------------------------
function mosim = demosaicAdagrad(im)
% 2018-01-21 EECS442hw1p2
mosim = repmat(im, [1 1 3]);
[imageHeight, imageWidth] = size(im);

% R G
% G B
mask_ul = -1*ones(imageHeight,imageWidth);
mask_ur = -1*ones(imageHeight,imageWidth);
mask_bl = -1*ones(imageHeight,imageWidth);
mask_br = -1*ones(imageHeight,imageWidth);
mask_ul(1:2:imageHeight, 1:2:imageWidth) = 1;
mask_ur(1:2:imageHeight, 2:2:imageWidth) = 1;
mask_bl(2:2:imageHeight, 1:2:imageWidth) = 1;
mask_br(2:2:imageHeight, 2:2:imageWidth) = 1;
padim = pad(im);
padsize = 1;

% Red channel
v_ur = conv2(padim,[0 0 0 ; 1 0 1 ; 0 0 0]*0.5);
v_ur = v_ur(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_bl = conv2(padim,[0 1 0 ; 0 0 0 ; 0 1 0]*0.5);
v_bl = v_bl(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
% there are two schemes for br: diagonal(1) vs anti-diagonal(2)
v_br1 = conv2(padim,[1 0 0 ; 0 0 0 ; 0 0 1]*0.5);
v_br1 = v_br1(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_br2 = conv2(padim,[0 0 1 ; 0 0 0 ; 1 0 0]*0.5);
v_br2 = v_br2(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
diff1 = conv2(padim,[1 0 0 ; 0 0 0 ; 0 0 -1]);
diff1 = abs(diff1(2+padsize:end-1-padsize,2+padsize:end-1-padsize));
diff2 = conv2(padim,[0 0 1 ; 0 0 0 ; -1 0 0]);
diff2 = abs(diff2(2+padsize:end-1-padsize,2+padsize:end-1-padsize));

% For the red pixels we copy the value
redChannel = im;
redChannel(mask_ur > 0) = v_ur(mask_ur > 0);
redChannel(mask_bl > 0) = v_bl(mask_bl > 0);
redChannel(mask_br > 0 & diff1 <= diff2) = v_br1(mask_br > 0 & diff1 <= diff2);
redChannel(mask_br > 0 & diff1 > diff2) = v_br2(mask_br > 0 & diff1 > diff2);
mosim(:,:,1) = redChannel;

% Blue channel
v_ur = conv2(padim,[0 1 0 ; 0 0 0 ; 0 1 0]*0.5);
v_ur = v_ur(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_bl = conv2(padim,[0 0 0 ; 1 0 1 ; 0 0 0]*0.5);
v_bl = v_bl(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
% there are two schemes for ul: diagonal(1) vs anti-diagonal(2)
v_ul1 = conv2(padim,[1 0 0 ; 0 0 0 ; 0 0 1]*0.5);
v_ul1 = v_ul1(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_ul2 = conv2(padim,[0 0 1 ; 0 0 0 ; 1 0 0]*0.5);
v_ul2 = v_ul2(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
diff1 = conv2(padim,[1 0 0 ; 0 0 0 ; 0 0 -1]);
diff1 = abs(diff1(2+padsize:end-1-padsize,2+padsize:end-1-padsize));
diff2 = conv2(padim,[0 0 1 ; 0 0 0 ; -1 0 0]);
diff2 = abs(diff2(2+padsize:end-1-padsize,2+padsize:end-1-padsize));

% For the blue pixels we copy the value
blueChannel = im;
blueChannel(mask_ur > 0) = v_ur(mask_ur > 0);
blueChannel(mask_bl > 0) = v_bl(mask_bl > 0);
blueChannel(mask_ul > 0 & diff1 <= diff2) = v_ul1(mask_ul > 0 & diff1 <= diff2);
blueChannel(mask_ul > 0 & diff1 > diff2) = v_ul2(mask_ul > 0 & diff1 > diff2);
mosim(:,:,3) = blueChannel;

% Green channel
% there are two schemes for ul: top-bottom(1), left-right(2)
v_ul1 = conv2(padim,[0 1 0 ; 0 0 0 ; 0 1 0]*0.5);
v_ul1 = v_ul1(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_ul2 = conv2(padim,[0 0 0 ; 1 0 1 ; 0 0 0]*0.5);
v_ul2 = v_ul2(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
diff_ul1 = conv2(padim,[0 1 0 ; 0 0 0 ; 0 -1 0]);
diff_ul1 = abs(diff_ul1(2+padsize:end-1-padsize,2+padsize:end-1-padsize));
diff_ul2 = conv2(padim,[0 0 0 ; 1 0 -1 ; 0 0 0]);
diff_ul2 = abs(diff_ul2(2+padsize:end-1-padsize,2+padsize:end-1-padsize));

% there are two schemes for br: top-bottom(1), left-right(2)
v_br1 = conv2(padim,[0 1 0 ; 0 0 0 ; 0 1 0]*0.5);
v_br1 = v_br1(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
v_br2 = conv2(padim,[0 0 0 ; 1 0 1 ; 0 0 0]*0.5);
v_br2 = v_br2(2+padsize:end-1-padsize,2+padsize:end-1-padsize);
diff_br1 = conv2(padim,[0 1 0 ; 0 0 0 ; 0 -1 0]);
diff_br1 = abs(diff_br1(2+padsize:end-1-padsize,2+padsize:end-1-padsize));
diff_br2 = conv2(padim,[0 0 0 ; 1 0 -1 ; 0 0 0]);
diff_br2 = abs(diff_br2(2+padsize:end-1-padsize,2+padsize:end-1-padsize));

% For the green pixels we copy the value
greenChannel = im;
greenChannel(mask_ul > 0 & diff_ul1 <= diff_ul2) = ...
    v_ul1(mask_ul > 0 & diff_ul1 <= diff_ul2);
greenChannel(mask_ul > 0 & diff_ul1 > diff_ul2) = ...
    v_ul2(mask_ul > 0 & diff_ul1 > diff_ul2);
greenChannel(mask_br > 0 & diff_br1 <= diff_br2) = ...
    v_br1(mask_br > 0 & diff_br1 <= diff_br2);
greenChannel(mask_br > 0 & diff_br1 > diff_br2) = ...
    v_br2(mask_br > 0 & diff_br1 > diff_br2);
mosim(:,:,2) = greenChannel;
