% Demo to track any color based on 'createMask' function.  Finds and annotates centroid and bounding box of any colored blobs.
% Modify thresholds to detect different colors. In this case we are finding
% blue colors and create blobs around it.

% --> This code implements an algorithm to find the Transformation matrix.
% --> Handles occlusion.
% --> Reconstructs the occluded points.

clear all;
clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
imtool close all;  % Close all imtool figures if you have the Image Processing Toolbox.
clear;  % Erase all existing variables. Or clearvars if you want.
workspace;  % Make sure the workspace panel is showing.
format long g;
format compact;
fontSize = 20;

% Specify input video file name.
folder = pwd; % Current folder path
baseFileName = 'Marker Focussed Videos\Euler Tours\Euler 11.mp4';  % Video to track
fullFileName = fullfile(folder, baseFileName);

% Check if the video file actually exists in the current folder or on the search path.
if ~exist(fullFileName, 'file')
	% File doesn't exist -- didn't find it there.  Check the search path for it.
	fullFileNameOnSearchPath = baseFileName; % No path this time.
	if ~exist(fullFileNameOnSearchPath, 'file')
		% Still didn't find it.  Alert user.
		errorMessage = sprintf('Error: %s does not exist in the search path folders.', fullFileName);
		uiwait(warndlg(errorMessage));
		return;
	end
end

% Instantiate a video reader object for this video.
videoObject = VideoReader(fullFileName);

% Setup other parameters
numberOfFrames = videoObject.NumberOfFrame;

% Initializing video for video writing
vwrite = VideoWriter('Euler 11_gcf','MPEG-4');
open(vwrite);

%Initializing variables
strt = 1;  % Start of frame
count = 0;

for k = strt : numberOfFrames
    tic 
    if k == strt
        centroid1 = zeros(numberOfFrames,3);
        centroid2 = zeros(numberOfFrames,3);
        centroid3 = zeros(numberOfFrames,3);
        centroid4 = zeros(numberOfFrames,3);
        centroid5 = zeros(numberOfFrames,3);
        centroid6 = zeros(numberOfFrames,3);
        centroid7 = zeros(numberOfFrames,3);
        centroid8 = zeros(numberOfFrames,3);
        newPrevPt = zeros(8,3);
        regions = zeros(numberOfFrames,1);
        
    end
    
        thisFrame = read(videoObject,k);
        thisFrame = imcrop(thisFrame,[0,0,630,400]);
        newim = createMaskfixedblue3(thisFrame);
%         newim = createMaskpink2(thisFrame);
%         newim = createMaskpink4(thisFrame);
        newim = bwareaopen(newim,2);
        newim = imfill(newim, 'holes');
        axis on;
%       caption = sprintf('Original RGB image, frame #%d 0f %d', k, numberOfFrames);
% 	    title(caption, 'FontSize', fontSize);
% 	    drawnow;
        [labeledImage, numberOfRegions] = bwlabel(newim);
        frame(k,:) = numberOfRegions;
        
        
count = 0;
cent = [];

                 stats = regionprops(labeledImage, 'BoundingBox','Centroid','Area','EquivDiameter'); 
                 for rb = 1:numberOfRegions
                     count = count + 1;
                     cent(count,:) = stats(rb).Centroid;
                 end
                 
                 zc = zeros(size(cent,1),1);
                 cent = [cent,zc];
               
                 
              
                 
if k == strt
      P0 = cent;
      PrevPt = cent;
      centroid1(k,:) = P0(1,:);
      centroid2(k,:) = P0(2,:);
      centroid3(k,:) = P0(3,:);
      centroid4(k,:) = P0(4,:);
      centroid5(k,:) = P0(5,:);
      centroid6(k,:) = P0(6,:);
      centroid7(k,:) = P0(7,:);
      centroid8(k,:) = P0(8,:);
end

  % Cent is available here. This will be the new one.
  % PPt is also available here.
  
  if k ~= strt && count > 8
      resrvd = zeros(8,3);
      for i = 1:8
          for j = 1:count
              X = [PrevPt(i,:);cent(j,:)];
              d(j) = pdist(X,'euclidean');
          end
              [dmin,ind] = min(d);  
              if(dmin < 12)
              resrvd(i,:) = cent(ind,:);
              end
      end
  end
  
    
  if k ~= strt && count <= 8
      resrvd = zeros(8,3);
      for i = 1:count
          for j = 1:8
              X = [cent(i,:);PrevPt(j,:)];

              d(j) = pdist(X,'euclidean');
          end
                [dmin,ind] = min(d);
                if(dmin < 12)
                   resrvd(ind,:) = cent(i,:);
                end
      end
  end
      

      
if k ~= strt
% Calculation of rotation matrix and translation
TF = resrvd(:,1);  % Writing the 1st column of resrvd
index = find(TF == 0);  % Finding those rows which is empty
val = isempty(index);   % Checking whether the index is empty
newPrevPt = PrevPt;
newP0 = P0;             % 1st point
if(val == 0)            % That means checking for index whether it is empty(if yes val is 1 or val is 0)
newPrevPt(index(1:size(index,1)),:) = 0;
newP0(index(1:size(index,1)),:) = 0;      % 
end
[Rot,T] = rigid_transform_3D(newPrevPt', resrvd');  % SE2 w.r.t previous frame
% [Rot_G,T_G] = rigid_transform_3D(newP0', resrvd');  % SE2 w.r.t 1st frame
 
% theta_a(k,:) = rad2deg(rotm2eul(Rot));
% theta(k,1) = theta_a(k,1);

theta(k,:) = reshape(Rot,[1,9]);   % Changed ANM
trans(k,:) = T';

% theta_G(k,:) = reshape(Rot_G,[1,9]);   % Rotation matrix w.r.t 1st frame
% trans_G(k,:) = T_G';                   % Translation matrix w.r.t 1st frame
 
if(val == 0)
    for gg = 1:size(index,1)
        newPt = Rot*(PrevPt(index(gg),:))' + T;
        resrvd(index(gg),:) = newPt;
    end
end

[Rot_G,T_G] = rigid_transform_3D(P0', resrvd');  % SE2 w.r.t 1st frame

theta_G(k,:) = reshape(Rot_G,[1,9]);   % Rotation matrix w.r.t 1st frame
trans_G(k,:) = T_G';                   % Translation matrix w.r.t 1st frame

PrevPt = resrvd;
clear d;
% In the respective centroid variables
      centroid1(k,:) = resrvd(1,:);
      centroid2(k,:) = resrvd(2,:);
      centroid3(k,:) = resrvd(3,:);
      centroid4(k,:) = resrvd(4,:);
      centroid5(k,:) = resrvd(5,:);
      centroid6(k,:) = resrvd(6,:);
      centroid7(k,:) = resrvd(7,:);
      centroid8(k,:) = resrvd(8,:);
end

% Plotting the points 
figure(1)
imshow(thisFrame)
set(gcf, 'Position',  [100, 100, 750, 400])
hold on
plot(PrevPt(:,1),PrevPt(:,2),'g*','LineWidth',0.5,'MarkerSize',2)
% plot([PrevPt(1,1) PrevPt(2,1)], [PrevPt(1,2) PrevPt(2,2)],'LineWidth',1.5)
caption = sprintf('%d blobs found in frame #%d 0f %d', count, k, numberOfFrames);
title(caption, 'FontSize', fontSize);
axis on
hold off
toc
pframe = getframe(gcf);
writeVideo(vwrite,pframe);
end
close(vwrite);

% Collectively writing all the tracked points in a single variable.
all_pt = cat(2,centroid1,centroid2,centroid3,centroid4,centroid5,centroid6,...
             centroid7,centroid8,theta,trans,theta_G,trans_G);


  
        