clear; clc; close all;

%% ========================================================================
%  [SECTION 1] 마스터 데이터 로드
% =========================================================================
mat_filepath = 'C:\Users\user\Desktop\Figure\Cost Model\mat 파일\Cost_Master.mat';
try
    load(mat_filepath, 'MasterData'); % MasterData 구조체만 로드
    disp(['마스터 데이터 파일 로드 완료: ' mat_filepath]);
    
    % MasterData 구조체에서 figure4b에 필요한 데이터 추출
    D_out_vec  = MasterData.fig_b.D_out_vec;
    c_cell_tub = MasterData.fig_b.c_cell_tub;
    c_cell_cyl = MasterData.fig_b.c_cell_cyl;
    
    assert(exist('c_cell_tub','var'), '필수 변수가 MasterData.fig_b에 없습니다.');
catch ME
    error('.mat 파일을 로드하거나 데이터를 추출하는 중 오류 발생: %s', ME.message);
end

%% ========================================================================
%  [SECTION 2] 데이터 보간 (더 부드러운 곡선을 위해)
% =========================================================================
% 그래프의 x축으로 사용할 더 조밀한 D_out 벡터 생성
D_out_new_vec = (min(D_out_vec):0.5:max(D_out_vec));

% Spline 보간법을 사용하여 부드러운 y값 데이터 생성
c_cell_tub_interp = interp1(D_out_vec, c_cell_tub, D_out_new_vec, 'spline');
c_cell_cyl_interp = interp1(D_out_vec, c_cell_cyl, D_out_new_vec, 'spline');

%% ========================================================================
%  [SECTION 3] 그래프 그리기
% =========================================================================
% --- 스타일링 변수 정의 ---
lw = 1; % 라인 두께
color_cyl = [0.8039, 0.3255, 0.2980]; % 빨간색 (Cylindrical)
color_tub = [0, 0.4510, 0.7608];     % 파란색 (Tubular)

% --- D_out이 5의 배수인 지점에만 마커를 찍기 위한 인덱스 계산 ---
marker_indices = find(mod(D_out_new_vec, 5) == 0);

% --- Figure 생성 ---
figure;
hold on;

% Tubular 데이터 플롯
plot(D_out_new_vec, c_cell_tub_interp, 'Color', color_tub, 'LineWidth', lw, ...
    'LineStyle', '-', 'Marker', 's', 'MarkerIndices', marker_indices, ...
    'MarkerSize', 8, 'DisplayName', 'tube.c_{cell}');

% Cylindrical 데이터 플롯
plot(D_out_new_vec, c_cell_cyl_interp, 'Color', color_cyl, 'LineWidth', lw, ...
    'LineStyle', '-', 'Marker', 's', 'MarkerIndices', marker_indices, ...
    'MarkerSize', 8, 'DisplayName', 'cyl.c_{cell}');
hold off;

%% ========================================================================
%  [SECTION 4] 그래프 스타일링, 저장 및 분석
% =========================================================================
% --- 그래프 스타일링 ---
ylabel('c_{cell} [$/kWh]', 'FontSize', 15);
xlabel('D_{out} [mm]', 'FontSize', 15);
ylim([40 160]);
xlim([0 80]);
legend('Location', 'southeast', 'NumColumns', 2, 'FontSize', 13);
grid off;
box on;

fig = gcf;
set(fig, 'Position', [100, 100, 560, 420]);
ax = gca;
ax.FontSize = 15;
disp('그래프 생성이 완료되었습니다.');

% --- 그림 파일로 저장 ---
figure_save_dir = 'C:\Users\user\Desktop\Figure\Figure 4\png 파일';
if ~exist(figure_save_dir, 'dir'), mkdir(figure_save_dir); end
figure_save_path = fullfile(figure_save_dir, 'Figure4b_from_Master.png');
exportgraphics(gcf, figure_save_path, 'Resolution', 300);
disp(['그림 파일 저장 완료: ' figure_save_path]);

% --- 교차점 분석 ---
c_tube_rounded = round(c_cell_tub_interp, 1);
c_cyl_rounded  = round(c_cell_cyl_interp, 1);
equal_indices = find(c_tube_rounded == c_cyl_rounded);

if ~isempty(equal_indices)
    D_out_eq = D_out_new_vec(equal_indices(1));
    c_cell_eq = c_tube_rounded(equal_indices(1));
    fprintf('\n[분석] 소수점 첫째자리까지 c_cell 값이 같아지는 지점:\n');
    fprintf('  D_out = %.2f mm, c_cell = %.1f $/kWh\n', D_out_eq, c_cell_eq);
else
    fprintf('\n[분석] 소수점 첫째자리까지 동일한 c_cell 값을 찾지 못했습니다.\n');
end