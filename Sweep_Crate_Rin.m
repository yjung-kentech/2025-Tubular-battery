clear; clc; close all

% Initiate COMSOL
import com.comsol.model.*
import com.comsol.model.util.*

%% Inputs
COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'JYR_cell_0909.mph'; % Tubular, Cylinder
COM_fullfile = fullfile(COM_filepath, COM_filename);

result_dir = 'C:\Users\user\Desktop\Figure\Sweep\mat 파일';
result_filename = 'Tubular_Sweep_Crate_Rin_46.mat'; % 46, 60, 80
result_fullfile = fullfile(result_dir, result_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

%% Sweep
R_out = 23; % 23, 30, 40

C_rate_vec = [1:0.2:8, 8.5:0.5:12]; % 데이터 44개
R_in_vec = 1:10;
N = length(C_rate_vec);
M = length(R_in_vec);

% Load progress information if available
if exist(result_filename, 'file')
    load(result_filename, 'data');
    resume_flag = true;
else
    data.C_rate = C_rate_vec;
    data.R_in = R_in_vec;
    data.T_max_total = cell(N, M);
    data.T_avg_total = cell(N, M);
    data.Elp_avg_total = cell(N, M);
    data.Elp_min_total = cell(N, M);
    data.SOC = cell(N, M);
    data.t = cell(N, M);

    data.T_max = zeros(N, M);
    data.T_avg = zeros(N, M);
    data.Elp_avg = zeros(N, M);
    data.Elp_min = zeros(N, M);
    data.t95 = zeros(N, M);

    data.last_i = 1;
    data.last_j = 1;
    resume_flag = false;
end

tic1 = tic;

for i = data.last_i:N
    current_C_rate = C_rate_vec(i);
         
    for j = data.last_j:M
        current_R_in = R_in_vec(j);

        fprintf('Current case: %u / %u, and %u / %u. \n', i, N, j, M)

        tic2 = tic;

        R_out_str = [num2str(R_out) '[mm]'];
        R_in_str = [num2str(current_R_in) '[mm]'];
        model.param.set('C_rate', current_C_rate);
        model.param.set('R_out', R_out_str);
        model.param.set('R_in', R_in_str);

        model.study('std1').run

        t_cal = toc(tic2);

        data.T_max_total{i, j} = mphglobal(model, 'T_max', 'unit', 'degC');
        data.T_avg_total{i, j} = mphglobal(model, 'T_avg', 'unit', 'degC');
        data.Elp_avg_total{i, j} = mphglobal(model, 'comp1.E_lp');
        data.Elp_min_total{i, j} = mphglobal(model, 'comp3.E_lp');

        data.T_max(i, j) = max(mphglobal(model, 'T_max', 'unit', 'degC'));
        data.T_avg(i, j) = max(mphglobal(model, 'T_avg', 'unit', 'degC'));
        data.Elp_avg(i, j) = min(mphglobal(model, 'comp1.E_lp'));
        data.Elp_min(i, j) = min(mphglobal(model, 'comp3.E_lp'));

        [data.SOC{i,j}, unique_idx] = unique(mphglobal(model, 'SOC'));
        t_values = mphglobal(model, 't', 'unit', 'min');

        data.t{i, j} = t_values(unique_idx);

        data.t95(i, j) = interp1(data.SOC{i, j}, data.t{i, j}, 0.95);

        fprintf('Done; the last case took %3.1f seconds. Completed %u out of %u cases (%3.1f%%). \n', ...
            t_cal, (i - 1) * M + j, N * M, round(100 * ((i - 1) * M + j) / (N * M)))

        fprintf('Elp_avg: %f, Elp_min: %f, T_max: %f, T_avg: %f at time %f minutes.\n', data.Elp_avg(i, j), data.Elp_min(i, j), data.T_max(i, j), data.T_avg(i, j), data.t95(i, j));

        % Update last_i and last_j for resuming
        data.last_i = i;
        data.last_j = j + 1;

        save(result_fullfile, 'data');
    end

    data.last_j = 1; % Reset last_j for the next iteration
end

t_total = toc(tic1);
fprintf('\n\n\n\nTotal calculation time is %4.3f hours.\n\n', t_total / 3600)
