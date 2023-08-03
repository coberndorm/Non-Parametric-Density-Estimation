function classifiers=HFrontierDepthAveraged(T, readInfo,alpha,percentile,show,outlier,outlier2)
% classifiers=ColoringRadius(in,show,outlier,outlier2,alpha)
% 
% DESCRIPTION 
%   'coloringRadius' takes species presence-data(observations) over 
%   a map and generates a niche probability intensity map, by using the
%   radius 
%
% REQUIRED INPUTS
%   T: Table given by sampleVS with species samples and information
%   ReadInfo: an strcuture generated by 'ReadLayers' function
%   
% OPTIONAL INPUTS
%   alpha: shrinking factor for the boundary, alpha=[0,1]
%   percentile: percentile until which the radius results will be averaged
%   show: if the boundary and the estimated map will show
%   outlier1: If the outliers are removed before normalization
%   outlier2: a integer with the number of required samples 
% 
% OUTPUTS:
%   classifiers.nodes: An array containing the boundary points with ther
%                       environmental covariates
%   classifiers.index: Indexes in T of the boundary points
%   classifiers.radius: radius of every point to its closest boundary point
%   classifiers.normalizers: normalization coefficients for environmental
%                            covariates
%   classifiers.T: Array of every sample data with their environmental
%                   covariate
%   classifiers.map: Array containing the probability  intensity of species
%                    presence in every map pixel
%%  
if nargin <3
    alpha = 0;
end
if nargin <4
    percentile = 0;
end
if nargin <5
    show = false;    
end
if nargin <6
    outlier=false;
end
if nargin <7
    outlier2=false;
end

%out1 and ouT will be the samples taken out by the outlier detection
out1=[];
ouT=[];

%preparing initial important data
Z = readInfo.Z; % Enviromental Info in each point of the map
R = readInfo.R; % Geographic cells Reference
reps = size(Z); % Size of Z
caps = reps(3); % Number of enviromental variables
template = Z(:, :, 1); % Array of map size
data = NaN(length(template(:)), caps); % 2D Array of the amount of pixels by enviromental variables

% Saves the enviromental variables of each pixel in the 2D array
for i = 1 : caps
    template = Z(:, :, i);
    data(:, i) = template(:);
end

% Determine which pixels of the array are not part of the map
nanDetector = sum(data, 2);
pointer = ~isnan(nanDetector);
idx = find(pointer==1);

%Normalizing the sample and map data
points = T{:,4:end};
normalizers=[max(points(:,:));min(points(:,:))];
points(:,:)=(points(:,:)-normalizers(2,:))./(normalizers(1,:)-normalizers(2,:));
data(idx,:) =  (data(idx,:)-normalizers(2,:))./(normalizers(1,:)-normalizers(2,:));

%pre-PCA outlier detection
if outlier
    [~,~,RD,chi_crt]=DetectMultVarOutliers(points(:,:));
    id_out=RD>chi_crt(4);
    out1=points(id_out,:);
    points=points(~id_out,:);
end

%PCA proyection of points
[coeff,~,~,~,explained]=pca(points(:,:));
pin=points(:,:)*coeff(:,1:3);

if ~isempty(out1)
    out1=out1*coeff(:,1:3);
end

%outlier detection pos-PCA
if outlier2
    %siz=round(size(pin,1)*0.3);
    [~,~,RD,chi_crt]=DetectMultVarOutliers(pin);
    id_out=RD>chi_crt(4);
    ouT=pin(id_out,:);
    pin=pin(~id_out,:);
end

%generating the boundary
nodes = boundary(pin(:,1),pin(:,2),pin(:,3),alpha);

boundPointsIndex = unique(nodes)';
boundPoints = points(boundPointsIndex,:);
pointsSize = length(boundPointsIndex);
samples = length(points);
radius = zeros(pointsSize,samples);
map = ones(reps(1), reps(2));

for j=1:samples
    for i=1:pointsSize
        radius(i,j)=norm(points(boundPointsIndex(i),:)-points(j,:));
        if radius(i,j) == 0
            radius(:,j) = 0;
            continue
        end
    end
end
radiusClass = zeros(percentile,samples);

for i=1:percentile
    radiusClass(i,:) = prctile(radius,i);
end

radiusIndex = find(radiusClass>0);
radiusClass = radiusClass(:,setdiff(1:end,boundPointsIndex));

response = NaN(1,length(radiusClass));
intensity = NaN(1,length(idx));

for i=1:length(idx)
    for j=1:length(radiusClass)
        response(j) = norm(points(radiusIndex(j),:)-data(idx(i),:));
    end
    probability = 0;
    for k=1:percentile
        probability = probability + sum(response<=radiusClass(k));
    end
    intensity(i) = probability/percentile;
end

intensity = (intensity - min(intensity))./(max(intensity)-min(intensity));

final = NaN(length(template(:)),1);

final(idx)=intensity;

map(:) = final(:);

classifiers.nodes = boundPoints;
classifiers.index = radiusIndex;
classifiers.radius = radiusClass;
classifiers.normalizers = normalizers;
classifiers.T = T;
classifiers.map = map;

outT=[out1;ouT];

if show
    trisurf(nodes,pin(:,1),pin(:,2),pin(:,3), 'Facecolor','cyan','FaceAlpha',0.8); axis equal;
    hold on
    plot3(pin(:,1),pin(:,2),pin(:,3),'.r')
    hold off
    

    figure
    clf
    geoshow(map, R, 'DisplayType','surface');
    contourcmap('jet',0:0.05:1, 'colorbar', 'on', 'location', 'vertical')
end
    

if isempty(outT)
    grap=false;
else
    grap=true;
end