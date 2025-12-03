clear; clc; close all;

%% ========================================================================
%  [SECTION 1] 데이터 로드
% =========================================================================
% 1) MasterData (c_cell, rho_E용)
mat_filepath = 'C:\Users\user\Desktop\Figure\Cost Model\mat 파일\Cost_Master.mat';
load(mat_filepath, 'MasterData');

% 2) D_in sweep (t_chg 계산용)
data_dir = 'C:\Users\user\Desktop\Figure\Sweep\mat 파일';
load(fullfile(data_dir, 'Tubular_Sweep_Crate_Rin_46.mat')); data_46 = data;
load(fullfile(data_dir, 'Tubular_Sweep_Crate_Rin_60.mat')); data_60 = data;
load(fullfile(data_dir, 'Tubular_Sweep_Crate_Rin_80.mat')); data_80 = data;

%% ========================================================================
%  [SECTION 2] D_in별 충전시간 t_chg 계산
%   - 등고선(Elp=0, Tmax=45°C) 경계에서 가능한 최소 C-rate 사용
% =========================================================================
Elpcut = 0; T_allowed = 45;

idx_46 = (data_46.R_in*2 >= 4);
[D_in_46, T_chg_46] = findChargingTime( ...
    data_46.R_in(idx_46)*2, data_46.C_rate, ...
    data_46.Elp_min(:,idx_46), data_46.T_max(:,idx_46), data_46.t95(:,idx_46), ...
    Elpcut, T_allowed);

idx_60 = (data_60.R_in*2 >= 4);
[D_in_60, T_chg_60] = findChargingTime( ...
    data_60.R_in(idx_60)*2, data_60.C_rate, ...
    data_60.Elp_min(:,idx_60), data_60.T_max(:,idx_60), data_60.t95(:,idx_60), ...
    Elpcut, T_allowed);

idx_80 = (data_80.R_in*2 >= 4);
[D_in_80, T_chg_80] = findChargingTime( ...
    data_80.R_in(idx_80)*2, data_80.C_rate, ...
    data_80.Elp_min(:,idx_80), data_80.T_max(:,idx_80), data_80.t95(:,idx_80), ...
    Elpcut, T_allowed);

%% ========================================================================
%  [SECTION 3] c_cell / rho_E 매칭
% =========================================================================
D_in_master = MasterData.fig_e.D_in_vec;

% Tubular (D_in에 따른 값)
c_cell_46 = interp1(D_in_master, MasterData.fig_e.c_cell_tub_46mm, D_in_46, 'linear','extrap');
rho_E_46  = interp1(D_in_master, MasterData.fig_f.rho_E_tub_46mm,  D_in_46, 'linear','extrap');

c_cell_60 = interp1(D_in_master, MasterData.fig_e.c_cell_tub_60mm, D_in_60, 'linear','extrap');
rho_E_60  = interp1(D_in_master, MasterData.fig_f.rho_E_tub_60mm,  D_in_60, 'linear','extrap');

c_cell_80 = interp1(D_in_master, MasterData.fig_e.c_cell_tub_80mm, D_in_80, 'linear','extrap');
rho_E_80  = interp1(D_in_master, MasterData.fig_f.rho_E_tub_80mm,  D_in_80, 'linear','extrap');

% Cylinder 기준 시간(x좌표)
desired_D_out     = [46, 60, 80];
t95_cyl_points    = [MasterData.fig_f.t_chg_cyl_46mm, MasterData.fig_f.t_chg_cyl_60mm, MasterData.fig_f.t_chg_cyl_80mm];

% ---- 핵심: "실린더 ≈ D_in = 4 mm" 가정으로 c_cell을 강제 정렬 ----
Din_eq = 4;  % 실질 최소 말이값
c_cell_tub_46_at4 = interp1(D_in_master, MasterData.fig_e.c_cell_tub_46mm, Din_eq, 'linear','extrap');
c_cell_tub_60_at4 = interp1(D_in_master, MasterData.fig_e.c_cell_tub_60mm, Din_eq, 'linear','extrap');
c_cell_tub_80_at4 = interp1(D_in_master, MasterData.fig_e.c_cell_tub_80mm, Din_eq, 'linear','extrap');
c_cell_cyl_points = [c_cell_tub_46_at4, c_cell_tub_60_at4, c_cell_tub_80_at4];  % ⟵ 실린더 c_cell을 D_in=4mm 값으로 대체

% rho_E는 기존 의도대로(실린더 자체 값 사용)
rho_E_cyl_points  = interp1(MasterData.fig_c.D_out_vec, MasterData.fig_c.rho_E_cyl, desired_D_out, 'linear','extrap');

%% ========================================================================
%  [SECTION 4] 그래프
% =========================================================================
figure('Position',[100,100,560,420]);
lw = 1;
colors = {[0.9373,0.7529,0], [0.5725,0.3686,0.6235], [0.1255,0.5216,0.3059]};
n_markers = 6;

% ------------------------- Left Y: c_cell -------------------------
yyaxis left; hold on; grid off; box on;

plot(T_chg_46, c_cell_46, '-', 'Color', colors{1}, 'LineWidth', lw);
plot(T_chg_60, c_cell_60, '-', 'Color', colors{2}, 'LineWidth', lw);
plot(T_chg_80, c_cell_80, '-', 'Color', colors{3}, 'LineWidth', lw);

[xm,ym] = selectMarkers(T_chg_46, c_cell_46, 'y', n_markers); plot(xm,ym,'s','Color',colors{1},'LineWidth',lw);
[xm,ym] = selectMarkers(T_chg_60, c_cell_60, 'x', n_markers); plot(xm,ym,'s','Color',colors{2},'LineWidth',lw);
[xm,ym] = selectMarkers(T_chg_80, c_cell_80, 'x', n_markers); plot(xm,ym,'s','Color',colors{3},'LineWidth',lw);

% 실린더 c_cell 점 (y는 D_in=4mm와 동일)
plot(t95_cyl_points(1), c_cell_cyl_points(1), 's', 'MarkerEdgeColor',colors{1}, 'MarkerFaceColor',colors{1}, 'HandleVisibility','off');
plot(t95_cyl_points(2), c_cell_cyl_points(2), 's', 'MarkerEdgeColor',colors{2}, 'MarkerFaceColor',colors{2}, 'HandleVisibility','off');
plot(t95_cyl_points(3), c_cell_cyl_points(3), 's', 'MarkerEdgeColor',colors{3}, 'MarkerFaceColor',colors{3}, 'HandleVisibility','off');

ylabel('c_{cell} [$/kWh]','FontSize',15);
ylim([70 78]);
set(gca,'YColor','k','FontSize',15);

% ------------------------- Right Y: rho_E -------------------------
yyaxis right; hold on;

plot(T_chg_46, rho_E_46, '-', 'Color', colors{1}, 'LineWidth', lw);
plot(T_chg_60, rho_E_60, '-', 'Color', colors{2}, 'LineWidth', lw);
plot(T_chg_80, rho_E_80, '-', 'Color', colors{3}, 'LineWidth', lw);

[xm,ym] = selectMarkers(T_chg_46, rho_E_46, 'y', n_markers); plot(xm,ym,'^','Color',colors{1},'LineWidth',lw);
[xm,ym] = selectMarkers(T_chg_60, rho_E_60, 'x', n_markers); plot(xm,ym,'^','Color',colors{2},'LineWidth',lw);
[xm,ym] = selectMarkers(T_chg_80, rho_E_80, 'x', n_markers); plot(xm,ym,'^','Color',colors{3},'LineWidth',lw);

% 실린더 rho_E 점 (원 코드 의도 유지)
plot(t95_cyl_points(1), rho_E_cyl_points(1), '^', 'MarkerEdgeColor',colors{1}, 'MarkerFaceColor',colors{1}, 'HandleVisibility','off');
plot(t95_cyl_points(2), rho_E_cyl_points(2), '^', 'MarkerEdgeColor',colors{2}, 'MarkerFaceColor',colors{2}, 'HandleVisibility','off');
plot(t95_cyl_points(3), rho_E_cyl_points(3), '^', 'MarkerEdgeColor',colors{3}, 'MarkerFaceColor',colors{3}, 'HandleVisibility','off');

ylabel('\rho_{E} [kWh/m^3]','FontSize',15);
ylim([610 885]);
set(gca,'YColor','k','FontSize',15);

% ------------------------- Common -------------------------
xlabel('Charging time [min]','FontSize',17);

yyaxis left
h(1) = plot(nan,nan,'-s','Color',colors{1},'DisplayName','c_{cell} 46mm');
h(2) = plot(nan,nan,'-s','Color',colors{2},'DisplayName','c_{cell} 60mm');
h(3) = plot(nan,nan,'-s','Color',colors{3},'DisplayName','c_{cell} 80mm');

yyaxis right
h(4) = plot(nan,nan,'-^','Color',colors{1},'DisplayName','\rho_{E} 46mm');
h(5) = plot(nan,nan,'-^','Color',colors{2},'DisplayName','\rho_{E} 60mm');
h(6) = plot(nan,nan,'-^','Color',colors{3},'DisplayName','\rho_{E} 80mm');

legend(h,'Location','northeast','NumColumns',2,'FontSize',13);

xlim([5 35]);  % 필요 시 조정

% 저장
figure_save_dir = 'C:\Users\user\Desktop\Figure\Figure 4\png 파일';
if ~exist(figure_save_dir,'dir'), mkdir(figure_save_dir); end
exportgraphics(gcf, fullfile(figure_save_dir,'Figure4f_from_Master.png'), 'Resolution',300);

%% ========================================================================
%  [LOCAL FUNCTIONS]
% =========================================================================
function [all_x, charging_time] = findChargingTime(D_in_vec, C_rate_vec, Elp_min, T_max, t95, Elpcut, T_allowed)
    % Elp=Elpcut, Tmax=T_allowed 등고선
    M_Elp  = contourc(D_in_vec, C_rate_vec, Elp_min, [Elpcut, Elpcut]);
    M_Tmax = contourc(D_in_vec, C_rate_vec, T_max,  [T_allowed, T_allowed]);
    [Elp_x, Elp_y]   = parseContour(M_Elp);
    [Tmax_x, Tmax_y] = parseContour(M_Tmax);

    % 가능한 D_in에서 허용 최소 C-rate
    all_x = unique([Elp_x, Tmax_x]);
    min_y = arrayfun(@(x) min([interp1(Elp_x, Elp_y, x, 'linear', inf), ...
                               interp1(Tmax_x, Tmax_y, x, 'linear', inf)]), all_x);
    charging_time = interp2(D_in_vec, C_rate_vec, t95, all_x, min_y, 'linear');
end

function [X, Y] = parseContour(M)
    X = []; Y = []; i = 1;
    while i < size(M,2)
        npt = M(2,i); i = i + 1;
        X = [X, M(1, i:i+npt-1)];
        Y = [Y, M(2, i:i+npt-1)];
        i = i + npt;
    end
end

function [x_markers, y_markers] = selectMarkers(x, y, axisChoice, n_markers)
    valid = isfinite(x) & isfinite(y);
    x = x(valid); y = y(valid);
    if isempty(x), x_markers=[]; y_markers=[]; return; end

    switch axisChoice
        case 'x'
            [xs, idx] = sort(x); ys = y(idx);
            x_points = linspace(min(xs), max(xs), n_markers);
            y_points = interp1(xs, ys, x_points, 'linear','extrap');
        case 'y'
            [ys, idx] = sort(y); xs = x(idx);
            y_points = linspace(min(ys), max(ys), n_markers);
            x_points = interp1(ys, xs, y_points, 'linear','extrap');
        otherwise
            error('axisChoice는 ''x'' 또는 ''y''여야 합니다.');
    end
    x_markers = x_points; y_markers = y_points;
end
