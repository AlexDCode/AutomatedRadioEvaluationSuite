function createAntenna3DRadiationPattern(axes, Magnitude, Theta, Phi)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % This function generates a 3D radiation pattern plot for antennas in App Designer environments. It
    % creates a visually informative 3D representation of radiation patterns without dependencies on
    % internal MATLAB functions. The function:
    %
    %   - Renders a 3D surface representation of radiation pattern data
    %   - Draws reference coordinate system with x, y, z axes and plane indicators
    %   - Creates interactive elements (data tips) for measurements
    %   - Provides visual indicators for azimuth and elevation angles
    %   - Supports proper scaling and normalization of magnitude data
    %
    % Things to consider:
    %   - Magnitude should be a matrix where dimensions match the length of Phi and Theta vectors
    %   - The function automatically normalizes the pattern for visualization
    %   - Colors represent magnitude values according to the default jet colormap
    %   - Coordinate system follows standard spherical conventions:
    %       * Theta = 0° points along positive z-axis
    %       * Theta = 90°, Phi = 0° points along positive x-axis
    %       * Theta = 90°, Phi = 90° points along positive y-axis
    %
    % INPUT:
    %   app       - App Designer application object containing the UI components
    %   axes      - Target UIAxes object where the pattern will be rendered
    %   Magnitude - Matrix of magnitude values (typically in dBi) corresponding to the pattern
    %   Theta     - Vector of theta angles in degrees (elevation angle, 0-180°)
    %   Phi       - Vector of phi angles in degrees (azimuth angle, 0-360°)
    %
    % OUTPUT:
    %   None. The function modifies the provided axes object directly.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Compute the max and min values of directivity
    minval = min(min(Magnitude));
    maxval = max(max(Magnitude));
    
    % Normalize the magnitude data
    r = Magnitude - minval;
    
    % Origin offset.
    antoff = [0 0 0];
    
    % Get the parent figure of the axes
    hfig = ancestor(axes, 'figure');
    
    % Begin plotting
    hold(axes, 'on');
    
    % Draw coordinate system
    addAxesLabels(axes, antoff);
    
    % Draw reference circles in 3D space..
    drawCircle(axes, 90, 0:359, [0 0 1], antoff, 'XY_Circle'); % XY plane (blue)
    drawCircle(axes, 0:359, 0, [0 1 0], antoff, 'XZ_Circle');  % XZ plane (green)
    drawCircle(axes, 0:359, 90, [1 0 0], antoff, 'YZ_Circle'); % YZ plane (red)
    
    % Create the 3D radiation pattern surface
    surfHdl = create3DPattern(axes, Magnitude, Theta, Phi, r, antoff);
    
    % Configure zoom and pan behavior
    z = zoom(hfig);
    if ismethod(z, 'setAxes3DPanAndZoomStyle')
        z.setAxes3DPanAndZoomStyle(axes, 'camera');
    end
    
    % Set the default view angle
    view(axes, 135, 20);
    
    % Apply axis limits and settings
    axis(axes, 'vis3d');
    axis(axes, [-1.2 1.2 -1.2 1.2 -1.2 1.2]);
    axis(axes, 'equal');
    axis(axes, 'off');
    
    % Release the hold
    hold(axes, 'off');
end

%% Helper Functions
function addAxesLabels(axes, antoff)
    % Draw coordinate axes and labels.
    r = 1.2;
    
    % X-axis (red).
    plot3(axes, [antoff(1), r+antoff(1)], [antoff(2), antoff(2)], [antoff(3), antoff(3)], 'r', 'LineWidth', 1.5);
    text(axes, 1.1*r+antoff(1), antoff(2), antoff(3), 'x');
    
    % Y-axis (green).
    plot3(axes, [antoff(1), antoff(1)], [antoff(2), r+antoff(2)], [antoff(3), antoff(3)], 'g', 'LineWidth', 1.5);
    text(axes, antoff(1), 1.05*r+antoff(2), antoff(3), 'y');
    
    % Z-axis (blue).
    plot3(axes, [antoff(1), antoff(1)], [antoff(2), antoff(2)], [antoff(3), r+antoff(3)], 'b', 'LineWidth', 1.5);
    text(axes, antoff(1), antoff(2), 1.05*r+antoff(3), 'z');
    
    % Add azimuth and elevation indicators.
    XPos = 1.2;
    
    % Azimuth arrow.
    arrowStart = [XPos + antoff(1), antoff(2), antoff(3)];
    arrowEnd = [XPos + antoff(1), 0.1 + antoff(2), antoff(3)];
    drawArrow(axes, arrowStart, arrowEnd, 'k');
    text(axes, XPos + antoff(1), 0.12 + antoff(2), antoff(3), 'az');
    
    % Elevation arrow.
    arrowStart = [XPos + antoff(1), antoff(2), antoff(3)];
    arrowEnd = [XPos + antoff(1), antoff(2), 0.1 + antoff(3)];
    drawArrow(axes, arrowStart, arrowEnd, 'k');
    text(axes, XPos + antoff(1), antoff(2), 0.15 + antoff(3), 'el');
end

function drawArrow(axes, start_point, end_point, color)
    % Draw a simple line arrow in 3D space.
    plot3(axes, [start_point(1), end_point(1)], ...
                [start_point(2), end_point(2)], ...
                [start_point(3), end_point(3)], ...
                'LineWidth', 1.5, 'Color', color);
    
    % Calculate head size based on arrow length.
    arrowLength = norm(end_point - start_point);
    headSize = arrowLength * 0.3;
    
    % Simple arrowhead (approximation).
    delta = end_point - start_point;

    % A vector perpendicular to delta.
    normal = [delta(3), 0, -delta(1)]; 
    if norm(normal) < 1e-6
        normal = [0, delta(3), -delta(2)];
    end
    normal = normal / norm(normal) * headSize;
    
    % First arrowhead line.
    head1 = end_point - delta/norm(delta) * headSize + normal/3;
    plot3(axes, [end_point(1), head1(1)], ...
                [end_point(2), head1(2)],... 
                [end_point(3), head1(3)], ...
                'LineWidth', 1.5, 'Color', color);
    
    % Second arrowhead line.
    head2 = end_point - delta/norm(delta) * headSize - normal/3;
    plot3(axes, [end_point(1), head2(1)], ...
                [end_point(2), head2(2)],... 
                [end_point(3), head2(3)], ...
                'LineWidth', 1.5, 'Color', color);
end


function drawCircle(axes, theta, phi, color, antoff, tag)
    % Get the Spherical Coordinates
    [theta_grid, phi_grid] = meshgrid(theta, phi);

    % Convert from Spherical (degrees) to Cartesian Coordinates. 
    [X, Y, Z] = sph2cart(phi_grid, theta_grid, 1.1);

    % Apply offset.
    X = X + antoff(1);
    Y = Y + antoff(2);
    Z = Z + antoff(3);
    
    % Draw the circle.
    plot3(axes, X, Y, Z, 'LineWidth', 2, 'Tag', tag, 'Color', color);
end

function [X, Y, Z] = sph2cart(phi, theta, r)
    % Phi and Theta are in degrees.
    Z = r .* cosd(theta);
    X = r .* sind(theta) .* cosd(phi);
    Y = r .* sind(theta) .* sind(phi);
end

function surfHdl = create3DPattern(axes, Mag, theta, phi, r, antoff)
    % Create the meshgrid for the spherical coordinates
    [theta, phi] = meshgrid(theta, phi);
    
    % Reshape the magnitude and radius matrices
    MagE = reshape(Mag, length(phi), length(theta));
    r = reshape(r, length(phi), length(theta));
    
    % Normalize the radius
    r_normalized = r./max(max(r));

    % Convert from Spherical (degrees) to Cartesian Coordinates. 
    [X, Y, Z] = sph2cart(phi, theta, r_normalized);
    
    % Apply offset if needed
    X = X + antoff(1);
    Y = Y + antoff(2);
    Z = Z + antoff(3);
    
    % Create the surface
    surfHdl = surf(axes, X, Y, Z, MagE, 'FaceColor', 'interp');
    
    % Set surface properties
    set(surfHdl, 'LineStyle', 'none', 'FaceAlpha', 1.0, 'Tag', '3D polar plot');
    
    % Apply colormap
    colormap(axes, jet(256));
end