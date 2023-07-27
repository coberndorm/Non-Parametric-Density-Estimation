function classifiers=FrontierDepthPreprocessing(T, layerInfo, alpha, percentile, show, outlier, outlier2)
% 
% DESCRIPTION 
%   'FrontierDepth' takes species presence-data(observations) over 
%   a map and generates a niche probability intensity map, by using the
%   depth of each point.
%   Note: sample and point will be used interchangeably, as well as map
%   point and pixel.
%
% REQUIRED INPUTS
%   T: Table given by sampleVS with species samples and information
%   layerInfo: an strcuture generated by 'ReadLayers' function
%   
% OPTIONAL INPUTS
%   alpha: shrinking factor for the boundary, alpha=[0,1]
%   percentile: percentile with which the radius will be taken
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

% Setting default values for alpha, show, and outlier detection
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

%Preprocessing the sample data
niche=nicheData(T,3,4:22);
niche=niche.aClus(0.9);
niche=niche.regressor;
niche=niche.setProcFun();
points = niche.procFun(T{:,niche.inds});

%Preprocessing the map environmental data
Z = layerInfo.Z; % Enviromental Info in each point of the map
[bio,pointer] = niche.map2vec(layerInfo.Z);
data = niche.procFun(bio);

%preparing initial important data
reps = size(Z); % Size of Z
R = layerInfo.R; % Geographic cells Reference
template = Z(:, :, 1); % Array of map size

% Determine which pixels of the array are not part of the map
idx = find(pointer==1);

% Outlier detection before PCA
if outlier
    [~,~,RD,chi_crt]=DetectMultVarOutliers(points(:,:));
    id_out=RD>chi_crt(4);
    out1=points(id_out,:);
    points=points(~id_out,:);
end

%PCA proyection of points
[coeff,~,~,~,~]=pca(points(:,:));
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

% defining the points that make up the frontier/boundary
nodes = boundary(pin(:,1),pin(:,2),pin(:,3),alpha);
boundPointsIndex = unique(nodes)'; %index of the points in T
boundPoints = points(boundPointsIndex,:); % Information of the frontier points
pointsSize = length(boundPointsIndex); % Size of the frontier array

% Amount of samples
samples = length(points);

% Array of the distance of each point to each frontier point
radius = zeros(pointsSize,samples); 

% Defining an array for the final map values
map = ones(reps(1), reps(2));


% Distance from each point to the frontier, including frontier points
for j=1:samples
    for i=1:pointsSize
        radius(i,j)=norm(points(boundPointsIndex(i),:)-points(j,:));
    end
end

% Selecting the sample's radius as the percentile's value of the distances
radiusClass = prctile(radius,percentile);

% Determining the index in T of each radius  (excludes frontier points)
radiusIndex = find(min(radius)>0);

% Deleting the frontier points from the radiusClass array
radiusClass = radiusClass(:,setdiff(1:end,boundPointsIndex));

% Creating an empty array to determine each pixel's depth
response = NaN(1,length(radiusClass));

% Creating an empty array to determine each pixel's depth
intensity = NaN(1,length(idx));

% Calculating the depth of each map pixel with the radiusClass points
for i=1:length(idx)
    for j=1:length(radiusClass)
        response(j) = norm(points(radiusIndex(j),:)-data(i,:));
    end
    intensity(i) = sum(response<=radiusClass);
end

% Normalizing the intensity array
intensity = (intensity - min(intensity))./(max(intensity)-min(intensity));

% Creating an empty array to determine each pixel's intensity
final = NaN(length(template(:)),1);
final(idx)=intensity;

% Going back from a 1d array to a 2d array
map(:) = final(:);
map(:) = final(:);

classifiers.nodes = boundPoints;
classifiers.index = radiusIndex;
classifiers.radius = radiusClass;
classifiers.niche = niche;
classifiers.T = T;
classifiers.map = map;

outT=[out1;ouT];

% Plot the frontier and the coloured map
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