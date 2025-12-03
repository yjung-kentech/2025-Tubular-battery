clear; clc; close all;

data_load_path  = 'C:\Users\user\Desktop\Figure\Figure 5\중간 데이터';
video_save_dir  = 'C:\Users\user\Desktop\Figure\Figure 5\video 파일\';

T_initial_values = [25 30 40]; % °C
fps   = 10;
step  = 1;

% 색상 고정 (요청하신 RGB)
color_Tmax = [0.8039 0.3255 0.2980];
color_Tavg = [0.0000 0.4500 0.7608];
lw = 1;

% 해상도 설정
target_width  = 1544;
target_height = 1218;
tmp_png = [tempname,'.png'];

for idx = 1:numel(T_initial_values)
    T0 = T_initial_values(idx);

    % 데이터 로드
    load(fullfile(data_load_path, ...
        sprintf('cell_temp_difference_Tinit_%d.mat',T0)), ...
        'timeVec','Tavg_all','Tmax_all');

    Tmax_all(:,1) = T0;
    Tavg_all(:,1) = T0;
    max_time = max(timeVec);

    % Figure 설정
    fig = figure('Position',[100 100 560*0.9 420*0.9]);
    hold on; box on;
    xlabel('Time [min]','FontSize',15);
    ylabel('Temperature [°C]','FontSize',15);
    ax = gca; ax.FontSize = 15;

    patch_Tmax = fill(NaN,NaN,color_Tmax,'FaceAlpha',1,'EdgeColor','none');
    patch_Tavg = fill(NaN,NaN,color_Tavg,'FaceAlpha',1,'EdgeColor','none');

    for iCell = 1:size(Tmax_all,1)
        line_Tmax(iCell) = animatedline('Color',color_Tmax,'LineWidth',lw);
        line_Tavg(iCell) = animatedline('Color',color_Tavg,'LineWidth',lw);
    end

    legend([plot(NaN,NaN,'Color',color_Tmax,'LineWidth',lw), ...
            plot(NaN,NaN,'Color',color_Tavg,'LineWidth',lw)], ...
           {sprintf('T_{max}'), sprintf('T_{avg}')}, ...
           'Location','southeast','FontSize',11,'NumColumns',2,'Orientation','horizontal');

    xlim([0 max_time]);

    min_temp = min([min(Tavg_all(:),[],'omitnan'), min(Tmax_all(:),[],'omitnan')]);
    ylim([min_temp 45]);

    % Video 설정
    video_save_path = fullfile(video_save_dir, sprintf('figure5_temp_%d.mp4',T0));
    v = VideoWriter(video_save_path,'MPEG-4');
    v.FrameRate = fps;
    v.Quality   = 100;
    open(v);

    % 프레임 루프
    for k = 1:step:numel(timeVec)
        Tmax_max = max(Tmax_all(:,1:k),[],1,'omitnan');
        Tmax_min = min(Tmax_all(:,1:k),[],1,'omitnan');
        Tavg_max = max(Tavg_all(:,1:k),[],1,'omitnan');
        Tavg_min = min(Tavg_all(:,1:k),[],1,'omitnan');

        set(patch_Tmax,'XData',[timeVec(1:k) fliplr(timeVec(1:k))], ...
                       'YData',[Tmax_max fliplr(Tmax_min)]);
        set(patch_Tavg,'XData',[timeVec(1:k) fliplr(timeVec(1:k))], ...
                       'YData',[Tavg_max fliplr(Tavg_min)]);

        for iCell = 1:size(Tmax_all,1)
            addpoints(line_Tmax(iCell),timeVec(k),Tmax_all(iCell,k));
            addpoints(line_Tavg(iCell),timeVec(k),Tavg_all(iCell,k));
        end

        drawnow;
        print(fig,'-dpng','-r300','-loose',tmp_png);
        frame_img = imread(tmp_png);
        frame_img = imresize(frame_img,[target_height target_width]);
        writeVideo(v,frame_img);
    end

    close(v);
    close(fig);
    disp(['영상 저장 완료: ', video_save_path]);
end

delete(tmp_png);
