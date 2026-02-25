clear; clc; close all;

% Initiate COMSOL
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename1 = 'JYR_3segment_tubular_0102.mph';
COM_filename2 = 'JYR_3segment_cylinder_0104.mph';

C_rate = 6;
R_out = 23;

R_out_str = [num2str(R_out) '[mm]'];

% Model 1
COM_fullfile1 = fullfile(COM_filepath, COM_filename1);
model1 = mphload(COM_fullfile1);
mphnavigator(model1);
ModelUtil.showProgress(true);
model1.param.set('C_rate', C_rate);
model1.param.set('R_out', R_out_str);

model1.study('std1').run;

% 결과 저장 또는 처리
time1 = mphglobal(model1, 't', 'unit', 'min');
T_max1 = mphglobal(model1, 'comp11.T_max_overall', 'unit', 'degC');
T_avg1 = mphglobal(model1, 'comp11.T_avg_overall', 'unit', 'degC');
max_T_max1 = max(mphglobal(model1, 'comp11.T_max_overall', 'unit', 'degC'));
max_T_avg1 = max(mphglobal(model1, 'comp11.T_avg_overall', 'unit', 'degC'));

ModelUtil.remove('model1'); % 모델 1 닫기

% Model 2
COM_fullfile2 = fullfile(COM_filepath, COM_filename2);
model2 = mphload(COM_fullfile2);
mphnavigator(model2);
model2.param.set('C_rate', C_rate);
model2.param.set('R_out', R_out_str);

model2.study('std2').run;

% 결과 저장 또는 처리
time2 = mphglobal(model2, 't', 'unit', 'min');
T_max2 = mphglobal(model2, 'comp11.T_max_overall', 'unit', 'degC');
T_avg2 = mphglobal(model2, 'comp11.T_avg_overall', 'unit', 'degC');
max_T_max2 = max(mphglobal(model2, 'comp11.T_max_overall', 'unit', 'degC'));
max_T_avg2 = max(mphglobal(model2, 'comp11.T_avg_overall', 'unit', 'degC'));

ModelUtil.remove('model2'); % 모델 2 닫기

% Figure 1a 생성
figure;
lw = 1;
color1 = [0.8039, 0.3255, 0.2980]; % Red
color2 = [0.0000, 0.4500, 0.7608]; % Blue
marker_gap1 = find(mod(time1, 2) == 0);
marker_gap2 = find(mod(time2, 2) == 0);

plot(time1, T_max1, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'o', 'MarkerIndices', marker_gap1, 'DisplayName', 'tube.T_{max}');
hold on
plot(time1, T_avg1, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'o', 'MarkerIndices', marker_gap1, 'DisplayName', 'tube.T_{avg}');
plot(time2, T_max2, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'x', 'MarkerIndices', marker_gap2, 'DisplayName', 'cyl.T_{max}');
plot(time2, T_avg2, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', 'Marker', 'x', 'MarkerIndices', marker_gap2, 'DisplayName', 'cyl.T_{avg}');
hold off

xlabel('Time [min]', 'FontSize', 15);
ylabel('Temperature [^oC]', 'FontSize', 15);
set(gca, 'FontSize', 15);
lgd = legend('Location', 'southeast', 'NumColumns', 2);
lgd.FontSize = 13;
xlim([0 min(max(time1), max(time2))]);

% 저장
figure_save_dir = 'C:\Users\user\Desktop\새figure\png';
if ~exist(figure_save_dir, 'dir'), mkdir(figure_save_dir); end
figure_save_path = fullfile(figure_save_dir, 'figure1a.png');
exportgraphics(gcf, figure_save_path, 'Resolution', 600);