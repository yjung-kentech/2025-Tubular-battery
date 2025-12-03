clear; clc; close all;

% COMSOL 모델 경로 설정
COM_filepath = 'C:/Users/user/Desktop/Tubular battery 최종';
COM_filename1 = 'JYR_cell_0202.mph';
COM_filename2 = 'pack_1cell_Rmodel.mph';
COM_fullfile1 = fullfile(COM_filepath, COM_filename1);
COM_fullfile2 = fullfile(COM_filepath, COM_filename2);

% 모델1 로드
model1 = mphload(COM_fullfile1);
model1.study('std1').run;

% 모델 1 변수 가져오기
time1   = mphglobal(model1, 't', 'unit', 'min');
T_max1  = mphglobal(model1, 'T_max', 'unit', 'degC');
T_avg1  = mphglobal(model1, 'T_avg', 'unit', 'degC');
I_cell1 = mphglobal(model1, 'comp1.I_cell', 'unit', 'A');
E_cell1 = mphglobal(model1, 'comp1.E_cell', 'unit', 'V');
SOC1    = mphglobal(model1, 'SOC');

[max_val1, idx] = max(T_max1);
max_time1 = time1(idx);

% 모델2 로드
model2 = mphload(COM_fullfile2);
model2.study('std1').run;

% 모델 2 변수 가져오기
time2   = mphglobal(model2, 't', 'unit', 'min');
T_max2  = mphglobal(model2, 'T_max', 'unit', 'degC');
T_avg2  = mphglobal(model2, 'T_avg', 'unit', 'degC');
I_cell2 = mphglobal(model2, 'comp1.I_cell', 'unit', 'A');
E_cell2 = mphglobal(model2, 'comp1.E_cell', 'unit', 'V');
%% SOCbvcx
SOC2    = mphglobal(model2, 'SOC');

[max_val2, idx] = max(T_max2);
max_time2 = time2(idx);

x_max = max( max(time1), max(time2) );

% 그림 생성
figure;

%% 서브플롯 1: Temperature plot
subplot(3, 1, 1)
lw = 1; % 선 굵기
color1 = [0.8039, 0.3255, 0.2980];    % orange
color2 = [0, 0.4510, 0.7608];         % blue
marker_gap1 = find(mod(time1, 1) == 0); % time1에서 1분 간격의 인덱스
marker_gap2 = find(mod(time2, 1) == 0); % time2에서 1분 간격의 인덱스

plot(time1, T_max1, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_gap1, 'DisplayName', 'P2D.T_{max}');
hold on
plot(time2, T_max2, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_gap2, 'DisplayName', 'ECM.T_{max}');
plot(time1, T_avg1, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_gap1, 'DisplayName', 'P2D.T_{avg}');
plot(time2, T_avg2, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_gap2, 'DisplayName', 'ECM.T_{avg}');
hold off

xlabel('Time [min]', 'FontSize', 12);
xlim([0, x_max]);
ylabel('Temperature [^oC]', 'FontSize', 12);
ylim([25 46]);
legend('Location', 'southeast', 'NumColumns', 2, 'FontSize', 9, 'Orientation', 'horizontal');
grid off;

% 서브플롯 1 왼쪽 상단에 라벨 'a' 추가
text(-0.08, 1.1, 'a', 'Units', 'normalized', 'FontSize', 15, 'FontWeight', 'bold');

%% 서브플롯 2: I-V Curve
subplot(3, 1, 2)

C_rate_1C = 33.947;

lw = 1; % 선 굵기
color3 = [0.9373, 0.7529, 0];          % yellow
color4 = [0.5725, 0.3686, 0.6235];     % purple
marker_gap1 = find(mod(time1, 1) == 0);
marker_gap2 = find(mod(time2, 1) == 0);

yyaxis left;
plot(time1, E_cell1, 'Color', color3, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_gap1, 'DisplayName', 'P2D.V');
hold on
plot(time2, E_cell2, 'Color', color3, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_gap2, 'DisplayName', 'ECM.V');
ylabel('Cell Voltage [V]', 'FontSize', 12);
ylim([3.54728, 4.25]);
set(gca, 'YColor', 'k');

yyaxis right;
plot(time1, -I_cell1/C_rate_1C, 'Color', color4, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_gap1, 'DisplayName', 'P2D.I');
plot(time2, I_cell2/C_rate_1C, 'Color', color4, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_gap2, 'DisplayName', 'ECM.I');
hold off
ylabel('C-rate', 'FontSize', 12);
ylim([0 12]);
set(gca, 'YColor', 'k');

xlabel('Time [min]', 'FontSize', 12);
xlim([0, x_max]);
legend('Location', 'southeast', 'NumColumns', 2, 'FontSize', 9, 'Orientation', 'horizontal');
grid off;

% 서브플롯 2 왼쪽 상단에 라벨 'b' 추가
text(-0.08, 1.1, 'b', 'Units', 'normalized', 'FontSize', 15, 'FontWeight', 'bold');

%% 서브플롯 3: SOC curve
subplot(3, 1, 3)
lw = 1; % 선 굵기
color5 = [0.1255, 0.5216, 0.3059]; % Green
% color6 = [0.302, 0.733, 0.835];    % Light blue

marker_gap1 = find(mod(time1, 1) == 0);
marker_gap2 = find(mod(time2, 1) == 0);

plot(time1, SOC1, 'Color', color5, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_gap1, 'DisplayName', 'P2D.SOC');
hold on
plot(time2, SOC2, 'Color', color5, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_gap2, 'DisplayName', 'ECM.SOC');
hold off

xlabel('Time [min]', 'FontSize', 12);
xlim([0, x_max]);
ylabel('SOC', 'FontSize', 12);
ylim([0 1]);
legend('Location', 'southeast', 'FontSize', 9);
grid off;

% 서브플롯 3 왼쪽 상단에 라벨 'c' 추가
text(-0.08, 1.1, 'c', 'Units', 'normalized', 'FontSize', 15, 'FontWeight', 'bold');

% 그림 크기 설정
set(gcf, 'Position', [100, 100, 600, 800]);

% Save the figure
figure_save_dir = 'C:\Users\user\Desktop\Figure\Supple Figure\png 파일';
figure_save_path = fullfile(figure_save_dir, 'S5_new2.png');
exportgraphics(gcf, figure_save_path, 'Resolution', 300);
