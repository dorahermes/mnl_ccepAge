%% ccep03_plotN1
% this code:
% 1. loads the latencies from ccep02_loadN1.m
% 2. displays the age distribution
% 3. displays a scatter plot for latencies of connections from one region
%    to another for different ages. 
% 4. 3 repeated for all combinations of regions. Now a first and second 
%    order polynomial are fitted on the data. 
% 5. multilinear regression is used to predict age from latencies. In the
%    figure, the first and second order polynomial are fitted and the R^2
%    are displayed for both. 
% 6. displays an adjacency matrix with all destrieux regions stimulated,
%    showing CCEPs in other destrieux regoins
% 7. tests leave one out cross validation of a first and second order
%    polynomial and plots the COD of the first order polynomial fitting. 

% none of those figures are used in the paper.

% Dora Hermes, Dorien van Blooijs, 2020


%% load the n1Latencies from the derivatives
clear
clc
close all

myDataPath = setLocalDataPath(1);
if exist(fullfile(myDataPath.output,'derivatives','av_ccep','n1Latencies_V1.mat'),'file')
    
    % if the n1Latencies_V1.mat was saved after ccep02_loadN1, load the n1Latencies structure here
    load(fullfile(myDataPath.output,'derivatives','av_ccep','n1Latencies_V1.mat'),'n1Latencies')
else
    disp('Run first ccep02_loadN1.m')
end

%% age distribution --> not used in paper

all_ages = zeros(length(n1Latencies),1);
for kk = 1:length(n1Latencies)
    all_ages(kk) = n1Latencies(kk).age;
end

figure, 
histogram(all_ages,'BinMethod','integers')
title('Age distribution')
xlabel('Age (years)')
ylabel('# subjects')

%% connections from one region to another --> not used in paper
% shows scatter plot with latencies per patient with connection from a
% specific region to another region. In the title, the pearson correlation
% for latency (ms) per age is displayed. 

region_start = input('Choose roi where connections start [temporal, frontal, parietal, occipital, central]: ','s');
region_end = input('Choose roi where connections end [temporal, frontal, parietal, occipital, central]: ','s');

% region_start = 'occipital';
% region_end = 'occipital';

out = ccep_connectRegions(n1Latencies,region_start,region_end);

% initialize output: age, mean and variance in latency per subject
my_output = NaN(length(out.sub),3);

% get variable per subject
for kk = 1:length(out.sub)
    my_output(kk,1) = out.sub(kk).age;
    my_output(kk,2) = mean(out.sub(kk).latencies,'omitnan');
    my_output(kk,3) = var(out.sub(kk).latencies,'omitnan');
end

figure
plot(my_output(:,1),1000*my_output(:,2),'k.','MarkerSize',10)
xlabel('age (years)'),ylabel('mean dT (ms)')
[r,p] = corr(my_output(~isnan(my_output(:,2)),1),my_output(~isnan(my_output(:,2)),2),'Type','Pearson');
title(['r=' num2str(r,3) ' p=' num2str(p,3)])

%% scatter plot with CCEP latency from one region to another related to age --> not used in paper
% we fitted a second order polynomial and first order polynomial. The r-
% and p-value of the pearson correlation is shown in the title of each
% subplot.
% subplots with all combinations

clear out
regions_connect = {'temporal','central','parietal','frontal'};
conn_matrix = [1 1; 1 2; 1 3; 1 4; 2 1; 2 2; 2 3; 2 4; 3 1; 3 2; 3 3; 3 4; 4 1; 4 2; 4 3; 4 4];
out = cell(1,size(conn_matrix,1));

for outInd = 1:size(conn_matrix,1)
    region_start = regions_connect{conn_matrix(outInd,1)};
    region_end = regions_connect{conn_matrix(outInd,2)};
    temp = ccep_connectRegions(n1Latencies,region_start,region_end);
    out{outInd} = temp;
    out{outInd}.name = {region_start,region_end};
end


figure('position',[0 0 700 700])
for outInd = 1:size(conn_matrix,1)

    % initialize output: age, mean and variance in latency per subject
    my_output = NaN(length(out{outInd}.sub),3);

    % get variable per subject
    for kk = 1:length(out{outInd}.sub)
        my_output(kk,1) = out{outInd}.sub(kk).age;
        my_output(kk,2) = mean(out{outInd}.sub(kk).latencies,'omitnan');
        my_output(kk,3) = var(out{outInd}.sub(kk).latencies,'omitnan');
    end

    % age vs mean CCEP
    subplot(4,4,outInd),hold on
    plot(my_output(:,1),1000*my_output(:,2),'k.','MarkerSize',10)
    xlabel('age (years)'),ylabel('mean dT (ms)')
    [r,p] = corr(my_output(~isnan(my_output(:,2)),1),my_output(~isnan(my_output(:,2)),2),'Type','Pearson');
%     title([out(outInd).name ' to ' out(outInd).name   ', r=' num2str(r,3) ' p=' num2str(p,3)])
    title(['r=' num2str(r,3) ' p=' num2str(p,3)])
    xlim([0 max(all_ages)+1])%, ylim([0 100])
    
    % Yeatman et al., fit a second order polynomial:
    % y  = w1* age^2 * w2*age + w3
    [P] = polyfit(my_output(~isnan(my_output(:,2)),1),1000*my_output(~isnan(my_output(:,2)),2),2);
    x_age = 1:1:max(all_ages);
    y_fit = P(1)*x_age.^2 + P(2)*x_age + P(3);
    plot(x_age,y_fit,'r')

    % Let's fit a first order polynomial:
    % y  =  w1*age + w2
    [P,S] = polyfit(my_output(~isnan(my_output(:,2)),1),1000*my_output(~isnan(my_output(:,2)),2),1);
    x_age = 1:1:max(all_ages);
    y_fit = P(1)*x_age + P(2);
    plot(x_age,y_fit,'r')
end

if ~exist(fullfile(myDataPath.output,'derivatives','age'),'dir')
    mkdir(fullfile(myDataPath.output,'derivatives','age'));    
end

% figureName = fullfile(myDataPath.output,'derivatives','age','AgeVsLatency_N1');

% set(gcf,'PaperPositionMode','auto')
% print('-dpng','-r300',figureName)
% print('-depsc','-r300',figureName)


%% Predict age from mean/var --> not used in paper
% apply multilinear regression 

figure('position',[0 0 700 700])
for outInd = 1:size(conn_matrix,1)

    % initialize output: age, mean and variance in latency per subject
    my_output = NaN(length(out{outInd}.sub),3);

    % get variable per subject
    for kk = 1:length(out{outInd}.sub)
        my_output(kk,1) = out{outInd}.sub(kk).age;
        my_output(kk,2) = mean(out{outInd}.sub(kk).latencies,'omitnan');
        my_output(kk,3) = std(out{outInd}.sub(kk).latencies,'omitnan');
    end

    % age vs mean CCEP
    subplot(4,4,outInd),hold on
    plot(1000*my_output(:,2),my_output(:,1),'k.','MarkerSize',10)
    ylabel('age (years)'),xlabel('mean dT (ms)')
%     [r,p] = corr(my_output(~isnan(my_output(:,2)),2),my_output(~isnan(my_output(:,2)),1),'Type','Pearson');
    stats2 = regstats(my_output(~isnan(my_output(:,2)),1),[my_output(~isnan(my_output(:,2)),2) my_output(~isnan(my_output(:,2)),3)]); % linear regression: age vs [mean latencies, SD latencies]
    stats1 = regstats(my_output(~isnan(my_output(:,2)),1),my_output(~isnan(my_output(:,2)),2)); % linear regression: age vs mean latencies
%     title([out(outInd).name ' to ' out(outInd).name   ', r=' num2str(r,3) ' p=' num2str(p,3)])
    title(['R_2=' num2str(stats2.adjrsquare,3) 'R_1=' num2str(stats1.rsquare,3)])
    xlim([0 max(all_ages)])%, ylim([0 100])
    
    % Yeatman et al., fit a second order polynomial:
    % y  = w1* age^2 * w2*age + w3
    [P,~] = polyfit(1000*my_output(~isnan(my_output(:,2)),2),my_output(~isnan(my_output(:,2)),1),2);
    x_latency = 20:1:max(all_ages);
    y_fit = P(1)*x_latency.^2 + P(2)*x_latency + P(3);
    plot(x_latency,y_fit,'r')

    % Let's fit a first order polynomial:
    % y  =  w1*age + w2
    [P,S] = polyfit(1000*my_output(~isnan(my_output(:,2)),2),my_output(~isnan(my_output(:,2)),1),1);
    x_latency = 2:1:60;
    y_fit = P(1)*x_latency + P(2);
    plot(x_latency,y_fit,'r')
end

if ~exist(fullfile(myDataPath.output,'derivatives','age'),'dir')
    mkdir(fullfile(myDataPath.output,'derivatives','age'));    
end

% figureName = fullfile(myDataPath.output,'derivatives','age','LatencyVSage_N1');

% set(gcf,'PaperPositionMode','auto')
% print('-dpng','-r300',figureName)
% print('-depsc','-r300',figureName)


%% overview of the number of connections from one region to another --> not used in paper
% adjacency matrix of subject  1 and all subjects together

DestAmatall = zeros(size(n1Latencies,2),75,75);
for kk = 1:length(n1Latencies) % loop subjects    
    % initialize connections as empty
    DestAmat = zeros(75,75); % roi_start --> roi_end
    
    for ll = 1:length(n1Latencies(kk).run) % loop runs
        % run through all first stimulated channels (nr 1 in pair)
        for chPair = 1:size(n1Latencies(kk).run(ll).n1_peak_sample,2)
            
            % find region label of chPair
            chPairDest = str2double(n1Latencies(kk).run(ll).average_ccep_DestrieuxNr(chPair,:));
            
            % find N1 responders
            chSig = find(~isnan(n1Latencies(kk).run(ll).n1_peak_sample(:,chPair))==1);
            % find region label of N1 responders
            chSigDest = str2double(n1Latencies(kk).run(ll).channel_DestrieuxNr(chSig));
            
            
            DestAmat(chSigDest(~isnan(chSigDest) & chSigDest ~= 0),chPairDest(~isnan(chPairDest) & chPairDest ~= 0)) = ...
                DestAmat(chSigDest(~isnan(chSigDest) & chSigDest ~= 0),chPairDest(~isnan(chPairDest) & chPairDest ~= 0))+1;
        end
    end
    
    DestAmatall(kk,:,:) = DestAmat; 
end

DestAmatsum = squeeze(sum(DestAmatall,1));

% visualize all existing connections per patient and in total

subj = 1;

figure,
subplot(1,2,1),
imagesc(squeeze(DestAmatall(subj,:,:)),[0 10])
title(sprintf('Connections between regions in subject %1.0f',subj))
xlabel('Responding Destrieux region')
ylabel('Stimulated Destrieux region')

subplot(1,2,2),
imagesc(DestAmatsum,[0 50])
title('Connections between regions in all subjects')
xlabel('Responding Destrieux region')
ylabel('Stimulated Destrieux region')

%% Test fitting a first and second order polynomial with leave 1 out cross validation --> not used in paper
% 

nsubs = length(out{outInd}.sub);
cod_out = zeros(size(conn_matrix,1),2);
figure('position',[0 0 700 600])
for outInd = 1:size(conn_matrix,1)

    % initialize output: age, mean and variance in latency per subject
    my_output = NaN(nsubs,3);

    % get variable per subject
    for kk = 1:nsubs
        my_output(kk,1) = out{outInd}.sub(kk).age;
        my_output(kk,2) = mean(out{outInd}.sub(kk).latencies,'omitnan');
        my_output(kk,3) = std(out{outInd}.sub(kk).latencies,'omitnan')./sqrt(length(out{outInd}.sub(kk).latencies));
    end
     
    % Test fitting a first order polynomial (leave 1 out cross validation)
    % y  =  w1*age + w2
    cross_val_linear = NaN(length(find(~isnan(my_output(:,2)))),4);
    % size latency (ms) X prediction (ms) X p1 (slope) X p2 (intercept) of left out
    sub_counter = 0;
    for kk = 1:nsubs
        if ~isnan(my_output(kk,2))
            sub_counter = sub_counter+1;
            % leave out kk
            theseSubsTrain = ~isnan(my_output(:,2)) & ~ismember(1:nsubs,kk)';
            P = polyfit(my_output(theseSubsTrain,1),1000*my_output(theseSubsTrain,2),1);
            cross_val_linear(sub_counter,3:4) = P;
            cross_val_linear(sub_counter,1) = 1000*my_output(kk,2); % kk (left out) actual
            cross_val_linear(sub_counter,2) = P(1)*my_output(kk,1)+P(2); % kk (left out) prediction
        end
    end
    cod_out(outInd,1) = calccod(cross_val_linear(:,2),cross_val_linear(:,1),1);
    
    % Like Yeatman et al., for DTI fit a second order polynomial:
    cross_val_second = NaN(length(find(~isnan(my_output(:,2)))),5);
    % size latency (ms) X prediction (ms) X p1 (age^2) X p2 (age) X p3 (intercept) of left out
    sub_counter = 0;
    for kk = 1:nsubs
        if ~isnan(my_output(kk,2))
            sub_counter = sub_counter+1;
            % leave out kk
            theseSubsTrain = ~isnan(my_output(:,2)) & ~ismember(1:nsubs,kk)';
            P = polyfit(my_output(theseSubsTrain,1),1000*my_output(theseSubsTrain,2),2);
            cross_val_second(sub_counter,3:5) = P;
            cross_val_second(sub_counter,1) = 1000*my_output(kk,2);
            cross_val_second(sub_counter,2) = P(1)*my_output(kk,1).^2+P(2)*my_output(kk,1)+P(3);
        end
    end
    cod_out(outInd,2) = calccod(cross_val_second(:,2),cross_val_second(:,1),1);
    
    % Fit with a piecewise linear model:
    cross_val_piecewiselin = NaN(length(find(~isnan(my_output(:,2)))),5);
    % size latency (ms) X prediction (ms) X p1 (age^2) X p2 (age) X p3 (intercept) of left out
    sub_counter = 0;
    my_options = optimoptions(@lsqnonlin,'Display','off','Algorithm','trust-region-reflective');
    for kk = 1:nsubs
        if ~isnan(my_output(kk,2))
            sub_counter = sub_counter+1;
            % leave out kk
            theseSubsTrain = ~isnan(my_output(:,2)) & ~ismember(1:nsubs,kk)';
            
%             % use the slmengine tool from here:
%             % John D'Errico (2020). SLM - Shape Language Modeling (https://www.mathworks.com/matlabcentral/fileexchange/24443-slm-shape-language-modeling), MATLAB Central File Exchange. Retrieved July 14, 2020.
%             slm = slmengine(my_output(theseSubsTrain,1),1000*my_output(theseSubsTrain,2),'degree',1,'plot','off','knots',3,'interiorknots','free');
%             % predicted value at left out x
%             yhat = slmeval(my_output(kk,1),slm,0);
%             cross_val_piecewiselin(sub_counter,1) = 1000*my_output(kk,2);
%             cross_val_piecewiselin(sub_counter,2) = yhat;
            
            % use our own function:
            x = my_output(theseSubsTrain,1);
            y = 1000*my_output(theseSubsTrain,2);
            [pp] = lsqnonlin(@(pp) ccep_fitpiecewiselinear(pp,y,x),...
                [40 -1 0 20],[0 -Inf -Inf 10],[40 0 Inf 30],my_options);
            x_fit = my_output(kk,1);
            y_fit = (pp(1) + pp(2)*min(pp(4),x_fit) + pp(3)*max(pp(4),x_fit));
            cross_val_piecewiselin(sub_counter,1) = 1000*my_output(kk,2);
            cross_val_piecewiselin(sub_counter,2) = y_fit;
        end
    end
    cod_out(outInd,3) = calccod(cross_val_piecewiselin(:,2),cross_val_piecewiselin(:,1),1);
    
    subplot(4,4,outInd),hold on

    % figure,hold on
    for kk = 1:nsubs
        % plot histogram per subject in the background
        if ~isnan(my_output(kk,2))
            distributionPlot(1000*out{outInd}.sub(kk).latencies','xValues',out{outInd}.sub(kk).age,...
                'color',[.6 .6 .6],'showMM',0,'histOpt',2)
        end
%         % plot mean+sterr per subject
%         plot([my_output(kk,1) my_output(kk,1)],[1000*(my_output(kk,2)-my_output(kk,3)) 1000*(my_output(kk,2)+my_output(kk,3))],...
%             'k','LineWidth',1)
    end
    % plot mean per subject in a dot
    plot(my_output(:,1),1000*my_output(:,2),'ko','MarkerSize',6)

    [r,p] = corr(my_output(~isnan(my_output(:,2)),1),my_output(~isnan(my_output(:,2)),2),'Type','Pearson');
%     title([out(outInd).name ' to ' out(outInd).name   ', r=' num2str(r,3) ' p=' num2str(p,3)])
    
    % plot confidence intervals for linear fit
    x_age = 1:1:max(all_ages);
    % get my crossval y distribution
    y_n1LatCross = cross_val_linear(:,3)*x_age + cross_val_linear(:,4);
    % y_n1LatCross = cross_val_second(:,3)*x_age.^2 + cross_val_second(:,4)*x_age + cross_val_second(:,5);
    
    % get 95% confidence intervals
    low_ci = quantile(y_n1LatCross,.025,1);
    up_ci = quantile(y_n1LatCross,.975,1);
    fill([x_age x_age(end:-1:1)],[low_ci up_ci(end:-1:1)],[0 .7 1],'EdgeColor',[0 .7 1])
    
    % put COD in title
    title(['COD=' int2str(cod_out(outInd,1)) ' p=' num2str(p,2)])
    
    xlim([0 60]), ylim([0 100])

%     xlabel('age (years)'),ylabel('mean dT (ms)')
    set(gca,'XTick',10:10:50,'YTick',20:20:100,'FontName','Arial','FontSize',12)
    
end

if ~exist(fullfile(myDataPath.output,'derivatives','age'),'dir')
    mkdir(fullfile(myDataPath.output,'derivatives','age'));    
end
figureName = fullfile(myDataPath.output,'derivatives','age','AgeVsLatency_N1');

% set(gcf,'PaperPositionMode','auto')
% print('-dpng','-r300',figureName)
% print('-depsc','-r300',figureName)
