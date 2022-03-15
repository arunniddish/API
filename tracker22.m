%%% This code is just a combined version of tracker03.m and tracker05.m
%%% This code will perform real time tracking. The video is live relayed
%%% from webcam. 
%%% The issue i am facing with this code is - all the marker points should
%%% be in the camera view from t = 0 or the first frame.
%%% Live tracking of Caitlin Inchworm for phase delay
%%% This tracking is done on only 2 points.
%%% Reading and writing data to serial port
%%% Records the plot and makes a video

% Demo to track any color based on 'createMask' function.  Finds and annotates centroid and bounding box of any colored blobs.
% Modify thresholds to detect different colors. In this case we are finding
% magenta colors and create blobs around it.

clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
imtool close all;  % Close all imtool figures if you have the Image Processing Toolbox.
clear;  % Erase all existing variables. Or clearvars if you want.
workspace;  % Make sure the workspace panel is showing.
format long g;
format compact;
fontSize = 20;


% Setup other parameters
numberOfFrames = 3000;
endpt1 = zeros(numberOfFrames,2);
endpt2 = zeros(numberOfFrames,2);
count = 0;
G = 20;
Td_int = 1000;
k = 1;
while(true)
    
        if k == 1
		% Enlarge figure to full screen.
		set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
		% Give a name to the title bar.
		set(gcf, 'Name', 'Particle Tracking', 'NumberTitle', 'Off') 
		hCheckbox = uicontrol('Style','checkbox',... 
			'Units', 'Normalized',...
			'String', 'Finish Now',... 
			'Value',0,'Position', [.2 .96 .4 .05], ...
			'FontSize', 14);
        
        
        centroid1 = zeros(numberOfFrames,2);
        centroid2 = zeros(numberOfFrames,2);
        
        % define the device (either Arduino or Seeeduino) serial communication
        % Timeout is defined so that it wait untils the mentioned time to
        % read from serial port 
        device = serialport('COM12',9600,"Timeout",30);
        flush(device);
        
        % Instantiate a video reader object for this video.
        cam = webcam;
        
        %Initializing video for video writing
         vwrite = VideoWriter('gcfcaptureV4','MPEG-4');
         open(vwrite);
           
        end
    
        thisFrame = cam.snapshot;
        thisFrame = imresize(thisFrame,[640,480]);
        newim = createMaskInchWormTdelay(thisFrame);
        
        % Filter out small blobs
        newim = bwareaopen(newim, 30);
        % Fill in holes
        newim = imfill(newim, 'holes');
        hImage=subplot(3, 1, 1);
        % Display it.
        imshow(thisFrame);
        axis on;
        caption = sprintf('Original RGB image, frame #%d 0f %d', k, numberOfFrames);
        title(caption, 'FontSize', fontSize);
        drawnow;
        subplot(3,1,2);
        imshow(newim);
        title('Colored Blob Mask', 'FontSize', fontSize);
        drawnow;
        
        flush(device);
        % reads the gait cycle number as a char value
        m_char = readline(device);
        % converts to double
        m = str2double(m_char);
        
        
        if count == 0 || m>=3
        
            [labeledImage, numberOfRegions] = bwlabel(newim);
            if numberOfRegions == 2
            stats = regionprops(labeledImage, 'BoundingBox', 'Centroid');
            count = count +1;
            % Delete old texts and rectangles
            if exist('hRect', 'var')
                delete(hRect);
            end
            if exist('hText', 'var')
                delete(hText);
            end
            end
        end

            % Display the original image again.
            subplot(3, 1, 3); % Switch to original image.
            hImage=subplot(3, 1, 3);
            imshow(thisFrame);
            axis on;
            hold on;
            caption = sprintf('%d blobs found in frame #%d 0f %d', numberOfRegions, k, numberOfFrames);
            title(caption, 'FontSize', fontSize);
            drawnow;

            if count == 1
                for r = 1 : numberOfRegions
                % Find location for this blob.
                thisBB = stats(r).BoundingBox;
                thisCentroid = stats(r).Centroid;

                    if r==1
                        centroid1(count,:) = thisCentroid;
                    end

                    if r==2
                        centroid2(count,:) = thisCentroid;
                    end

                end

                    X1 = [centroid1(count,:);centroid2(count,:)];
                    d1 = pdist(X1,'euclidean');
                    pix2mm = 89/d1;
            end

        % reads the gait cycle number as a char value
        m_char = readline(device);
        % converts to double
        m = str2double(m_char);

        if m>=3

            if count~=1
                for r = 1 : numberOfRegions
                % Find location for this blob.
                thisBB = stats(r).BoundingBox;
                thisCentroid = stats(r).Centroid;
                thisCentroid = [thisCentroid(1) thisCentroid(2)];

                    if r==1
                        endpt1(count,:) = thisCentroid;
                    end

                    if r==2
                        endpt2(count,:) = thisCentroid;
                    end

                end

                        if endpt1(count,1)<endpt2(count,1)

                            centroid1(count,:) = endpt1(count,:);
                            centroid2(count,:) = endpt2(count,:);

                        end


                        if endpt2(count,1)<endpt1(count,1)

                            centroid1(count,:) = endpt2(count,:);
                            centroid2(count,:) = endpt1(count,:);

                        end

            end

            % defines new T_d as double, rounded to make sure it is an int
            Td_int = round(Td_int + G*(centroid1(count,1) - centroid1(count-1,1)));
            % converts double to string 
            Td = num2str(Td_int);
            % writes string to serial port
            writeline(device,Td);


        end

                hRect(r) = rectangle('Position', thisBB, 'EdgeColor', 'r', 'LineWidth', 2);
                hSpot = plot(thisCentroid(1), thisCentroid(2), 'y+', 'MarkerSize', 8, 'LineWidth', 2);
                hText(r) = text(thisBB(1), thisBB(2)-20, strcat('X: ', num2str(round(thisCentroid(1))), '    Y: ', num2str(round(thisCentroid(2)))));
                set(hText(r), 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 8, 'Color', 'yellow');
%                 if exist(Td)
%                             Td_text = text(300,300,strcat('Td: ', num2str(round(Td))));
%                             set(Td_text, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 15, 'Color', 'white');
%                 end
                
                hold off
                drawnow;
                frame = getframe(gcf);
                writeVideo(vwrite,frame);

                if get(hCheckbox, 'Value')
                % Finish now checkbox is checked.
                msgbox('Done with processing.');
                return;
                end

k = k+1;
% flush(device); % Clears buffer
end
close(vwrite);
                