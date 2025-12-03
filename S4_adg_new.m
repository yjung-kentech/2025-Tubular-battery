clear; clc; close all

%% 1. 데이터 읽기 -----------------------------------------------------------
data_dir  = 'C:\Users\user\Desktop\MATLAB\Tubular_battery';
data_file = fullfile(data_dir,'Tubular_Sweep_Crate_Rin_80.mat');
load(data_file)

% 컬러맵 읽기
color_data_file = fullfile(data_dir,'slanCM_Data.mat');
load(color_data_file)

color_type = 'SequentialP';
color_name = 'Reds';
diverging_idx = find(strcmp({slandarerCM.Type}, color_type));
idx_Reds      = find(strcmp(slandarerCM(diverging_idx).Names, color_name));
Reds          = slandarerCM(diverging_idx).Colors{idx_Reds};

%% 2. 축 데이터 -------------------------------------------------------------
C_rate_vec = data.C_rate;          % 원본 C-rate
D_in_vec   = 2*data.R_in;          % 원본 D_in

%% 3. 고해상도 2-D 보간 -----------------------------------------------
%   (→ 100 °C 경계가 부드럽게 표현)
N = 500;                                               % 해상도 (500×500)
D_in_hi   = linspace(min(D_in_vec),   max(D_in_vec),   N);
C_rate_hi = linspace(min(C_rate_vec), max(C_rate_vec), N);

[D_in_grid,   C_rate_grid]   = meshgrid(D_in_vec,   C_rate_vec);
[D_in_higrid, C_rate_higrid] = meshgrid(D_in_hi,    C_rate_hi);

T_max_hi = interp2(D_in_grid, C_rate_grid, ...
                   data.T_max, D_in_higrid, C_rate_higrid, 'spline');

%% 4. 100 °C 기준으로 회색 마스킹 --------------------------------------
T_cut = 100;
over_100_mask = (T_max_hi > T_cut);   % 100도 초과 마스크

%% 5. 플로팅 ---------------------------------------------------------------
figure
set(gcf,'Position',[680 558 800 620])

cmin = min(T_max_hi(:));
cmax = 100;
numContours = 20;

% (1) T_max contour
contourf(D_in_hi, C_rate_hi, T_max_hi, ...
         linspace(cmin, cmax, numContours), 'LineColor','none');
clim([cmin cmax])
colormap(Reds)
colorbar; hold on

% (2) 100 °C 초과 회색 영역 추가
[~,hOver100] = contourf(D_in_hi, C_rate_hi, double(over_100_mask), ...
                        [0.5 1.5], 'LineColor','none');
set(hOver100, 'FaceColor', [0.5 0.5 0.5], 'EdgeColor', 'none');

% (3) Tmax = 45 °C 경계선 (고해상도 격자 이용 → 부드러움)
T45 = 45;
[~,hT45] = contour(D_in_hi, C_rate_hi, T_max_hi, ...
                   [T45 T45], 'LineWidth',2,'LineColor','#EE4C97');

%% 6. 서식·레이블 -----------------------------------------------------------
xlabel('D_{in} [mm]','FontSize',26)
ylabel('C-rate','FontSize',26)

h = colorbar;
ylabel(h,'T_{max} [^oC]','FontSize',26)
h.Label.Position(1) = h.Label.Position(1) + 0.1;

ax = gca;  ax.FontSize = 24;

% 관심 지점 하이라이트 (값은 그대로 사용)
% x = 6;  y = 6;
% xline(x,'--w','LineWidth',1)
% yline(y,'--w','LineWidth',1)
% plot(x,y,'o','MarkerEdgeColor','#EFC000','MarkerFaceColor','#EFC000')

lgd = legend(hT45,'T_{max} = 45 ^oC', ...
             'Location','northwest','FontSize',26);
set(lgd,'Color',[0.8 0.8 0.8],'EdgeColor','black')

hold off

%% 7. 저장 ------------------------------------------------------------------
exportgraphics(gcf, ...
    'C:\Users\user\Desktop\Figure\Supple Figure\png 파일\S4_g.png', ...
    'Resolution',300);
