clear; clc; close all;

%%  Part 1: 환경 설정 및 스타일 정의

% 1. 기본 경로 및 파일 설정
data_dir = 'G:\공유 드라이브\Battery Software Group (2025)\Members\정유림\Tubular battery\mat 파일';
save_dir = 'C:\Users\user\Desktop\Figure\Figure 3\png 파일'; % 사용자 데스크탑 경로
mat_files = {'contour_cyl.mat', 'contour_tube.mat'};

% 2. 색상맵 라이브러리 로드
load('G:\공유 드라이브\Battery Software Group (2025)\Members\정유림\Tubular battery\mat 파일\slanCM_Data.mat');

% 3. 스타일 순서 정의
plot_types       = {'Tmax', 'Elp', 't95'};
style_cmap_names = {'Reds', 'Blues', 'Greens'}; % 원하는 색상으로 변경!!

cmap_properties = [
    struct('flip', false, 'gamma', 1.0),  % ('Reds')의 속성
    struct('flip', true,  'gamma', 1.0),  % ('Blues')의 속성
    struct('flip', false, 'gamma', 1.8)   % ('Greens')의 속성
];

style_cb_labels  = {'T_{max} [^oC]', 'η_{n} [V]', 't_{chg} [min]'}; % 컬러바 라벨
style_lines      = {{'Tmax'}, {'Elp'}, {'Tmax', 'Elp'}};
style_lgd_texts  = {{'T_{max} = 45 ^oC'}, {'η_{n} = 0 V'}, {'T_{max} = 45 ^oC', 'η_{n} = 0 V'}};

% 4. 정의된 스타일에 따라 색상맵 자동 준비
fprintf('사용할 색상맵을 준비합니다...\n');
colormaps = containers.Map;
type_idx = find(strcmp({slandarerCM.Type}, 'SequentialP')); % 타입 변경!!

for i = 1:length(style_cmap_names)
    cmap_name = style_cmap_names{i};
    properties = cmap_properties(i);

    name_idx = find(strcmp(slandarerCM(type_idx).Names, cmap_name));
    
    cmap = slandarerCM(type_idx).Colors{name_idx};
    if properties.flip, cmap = flipud(cmap); end
    cmap = cmap .^ properties.gamma;
    
    colormaps(cmap_name) = cmap;
end
fprintf('색상맵 준비 완료.\n\n');


%% 아래는 이미지 저장 코드 (변경 X)

%% Part 2: 개별 플롯 생성 및 저장

if ~exist(save_dir, 'dir'), mkdir(save_dir), end
png_files = {}; 

for k = 1:length(mat_files)
    file = mat_files{k};
    fprintf('그래프 생성 중: %s\n', file);
    load(fullfile(data_dir, file));
    
    if contains(file, 'cyl'), prefix = 'Cyl'; else, prefix = 'Tube'; end
    
    configs = {
        struct('data', T_smooth, 'clim', [min(T_smooth(:)), 100]),
        struct('data', Elp_smooth, 'clim', [min(Elp_smooth(:)), max(Elp_smooth(:))]),
        struct('data', t95_smooth, 'clim', [5, 40])
    };
    
    for i = 1:length(configs)
        cfg = configs{i};
        
        plot_type = plot_types{i};
        cmap_name = style_cmap_names{i};
        cb_label  = style_cb_labels{i};
        lines     = style_lines{i};
        lgd_text  = style_lgd_texts{i};
        
        fig = figure('Visible', 'off', 'Position', [100, 100, 800, 600]);
        cmap = colormaps(cmap_name);
        
        contourf(d_out_hr, c_rate_hr, cfg.data, 20, 'LineColor', 'none');
        clim(cfg.clim); colormap(cmap); cb = colorbar;
        ylabel(cb, cb_label, 'FontSize', 20);
        hold on;
        
        contourf(d_out_hr, c_rate_hr, double(isnan(cfg.data)), [0.5 1.5], 'FaceColor', [0.5 0.5 0.5], 'LineColor', 'none');
        
        x = 46; y = 6;
        xline(x, '--w', 'LineWidth', 1); yline(y, '--w', 'LineWidth', 1);
        plot(x, y, 'o', 'MarkerEdgeColor', '#EFC000', 'MarkerFaceColor', '#EFC000');
        
        h_lines = []; t_max_val = 45; elp_val = 0;
        if any(strcmp(lines, 'Tmax')), [~, h] = contour(d_out_hr, c_rate_hr, T_smooth, [t_max_val, t_max_val], 'LineWidth', 2, 'LineColor', '#EE4C97'); h_lines = [h_lines, h]; end
        if any(strcmp(lines, 'Elp')), [~, h] = contour(d_out, c_rate, elp_orig, [elp_val, elp_val], 'LineWidth', 2, 'LineColor', '#4DBBD5'); h_lines = [h_lines, h]; end
        if ~isempty(h_lines), lgd = legend(h_lines, lgd_text, 'Location', 'northeast'); set(lgd, 'FontSize', 18, 'Color', [0.8, 0.8, 0.8], 'EdgeColor', 'black'); end
        
        xlabel('D_{out} [mm]'); ylabel('C-rate');
        ax = gca; ax.FontSize = 20; ax.Units = 'normalized'; ax.Position = [0.1, 0.2, 0.65, 0.7];
        box on; hold off;
        
        file_name = [prefix, '_', plot_type, '.png'];
        save_path = fullfile(save_dir, file_name);
        exportgraphics(fig, save_path, 'Resolution', 300);
        fprintf('  > 개별 그림 저장 완료: %s\n', file_name);
        
        png_files{end+1} = save_path;
        close(fig);
    end
end
fprintf('\n모든 개별 플롯 생성이 완료되었습니다.\n');

%%  Part 3: 생성된 패널 이미지 통합 및 최종 저장

fprintf('이제 생성된 이미지들을 하나로 통합합니다...\n');

save_path_combined = fullfile(save_dir, 'figure3_combined.png');

labels = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'};
fontSize = 18; dpi = 300; n_rows = 2; n_cols = 3;
v_spacing = -0.15; h_spacing = 0.025;
margin_top = 0.05; margin_bottom = 0.05; margin_left = 0.03; margin_right = 0.03;
panel_w = (1 - margin_left - margin_right - (n_cols-1)*h_spacing) / n_cols;
panel_h = (1 - margin_top - margin_bottom - (n_rows-1)*v_spacing) / n_rows;

fig = figure('Position', [50 50 1600 1000]);

for k = 1:length(png_files)
    row_idx = ceil(k / n_cols);
    col_idx = mod(k-1, n_cols) + 1;
    pos_x = margin_left + (col_idx-1)*(panel_w + h_spacing);
    pos_y = 1 - margin_top - row_idx*panel_h - (row_idx-1)*v_spacing;
    ax = axes('Position', [pos_x, pos_y, panel_w, panel_h]);
    imshow(imread(png_files{k}), 'Parent', ax);
    text(ax, 0, 1.1, labels{k}, 'FontSize', fontSize, 'FontWeight', 'bold', 'Color', 'k', 'BackgroundColor', 'w', 'Margin', 2, 'Units', 'normalized', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
end

exportgraphics(fig, save_path_combined, 'Resolution', dpi);

fprintf('통합 이미지 저장 완료: %s\n', save_path_combined);

close(fig);
