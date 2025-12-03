clear; clc; close all;
%% ========================================================================
%  [SECTION 1] 마스터 데이터 로드
% =========================================================================
mat_filepath = 'C:\Users\user\Desktop\Figure\Cost Model\mat 파일\Cost_Master.mat';
try
    load(mat_filepath, 'MasterData'); % MasterData 구조체만 로드
    disp(['데이터 파일 로드 완료: ' mat_filepath]);
    
    % MasterData 구조체에서 figure4c에 필요한 모든 데이터를 추출합니다.
    T_chg_tub  = MasterData.fig_c.t_chg_tub;
    c_cell_tub = MasterData.fig_c.c_cell_tub;
    rho_E_tub  = MasterData.fig_c.rho_E_tub;
    T_chg_cyl  = MasterData.fig_c.t_chg_cyl;
    c_cell_cyl = MasterData.fig_c.c_cell_cyl;
    rho_E_cyl  = MasterData.fig_c.rho_E_cyl;
    
    assert(exist('rho_E_tub','var'), '필수 변수가 MasterData.fig_c에 없습니다.');
catch ME
    error('.mat 파일을 로드하거나 데이터를 추출하는 중 오류 발생: %s', ME.message);
end
%% ========================================================================
%  [SECTION 2] 데이터 필터링 및 x축 범위 계산
% =========================================================================
% 특정 값 범위를 벗어나는 데이터를 플롯에 표시하지 않도록 처리합니다.
tube_c_cell_filtered = c_cell_tub;
tube_c_cell_filtered(tube_c_cell_filtered >= 76.2968) = NaN;
tube_rhoE_filtered = rho_E_tub;
tube_rhoE_filtered(tube_rhoE_filtered <= 756) = NaN;
cyl_c_cell_filtered = c_cell_cyl;
cyl_c_cell_filtered(cyl_c_cell_filtered >= 79.5325) = NaN;
cyl_rhoE_filtered = rho_E_cyl;
cyl_rhoE_filtered(cyl_rhoE_filtered <= 763) = NaN;

% x축 최소값 계산
x_min = min([T_chg_tub, T_chg_cyl],[],'omitnan');

%% ========================================================================
%  [SECTION 3] 최종 플롯 (marker_times 적용)
% =========================================================================
figure('Position',[100 100 600 420]);
lw = 1;
color1 = [0, 0.4510, 0.7608];       % 파란색 (Tubular)
color2 = [0.8039, 0.3255, 0.2980];   % 빨간색 (Cylindrical)

% --- [추가된 부분] 마커를 표시할 x축 시간 정의 ---
marker_times = ceil(x_min):1:20;

% --- 왼쪽 Y축: c_cell ---
yyaxis left
hold on;

% 선 그리기
plot(T_chg_tub, tube_c_cell_filtered, '-', 'LineWidth', lw, 'Color', color1);
plot(T_chg_cyl, cyl_c_cell_filtered, '-', 'LineWidth', lw, 'Color', color2);

% --- [추가된 부분] 보간을 통해 일정한 간격으로 마커 그리기 ---
tube_y_markers = interp1(T_chg_tub, tube_c_cell_filtered, marker_times, 'linear');
plot(marker_times, tube_y_markers, 's', 'Color', color1, 'LineWidth', lw);
cyl_y_markers = interp1(T_chg_cyl, cyl_c_cell_filtered, marker_times, 'linear');
plot(marker_times, cyl_y_markers, 's', 'Color', color2, 'LineWidth', lw);

ylabel('c_{cell} [$/kWh]', 'FontSize', 16);
ylim([65 85]);
set(gca, 'YColor','k', 'FontSize', 16);

% --- 오른쪽 Y축: rho_E ---
yyaxis right
hold on;

% 선 그리기
plot(T_chg_tub, tube_rhoE_filtered, '-', 'LineWidth', lw, 'Color', color1);
plot(T_chg_cyl, cyl_rhoE_filtered, '-', 'LineWidth', lw, 'Color', color2);

% --- [추가된 부분] 보간을 통해 일정한 간격으로 마커 그리기 ---
tube_rho_markers = interp1(T_chg_tub, tube_rhoE_filtered, marker_times, 'linear');
plot(marker_times, tube_rho_markers, '^', 'Color', color1, 'LineWidth', lw);
cyl_rho_markers = interp1(T_chg_cyl, cyl_rhoE_filtered, marker_times, 'linear');
plot(marker_times, cyl_rho_markers, '^', 'Color', color2, 'LineWidth', lw);

ylabel('\rho_{E} [kWh/m^3]', 'FontSize', 16);
ylim([750 775]);

% --- 마커 및 범례(Legend)를 위한 더미(dummy) 플롯 ---
yyaxis left
h_dummy1 = plot(nan, nan, '-s', 'LineWidth', lw, 'Color', color1);
h_dummy2 = plot(nan, nan, '-s', 'LineWidth', lw, 'Color', color2);
yyaxis right
h_dummy3 = plot(nan, nan, '-^', 'LineWidth', lw, 'Color', color1);
h_dummy4 = plot(nan, nan, '-^', 'LineWidth', lw, 'Color', color2);
hold off;

% --- 공통 스타일링 ---
set(gca, 'YColor','k', 'FontSize', 16);
grid off;
box on;
xlabel('Charging time [min]', 'FontSize', 17);
xlim([x_min, 20]);
legend([h_dummy1, h_dummy2, h_dummy3, h_dummy4], ...
    {'tube.c_{cell}', 'cyl.c_{cell}', 'tube.\rho_{E}', 'cyl.\rho_{E}'}, ...
    'Fontsize', 13, 'Location','southeast','NumColumns',2);
disp('그래프 생성이 완료되었습니다.');


% --- 그림 파일로 저장 ---
figure_save_dir = 'C:\Users\user\Desktop\Figure\Figure 4\png 파일';
if ~exist(figure_save_dir, 'dir'), mkdir(figure_save_dir); end
figure_save_path = fullfile(figure_save_dir, 'Figure4c_from_Master.png');
exportgraphics(gcf, figure_save_path, 'Resolution', 300);
disp(['그림 파일 저장 완료: ' figure_save_path]);