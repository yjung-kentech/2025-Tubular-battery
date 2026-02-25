clear; clc; close all;

%% COMSOL 모델 불러오기
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'Tubular pack_4s2p_1105'; 
COM_fullfile = fullfile(COM_filepath, COM_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

%% 해석 기본 파라미터 설정
C_rate_cc = 5.4;
model.param.set('C_rate_cc', C_rate_cc);

% 초기 온도 조건
T_initial_values = [25, 30, 40]; % 단위: °C

% 폴더 설정
data_save_path = 'C:\Users\user\Desktop\새figure\mat 파일';
figure_save_path = 'C:\Users\user\Desktop\새figure\png';

% 폴더 생성
if ~exist(data_save_path, 'dir')
    mkdir(data_save_path);
end
if ~exist(figure_save_path, 'dir')
    mkdir(figure_save_path);
end

%% 그래프 색상 정의
% 25°C: 덜 빨간/더 파란, 30°C: 기본 빨간/파란, 40°C: 더 빨간/덜 파란
colors_Tmax = [
    0.9804, 0.6000, 0.6000;     % T_initial=25°C: 덜 빨간색
    0.8039, 0.3255, 0.2980;     % T_initial=30°C: 기본 빨간색 (#CD534C)
    0.6000, 0.2000, 0.2000      % T_initial=40°C: 더 빨간색
];
colors_Tavg = [
    0.200, 0.624, 0.859;        % T_initial=25°C: 덜 파란색
    0.0000, 0.4500, 0.7608;     % T_initial=30°C: 기본 파란색 (#0073C2)
    0.000, 0.353, 0.620         % T_initial=40°C: 더 파란색
];

%% 결과 저장용 변수
all_time = [];       % (1×N) 형태 시간
all_Tavg = {};       % 각 T_initial에 대한 전체 Tavg(8×N)
all_Tmax = {};       % 각 T_initial에 대한 전체 Tmax(8×N)

% 최대·최소 값 기록
max_Tmax = zeros(length(T_initial_values),1);
min_Tmax = Inf(length(T_initial_values),1);
max_Tavg = zeros(length(T_initial_values),1);
min_Tavg = Inf(length(T_initial_values),1);

%% Figure 설정
figure;
hold on;
lw = 1.5; % 선 두께

%% 반복 해석
for idx = 1:length(T_initial_values)
    T_initial = T_initial_values(idx);
    
    % 모델 파라미터 설정
    model.param.set('T_initial', sprintf('%d [degC]', T_initial));
    
    % 해석 실행
    model.study('std1').run;
    
    % 시간(분) 추출
    time = mphglobal(model, 't', 'unit', 'min');
    % 행 벡터(1×N)로 변환
    timeVec = time(:)';
    
    %% 각 셀 평균·최대 온도 추출
    Tavg_cell11 = mphglobal(model, 'Tavg_cell11', 'unit', 'degC')'; 
    Tavg_cell21 = mphglobal(model, 'Tavg_cell21', 'unit', 'degC')'; 
    Tavg_cell31 = mphglobal(model, 'Tavg_cell31', 'unit', 'degC')'; 
    Tavg_cell41 = mphglobal(model, 'Tavg_cell41', 'unit', 'degC')'; 
    Tavg_cell12 = mphglobal(model, 'Tavg_cell12', 'unit', 'degC')'; 
    Tavg_cell22 = mphglobal(model, 'Tavg_cell22', 'unit', 'degC')'; 
    Tavg_cell32 = mphglobal(model, 'Tavg_cell32', 'unit', 'degC')'; 
    Tavg_cell42 = mphglobal(model, 'Tavg_cell42', 'unit', 'degC')'; 

    Tmax_cell11 = mphglobal(model, 'Tmax_cell11', 'unit', 'degC')'; 
    Tmax_cell21 = mphglobal(model, 'Tmax_cell21', 'unit', 'degC')'; 
    Tmax_cell31 = mphglobal(model, 'Tmax_cell31', 'unit', 'degC')'; 
    Tmax_cell41 = mphglobal(model, 'Tmax_cell41', 'unit', 'degC')'; 
    Tmax_cell12 = mphglobal(model, 'Tmax_cell12', 'unit', 'degC')'; 
    Tmax_cell22 = mphglobal(model, 'Tmax_cell22', 'unit', 'degC')'; 
    Tmax_cell32 = mphglobal(model, 'Tmax_cell32', 'unit', 'degC')'; 
    Tmax_cell42 = mphglobal(model, 'Tmax_cell42', 'unit', 'degC')'; 
    
    %% 행렬로 묶기: 8(셀)×N(시간)
    Tavg_all = [Tavg_cell11;
                Tavg_cell21;
                Tavg_cell31;
                Tavg_cell41;
                Tavg_cell12;
                Tavg_cell22;
                Tavg_cell32;
                Tavg_cell42];
    
    Tmax_all = [Tmax_cell11;
                Tmax_cell21;
                Tmax_cell31;
                Tmax_cell41;
                Tmax_cell12;
                Tmax_cell22;
                Tmax_cell32;
                Tmax_cell42];
    
    % 첫 반복에만 all_time 정의 (모든 해석에서 시간 스텝이 같다고 가정)
    if isempty(all_time)
        all_time = timeVec;
    end
    all_Tavg{idx} = Tavg_all;
    all_Tmax{idx} = Tmax_all;
    
    %% 중간 데이터 저장 (MAT 파일)
    data_filename = sprintf('cell_temp_difference_Tinit_%d.mat', T_initial);
    data_fullpath = fullfile(data_save_path, data_filename);
    save(data_fullpath, 'timeVec', 'Tavg_all', 'Tmax_all');
    
    %% 최대·최소 업데이트
    max_Tmax(idx) = max(Tmax_all(:));
    min_Tmax(idx) = min(Tmax_all(:));
    max_Tavg(idx) = max(Tavg_all(:));
    min_Tavg(idx) = min(Tavg_all(:));
    
    %% Tmax 영역 음영 (Shade)
    Tmax_max_curve = max(Tmax_all, [], 1);  % 각 시간에서의 최대 (1×N)
    Tmax_min_curve = min(Tmax_all, [], 1);  % 각 시간에서의 최소 (1×N)
    
    % 유효한 인덱스만 사용하여 음영 채우기
    valid_idx = ~isnan(Tmax_max_curve) & ~isnan(Tmax_min_curve);
    fill([timeVec(valid_idx), fliplr(timeVec(valid_idx))], ...
         [Tmax_max_curve(valid_idx), fliplr(Tmax_min_curve(valid_idx))], ...
         colors_Tmax(idx, :), ...
         'FaceAlpha', 0.3, 'EdgeColor', 'none');  % FaceAlpha 증가
    
    %% Tmax 선 플롯 (각 셀별)
    for iCell = 1:size(Tmax_all, 1)
        plot(timeVec, Tmax_all(iCell, :), ...
             'Color', colors_Tmax(idx, :), 'LineWidth', lw);
    end
    
    %% Tavg 영역 음영 (Shade)
    Tavg_max_curve = max(Tavg_all, [], 1);  % 각 시간에서의 최대
    Tavg_min_curve = min(Tavg_all, [], 1);  % 각 시간에서의 최소
    
    % 유효한 인덱스만 사용하여 음영 채우기
    valid_idx = ~isnan(Tavg_max_curve) & ~isnan(Tavg_min_curve);
    fill([timeVec(valid_idx), fliplr(timeVec(valid_idx))], ...
         [Tavg_max_curve(valid_idx), fliplr(Tavg_min_curve(valid_idx))], ...
         colors_Tavg(idx, :), ...
         'FaceAlpha', 0.3, 'EdgeColor', 'none');  % FaceAlpha 증가
    
    %% Tavg 선 플롯 (각 셀별)
    for iCell = 1:size(Tavg_all, 1)
        plot(timeVec, Tavg_all(iCell, :), ...
             'Color', colors_Tavg(idx, :), 'LineWidth', lw);
    end
end

%% 범례를 위한 handle 생성 (빈 플롯 활용)
legend_handles = [];
legend_labels = {};
for idx = 1:length(T_initial_values)
    hTmax = plot(nan, nan, 'Color', colors_Tmax(idx, :), 'LineWidth', lw);
    legend_handles = [legend_handles, hTmax];
    legend_labels = [legend_labels, sprintf('T_{max} (%d°C)', T_initial_values(idx))];

    hTavg = plot(nan, nan, 'Color', colors_Tavg(idx, :), 'LineWidth', lw);
    legend_handles = [legend_handles, hTavg];
    legend_labels = [legend_labels, sprintf('T_{avg}, T_{init} (%d°C)', T_initial_values(idx))];
end

lgd = legend(legend_handles, legend_labels, 'Location', 'southeast', 'NumColumns', 2);
lgd.FontSize = 11;
xlabel('Time [min]', 'FontSize', 15);
ylabel('Temperature [°C]', 'FontSize', 15);

set(gca, 'YColor', 'k');
ax = gca;
ax.FontSize = 15;

box on; grid off;  % grid off에서 grid on으로 변경하여 시각적 가이드 추가

%% 그래프 저장
figure_filename = 'figure6f.png';
figure_fullpath = fullfile(figure_save_path, figure_filename);
exportgraphics(gcf, figure_fullpath, 'Resolution', 300);

%% 시간(시) 변환
time_hours = all_time / 60;

%% 각 T_initial 별 Tmax, Tavg의 최대값 출력
fprintf('\n[각 T_{init} 별 Tmax, Tavg 최대값]\n');
for idx = 1:length(T_initial_values)
    T_initial = T_initial_values(idx);
    Tmax_max_val = max(all_Tmax{idx}(:));
    Tavg_max_val = max(all_Tavg{idx}(:));
    fprintf('> T_init=%2d°C: Tmax=%.2f°C, Tavg=%.2f°C\n', ...
        T_initial, Tmax_max_val, Tavg_max_val);
end

%% 전체 Tmax 중 최대값 찾기
Tmax_overall = -Inf;
idx_max = 0;
cell_idx_max = 0;
time_idx_max = 0;

for idx = 1:length(T_initial_values)
    [local_max, lin_idx] = max(all_Tmax{idx}(:));
    if local_max > Tmax_overall
        Tmax_overall = local_max;
        idx_max = idx;
        [cell_idx_max, time_idx_max] = ind2sub(size(all_Tmax{idx}), lin_idx);
    end
end

time_max_hours = time_hours(time_idx_max);
T_initial_at_max = T_initial_values(idx_max);

fprintf('\n[전체 Tmax 중 최대값]\n');
fprintf('%.2f°C (T_init=%d°C, 셀=%d, 시간=%.3f h)\n', ...
    Tmax_overall, T_initial_at_max, cell_idx_max, time_max_hours);
