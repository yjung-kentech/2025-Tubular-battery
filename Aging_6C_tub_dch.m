clear; clc; close all;
import com.comsol.model.*
import com.comsol.model.util.*

%% 1. 파일 및 저장 경로 설정
COM_filepath = 'C:\Users\user\Desktop\Aging model';
COM_filename = 'JYR_3segment_agingcycle (6C)_1121.mph';
COM_fullfile = fullfile(COM_filepath, COM_filename);

out_dir = 'C:\Users\user\Desktop\Figure\Supple Figure\png 파일';
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
out_name = '6C 튜블러_방전.png';
out_fullfile = fullfile(out_dir, out_name);

%% 2. 데이터셋 및 색상
all_datasets = {'dset43','dset19','dset24','dset29','dset34','dset39'};
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
hLeg      = gobjects(0);   % 실제로 플로팅한 라인만 담음
legLabels = {};

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

%% 5. 데이터 추출 및 방전 구간 플롯
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
    
    % C-rate: -I/I_1C_2D  (방전 플롯용)
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
    Q_raw  = Q_raw(1:n);
    V_raw  = V_raw(1:n);
    C_raw  = C_raw(1:n);
    Tm_raw = Tm_raw(1:n);
    Ta_raw = Ta_raw(1:n);

    % --------------------------------------------------
    % (4) 충전 구간: 전압 단조 증가 구간
    % --------------------------------------------------
    idx_chg = longest_segment_by_monotonicity(V_raw, +1);
    if isempty(idx_chg) || idx_chg(end) >= n
        continue;
    end

    %% ===== 공통 방전 구간: 충전 이후 단조 감소 구간 =====
    idx_after   = (idx_chg(end)+1):n;
    idx_dis_rel = longest_segment_by_monotonicity(V_raw(idx_after), -1);
    if isempty(idx_dis_rel)
        continue;
    end
    idx_dis = idx_after(idx_dis_rel);

    % 이 인덱스를 네 패널 모두에서 사용
    Q_dis  = Q_raw(idx_dis);
    V_dis  = V_raw(idx_dis);
    C_dis  = C_raw(idx_dis);
    Tm_dis = Tm_raw(idx_dis);
    Ta_dis = Ta_raw(idx_dis);

    Q_dis  = Q_dis(:);
    V_dis  = V_dis(:);
    C_dis  = C_dis(:);
    Tm_dis = Tm_dis(:);
    Ta_dis = Ta_dis(:);

    % ==========================================
    % [핵심] 좌우반전 + 0Ah 정렬
    % ==========================================
    Q_plot = max(Q_dis) - Q_dis;
    Q_plot = Q_plot - min(Q_plot);
    Q_plot = Q_plot(:);

    if numel(Q_plot) < 2
        continue;
    end

    lw  = 1.0;
    col = colors(k,:);

    % --- (1) Voltage: 방전 곡선 ---
    hLine = plot(ax1, Q_plot, V_dis, '-', 'Color', col, 'LineWidth', lw); hold(ax1,'on');

    % ==========================================
    % [핵심] a번 세로선: 0Ah에서 시작 전압 → 4.2V
    % ==========================================
    [Q0, iQ0] = min(Q_plot);
    V_at_Q0   = V_dis(iQ0);
    plot(ax1, [Q0 Q0], [V_at_Q0 4.2], '-', 'Color', col, 'LineWidth', lw);

    % legend용
    hLeg(end+1,1)      = hLine;
    legLabels{end+1,1} = all_labels{k};

    % --- (2) C-rate (방전 plateau + 양쪽 세로선) ---
    Q_b = [Q_plot(1); Q_plot; Q_plot(end)];
    C_b = [0;         C_dis;  0         ];
    plot(ax2, Q_b, C_b, '-', 'Color', col, 'LineWidth', lw); hold(ax2,'on');

    % ==========================================
    % (3)(4) 온도: Q_max(방전 capacity 최대점)에서
    %            해당 온도값 → 25°C까지 세로선
    % ==========================================
    T0 = 25;

    % 온도 곡선
    plot(ax3, Q_plot, Tm_dis, '-', 'Color', col, 'LineWidth', lw); hold(ax3,'on');
    plot(ax4, Q_plot, Ta_dis, '-', 'Color', col, 'LineWidth', lw); hold(ax4,'on');

    % 방전 capacity 최대점
    [Q_max, iQmax] = max(Q_plot);

    Tm_at_Qmax = Tm_dis(iQmax);
    Ta_at_Qmax = Ta_dis(iQmax);

    % 세로선
    plot(ax3, [Q_max Q_max], [T0 Tm_at_Qmax], '-', 'Color', col, 'LineWidth', lw);
    plot(ax4, [Q_max Q_max], [T0 Ta_at_Qmax], '-', 'Color', col, 'LineWidth', lw);

end

% 범례
% if ~isempty(hLeg)
%     legend(ax1, hLeg, legLabels, 'Location','southeast', 'FontSize', 12);
% end

% 축 동기화 및 범위 설정
linkaxes([ax1, ax2, ax3, ax4], 'x');
xlim(ax1, [0 inf]);

ylim(ax1, [3.0 4.2]);
ylim(ax3, [25 28]);
ylim(ax4, [25 27]);

% 방전 C-rate 축(하나만 남김)
ylim(ax2, [-2 0]);

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
