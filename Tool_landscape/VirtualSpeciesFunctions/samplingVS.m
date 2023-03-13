function T = samplingVS(Layers, InitialPoint, MapInfo, samples, factor, show, spName, replacement, uniqueness)
% T = samplingVS(ReadInfo, InfoInitialPoint, MapInfo, samples, factor, show,...
%                spName, replacement, uniqueness)
% 
% DESCRIPTION:
%   'samplingVS' sample the species presence-data(observations) over 
%   the generated map niche 
%
% REQUIRED INPUTS:
%   ReadInfo: A structure generated by 'ReadLayers' function.
%   InfoInitialPoint: A structure generated by 'InitialPoint' function.
%   MapInfo: A structure generated by 'NicheGeneration' function.
%   samples: An integer with the number of required samples.
%   factor (alpha): Real number that defines the sampling method.
%   show: boolean variable (true, false), show the resulting niche map  
%         and the sampled points
%   spName: a string with the species name
%   replacement: boolean variable (true, false), perform a replacemet in 
%                the sample if true, or not replacement if false
%   
% OPTIONAL INPUTS:
%   uniqueness: (default: false)
% 
% OUTPUTS:
%   T: a table with the species name 'spName', the longitude and 
%   the latitude of the virtual species observations
%%  
    if nargin < 9
        uniqueness = false;
    end
    
    Map = MapInfo.Map;
    sorted_norm_distance = MapInfo.SortNormDistance;
    NormDistance = MapInfo.NormDistance;
    R = Layers.R;
    idx = InitialPoint.idx;
    Indicator = Layers.Indicator;

% Sampling the niche map
    switch factor >= 0
        %Positive alpha
        case true
            limit = find(sorted_norm_distance, 1, 'last') + 1;
            DistanceSampling = sorted_norm_distance( 1 : limit-1);
            score = zeros(1, 5);
            breaks = [1 0.8 0.6 0.4 0.2 0];

            if factor <=1
                for i = 1 : 5

                    dist1 = DistanceSampling < breaks(i);
                    dist2 = DistanceSampling > breaks(i + 1);
                    dist = DistanceSampling(logical(dist1.*dist2));
                    len = length(dist);
                    score(i) = (len/(limit - 1)) ^ factor * mean(dist);

                end
            else
                for i = 1 : 5

                    dist1 = DistanceSampling < breaks(i);
                    dist2 = DistanceSampling > breaks(i + 1);
                    dist = DistanceSampling(logical(dist1.*dist2));
                    len = length(dist);
                    if i <= 2
                        score(i) = mean(dist);
                    else
                        score(i) = (len/(limit - 1)) * mean(dist);
                    end

                end
            end

            score = score / sum(score);
            score = [0, round(score * samples)];    
            len = zeros(6, 1);
            sscore = cumsum(score);
            sampled = zeros(1, sscore(end));

            for i = 1 : 5
                dist1 = DistanceSampling < breaks(i);
                dist2 = DistanceSampling > breaks(i + 1);
                dist = DistanceSampling(logical(dist1.*dist2));
                len(i + 1) = len(i) + length(dist);
                
                sampled(sscore(i) + 1 : sscore( i + 1 )) = ...
                    randsample(len(i) + 1 : len( i + 1), score(i + 1), replacement,...
                    DistanceSampling(len(i) + 1 : len( i + 1))/...
                    sum(DistanceSampling(len(i) + 1 : len( i + 1))));%muestrear   
            end
        % Negative alpha    
        case false
            
            DistanceSampling = 1:length(sorted_norm_distance);
            factor = abs(factor);
            
            if factor > 1
                sorted_norm_distance = sorted_norm_distance.^factor;
            end 
            
            sampled = randsample(DistanceSampling, round(samples), replacement,...
                sorted_norm_distance/sum(sorted_norm_distance));
            
            
        otherwise
            T = [];
            disp('Wrong factor, try "-1" or "0"')
            return
    end
    
    Map2 = nan(size(Layers.Map));
    
    if ~uniqueness   
        Tsamples = length(sampled);
        sampledRow = zeros(1,Tsamples);
        sampledCol = sampledRow;
        
        for i = 1:Tsamples
            sorted_norm_distance(:) = 0;
            sorted_norm_distance(sampled(i)) = 1;
            NormDistance(idx) = sorted_norm_distance;
            Map2(~Indicator) = NormDistance;
            [sampledRow(i) , sampledCol(i)] = find(Map2 == 1);
            Map2(~Indicator) = 0;
        end
        
        sampledRow = sampledRow';
        sampledCol = sampledCol';
        
    else
        sorted_norm_distance(:) = 0;
        sorted_norm_distance(sampled) = 1;
        NormDistance(idx) = sorted_norm_distance;
        Map2(~Indicator) = NormDistance;
        [sampledRow , sampledCol] = find(Map2 == 1);
    end
        
    % Extract longitude and latitude  
    [Lat, Long] = intrinsicToGeographic(R,sampledCol,sampledRow);
    
    % Plot the niche map with the samples if show is true
    if show
        clf
        geoshow(Map, R, 'DisplayType', 'surface');
        contourcmap('jet',0 : 0.05 : 1, 'colorbar', 'on', 'location', 'vertical')
        geoshow(Lat, Long, 'DisplayType', 'Point', 'Marker', 'o', ...
            'MarkerSize', 5, 'MarkerFaceColor', [.95 .9 .8], 'MarkerEdgeColor', ...
            'black', 'Zdata', 2 * ones(length(Long), 1));  
    end
    
    % Create the output table with samples coordinates
    T = table(repmat(spName, length(Lat), 1));    
    T.LONG = Long;
    T.LAT = Lat;
    T.Properties.VariableNames{1} = 'Name';
end
