clear; clc; close all;

%% 폴더 경로 설정
data_load_path = 'C:\Users\user\Desktop\Figure\Figure 5\중간 데이터';

%% 초기 온도 값
T_initial_values = [25, 30, 40]; % 단위: °C

%% 그래프 색상 정의
colors_Tmax = [
    0.9804, 0.6000, 0.6000;
    0.8039, 0.3255, 0.2980;
    0.6000, 0.2000, 0.2000
];
colors_Tavg = [
    0.200, 0.624, 0.859;
    0.0000, 0.4500, 0.7608;
    0.000, 0.353, 0.620
];

%% Figure 설정
figure;
hold on;
lw = 1; % 선 두께

%% 데이터 불러오기 및 그래프 생성
legend_handles = [];
legend_labels = {};
max_time = 0;

for idx = 1:length(T_initial_values)
    T_initial = T_initial_values(idx);
    
    % 파일 로드
    data_filename = sprintf('cell_temp_difference_Tinit_%d.mat', T_initial);
    data_fullpath = fullfile(data_load_path, data_filename);
    load(data_fullpath, 'timeVec', 'Tavg_all', 'Tmax_all');
    
    max_time = max(max_time, max(timeVec));

    % Tmax 및 Tavg의 첫 번째 값을 초기 온도로 강제 설정
    Tmax_all(:,1) = T_initial;
    Tavg_all(:,1) = T_initial;

    % Tmax 영역 음영
    Tmax_max_curve = max(Tmax_all, [], 1);
    Tmax_min_curve = min(Tmax_all, [], 1);
    valid_idx = ~isnan(Tmax_max_curve) & ~isnan(Tmax_min_curve);
    fill([timeVec(valid_idx), fliplr(timeVec(valid_idx))], ...
         [Tmax_max_curve(valid_idx), fliplr(Tmax_min_curve(valid_idx))], ...
         colors_Tmax(idx, :), 'FaceAlpha', 1, 'EdgeColor', 'none');
    
    % Tmax 선 플롯
    for iCell = 1:size(Tmax_all, 1)
        plot(timeVec, Tmax_all(iCell, :), 'Color', colors_Tmax(idx, :), 'LineWidth', lw);
    end
    
    % Tavg 영역 음영
    Tavg_max_curve = max(Tavg_all, [], 1);
    Tavg_min_curve = min(Tavg_all, [], 1);
    valid_idx = ~isnan(Tavg_max_curve) & ~isnan(Tavg_min_curve);
    fill([timeVec(valid_idx), fliplr(timeVec(valid_idx))], ...
         [Tavg_max_curve(valid_idx), fliplr(Tavg_min_curve(valid_idx))], ...
         colors_Tavg(idx, :), 'FaceAlpha', 1, 'EdgeColor', 'none');
    
    % Tavg 선 플롯
    for iCell = 1:size(Tavg_all, 1)
        plot(timeVec, Tavg_all(iCell, :), 'Color', colors_Tavg(idx, :), 'LineWidth', lw);
    end
    
    % 범례 추가
    hTmax = plot(nan, nan, 'Color', colors_Tmax(idx, :), 'LineWidth', lw);
    legend_handles = [legend_handles, hTmax];
    legend_labels = [legend_labels, sprintf('T_{max} (%d°C)', T_initial)];
    
    hTavg = plot(nan, nan, 'Color', colors_Tavg(idx, :), 'LineWidth', lw);
    legend_handles = [legend_handles, hTavg];
    legend_labels = [legend_labels, sprintf('T_{avg} (%d°C)', T_initial)];
end


%% 그래프 설정
legend(legend_handles, legend_labels, 'Location', 'southeast', 'FontSize', 11, 'NumColumns', 2, 'Orientation', 'horizontal');
xlabel('Time [min]', 'FontSize', 15);
ylabel('Temperature [°C]', 'FontSize', 15);
xlim([0 max_time]);

set(gca, 'YColor', 'k');
ax = gca;
ax.FontSize = 15;

box on; grid off;

%% 그래프 저장
fig = gcf;
set(fig, 'Position', [100, 100, 560*0.9, 420*0.9]); % Figure 크기 설정
exportgraphics(gcf, 'C:\Users\user\Desktop\Figure\Figure 5\png 파일\figure5d.png', 'Resolution', 300);

disp('Figure successfully saved!');