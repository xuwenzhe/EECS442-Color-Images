function [im, gtShift] = randomlyShiftChannels(im, maxShift)
%
% RANDOMLYSHIFTCHANNELS shifts the channels with respect to one another.
%
%   [IM, GTSHIFT] = RANDOMLYSHIFTCHANNELS(IM, MAXSHIFT) randomly shifts the
%   second and third channels of IM within the MAXSHIFT range. 
%


assert(size(im,3) == 3);

% Randomly sample displacements in I and J coordinates between -maxDisp:maxDisp
shiftI = randi([-maxShift(1) maxShift(1)], [1 2]);
shiftJ = randi([-maxShift(2) maxShift(2)], [1 2]);

% Replace the channels with the shifted versions
im(:,:,2) = circshift(im(:,:,2), [shiftI(1) shiftJ(1)]);
im(:,:,3) = circshift(im(:,:,3), [shiftI(2) shiftJ(2)]);

% Record the true shifts
gtShift = [shiftI'  shiftJ'];
