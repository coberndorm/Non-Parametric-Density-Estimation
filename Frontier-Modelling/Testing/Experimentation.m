function Results = Experimentation(Dimensions, Virtual_Species_Methods, Samples, Number_Of_Maps, Plotting)
% This function runs an experimentation to evaluate the accuracy of two methods
% for approximating a niche. The function generates several virtual species
% niches and for each one, it generates a number of samples and approximates
% the niche using two different methods. The accuracy results of the two methods
% are stored in a struct and returned by the function.

% INPUTS:
%   Dimensions: The number of dimensions of the niches to be generated.
%   Virtual_Species_Methods: A vector of three strings indicating the methods
%   to be used for generating the virtual species niches.
%   Samples: A vector of three integers indicating the number of samples to be
%   generated on each virtual species niche.
%   Number_Of_Maps: The number of virtual species niches to be generated.

% OUTPUTS:
% - Results: A table containing the accuracy results of the two methods for
%   approximating the niches.

    FrontierDepthResults = zeros(length(Virtual_Species_Methods),length(Samples));
    FrontierDepthAverageResults = FrontierDepthResults(:,:);

    for i = 1:length(Virtual_Species_Methods)
        close all, clf
    
        Acc_Results_Frontier_Depth = zeros(length(Samples), Number_Of_Maps);
        Acc_Results_Frontier_Depth_Average = zeros(length(Samples), Number_Of_Maps);
        
    
        % Initializing outlier handling and if generated maps show
        Outlier_Before_PCA = false;
        Outlier_After_PCA = false;
        Show_Graphs=false;
    
        % Choosing virtual species niche generation method
        Virtual_Species_Method = Virtual_Species_Methods(i);
    
        for j = 1:Number_Of_Maps
    
            % Choosing an initial point
            Info_Initial_Point = InitialPoint(Dimensions, ...
                Virtual_Species_Method); 
            
            % Generating niche based on distribution generation method and
            % initialPoint chosen
            Map_Info = NicheGeneration(Dimensions, Info_Initial_Point, 0.8, ...
                Show_Graphs);
    
            for k = 1:length(Samples)
                % Choosing amount of samples to generate on vritual niche
                Number_Samples = Samples(k);
    
                % Generating samples
                T = samplingVS(Dimensions, Info_Initial_Point, Map_Info, ...
                    Number_Samples, -1, Show_Graphs, 'GenSP', true, true);
    
                close all, clf
        
                % Aproximating niche with closest frontier point method
                classA1 = FrontierDepth(T,Dimensions,1,Show_Graphs, ...
                    Outlier_Before_PCA,Outlier_After_PCA); 
                Accuracy_Closest_Point_Method = MapMetric(Map_Info.Map,classA1.map,false);
                Acc_Results_Frontier_Depth(k, j) = Accuracy_Closest_Point_Method(1);
            
                % Aproximating niche with 25 percentile closest frontier points
                % average
                classB1 = FrontierDepthPAverage(T,Dimensions,1,25,Show_Graphs, ...
                    Outlier_Before_PCA,Outlier_After_PCA); 
                Accuracy_Percentile_Point_Method = MapMetric(Map_Info.Map,classB1.map,false);
                Acc_Results_Frontier_Depth_Average(k, j) = Accuracy_Percentile_Point_Method(1);
            end
        end

        % Computing mean accuracy results for the two methods
        Result_Closest_Point_Method = mean(Acc_Results_Frontier_Depth');
        Result_Percentile_Point_Method = mean(Acc_Results_Frontier_Depth_Average');

        if Plotting
            % Create a figure with two subplots
            figure(i);
            samples = 'Samples = '+ string(Samples);
            
            % Create the first subplot
            subplot(1,2,1);
            plot(Acc_Results_Frontier_Depth_Average');
            title('Accuracy Percentile Point');
            ylabel('Accuracy');
            xlabel('Maps')
            legend(samples)
            
            % Create the second subplot
            subplot(1,2,2);
            plot(Acc_Results_Frontier_Depth');
            title('Accuracy Closest Point');
            ylabel('Accuracy');
            xlabel('Maps')
            legend(samples)

            hold on
         end

        FrontierDepthResults(i,:) = Result_Closest_Point_Method;
        FrontierDepthAverageResults(i,:) = Result_Percentile_Point_Method;
    end

    % Saving results for current virtual species method

    Results.Closest_Point = array2table(FrontierDepthResults, 'RowNames',Virtual_Species_Methods, 'VariableNames', string(Samples));
    Results.Percentile_Point = array2table(FrontierDepthAverageResults, 'RowNames',Virtual_Species_Methods, 'VariableNames', string(Samples));
end