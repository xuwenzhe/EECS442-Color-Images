function [imShift, predShift] = alignChannels(im, maxShift)
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
assert(all(maxShift > 0));

% 2018-01-21 RGB channel alignment, EECS442hw1 part1
channelb = im(:,:,1); % channel1 is the "base" channel
channel2 = im(:,:,2);
channel3 = im(:,:,3);

% edge() method compare
% figure()
% subplot(2,3,1)       
% imshow(edge(channelb,'Sobel'))
% xlabel('Sobel')
% subplot(2,3,2)
% imshow(edge(channelb,'Prewitt'))
% xlabel('Prewitt')
% subplot(2,3,3)
% imshow(edge(channelb,'Roberts'))
% xlabel('Roberts')
% subplot(2,3,4)
% imshow(edge(channelb,'log'))
% xlabel('log')
% subplot(2,3,5)
% imshow(edge(channelb,'Canny'))
% xlabel('Canny')
% subplot(2,3,6)       
% imshow(edge(channelb,'approxcanny'))
% xlabel('approxcanny')

[cShift2, pShift2] = alignc(channel2); 
[cShift3, pShift3] = alignc(channel3);

predShift = [pShift2;pShift3];
imShift = im;
imShift(:,:,2) = cShift2;
imShift(:,:,3) = cShift3;

% boundary trim
imShift = trim(imShift, predShift);
% imShift = crop(imShift);

figure()
imshow(imShift)

    % nested function to help call for channel2 and channel3
    function [cShift, pShift] = alignc(channel)
        % pShift is a 1x2 array, 
        % pShift(1,1) is first dimension shift
        % pShift(1,2) is second dimension shift
        % searchDomain is maxShift-by-maxshift
        ref = double(edge(channelb,'Canny'));
        error = realmax;
        for i = -maxShift(1):maxShift(1)
            for j = -maxShift(2):maxShift(2)
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
    % crop 5 percent border
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
