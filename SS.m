classdef SS < matlab.apps.AppBase
    properties (Access = public)
        UIFigure           matlab.ui.Figure
        StartButton        matlab.ui.control.Button
        StopButton         matlab.ui.control.Button
        DistancePanel      matlab.ui.container.Panel
        DistanceLabel      matlab.ui.control.Label
        DistanceValue      matlab.ui.control.Label
        AngleLabel         matlab.ui.control.Label
        AngleValue         matlab.ui.control.Label
        SizeLabel          matlab.ui.control.Label
        SizeValue          matlab.ui.control.Label 
        ObjectStatusLabel  matlab.ui.control.Label % Added ObjectStatusLabel property
        ObjectStatusValue  matlab.ui.control.Label % Added ObjectStatusValue property
        ColorCodePanel     matlab.ui.container.Panel % Added ColorCodePanel property
        ColorCodeLabel     matlab.ui.control.Label  % Added ColorCodeLabel property
        ColorCode10Label   matlab.ui.control.Label  % Added ColorCode10Label property
        ColorCode20Label   matlab.ui.control.Label  % Added ColorCode20Label property
        ColorCode30Label   matlab.ui.control.Label  % Added ColorCode30Label property
        ColorCode40Label   matlab.ui.control.Label  % Added ColorCode40Label property
        ColorCode50Label   matlab.ui.control.Label  % Added ColorCode50Label property
        ColorCode60Label   matlab.ui.control.Label  % Added ColorCode60Label property
        a                  % Arduino object
        sensor             % Ultrasonic sensor object
        servo_motor        % Servo motor object
        ax                 matlab.graphics.axis.PolarAxes
        running            logical = false
        pauseDuration      double = 0 % Default pause duration
    end

    properties (Access = private)
        distanceBuffer % Buffer for distance values
        bufferSize     % Size of the buffer
        bufferIndex    % Current index in the buffer
    end
    
    methods (Access = private)
        function setupArduino(app)
            % Check if an Arduino object already exists and clear it
            if ~isempty(instrfind)
                fclose(instrfind);
                delete(instrfind);
            end
            
            % Create an Arduino object with the necessary add-ons.
            app.a = arduino('COM6', 'Uno', 'Libraries', {'Ultrasonic', 'Servo'});
            % Create an ultrasonic sensor object with trigger pin D12 and echo pin D13.
            app.sensor = ultrasonic(app.a, 'D12', 'D13');
            % Create a servo object for the servo connected to pin D3.
            app.servo_motor = servo(app.a, 'D3');
        end
        
        function initializeBuffer(app, size)
            app.bufferSize = size;
            app.distanceBuffer = zeros(1, size);
            app.bufferIndex = 1;
        end
        
        function addToBuffer(app, value)
            app.distanceBuffer(app.bufferIndex) = value;
            app.bufferIndex = mod(app.bufferIndex, app.bufferSize) + 1;
        end
        
        function filteredValue = getFilteredValue(app)
            filteredValue = mean(app.distanceBuffer);
        end
        
        function updatePlot(app)
            numSteps = 180; % Number of steps from 0 to 180 degrees
            app.initializeBuffer(5); % Initialize buffer for smoothing with window size 5

            while app.running
                % Sweep from 0 to 180 degrees
                for i = 1:numSteps+1
                    if ~app.running
                        break;
                    end
                    theta = (i-1) / numSteps;
                    writePosition(app.servo_motor, theta);
                    dist1 = readDistance(app.sensor);
                    angle = theta * 180;
                    dist = dist1 * 100;
                    if dist > 60
                        dist = 60;
                    end
                    app.addToBuffer(dist); % Add the distance to the buffer
                    smoothedDist = app.getFilteredValue(); % Get the smoothed distance
                    size = (smoothedDist * angle * pi) / 180;

                    % Update the distance, angle, and size display
                    app.DistanceValue.Text = sprintf('%.2f cm', smoothedDist);
                    app.AngleValue.Text = sprintf('%.0f°', angle);
                    app.SizeValue.Text = sprintf('%.2f cm', size);

                    % Update object status display
                    if smoothedDist < 60
                        app.ObjectStatusValue.Text = 'Object Detected';
                    else
                        app.ObjectStatusValue.Text = 'No Object';
                    end

                    % Determine color based on distance
                    if smoothedDist <= 10
                        color = 'r'; % Red
                    elseif smoothedDist <= 20
                        color = 'm'; % Magenta
                    elseif smoothedDist <= 30
                        color = 'b'; % Blue
                    elseif smoothedDist <= 40
                        color = 'c'; % Cyan
                    elseif smoothedDist <= 50
                        color = 'y'; % Yellow
                    else
                        color = 'g'; % Green
                    end

                    % Update the polar plot
                    cla(app.ax); % Clear the previous plot
                    polarplot(app.ax, angle*pi/180, smoothedDist, 'o', 'Color', color, 'MarkerFaceColor', color);

                    % Update the chord line
                    polarplot(app.ax, [0 angle*pi/180], [0 smoothedDist], 'LineWidth', 5, 'Color', color);
                    drawnow;

                    % Adjust speed here
                    pause(app.pauseDuration); % Use the pauseDuration property
                end

                % Sweep from 180 to 0 degrees
                for i = numSteps+1:-1:1
                    if ~app.running
                        break;
                    end
                    theta = (i-1) / numSteps;
                    writePosition(app.servo_motor, theta);
                    dist1 = readDistance(app.sensor);
                    angle = theta * 180;
                    dist = dist1 * 100;
                    if dist > 60
                        dist = 60;
                    end
                    app.addToBuffer(dist); % Add the distance to the buffer
                    smoothedDist = app.getFilteredValue(); % Get the smoothed distance
                    size = (smoothedDist * angle * pi) / 180;

                    % Update the distance, angle, and size display
                    app.DistanceValue.Text = sprintf('%.2f cm', smoothedDist);
                    app.AngleValue.Text = sprintf('%.0f°', angle);
                    app.SizeValue.Text = sprintf('%.2f cm', size);

                    % Update object status display
                    if smoothedDist < 60
                        app.ObjectStatusValue.Text = 'Object Detected';
                    else
                        app.ObjectStatusValue.Text = 'No Object';
                    end

                    % Determine color based on distance
                    if smoothedDist <= 10
                        color = 'r'; % Red
                    elseif smoothedDist <= 20
                        color = 'm'; % Magenta
                    elseif smoothedDist <= 30
                        color = 'b'; % Blue
                    elseif smoothedDist <= 40
                        color = 'c'; % Cyan
                    elseif smoothedDist <= 50
                        color = 'y'; % Yellow
                    else
                        color = 'g'; % Green
                    end

                    % Update the polar plot
                    cla(app.ax); % Clear the previous plot
                    polarplot(app.ax, angle*pi/180, smoothedDist, 'o', 'Color', color, 'MarkerFaceColor', color);

                    % Update the chord line
                    polarplot(app.ax, [0 angle*pi/180], [0 smoothedDist], 'LineWidth', 5, 'Color', color);
                    drawnow;

                    % Adjust speed here
                    pause(app.pauseDuration); % Use the pauseDuration property
                end
            end
        end

        function startRadar(app)
            if ~app.running
                app.running = true;
                app.updatePlot();
            end
        end
        
        function stopRadar(app)
            app.running = false;
            % Clear the Arduino object to release the connection
            if ~isempty(app.a)
                clear app.a;
                app.a = [];
            end
        end

    end
    
    methods (Access = private)
        function StartButtonPushed(app)
            app.setupArduino();
            app.startRadar();
        end
        
        function StopButtonPushed(app)
            app.stopRadar();
        end
    end
    
    methods (Access = public)
        function startupFcn(app)
            % Create Arduino and sensor objects
            app.setupArduino();
        end
    end
    
    methods (Access = public)
        function app = SS()
            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'Radar System';
            app.UIFigure.Color = [0.2 0.2 0.2]; % Dark background

            % Create Start Button
            app.StartButton = uibutton(app.UIFigure, 'push');
            app.StartButton.Position = [20 70 100 30]; % Lowered position
            app.StartButton.Text = 'Start Radar';
            app.StartButton.FontSize = 14;
            app.StartButton.FontWeight = 'bold';
            app.StartButton.BackgroundColor = [0.0 0.7 0.0];
            app.StartButton.FontColor = 'w';
            app.StartButton.ButtonPushedFcn = @(btn, event) StartButtonPushed(app);

            % Create Stop Button
            app.StopButton = uibutton(app.UIFigure, 'push');
            app.StopButton.Position = [20 30 100 30]; % Lowered position with spacing
            app.StopButton.Text = 'Stop Radar';
            app.StopButton.FontSize = 14;
            app.StopButton.FontWeight = 'bold';
            app.StopButton.BackgroundColor = [0.7 0.0 0.0];
            app.StopButton.FontColor = 'w';
            app.StopButton.ButtonPushedFcn = @(btn, event) StopButtonPushed(app);

            % Create Distance Panel
            app.DistancePanel = uipanel(app.UIFigure);
            app.DistancePanel.Position = [20 150 200 200]; % Adjusted height to fit the new elements
            app.DistancePanel.Title = 'Sensor Data';
            app.DistancePanel.FontSize = 16;
            app.DistancePanel.FontWeight = 'bold';
            app.DistancePanel.ForegroundColor = 'w';
            app.DistancePanel.BackgroundColor = [0.3 0.3 0.3];
            app.DistancePanel.BorderType = 'none';

            % Create Angle Label inside the panel
            app.AngleLabel = uilabel(app.DistancePanel);
            app.AngleLabel.Position = [10 130 80 30]; % Adjusted positions
            app.AngleLabel.Text = 'Angle:';
            app.AngleLabel.FontSize = 14;
            app.AngleLabel.FontWeight = 'bold';
            app.AngleLabel.FontColor = 'w';

            % Create Angle Value Label inside the panel
            app.AngleValue = uilabel(app.DistancePanel);
            app.AngleValue.Position = [100 130 80 30]; % Adjusted positions
            app.AngleValue.Text = '0°';
            app.AngleValue.FontSize = 14;
            app.AngleValue.FontWeight = 'bold';
            app.AngleValue.FontColor = 'w';

            % Create Distance Label inside the panel
            app.DistanceLabel = uilabel(app.DistancePanel);
            app.DistanceLabel.Position = [10 100 80 30]; % Adjusted positions
            app.DistanceLabel.Text = 'Distance:';
            app.DistanceLabel.FontSize = 14;
            app.DistanceLabel.FontWeight = 'bold';
            app.DistanceLabel.FontColor = 'w';

            % Create Distance Value Label inside the panel
            app.DistanceValue = uilabel(app.DistancePanel);
            app.DistanceValue.Position = [100 100 80 30]; % Adjusted positions
            app.DistanceValue.Text = '0.00 cm';
            app.DistanceValue.FontSize = 14;
            app.DistanceValue.FontWeight = 'bold';
            app.DistanceValue.FontColor = 'w';

            % Create Size Label inside the panel
            app.SizeLabel = uilabel(app.DistancePanel);
            app.SizeLabel.Position = [10 70 80 30]; % Adjusted positions
            app.SizeLabel.Text = 'Size:';
            app.SizeLabel.FontSize = 14;
            app.SizeLabel.FontWeight = 'bold';
            app.SizeLabel.FontColor = 'w';

            % Create Size Value Label inside the panel
            app.SizeValue = uilabel(app.DistancePanel);
            app.SizeValue.Position = [100 70 80 30]; % Adjusted positions
            app.SizeValue.Text = '0.00 cm';
            app.SizeValue.FontSize = 14;
            app.SizeValue.FontWeight = 'bold';
            app.SizeValue.FontColor = 'w';

            % Create Object Status Label inside the panel
            app.ObjectStatusLabel = uilabel(app.DistancePanel);
            app.ObjectStatusLabel.Position = [10 40 100 30]; % Adjusted positions
            app.ObjectStatusLabel.Text = 'Status:';
            app.ObjectStatusLabel.FontSize = 14;
            app.ObjectStatusLabel.FontWeight = 'bold';
            app.ObjectStatusLabel.FontColor = 'w';

            % Create Object Status Value Label inside the panel
            app.ObjectStatusValue = uilabel(app.DistancePanel);
            app.ObjectStatusValue.Position = [100 40 80 30]; % Adjusted positions
            app.ObjectStatusValue.Text = 'No Object';
            app.ObjectStatusValue.FontSize = 14;
            app.ObjectStatusValue.FontWeight = 'bold';
            app.ObjectStatusValue.FontColor = 'w';

            % Create Color Code Panel
            app.ColorCodePanel = uipanel(app.UIFigure);
            app.ColorCodePanel.Position = [20 370 200 150]; % Adjusted position for the new panel
            app.ColorCodePanel.Title = 'Color Codes';
            app.ColorCodePanel.FontSize = 16;
            app.ColorCodePanel.FontWeight = 'bold';
            app.ColorCodePanel.ForegroundColor = 'w';
            app.ColorCodePanel.BackgroundColor = [0.3 0.3 0.3];
            app.ColorCodePanel.BorderType = 'none';

            % Create Color Code Label for 10cm inside the panel
            app.ColorCode10Label = uilabel(app.ColorCodePanel);
            app.ColorCode10Label.Position = [10 110 180 20]; % Adjusted positions
            app.ColorCode10Label.Text = '0-10 cm: Red';
            app.ColorCode10Label.FontSize = 12;
            app.ColorCode10Label.FontWeight = 'bold';
            app.ColorCode10Label.FontColor = 'r';

            % Create Color Code Label for 20cm inside the panel
            app.ColorCode20Label = uilabel(app.ColorCodePanel);
            app.ColorCode20Label.Position = [10 90 180 20]; % Adjusted positions
            app.ColorCode20Label.Text = '10-20 cm: Magenta';
            app.ColorCode20Label.FontSize = 12;
            app.ColorCode20Label.FontWeight = 'bold';
            app.ColorCode20Label.FontColor = 'm';

            % Create Color Code Label for 30cm inside the panel
            app.ColorCode30Label = uilabel(app.ColorCodePanel);
            app.ColorCode30Label.Position = [10 70 180 20]; % Adjusted positions
            app.ColorCode30Label.Text = '20-30 cm: Blue';
            app.ColorCode30Label.FontSize = 12;
            app.ColorCode30Label.FontWeight = 'bold';
            app.ColorCode30Label.FontColor = 'b';

            % Create Color Code Label for 40cm inside the panel
            app.ColorCode40Label = uilabel(app.ColorCodePanel);
            app.ColorCode40Label.Position = [10 50 180 20]; % Adjusted positions
            app.ColorCode40Label.Text = '30-40 cm: Cyan';
            app.ColorCode40Label.FontSize = 12;
            app.ColorCode40Label.FontWeight = 'bold';
            app.ColorCode40Label.FontColor = 'c';

            % Create Color Code Label for 50cm inside the panel
            app.ColorCode50Label = uilabel(app.ColorCodePanel);
            app.ColorCode50Label.Position = [10 30 180 20]; % Adjusted positions
            app.ColorCode50Label.Text = '40-50 cm: Yellow';
            app.ColorCode50Label.FontSize = 12;
            app.ColorCode50Label.FontWeight = 'bold';
            app.ColorCode50Label.FontColor = 'y';

            % Create Color Code Label for 60cm inside the panel
            app.ColorCode60Label = uilabel(app.ColorCodePanel);
            app.ColorCode60Label.Position = [10 10 180 20]; % Adjusted positions
            app.ColorCode60Label.Text = '50-60 cm: Green';
            app.ColorCode60Label.FontSize = 12;
            app.ColorCode60Label.FontWeight = 'bold';
            app.ColorCode60Label.FontColor = 'g';

            % Create polar plot
            app.ax = polaraxes(app.UIFigure);            
            app.ax.Position = [0.4 0.1 0.55 0.8]; % Adjusted size and position
            app.ax.Color = [0.1 0.1 0.1];
            app.ax.ThetaColor = 'w';
            app.ax.RColor = 'w';
            app.ax.GridColor = 'w';
            app.ax.GridAlpha = 0.3;
            app.ax.LineWidth = 1.5;
            title(app.ax, 'Real-Time Radar System', 'Color', 'w', 'FontSize', 18); % Increased font size
            thetalim(app.ax, [0 180]);
            rlim(app.ax, [0 60]); % Set the distance limit to 0-60 cm
            grid(app.ax, 'on');
            hold(app.ax, 'on');
        end
    end
end
