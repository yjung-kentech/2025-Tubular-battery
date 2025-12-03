clear; clc; close all;

% 데이터 경로 설정
data_dir = 'C:\Users\user\Desktop\Figure\Sweep\mat 파일';
tubular_file = fullfile(data_dir, 'Tubular_Sweep_Crate_Rout.mat');
cylinder_file = fullfile(data_dir, 'Cylinder_Sweep_Crate_Rout.mat');

% 데이터 로드
load(tubular_file);
tube_data = data;

load(cylinder_file);
cyl_data = data;

% D_out과 C_rate 추출
D_out_vec_tube = 2 * tube_data.R_out;
C_rate_vec_tube = tube_data.C_rate;

D_out_vec_cyl = 2 * cyl_data.R_out;
C_rate_vec_cyl = cyl_data.C_rate;

% 4C와 6C 인덱스 찾기
idx_4C_tube = find(C_rate_vec_tube == 4);
idx_6C_tube = find(C_rate_vec_tube == 6);

idx_4C_cyl = find(C_rate_vec_cyl == 4);
idx_6C_cyl = find(C_rate_vec_cyl == 6);

% 4C 및 6C의 T_max와 T_avg 추출
T_max_4C_tube = tube_data.T_max(idx_4C_tube, :);
T_avg_4C_tube = tube_data.T_avg(idx_4C_tube, :);
T_max_6C_tube = tube_data.T_max(idx_6C_tube, :);
T_avg_6C_tube = tube_data.T_avg(idx_6C_tube, :);

T_max_4C_cyl = cyl_data.T_max(idx_4C_cyl, :);
T_avg_4C_cyl = cyl_data.T_avg(idx_4C_cyl, :);
T_max_6C_cyl = cyl_data.T_max(idx_6C_cyl, :);
T_avg_6C_cyl = cyl_data.T_avg(idx_6C_cyl, :);

% 원하는 마커 간격 정의 (예: 5mm)
desired_marker_interval = 5; % mm

% 보간을 위한 등간격 D_out 벡터 생성 (예: 1mm 간격)
interp_interval = 1; % mm
D_out_interp_tube = min(D_out_vec_tube):interp_interval:max(D_out_vec_tube);
D_out_interp_cyl = min(D_out_vec_cyl):interp_interval:max(D_out_vec_cyl);

% 4C 데이터 보간
T_max_4C_tube_interp = interp1(D_out_vec_tube, T_max_4C_tube, D_out_interp_tube, 'linear');
T_avg_4C_tube_interp = interp1(D_out_vec_tube, T_avg_4C_tube, D_out_interp_tube, 'linear');

T_max_4C_cyl_interp = interp1(D_out_vec_cyl, T_max_4C_cyl, D_out_interp_cyl, 'linear');
T_avg_4C_cyl_interp = interp1(D_out_vec_cyl, T_avg_4C_cyl, D_out_interp_cyl, 'linear');

% 6C 데이터 보간
T_max_6C_tube_interp = interp1(D_out_vec_tube, T_max_6C_tube, D_out_interp_tube, 'linear');
T_avg_6C_tube_interp = interp1(D_out_vec_tube, T_avg_6C_tube, D_out_interp_tube, 'linear');

T_max_6C_cyl_interp = interp1(D_out_vec_cyl, T_max_6C_cyl, D_out_interp_cyl, 'linear');
T_avg_6C_cyl_interp = interp1(D_out_vec_cyl, T_avg_6C_cyl, D_out_interp_cyl, 'linear');

% 보간된 데이터로 마커 인덱스 계산
marker_douts_tube = min(D_out_interp_tube):desired_marker_interval:max(D_out_interp_tube);
marker_indices_tube = arrayfun(@(x) find(abs(D_out_interp_tube - x) == min(abs(D_out_interp_tube - x)), 1), marker_douts_tube);

marker_douts_cyl = min(D_out_interp_cyl):desired_marker_interval:max(D_out_interp_cyl);
marker_indices_cyl = arrayfun(@(x) find(abs(D_out_interp_cyl - x) == min(abs(D_out_interp_cyl - x)), 1), marker_douts_cyl);

% 중복 인덱스 제거 및 정렬
marker_indices_tube = unique(marker_indices_tube);
marker_indices_cyl = unique(marker_indices_cyl);

% 플롯 설정
figure;

% 4C 플롯
subplot(2, 1, 1)
lw = 1; % 선 너비
color1 = [0.8039, 0.3255, 0.2980]; % red
color2 = [0.0000, 0.4500, 0.7608]; % 파랑

% 튜브 T_max 보간 데이터 플롯
plot(D_out_interp_tube, T_max_4C_tube_interp, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_indices_tube, 'DisplayName', 'tube.T_{max}')
hold on
% 튜브 T_avg 보간 데이터 플롯
plot(D_out_interp_tube, T_avg_4C_tube_interp, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_indices_tube, 'DisplayName', 'tube.T_{avg}')
% 실린더 T_max 보간 데이터 플롯
plot(D_out_interp_cyl, T_max_4C_cyl_interp, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_indices_cyl, 'DisplayName', 'cyl.T_{max}')
% 실린더 T_avg 보간 데이터 플롯
plot(D_out_interp_cyl, T_avg_4C_cyl_interp, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_indices_cyl, 'DisplayName', 'cyl.T_{avg}')
hold off

xlabel('D_{out} [mm]', 'FontSize', 12);
ylabel('Temperature [^oC]', 'FontSize', 12);
ylim([20 100]);
% title('4C', 'FontSize', 11);
lgd1 = legend('Location', 'northwest', 'NumColumns', 2);
lgd1.FontSize = 10;
grid off;

% 라벨 a 추가
text(min(D_out_interp_tube)-10, max(T_max_4C_tube_interp)+20, 'a', ...
     'FontSize', 15, 'FontWeight', 'bold', 'Clipping', 'off')

% 6C 플롯
subplot(2, 1, 2)
% 튜브 T_max 보간 데이터 플롯
plot(D_out_interp_tube, T_max_6C_tube_interp, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_indices_tube, 'DisplayName', 'tube.T_{max}')
hold on
% 튜브 T_avg 보간 데이터 플롯
plot(D_out_interp_tube, T_avg_6C_tube_interp, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'o', 'MarkerIndices', marker_indices_tube, 'DisplayName', 'tube.T_{avg}')
% 실린더 T_max 보간 데이터 플롯
plot(D_out_interp_cyl, T_max_6C_cyl_interp, 'Color', color1, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_indices_cyl, 'DisplayName', 'cyl.T_{max}')
% 실린더 T_avg 보간 데이터 플롯
plot(D_out_interp_cyl, T_avg_6C_cyl_interp, 'Color', color2, 'LineWidth', lw, 'LineStyle', '-', ...
    'Marker', 'x', 'MarkerIndices', marker_indices_cyl, 'DisplayName', 'cyl.T_{avg}')
hold off

xlabel('D_{out} [mm]', 'FontSize', 12);
ylabel('Temperature [^oC]', 'FontSize', 12);
ylim([20 100]);
% title('6C', 'FontSize', 11);
lgd2 = legend('Location', 'northwest', 'NumColumns', 2);
lgd2.FontSize = 10;
grid off;

% 라벨 b 추가
text(min(D_out_interp_tube)-10, max(T_max_4C_tube_interp)+20, 'b', ...
     'FontSize', 15, 'FontWeight', 'bold', 'Clipping', 'off')

% 그림 크기 설정
set(gcf, 'Position', [100, 100, 600, 700]);

% 그림 저장
figure_save_dir = 'C:\Users\user\Desktop\Figure\Figure 2';
if ~exist(figure_save_dir, 'dir'), mkdir(figure_save_dir); end
figure_save_path = fullfile(figure_save_dir, 'figure2.png');
exportgraphics(gcf, figure_save_path, 'Resolution',300);


%% 4C, 6C에서 특정 D_out 지점 온도 출력 (46mm, 70mm, 60mm)

% 타겟 D_out 정의
target_douts = [46, 70, 60];

% 각 타겟에 대해 튜블러 및 실린더 셀의 Tmax, Tavg 추출
for i = 1:length(target_douts)
    D_target = target_douts(i);

    % 4C 조건일 때만 70mm 포함
    if D_target == 70
        fprintf('\n[4C] D_out = %d mm:\n', D_target);
        idx_tube = find(abs(D_out_interp_tube - D_target) == min(abs(D_out_interp_tube - D_target)), 1);
        idx_cyl  = find(abs(D_out_interp_cyl - D_target) == min(abs(D_out_interp_cyl - D_target)), 1);

        fprintf('Tubular Cell: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_tube_interp(idx_tube), T_avg_4C_tube_interp(idx_tube));
        fprintf('Cylindrical Cell: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_cyl_interp(idx_cyl), T_avg_4C_cyl_interp(idx_cyl));
    else
        % 4C 조건
        fprintf('\n[4C] D_out = %d mm:\n', D_target);
        idx_tube_4C = find(abs(D_out_interp_tube - D_target) == min(abs(D_out_interp_tube - D_target)), 1);
        idx_cyl_4C  = find(abs(D_out_interp_cyl - D_target) == min(abs(D_out_interp_cyl - D_target)), 1);
        fprintf('Tubular Cell: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_tube_interp(idx_tube_4C), T_avg_4C_tube_interp(idx_tube_4C));
        fprintf('Cylindrical Cell: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_cyl_interp(idx_cyl_4C), T_avg_4C_cyl_interp(idx_cyl_4C));

        % 6C 조건
        fprintf('[6C] D_out = %d mm:\n', D_target);
        idx_tube_6C = find(abs(D_out_interp_tube - D_target) == min(abs(D_out_interp_tube - D_target)), 1);
        idx_cyl_6C  = find(abs(D_out_interp_cyl - D_target) == min(abs(D_out_interp_cyl - D_target)), 1);
        fprintf('Tubular Cell: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_6C_tube_interp(idx_tube_6C), T_avg_6C_tube_interp(idx_tube_6C));
        fprintf('Cylindrical Cell: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_6C_cyl_interp(idx_cyl_6C), T_avg_6C_cyl_interp(idx_cyl_6C));
    end
end



% %% D_out 10mm, 80mm에서의 온도
% 
% % 찾고자 하는 D_out 값 설정
% D_out_target = [10, 80]; % mm
% 
% % 튜블러 셀에서 D_out이 10과 80일 때의 인덱스 찾기 (4C)
% idx_tube_10_4C = find(abs(D_out_interp_tube - D_out_target(1)) == min(abs(D_out_interp_tube - D_out_target(1))), 1);
% idx_tube_80_4C = find(abs(D_out_interp_tube - D_out_target(2)) == min(abs(D_out_interp_tube - D_out_target(2))), 1);
% 
% % 튜블러 셀에서 D_out이 10과 80일 때의 인덱스 찾기 (6C)
% idx_tube_10_6C = find(abs(D_out_interp_tube - D_out_target(1)) == min(abs(D_out_interp_tube - D_out_target(1))), 1);
% idx_tube_80_6C = find(abs(D_out_interp_tube - D_out_target(2)) == min(abs(D_out_interp_tube - D_out_target(2))), 1);
% 
% % 실린더 셀에서 D_out이 10과 80일 때의 인덱스 찾기 (4C)
% idx_cyl_10_4C = find(abs(D_out_interp_cyl - D_out_target(1)) == min(abs(D_out_interp_cyl - D_out_target(1))), 1);
% idx_cyl_80_4C = find(abs(D_out_interp_cyl - D_out_target(2)) == min(abs(D_out_interp_cyl - D_out_target(2))), 1);
% 
% % 실린더 셀에서 D_out이 10과 80일 때의 인덱스 찾기 (6C)
% idx_cyl_10_6C = find(abs(D_out_interp_cyl - D_out_target(1)) == min(abs(D_out_interp_cyl - D_out_target(1))), 1);
% idx_cyl_80_6C = find(abs(D_out_interp_cyl - D_out_target(2)) == min(abs(D_out_interp_cyl - D_out_target(2))), 1);
% 
% % 각 셀의 Tmax와 Tavg 값을 출력
% fprintf('4C Condition:\n');
% fprintf('Tubular Cell:\n');
% fprintf('D_out = 10 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_tube_interp(idx_tube_10_4C), T_avg_4C_tube_interp(idx_tube_10_4C));
% fprintf('D_out = 80 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_tube_interp(idx_tube_80_4C), T_avg_4C_tube_interp(idx_tube_80_4C));
% 
% fprintf('Cylindrical Cell:\n');
% fprintf('D_out = 10 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_cyl_interp(idx_cyl_10_4C), T_avg_4C_cyl_interp(idx_cyl_10_4C));
% fprintf('D_out = 80 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_4C_cyl_interp(idx_cyl_80_4C), T_avg_4C_cyl_interp(idx_cyl_80_4C));
% 
% fprintf('\n6C Condition:\n');
% fprintf('Tubular Cell:\n');
% fprintf('D_out = 10 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_6C_tube_interp(idx_tube_10_6C), T_avg_6C_tube_interp(idx_tube_10_6C));
% fprintf('D_out = 80 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_6C_tube_interp(idx_tube_80_6C), T_avg_6C_tube_interp(idx_tube_80_6C));
% 
% fprintf('Cylindrical Cell:\n');
% fprintf('D_out = 10 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_6C_cyl_interp(idx_cyl_10_6C), T_avg_6C_cyl_interp(idx_cyl_10_6C));
% fprintf('D_out = 80 mm: T_max = %.2f °C, T_avg = %.2f °C\n', T_max_6C_cyl_interp(idx_cyl_80_6C), T_avg_6C_cyl_interp(idx_cyl_80_6C));

% %% 100°C에 도달하는 D_out 찾기 (더 정밀한 보간 사용)
% 
% % 보간 간격을 0.1mm로 증가
% interp_interval_fine = 0.1; % mm
% 
% % 더 촘촘한 D_out 벡터 생성 (0.1mm 간격)
% D_out_interp_fine_tube = min(D_out_vec_tube):interp_interval_fine:max(D_out_vec_tube);
% D_out_interp_fine_cyl = min(D_out_vec_cyl):interp_interval_fine:max(D_out_vec_cyl);
% 
% % 4C 데이터에 대해 0.1mm 간격으로 보간
% T_max_4C_tube_fine = interp1(D_out_interp_tube, T_max_4C_tube_interp, D_out_interp_fine_tube, 'linear');
% T_max_4C_cyl_fine = interp1(D_out_interp_cyl, T_max_4C_cyl_interp, D_out_interp_fine_cyl, 'linear');
% 
% % 6C 데이터에 대해 0.1mm 간격으로 보간
% T_max_6C_tube_fine = interp1(D_out_interp_tube, T_max_6C_tube_interp, D_out_interp_fine_tube, 'linear');
% T_max_6C_cyl_fine = interp1(D_out_interp_cyl, T_max_6C_cyl_interp, D_out_interp_fine_cyl, 'linear');
% 
% % 4C 조건에서 100°C가 되는 D_out 찾기 (정밀 버전)
% idx_tube_100_4C = find(abs(T_max_4C_tube_fine - 100) == min(abs(T_max_4C_tube_fine - 100)), 1);
% idx_cyl_100_4C = find(abs(T_max_4C_cyl_fine - 100) == min(abs(T_max_4C_cyl_fine - 100)), 1);
% 
% % 6C 조건에서 100°C가 되는 D_out 찾기 (정밀 버전)
% idx_tube_100_6C = find(abs(T_max_6C_tube_fine - 100) == min(abs(T_max_6C_tube_fine - 100)), 1);
% idx_cyl_100_6C = find(abs(T_max_6C_cyl_fine - 100) == min(abs(T_max_6C_cyl_fine - 100)), 1);
% 
% % 결과 출력 (소수점까지 정밀하게)
% fprintf('\nD_out 값 (T_max ≈ 100°C, 0.1mm 정밀도 적용)\n');
% 
% fprintf('4C Condition:\n');
% fprintf('Tubular Cell: D_out = %.1f mm (T_max = %.2f °C)\n', D_out_interp_fine_tube(idx_tube_100_4C), T_max_4C_tube_fine(idx_tube_100_4C));
% fprintf('Cylindrical Cell: D_out = %.1f mm (T_max = %.2f °C)\n', D_out_interp_fine_cyl(idx_cyl_100_4C), T_max_4C_cyl_fine(idx_cyl_100_4C));
% 
% fprintf('\n6C Condition:\n');
% fprintf('Tubular Cell: D_out = %.1f mm (T_max = %.2f °C)\n', D_out_interp_fine_tube(idx_tube_100_6C), T_max_6C_tube_fine(idx_tube_100_6C));
% fprintf('Cylindrical Cell: D_out = %.1f mm (T_max = %.2f °C)\n', D_out_interp_fine_cyl(idx_cyl_100_6C), T_max_6C_cyl_fine(idx_cyl_100_6C));
% 
% %% 45°C에 도달하는 D_out 찾기 (0.1mm 간격 보간 사용)
% 
% % 4C 조건에서 45°C가 되는 D_out 찾기 (정밀 버전)
% idx_tube_45_4C = find(abs(T_max_4C_tube_fine - 45) == min(abs(T_max_4C_tube_fine - 45)), 1);
% idx_cyl_45_4C = find(abs(T_max_4C_cyl_fine - 45) == min(abs(T_max_4C_cyl_fine - 45)), 1);
% 
% % 6C 조건에서 45°C가 되는 D_out 찾기 (정밀 버전)
% idx_tube_45_6C = find(abs(T_max_6C_tube_fine - 45) == min(abs(T_max_6C_tube_fine - 45)), 1);
% idx_cyl_45_6C = find(abs(T_max_6C_cyl_fine - 45) == min(abs(T_max_6C_cyl_fine - 45)), 1);
% 
% % 결과 출력 (소수점까지 정밀하게)
% fprintf('\nD_out 값 (T_max ≈ 45°C, 0.1mm 정밀도 적용)\n');
% 
% fprintf('4C Condition:\n');
% fprintf('Tubular Cell: D_out = %.1f mm (T_max = %.2f °C)\n', D_out_interp_fine_tube(idx_tube_45_4C), T_max_4C_tube_fine(idx_tube_45_4C));
% fprintf('Cylindrical Cell: D_out = %.1f mm (T_max = %.2f °C)\n', D_out_interp_fine_cyl(idx_cyl_45_4C), T_max_4C_cyl_fine(idx_cyl_45_4C));
% 
% fprintf('\n6C Condition:\n');
% fprintf('Tubular Cell: D_out = %.1f mm (T_max = %.2f °C)\n', D_out_interp_fine_tube(idx_tube_45_6C), T_max_6C_tube_fine(idx_tube_45_6C));
% fprintf('Cylindrical Cell: D_out = %.1f mm (T_max = %.2f °C)\n', D_out_interp_fine_cyl(idx_cyl_45_6C), T_max_6C_cyl_fine(idx_cyl_45_6C));

