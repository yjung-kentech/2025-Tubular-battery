clear; clc; close all;

%% ========================================================================
%  [SECTION 1] 마스터 데이터 로드
% =========================================================================
mat_filepath = 'C:\Users\user\Desktop\Figure\Cost Model\mat 파일\Cost_Master.mat';
try
    load(mat_filepath, 'MasterData'); % MasterData 구조체만 로드
    disp(['마스터 데이터 파일 로드 완료: ' mat_filepath]);
catch ME
    error('.mat 파일을 로드하는 중 오류 발생: %s', ME.message);
end

%% ========================================================================
%  [SECTION 2] 데이터 준비 및 플롯 생성
% =========================================================================
% --- 스타일링 변수 정의 ---
D_out_values_mm = [46, 60, 80]; % 플롯할 D_out 값
D_in_vec = MasterData.fig_e.D_in_vec; % D_in 벡터 로드
colors = {
    [0.9373, 0.7529, 0],      % Yellow - 46 mm
    [0.5725, 0.3686, 0.6235], % Purple - 60 mm
    [0.1255, 0.5216, 0.3059]  % Green - 80 mm
};

% --- Figure 생성 ---
figure;
hold on;

% --- 각 D_out 값에 대해 루프를 돌며 플롯 ---
for j = 1:length(D_out_values_mm)
    d_val = D_out_values_mm(j);
    color = colors{j};
    
    % --- Tubular 데이터 (선 그래프) ---
    % D_in >= 4 조건에 맞는 데이터 추출
    tubular_indices = find(D_in_vec >= 4);
    D_in_tubular = D_in_vec(tubular_indices);
    c_cell_tub_line = MasterData.fig_e.(['c_cell_tub_' num2str(d_val) 'mm'])(tubular_indices);
    
    % 2칸 간격으로 마커를 찍기 위한 인덱스
    marker_indices = 1:2:length(D_in_tubular);
    
    plot(D_in_tubular, c_cell_tub_line, 's-', 'Color', color, ...
        'LineWidth', 1, 'MarkerIndices', marker_indices, ...
        'DisplayName', sprintf('c_{cell} %dmm', d_val));
        
    % --- Cylindrical 데이터 (D_in = 0 지점의 단일 마커) ---
    % fig_b에 저장된, 조건에 맞는 cylindrical 데이터를 가져옴
    [~, idx_b] = min(abs(MasterData.fig_b.D_out_vec - d_val));
    c_cell_cyl_point = MasterData.fig_b.c_cell_cyl(idx_b);
    
    plot(0, c_cell_cyl_point, 's', 'Color', color, 'MarkerFaceColor', color, 'HandleVisibility','off');
end

%% ========================================================================
%  [SECTION 3] 그래프 스타일링 및 저장
% =========================================================================
hold off;
xlabel('D_{in} [mm]', 'FontSize', 15);
xlim([0 20]);
ylabel('c_{cell} [$/kWh]', 'FontSize', 15);
ylim([70 85]);
legend('Location', 'northwest', 'FontSize', 13);
box on;

fig = gcf;
set(fig, 'Position', [100, 100, 560, 420]);
ax = gca;
ax.FontSize = 15;
ax.YColor = 'k';
disp('그래프 생성이 완료되었습니다.');

% --- 그림 파일로 저장 ---
figure_save_dir = 'C:\Users\user\Desktop\Figure\Figure 4\png 파일';
if ~exist(figure_save_dir, 'dir'), mkdir(figure_save_dir); end
figure_save_path = fullfile(figure_save_dir, 'Figure4e_from_Master.png');
exportgraphics(gcf, figure_save_path, 'Resolution', 300);
disp(['그림 파일 저장 완료: ' figure_save_path]);
