clear; clc; close all;

%% ───────────── 데이터 로드 ─────────────
data_dir = 'C:\Users\user\Desktop\Figure\Supple Figure\중간 데이터';
load(fullfile(data_dir,'S6.mat'),"allResults");       % 구조체 배열 3×1
T_initial_values = [allResults.T_init];               % [25 30 40]

timeVec = allResults(1).time_min(:)';                 % 공통 시간
max_time = max(timeVec);
nCells   = size(allResults(1).I_cell,2);

%% ───────────── 색상, 해상도, 저장 경로 설정 ─────────────
color_V = [0.5725, 0.3686, 0.6235];
color_I = [0.9373, 0.7529, 0.0000];     

lw = 1.5;
target_wh = [1218 1544];  % 출력 해상도
step = 1;
video_dir = 'C:\Users\user\Desktop\Figure\Figure 5\video 파일';
if ~exist(video_dir, 'dir'), mkdir(video_dir); end

%% ───────────── 각 T_initial 값에 대해 반복 저장 ─────────────
for idx = 1:numel(T_initial_values)
    T0 = T_initial_values(idx);
    V_all = allResults(idx).E_cell;       % 전압 (N x Cells)
    I_all = allResults(idx).I_cell;       % 전류(C-rate)

    I_all(I_all==0) = NaN;  % 0은 표시 생략

    % Figure 설정
    fig = figure('Visible','off'); hold on; box on;

    % ─ 좌측 y축 : Voltage
    yyaxis left
    ylabel('Voltage [V]','FontSize',15,'Color','k');
    ylim([3.4 4.2]); set(gca,'YColor','k');

    % ─ 우측 y축 : C-rate
    yyaxis right
    ylabel('C-rate','FontSize',15,'Color','k');
    ylim([0 12]); set(gca,'YColor','k');

    % ─ 공통
    xlabel('Time [min]','FontSize',15);
    xlim([0 max_time]);
    set(gca,'FontSize',15);
    
    % Patch
    yyaxis left
    patch_V = fill(NaN,NaN,color_V,'FaceAlpha',1,'EdgeColor','none');
    yyaxis right
    patch_I = fill(NaN,NaN,color_I,'FaceAlpha',1,'EdgeColor','none');

    % Animated line
    for c = 1:nCells
        yyaxis left
        line_V(c) = animatedline('Color',color_V,'LineWidth',lw);
        yyaxis right
        line_I(c) = animatedline('Color',color_I,'LineWidth',lw);
    end

    % Legend
    yyaxis left
    hV = plot(NaN,NaN,'Color',color_V,'LineWidth',lw, 'LineStyle', '-');
    yyaxis right
    hI = plot(NaN,NaN,'Color',color_I,'LineWidth',lw, 'LineStyle', '-');
    legend([hV hI], {sprintf('V_{pack}'), sprintf('I_{pack}')}, ...
           'Location','southeast','NumColumns',2,'Orientation','horizontal','FontSize',12);

    % 비디오 저장 설정
    video_path = fullfile(video_dir, sprintf('figure5_VI_%d.mp4',T0));
    vobj = VideoWriter(video_path,'MPEG-4');
    vobj.FrameRate = 9; open(vobj);

    tmp_png = [tempname,'.png'];  % 임시 이미지

    % ─ 프레임 루프
    for k = 1:step:numel(timeVec)
        t = timeVec(k);

        % patch
        V_max = max(V_all(1:k,:),[],2,'omitnan');
        V_min = min(V_all(1:k,:),[],2,'omitnan');
        yyaxis left
        set(patch_V,'XData',[timeVec(1:k) fliplr(timeVec(1:k))], ...
                    'YData',[V_max' fliplr(V_min')]);

        I_max = max(I_all(1:k,:),[],2,'omitnan');
        I_min = min(I_all(1:k,:),[],2,'omitnan');
        yyaxis right
        set(patch_I,'XData',[timeVec(1:k) fliplr(timeVec(1:k))], ...
                    'YData',[I_max' fliplr(I_min')]);

        % line
        for c = 1:nCells
            yyaxis left
            addpoints(line_V(c),t,V_all(k,c));
            yyaxis right
            addpoints(line_I(c),t,I_all(k,c));
        end

        drawnow;

        print(fig,'-dpng','-r300','-loose',tmp_png);
        frame_img = imresize(imread(tmp_png),target_wh);
        writeVideo(vobj,frame_img);
    end

    close(vobj); close(fig); delete(tmp_png);
    disp(['저장 완료: ', video_path]);
end
