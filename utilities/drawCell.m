function handle = drawCell(POSITION, LENGTH, WIDTH, ANGLE, COLOR, varargin)
%   drawCell - plots a filled bacteria cell with a given length, width, position, angle, and color
%
%   Inputs:
%           POSITION        - coordinates of the cell centroid [x y]
%           LENGTH          - length of the cell (um)
%           WIDTH           - width of the cell (um)
%           ANGLE           - orientation of the cell in radians
%           COLOR           - color of the cell (rgb triplet)
%           varargin        - used to input the current axis hangle if given
%
%   Output:
%           handle         - the handle for the cell scatter
%
%   Andrew Woodward - Fall 2018

% create a starting 2d vector parallel with the x axis
x1 = POSITION(1) - LENGTH/2;
x2 = POSITION(1) + LENGTH/2;

% define the points along the line
x = x1:0.01:x2;
y = zeros(1,size(x,2))+POSITION(2);
a = POSITION(1);
b = POSITION(2);
phi = mod(ANGLE, 2*pi); % redefine angle between 0-2pi
A=(x+1i*y-a-1i*b)*exp(1i*phi); %convert the points to the complex plane and rotate
xnew=real(A)+a; % convert back to the real world
ynew=imag(A)+b;

% get the figures unit size to help determine the markerWidth of the scatter
if size(varargin,2) > 0
    editAxis = varargin{1};
else
    editAxis = gca;
end
currentunits = get(editAxis,'Units');
set(editAxis, 'Units', 'Points');
axpos = get(editAxis,'Position');
set(editAxis, 'Units', currentunits);

markerWidth = WIDTH/diff(xlim)*axpos(3); % set width of cell relative to axis size

handle = scatter(xnew, ynew, markerWidth^2, COLOR, 'filled'); % return the scatter object handle

