clear; clc; close all;

%% ==========================================================
%  파트 1: C-rate별 개별 그래프 생성 (For Loop)
%  ==========================================================

%% 사용자 설정
RELOAD_FROM_MAT_FILE = true; % true로 바꿔서 저장된 .mat 파일을 바로 사용
C_rates_list = {'2C', '6C'}; % 처리할 C-rate 목록

% --- 기본 경로 설정 ---
mat_base_path = 'C:\Users\user\Desktop\Figure\Figure 5\중간데이터';
comsol_base_path = 'C:\Users\user\Desktop\Aging model';
save_base_path = 'C:\Users\user\Desktop\Figure\Figure 5\png 파일';

% --- 파트 2에서 사용할 파일명을 저장할 변수 ---
generated_files = cell(size(C_rates_list)); 

%% C-rate 별로 루프 시작
for i = 1:length(C_rates_list)
    c_rate = C_rates_list{i}; % 현재 C-rate (예: '2C' 또는 '6C')
    
    fprintf('\n\n==========================================\n');
    fprintf('>>>>>> %s C-rate 작업 시작 <<<<<<\n', c_rate);
    fprintf('==========================================\n');

    % --- 루프 반복 시 변수 초기화 ---
    clearvars cycle_count_tub capacity_retention_tub1 capacity_retention_tub2 capacity_retention_tub3 ...
              cycle_count_cyl capacity_retention_cyl1 capacity_retention_cyl2 capacity_retention_cyl3 ...
              model1 model2 d1_data d2_data d3_data d4_data idx_tub idx_cyl ...
              cycle_count_un_tub cap_tub1_un cap_tub2_un cap_tub3_un ...
              cycle_count_un_cyl cap_cyl1_un cap_cyl2_un cap_cyl3_un ...
              cap_tub1 cap_tub2 cap_tub3 cap_cyl1 cap_cyl2 cap_cyl3 ...
              retention_tub_all retention_tub_max retention_tub_min retention_tub_avg ...
              retention_cyl_all retention_cyl_max retention_cyl_min retention_cyl_avg ...
              ax_inset; % 인셋 핸들도 초기화

    % C-rate에 따라 파일 이름 동적 설정
    mat_filename = fullfile(mat_base_path, sprintf('aging_data_%s.mat', c_rate));
    
    % C-rate에 따라 저장 파일명과 COMSOL 파일명 분기
    if strcmp(c_rate, '2C')
        COM_filename1 = 'JYR_3segment_agingcycle (2C)_1030';
        COM_filename2 = 'JYR_3seg_agingcycle_cyl (2C)_1016';
        save_filename = 'figure5_2C(2).png'; % 2C용 파일명
    elseif strcmp(c_rate, '6C')
        COM_filename1 = 'JYR_3segment_agingcycle (6C)_1020(2)';
        COM_filename2 = 'JYR_3seg_agingcycle_cyl (6C)_1030';
        save_filename = 'figure5_6C.png'; % 6C용 파일명
    else
        warning('알 수 없는 C-rate "%s"입니다. 이 C-rate는 건너뜁니다.', c_rate);
        continue; 
    end
    
    generated_files{i} = save_filename; % 파트 2를 위해 파일명 저장

    %% 데이터 불러오기 또는 새로 추출하기
    if RELOAD_FROM_MAT_FILE && exist(mat_filename, 'file')
        fprintf('"%s" 파일에서 기존 데이터를 불러옵니다...\n', mat_filename);
        load(mat_filename);
        disp('데이터 불러오기 완료.');
        
        % .mat 파일 로드 시 정렬 (안전 장치)
        [cycle_count_tub, sort_idx] = sort(cycle_count_tub);
        capacity_retention_tub1 = capacity_retention_tub1(sort_idx);
        capacity_retention_tub2 = capacity_retention_tub2(sort_idx);
        capacity_retention_tub3 = capacity_retention_tub3(sort_idx);
        [cycle_count_cyl, sort_idx] = sort(cycle_count_cyl);
        capacity_retention_cyl1 = capacity_retention_cyl1(sort_idx);
        capacity_retention_cyl2 = capacity_retention_cyl2(sort_idx);
        capacity_retention_cyl3 = capacity_retention_cyl3(sort_idx);
    else
        fprintf('"%s" .mat 파일이 없습니다. COMSOL 모델에서 데이터를 새로 추출합니다...\n', mat_filename);
        
        import com.comsol.model.*
        import com.comsol.model.util.*
        
        COM_fullfile1 = fullfile(comsol_base_path, COM_filename1);
        COM_fullfile2 = fullfile(comsol_base_path, COM_filename2);

        ModelUtil.clear(); 
        
        % --- 튜블러 모델 먼저 처리 ---
        disp('COMSOL 모델 1 (튜블러) 불러오는 중입니다');
        model1 = mphload(COM_fullfile1);
        disp('모델 1 불러오기 완료.');
        
        disp('모델 1 (튜블러) 데이터 처리 중 (변수별 개별 추출)...');
        d1_data = mpheval(model1, 'comp11.cycle_count', 'dataset', 'dset1');
        d2_data = mpheval(model1, 'comp11.Q_dch_recap1', 'dataset', 'dset1');
        d3_data = mpheval(model1, 'comp11.Q_dch_recap2', 'dataset', 'dset1');
        d4_data = mpheval(model1, 'comp11.Q_dch_recap3', 'dataset', 'dset1');
        
        ModelUtil.remove(model1.tag());
        clear model1;
        
        idx_tub = d1_data.d1 > 0; 
        cycle_count_un_tub = d1_data.d1(idx_tub);
        cap_tub1_un = d2_data.d1(idx_tub);
        cap_tub2_un = d3_data.d1(idx_tub);
        cap_tub3_un = d4_data.d1(idx_tub);
        
        [cycle_count_tub, sort_idx] = sort(cycle_count_un_tub);
        cap_tub1 = cap_tub1_un(sort_idx);
        cap_tub2 = cap_tub2_un(sort_idx);
        cap_tub3 = cap_tub3_un(sort_idx);
        
        clear d1_data d2_data d3_data d4_data cycle_count_un_tub cap_tub1_un cap_tub2_un cap_tub3_un; 
        
        fprintf('--- [디버그] 튜블러 모델 정규화 기준 값 (1st cycle capacity) ---\n');
        fprintf('cap_tub1(1) = %.4f\n', cap_tub1(1));
        fprintf('cap_tub2(1) = %.4f\n', cap_tub2(1));
        fprintf('cap_tub3(1) = %.4f\n', cap_tub3(1));
        
        capacity_retention_tub1 = cap_tub1 / cap_tub1(1);
        capacity_retention_tub2 = cap_tub2 / cap_tub2(1);
        capacity_retention_tub3 = cap_tub3 / cap_tub3(1);
        % --- 모델 1 처리 끝 ---
        
        % --- 원통형 모델 다음 처리 ---
        disp('COMSOL 모델 2 (원통형) 불러오는 중입니다');
        model2 = mphload(COM_fullfile2); 
        disp('모델 2 불러오기 완료.');
        
        disp('모델 2 (원통형) 데이터 처리 중 (변수별 개별 추출)...');
        d1_data = mpheval(model2, 'comp11.cycle_count', 'dataset', 'dset1');
        d2_data = mpheval(model2, 'comp11.Q_dch_recap1', 'dataset', 'dset1');
        d3_data = mpheval(model2, 'comp11.Q_dch_recap2', 'dataset', 'dset1');
        d4_data = mpheval(model2, 'comp11.Q_dch_recap3', 'dataset', 'dset1');
        
        ModelUtil.remove(model2.tag());
        clear model2;
        
        idx_cyl = d1_data.d1 > 0; 
        cycle_count_un_cyl = d1_data.d1(idx_cyl);
        cap_cyl1_un = d2_data.d1(idx_cyl);
        cap_cyl2_un = d3_data.d1(idx_cyl);
        cap_cyl3_un = d4_data.d1(idx_cyl);
        
        [cycle_count_cyl, sort_idx] = sort(cycle_count_un_cyl);
        cap_cyl1 = cap_cyl1_un(sort_idx);
        cap_cyl2 = cap_cyl2_un(sort_idx);
        cap_cyl3 = cap_cyl3_un(sort_idx);
        
        clear d1_data d2_data d3_data d4_data cycle_count_un_cyl cap_cyl1_un cap_cyl2_un cap_cyl3_un;
        
        fprintf('--- [디버그] 원통형 모델 정규화 기준 값 (1st cycle capacity) ---\n');
        fprintf('cap_cyl1(1) = %.4f\n', cap_cyl1(1));
        fprintf('cap_cyl2(1) = %.4f\n', cap_cyl2(1));
        fprintf('cap_cyl3(1) = %.4f\n', cap_cyl3(1));
        
        capacity_retention_cyl1 = cap_cyl1 / cap_cyl1(1);
        capacity_retention_cyl2 = cap_cyl2 / cap_cyl2(1);
        capacity_retention_cyl3 = cap_cyl3 / cap_cyl3(1);
        % --- 모델 2 처리 끝 ---
        
        ModelUtil.showProgress(false);
        
        fprintf('추출된 데이터를 "%s" 파일로 저장합니다...\n', mat_filename);
        save(mat_filename, ...
            'cycle_count_tub', 'capacity_retention_tub1', 'capacity_retention_tub2', 'capacity_retention_tub3', ...
            'cycle_count_cyl', 'capacity_retention_cyl1', 'capacity_retention_cyl2', 'capacity_retention_cyl3');
        disp('데이터 저장 완료.');
    end

    %% 데이터 확인 (디버깅용)
    disp('=== 데이터 확인 ===');
    if exist('cycle_count_tub', 'var') && ~isempty(cycle_count_tub)
        fprintf('Tubular - cycle_count 크기: %s, 범위: [%.2f, %.2f]\n', ...
            mat2str(size(cycle_count_tub)), min(cycle_count_tub), max(cycle_count_tub));
        fprintf('Tubular - capacity_retention_tub1 크기: %s, 범위: [%.4f, %.4f]\n', ...
            mat2str(size(capacity_retention_tub1)), min(capacity_retention_tub1), max(capacity_retention_tub1));
    else
        fprintf('Tubular 데이터가 비어있거나 존재하지 않습니다.\n');
    end
    if exist('cycle_count_cyl', 'var') && ~isempty(cycle_count_cyl)
        fprintf('Cylindrical - cycle_count 크기: %s, 범위: [%.2f, %.2f]\n', ...
            mat2str(size(cycle_count_cyl)), min(cycle_count_cyl), max(cycle_count_cyl));
        fprintf('Cylindrical - capacity_retention_cyl1 크기: %s, 범위: [%.4f, %.4f]\n', ...
            mat2str(size(capacity_retention_cyl1)), min(capacity_retention_cyl1), max(capacity_retention_cyl1));
    else
         fprintf('Cylindrical 데이터가 비어있거나 존재하지 않습니다.\n');
    end
    disp('==================');
    
    %% 결과 그래프 작성
    disp('그래프 생성 중...');
    figure; 
    ax_main = gca; % 메인 축 핸들 저장
    hold(ax_main, 'on');
    
    % 색상 설정
    color_tub_band = [0.0000, 0.4500, 0.7608]; 
    color_tub_line = [0.0000, 0.4500, 0.7608]; 
    color_cyl_band = [0.8039, 0.3255, 0.2980]; 
    color_cyl_line = [0.8039, 0.3255, 0.2980]; 
    
    % 튜블러 데이터 그리기
    if exist('cycle_count_tub', 'var') && ~isempty(cycle_count_tub) && ~isempty(capacity_retention_tub1)
        capacity_retention_tub1 = capacity_retention_tub1(:);
        capacity_retention_tub2 = capacity_retention_tub2(:);
        capacity_retention_tub3 = capacity_retention_tub3(:);
        cycle_count_tub = cycle_count_tub(:);
        retention_tub_all = [capacity_retention_tub1, capacity_retention_tub2, capacity_retention_tub3];
        retention_tub_max = max(retention_tub_all, [], 2);
        retention_tub_min = min(retention_tub_all, [], 2);
        retention_tub_avg = mean(retention_tub_all, 2);
        cycle_count_tub_row = cycle_count_tub';
        retention_tub_max_row = retention_tub_max';
        retention_tub_min_row = retention_tub_min';
        
        fill(ax_main, [cycle_count_tub_row, fliplr(cycle_count_tub_row)], ...
             [retention_tub_max_row, fliplr(retention_tub_min_row)], ...
             color_tub_band, 'FaceAlpha', 0.5, 'EdgeColor', 'none', ...
             'HandleVisibility', 'off');
        plot(ax_main, cycle_count_tub, retention_tub_avg, 'Color', color_tub_line, ...
             'LineWidth', 1, 'HandleVisibility', 'off');
    else
        disp('경고: 튜블러 데이터가 없어 그래프를 그릴 수 없습니다.');
    end
    
    % 원통형 데이터 그리기
    if exist('cycle_count_cyl', 'var') && ~isempty(cycle_count_cyl) && ~isempty(capacity_retention_cyl1)
        capacity_retention_cyl1 = capacity_retention_cyl1(:);
        capacity_retention_cyl2 = capacity_retention_cyl2(:);
        capacity_retention_cyl3 = capacity_retention_cyl3(:);
        cycle_count_cyl = cycle_count_cyl(:);
        retention_cyl_all = [capacity_retention_cyl1, capacity_retention_cyl2, capacity_retention_cyl3];
        retention_cyl_max = max(retention_cyl_all, [], 2);
        retention_cyl_min = min(retention_cyl_all, [], 2);
        retention_cyl_avg = mean(retention_cyl_all, 2); 
        cycle_count_cyl_row = cycle_count_cyl';
        retention_cyl_max_row = retention_cyl_max';
        retention_cyl_min_row = retention_cyl_min';
        
        fill(ax_main, [cycle_count_cyl_row, fliplr(cycle_count_cyl_row)], ...
             [retention_cyl_max_row, fliplr(retention_cyl_min_row)], ...
             color_cyl_band, 'FaceAlpha', 0.5, 'EdgeColor', 'none', ...
             'HandleVisibility', 'off');
        plot(ax_main, cycle_count_cyl, retention_cyl_avg, 'Color', color_cyl_line, ... 
             'LineWidth', 1, 'HandleVisibility', 'off');
    else
        disp('경고: 원통형 데이터가 없어 그래프를 그릴 수 없습니다.');
    end
    
    %% 그래프 설정 (메인 플롯)
    xlabel(ax_main, 'Cycle number', 'FontSize', 13);
    ylabel(ax_main, 'Capacity retention', 'FontSize', 14);
    
    % X축 범위 500으로 통일 (2C 스크립트 기준), Y축 범위 0.5~1
    xlim(ax_main, [0 500]);
    ylim(ax_main, [0.5 1]);
    
    grid(ax_main, 'off');
    box(ax_main, 'on');
    set(ax_main, 'FontSize', 15);
    hold(ax_main, 'off');
    
    %% 수동 범례 생성
    % 이 부분의 좌표는 Figure의 'Normalized' 단위입니다 (0~1 범위).
    % 범례 상자 시작 위치 (왼쪽 하단 기준)
    legend_box_x = 0.15; % x 시작
    legend_box_y = 0.17; % y 시작
    legend_box_width = 0.35; % 박스 가로 길이 (넉넉하게)
    legend_box_height = 0.15; % 박스 세로 길이
    % 아이콘 크기 및 간격 설정
    icon_width = 0.08; % 아이콘 (밴드) 가로 길이
    icon_height = 0.04; % 아이콘 (밴드) 세로 길이
    icon_line_width = 1; % 아이콘 내부 선 굵기
    text_offset = 0.01; % 아이콘과 텍스트 사이 간격
    entry_height = 0.04; % (신규) 텍스트 상자 높이
    text_width = 0.3; % 텍스트 상자 가로 길이 (넉넉하게)
    line_spacing = 0.06; % 각 범례 항목 줄 간격 (넉넉하게)
    % 범례 배경 박스 그리기
    annotation('rectangle', [legend_box_x, legend_box_y, legend_box_width, legend_box_height], ...
               'Color', 'k', 'LineWidth', 0.5, 'FaceColor', 'w');
    % --- Tubular Cell 범례 항목 ---
    % 첫 번째 항목의 Y위치 (아래쪽 기준)
    tub_entry_y = legend_box_y + legend_box_height - 0.07; % 상단 여백을 두고 시작
    icon_x = legend_box_x + 0.02; % 아이콘 x 위치
    % 밴드 아이콘 (entry_height 안에서 세로 중앙 정렬)
    tub_icon_y = tub_entry_y + (entry_height - icon_height) / 2;
    annotation('rectangle', [icon_x, tub_icon_y, icon_width, icon_height], ...
               'FaceColor', color_tub_band, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
    % 중앙 실선 아이콘 (entry_height 안에서 세로 중앙 정렬)
    annotation('line', [icon_x, icon_x + icon_width], ...
               [tub_entry_y + entry_height/2, tub_entry_y + entry_height/2], ...
               'Color', color_tub_line, 'LineWidth', icon_line_width);
    % 텍스트 레이블 (높이를 entry_height로 설정)
    annotation('textbox', [icon_x + icon_width + text_offset, tub_entry_y, text_width, entry_height], ...
               'String', 'Tubular Cell', 'EdgeColor', 'none', ...
               'FontSize', 14, 'VerticalAlignment', 'middle');
    % --- Cylindrical Cell 범례 항목 ---
    % 두 번째 항목의 Y위치
    cyl_entry_y = tub_entry_y - line_spacing; % 이전 항목에서 line_spacing만큼 아래
    % 밴드 아이콘
    cyl_icon_y = cyl_entry_y + (entry_height - icon_height) / 2;
    annotation('rectangle', [icon_x, cyl_icon_y, icon_width, icon_height], ...
               'FaceColor', color_cyl_band, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
    % 중앙 실선 아이콘
    annotation('line', [icon_x, icon_x + icon_width], ...
               [cyl_entry_y + entry_height/2, cyl_entry_y + entry_height/2], ...
               'Color', color_cyl_line, 'LineWidth', icon_line_width);
    % 텍스트 레이블
    annotation('textbox', [icon_x + icon_width + text_offset, cyl_entry_y, text_width, entry_height], ...
               'String', 'Cylindrical Cell', 'EdgeColor', 'none', ...
               'FontSize', 14, 'VerticalAlignment', 'middle');
    % --- 수동 범례 생성 끝 ---

    %% 2C일 때만 인셋 플롯 추가
    if strcmp(c_rate, '2C')
        fprintf('2C 조건이므로 인셋 플롯을 추가합니다...\n');
        % 1. 인셋 플롯을 그릴 새로운 axes 객체 생성
        % 'Position'은 [left, bottom, width, height] (Normalized 단위, 0~1)
        ax_inset = axes('Position', [0.33, 0.4, 0.38, 0.38]); 
        hold(ax_inset, 'on'); 
        
        % 2. 확대할 데이터 필터링 (범위: Cycle 200에서 300 사이)
        % (데이터가 존재하는지 먼저 확인)
        if exist('cycle_count_tub', 'var') && ~isempty(cycle_count_tub)
            idx_inset_tub = cycle_count_tub >= 200 & cycle_count_tub <= 300;
            % 3. 인셋 플롯에 튜블러 데이터 그리기
            if ~isempty(cycle_count_tub(idx_inset_tub))
                fill(ax_inset, [cycle_count_tub(idx_inset_tub)', fliplr(cycle_count_tub(idx_inset_tub)')], ...
                     [retention_tub_max(idx_inset_tub)', fliplr(retention_tub_min(idx_inset_tub)')], ...
                     color_tub_band, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
                plot(ax_inset, cycle_count_tub(idx_inset_tub), retention_tub_avg(idx_inset_tub), ...
                     'Color', color_tub_line, 'LineWidth', 1);
            end
        end
        
        if exist('cycle_count_cyl', 'var') && ~isempty(cycle_count_cyl)
            idx_inset_cyl = cycle_count_cyl >= 200 & cycle_count_cyl <= 300;
            % 4. 인셋 플롯에 원통형 데이터 그리기
            if ~isempty(cycle_count_cyl(idx_inset_cyl))
                fill(ax_inset, [cycle_count_cyl(idx_inset_cyl)', fliplr(cycle_count_cyl(idx_inset_cyl)')], ...
                     [retention_cyl_max(idx_inset_cyl)', fliplr(retention_cyl_min(idx_inset_cyl)')], ...
                     color_cyl_band, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
                plot(ax_inset, cycle_count_cyl(idx_inset_cyl), retention_cyl_avg(idx_inset_cyl), ...
                     'Color', color_cyl_line, 'LineWidth', 1);
            end
        end
        
        % 5. 인셋 플롯의 축 설정
        set(ax_inset, 'XLim', [200 300], 'YLim', [0.94 0.98], 'FontSize', 10); 
        box(ax_inset, 'on'); 
        grid(ax_inset, 'off'); 
        hold(ax_inset, 'off');
    end
    
    %% 데이터 범위 확인 출력
    if exist('retention_tub_avg', 'var') && exist('retention_cyl_avg', 'var') && ~isempty(retention_tub_avg) && ~isempty(retention_cyl_avg)
        fprintf('그래프 X축 범위: [%.2f, %.2f]\n', min([cycle_count_tub; cycle_count_cyl]), max([cycle_count_tub; cycle_count_cyl]));
        fprintf('그래프 Y축 범위: [%.4f, %.4f]\n', ...
            min([retention_tub_avg; retention_cyl_avg]), max([retention_tub_avg; retention_cyl_avg]));
    elseif exist('retention_tub_avg', 'var') && ~isempty(retention_tub_avg)
         fprintf('그래프 X축 범위: [%.2f, %.2f]\n', min(cycle_count_tub), max(cycle_count_tub));
         fprintf('그래프 Y축 범위: [%.4f, %.4f]\n', min(retention_tub_avg), max(retention_tub_avg));
    elseif exist('retention_cyl_avg', 'var') && ~isempty(retention_cyl_avg)
         fprintf('그래프 X축 범위: [%.2f, %.2f]\n', min(cycle_count_cyl), max(cycle_count_cyl));
         fprintf('그래프 Y축 범위: [%.4f, %.4f]\n', min(retention_cyl_avg), max(retention_cyl_avg));
    end
    
    disp('그래프 생성이 완료되었습니다. Figure 창을 확인해주세요.');
    
    %% 그래프 저장
    full_save_path = fullfile(save_base_path, save_filename); % C-rate에 맞는 파일명
    if ~exist(save_base_path, 'dir')
        mkdir(save_base_path);
    end
    exportgraphics(gcf, full_save_path, 'Resolution', 300);
    fprintf('그래프가 성공적으로 저장되었습니다: %s\n', full_save_path);

end % --- C-rate 루프 종료 ---

fprintf('\n\n모든 C-rate 개별 그래프 생성이 완료되었습니다.\n');
fprintf('이제 최종 이미지 병합을 시작합니다...\n\n');

%% ==========================================================
%  파트 2: (a), (b) 라벨링 및 최종 병합
%  ==========================================================

%% --- 1. 파일 경로 및 설정 ---
% PNG 파일이 저장된 폴더 (파트 1의 'save_base_path' 변수 재사용)
path_png = save_base_path; 

% (a)로 지정될 상단 이미지 (파트 1에서 생성된 파일명 동적 할당)
file_a = generated_files{1}; % 'figure5_2C.png'
% (b)로 지정될 하단 이미지 (파트 1에서 생성된 파일명 동적 할당)
file_b = generated_files{2}; % 'figure5_6C.png'

% 이미지 사이 여백 (픽셀)
padding_height_pixels = 120; 
% 상단 여백 추가 (라벨이 잘리지 않도록)
padding_top_pixels = 100; 
% 저장될 최종 파일명
file_combined_out = 'figure5(2).png';

%% --- 2. 이미지 불러오기 ---
fprintf('"%s" 와 "%s" 파일을 불러옵니다...\n', file_a, file_b);
img_a = imread(fullfile(path_png, file_a));
img_b = imread(fullfile(path_png, file_b));

%% --- 3. (선택적) 이미지 너비 통일 ---
[h_a, w_a, c_a] = size(img_a); 
[h_b, w_b, ~] = size(img_b);

if w_a ~= w_b
    disp('이미지 너비가 다릅니다. 더 작은 너비로 통일합니다.');
    target_width = min(w_a, w_b);
    img_a = imresize(img_a, [NaN, target_width]);
    img_b = imresize(img_b, [NaN, target_width]);
    % 리사이즈 후 크기 다시 가져오기
    [h_a, w_a, c_a] = size(img_a);
    [h_b, ~, ~] = size(img_b);
    disp('리사이즈 완료.');
else
    disp('이미지 너비가 동일합니다.');
end

%% --- 4. 여백 생성 및 이미지 수직으로 합치기 ---
% 상단 여백 매트릭스 생성
img_padding_top = 255 * ones(padding_top_pixels, w_a, c_a, class(img_a));
% 중간 여백 매트릭스 생성
img_padding = 255 * ones(padding_height_pixels, w_a, c_a, class(img_a));
% A와 B를 세로로 쌓습니다. (상단여백 - A - 중간여백 - B)
img_combined = [img_padding_top; img_a; img_padding; img_b];

%% --- 5. 합쳐진 이미지 표시 및 라벨 추가 ---
fig = figure;
imshow(img_combined); 
axis off; 
hold on;

% --- 라벨 위치 및 스타일 설정 ---
x_pos = -40;           
y_pos_offset = -90;   
label_fontsize = 24;  
label_fontweight = 'bold'; 

% 'a' 라벨 추가
text(x_pos, padding_top_pixels + y_pos_offset, 'a', ...
    'FontSize', label_fontsize, 'FontWeight', label_fontweight, 'Color', 'k', ...
    'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');

% 'b' 라벨 추가
text(x_pos, padding_top_pixels + h_a + padding_height_pixels + y_pos_offset, 'b', ...
    'FontSize', label_fontsize, 'FontWeight', label_fontweight, 'Color', 'k', ...
    'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
hold off;

%% --- 6. 최종 이미지 저장 ---
fprintf('합성된 이미지를 저장하는 중...\n');
% Figure 창의 불필요한 회색 여백을 모두 제거하고 이미지만 꽉 채웁니다.
set(gca, 'Position', [0 0 1 1]);
% 최종 저장 경로
full_save_path = fullfile(path_png, file_combined_out);
% Figure를 PNG 파일로 저장
exportgraphics(fig, full_save_path, 'Resolution', 300);

fprintf('\n==========================================\n');
fprintf('>>>>>> 최종 병합 파일 저장 완료 <<<<<<\n');
fprintf('저장 위치: %s\n', full_save_path);
fprintf('==========================================\n');