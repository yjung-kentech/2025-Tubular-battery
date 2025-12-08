clear; clc; close all;
import com.comsol.model.*
import com.comsol.model.util.*

%% 1. 파일 및 저장 경로 설정
COM_filepath = 'C:\Users\user\Desktop\Aging model';
COM_filename = 'JYR_3segment_agingcycle (2C)_1121.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

out_dir = 'C:\Users\user\Desktop\Figure\Supple Figure\png 파일';
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
out_name = '2C 튜블러_방전.png';
out_fullfile = fullfile(out_dir, out_name);

%% 2. 데이터셋 및 색상
all_datasets = {'dset44','dset19','dset24','dset29','dset34','dset39'};
all_labels   = {'1st cycle','100th cycle','200th cycle','300th cycle','400th cycle','500th cycle'};
n_dset = numel(all_datasets);
colors = get_nebula_colors(n_dset);

%% 3. 모델 로드
if ~exist('model','var')
    fprintf('모델 로드 중: %s\n', COM_fullfile);
    model = mphload(COM_fullfile);
    fprintf('모델 로드 완료.\n');
end

%% 4. Figure 설정
hLeg = gobjects(n_dset,1);
f = figure('Color','w','Units','pixels', 'Position',[150 50 580 1300]);
tlo = tiledlayout(f, 4, 1, 'TileSpacing','loose', 'Padding','loose');

yLabelFontSize = 16;
xLabelFontSize = 15;
axisFontSize   = 13;
labelFontSize  = 18;
labelXPos      = -0.16;
labelYPos      = 1.05;

% --- (1) 전압 (Voltage) ---
ax1 = nexttile(1);
hold(ax1, 'on'); grid(ax1, 'off'); box(ax1, 'on');
ylabel(ax1, 'Voltage [V]', 'FontSize', yLabelFontSize);
xlabel(ax1, 'Discharging capacity [Ah]', 'FontSize', xLabelFontSize);
set(ax1, 'FontSize', axisFontSize, 'LineWidth', 1);
text(ax1, labelXPos, labelYPos, 'b', 'Units', 'normalized', ...
    'FontSize', labelFontSize, 'FontWeight', 'bold');

% --- (2) 전류 (C-rate) ---
ax2 = nexttile(2);
hold(ax2, 'on'); grid(ax2, 'off'); box(ax2, 'on');
ylabel(ax2, 'C-rate', 'FontSize', yLabelFontSize);
xlabel(ax2, 'Discharging capacity [Ah]', 'FontSize', xLabelFontSize);
set(ax2, 'FontSize', axisFontSize, 'LineWidth', 1);
text(ax2, labelXPos, labelYPos, 'd', 'Units', 'normalized', ...
    'FontSize', labelFontSize, 'FontWeight', 'bold');

% --- (3) 최고 온도 (Max Temp) ---
ax3 = nexttile(3);
hold(ax3, 'on'); grid(ax3, 'off'); box(ax3, 'on');
ylabel(ax3, 'T_{max} [°C]', 'FontSize', yLabelFontSize);
xlabel(ax3, 'Discharging capacity [Ah]', 'FontSize', xLabelFontSize);
set(ax3, 'FontSize', axisFontSize, 'LineWidth', 1);
text(ax3, labelXPos, labelYPos, 'f', 'Units', 'normalized', ...
    'FontSize', labelFontSize, 'FontWeight', 'bold');

% --- (4) 평균 온도 (Avg Temp) ---
ax4 = nexttile(4);
hold(ax4, 'on'); grid(ax4, 'off'); box(ax4, 'on');
ylabel(ax4, 'T_{avg} [°C]', 'FontSize', yLabelFontSize);
xlabel(ax4, 'Discharging capacity [Ah]', 'FontSize', xLabelFontSize);
set(ax4, 'FontSize', axisFontSize, 'LineWidth', 1);
text(ax4, labelXPos, labelYPos, 'h', 'Units', 'normalized', ...
    'FontSize', labelFontSize, 'FontWeight', 'bold');

%% 5. 데이터 추출 및 플롯
fprintf('데이터 추출 및 방전 구간 플롯 시작...\n');

for k = 1:n_dset
    dset = all_datasets{k};
    
    % (1) 시간 및 기준점
    t = mphglobal(model, 't', 'dataset', dset, 'outersolnum','all', 'unit','s');
    t = t(:);
    if isempty(t), continue; end
    t0 = t(1);

    % (2) 표현식 정의 (공통)
    expr_Q = sprintf(['((comp1.deltaQ - at(%g, comp1.deltaQ)) + ' ...
                      '(comp2.deltaQ - at(%g, comp2.deltaQ)) + ' ...
                      '(comp3.deltaQ - at(%g, comp3.deltaQ)))/3'], t0,t0,t0);
    
    expr_V = '(comp1.E_cell + comp2.E_cell + comp3.E_cell)/3';
    
    % C-rate: -I/I_1C_2D (위가 충전, 아래가 방전)
    expr_C = '-(comp1.I_cell + comp2.I_cell + comp3.I_cell)/(3*I_1C_2D)';
           
    expr_Tmax = '((comp1.T_max + comp2.T_max + comp3.T_max)/3) - 273.15';
    expr_Tavg = '((comp1.T_avg + comp2.T_avg + comp3.T_avg)/3) - 273.15';

    % (3) 데이터 가져오기
    Q_raw  = mphglobal(model, expr_Q,   'dataset', dset, 'outersolnum','all', 'unit','Ah');
    V_raw  = mphglobal(model, expr_V,   'dataset', dset, 'outersolnum','all', 'unit','V');
    C_raw  = mphglobal(model, expr_C,   'dataset', dset, 'outersolnum','all'); 
    Tm_raw = mphglobal(model, expr_Tmax,'dataset', dset, 'outersolnum','all');
    Ta_raw = mphglobal(model, expr_Tavg,'dataset', dset, 'outersolnum','all');
    
    % 길이 동기화
    n = min([numel(Q_raw), numel(V_raw), numel(C_raw), numel(Tm_raw), numel(Ta_raw)]);
    Q_raw = Q_raw(1:n); V_raw = V_raw(1:n); C_raw = C_raw(1:n); 
    Tm_raw = Tm_raw(1:n); Ta_raw = Ta_raw(1:n);

    % --------------------------------------------------
    % (4) 충전 구간: 전압 단조 증가 구간
    % --------------------------------------------------
    idx_chg = longest_segment_by_monotonicity(V_raw, +1);
    if isempty(idx_chg) || idx_chg(end) >= n
        continue;
    end

    %% ===== a, b 축: 충전 이후 단조 감소(방전) 구간 =====
    idx_after      = (idx_chg(end)+1):n;                      % 충전 종료 이후
    idx_dis_rel_ab = longest_segment_by_monotonicity(V_raw(idx_after), -1);
    if isempty(idx_dis_rel_ab)
        continue;
    end
    idx_dis_ab = idx_after(idx_dis_rel_ab);

    Q_ab  = Q_raw(idx_dis_ab);
    V_ab  = V_raw(idx_dis_ab);
    C_ab  = C_raw(idx_dis_ab);

    Q_ab  = Q_ab(:);
    V_ab  = V_ab(:);
    C_ab  = C_ab(:);

    % x축 보정 (좌우 반전 없이, 최소값을 0으로 이동)
    Q_plot_ab = max(Q_ab) - Q_ab;
    Q_plot_ab = Q_plot_ab - min(Q_plot_ab);

    lw  = 1.0;
    col = colors(k,:);

    % --- a: Voltage + capacity 최대점에서 4.2 V까지 세로선 ---
    hLeg(k) = plot(ax1, Q_plot_ab, V_ab, '-', 'Color', col, 'LineWidth', lw); hold(ax1,'on');
    [Q0_ab, iQ0_ab] = min(Q_plot_ab);
    V_at_Q0_ab      = V_ab(iQ0_ab);
    plot(ax1, [Q0_ab Q0_ab], [V_at_Q0_ab 4.2], '-', 'Color', col, 'LineWidth', lw);

    % --- b: C-rate (방전 구간 plateau + 양쪽 세로선 == 0↔-1 포함) ---
    % 시작점에서 C=0을 하나 붙이고, 끝점에서 C=0을 하나 더 붙인다
    Q_b = [Q_plot_ab(1); Q_plot_ab; Q_plot_ab(end)];
    C_b = [0;            C_ab;      0           ];
    plot(ax2, Q_b, C_b, '-', 'Color', col, 'LineWidth', lw); hold(ax2,'on');

    %% ===== c, d 축: 전체 - 충전 = 방전 방식 =====
    all_idx    = (1:n).';
    idx_dis_cd = setdiff(all_idx, idx_chg(:));   % 전체에서 충전 구간 제외
    if isempty(idx_dis_cd), continue; end

    Q_cd  = Q_raw(idx_dis_cd);
    Tm_cd = Tm_raw(idx_dis_cd);
    Ta_cd = Ta_raw(idx_dis_cd);

    Q_cd  = Q_cd(:);
    Tm_cd = Tm_cd(:);
    Ta_cd = Ta_cd(:);

    Q_plot_cd = max(Q_cd) - Q_cd;
    Q_plot_cd = Q_plot_cd - min(Q_plot_cd);

    plot(ax3, Q_plot_cd, Tm_cd, '-', 'Color', col, 'LineWidth', lw); hold(ax3,'on');
    plot(ax4, Q_plot_cd, Ta_cd, '-', 'Color', col, 'LineWidth', lw); hold(ax4,'on');
end

% 범례 (맨 위 그래프에만 표시)
% legend(ax1, hLeg, all_labels, 'Location','southeast', 'FontSize', 12);

% 축 동기화 및 범위 설정
linkaxes([ax1, ax2, ax3, ax4], 'x');
xlim(ax1, [0 inf]);

ylim(ax1, [3.0 4.2]);
ylim(ax3, [25 27.5]);
ylim(ax4, [25 26.5]);
ylim(ax2, [-2 0]);   % 필요하면 조절

%% 6. 이미지 저장
fprintf('이미지 저장 중: %s\n', out_fullfile);
exportgraphics(f, out_fullfile, 'Resolution', 600);
fprintf('저장 완료.\n');

%% =================================================================
%  Local Functions
% =================================================================

function colors = get_nebula_colors(n)
    stops = [0.0,  0.00, 0.20, 0.60;
             0.5,  0.50, 0.10, 0.70;
             1.0,  0.90, 0.40, 0.60];
    x = linspace(0, 1, n)';
    r = interp1(stops(:,1), stops(:,2), x, 'pchip');
    g = interp1(stops(:,1), stops(:,3), x, 'pchip');
    b = interp1(stops(:,1), stops(:,4), x, 'pchip');
    colors = max(0, min(1, [r, g, b]));
end

function idx = longest_segment_by_monotonicity(x, modeSign)
    x = x(:);
    dx = [0; diff(x)];
    epsVal = 1e-4; 

    if modeSign > 0
        mask = dx > -epsVal;   % 거의 증가
    else
        mask = dx <  epsVal;   % 거의 감소
    end
    
    win = max(1, min(11, floor(numel(mask)/100)));
    if win > 1
        mask = movmean(double(mask), win) > 0.5;
    end

    d = diff([false; mask; false]);
    s = find(d==1);
    e = find(d==-1) - 1;

    if isempty(s)
        idx = [];
    else
        [~, im] = max(e - s + 1);
        idx = s(im):e(im);
    end
end
