clear; clc; close all

% Initiate comsol
import com.comsol.model.*
import com.comsol.model.util.*

%% Inputs
COM_filepath = 'C:\Users\user\Desktop\Tubular battery 최종';
COM_filename = 'JYR_cylinder_cell_1223.mph'; % JYR_cell_1223
COM_fullfile = fullfile(COM_filepath, COM_filename);

result_dir = 'C:\Users\user\Desktop\Figure\Sweep\mat 파일';
% result_filename = 'Tubular_Sweep_Crate_Rout.mat';
result_filename = 'Cylinder_Sweep_Crate_Rout.mat';
result_fullfile = fullfile(result_dir, result_filename);

model = mphload(COM_fullfile);
ModelUtil.showProgress(true);

% mphnavigator;

%% Sweep

C_rate_vec = [1:0.2:8, 8.5:0.5:12]; % 데이터 44개
R_out_vec = 5:1:40; % 데이터 36개
L_vec = R_out_vec; % 원통형 셀에서만 필요
N = length(C_rate_vec);
M = length(R_out_vec);

% Load progress information if available
if exist(result_filename, 'file')
    load(result_filename, 'data');
    resume_flag = true;
else
    data.C_rate = C_rate_vec;
    data.R_out = R_out_vec;
    data.T_max_total = cell(N, M);
    data.T_avg_total = cell(N, M);
    data.Elp_avg_total = cell(N, M);
    data.Elp_min_total = cell(N, M);
    data.SOC = cell(N, M);
    data.t = cell(N, M);

    data.T_max = NaN(N, M);
    data.T_avg = NaN(N, M);
    data.Elp_avg = NaN(N, M);
    data.Elp_min = NaN(N, M);
    data.t95 = NaN(N, M);

    data.last_i = 1;
    data.last_j = 1;
    resume_flag = false;
end

tic1 = tic;

for i = data.last_i:N
    current_C_rate = C_rate_vec(i);

    for j = data.last_j:M
        current_R_out = R_out_vec(j);
        current_L = L_vec(j); % 원통형 셀에서만 필요

        fprintf('Current case: %u / %u and %u / %u. \n', i, N, j, M)

        tic2 = tic;

        try
            R_out_str = [num2str(current_R_out) '[mm]'];
            model.param.set('C_rate', current_C_rate);
            model.param.set('R_out', R_out_str);
            model.param.set('L', current_L); % 원통형 셀에서만 필요

            model.study('std1').run

            % If simulation is successful, extract results
            data.T_max_total{i, j} = mphglobal(model, 'T_max', 'unit', 'degC');
            data.T_avg_total{i, j} = mphglobal(model, 'T_avg', 'unit', 'degC');
            data.Elp_avg_total{i, j} = mphglobal(model, 'comp1.E_lp');
            data.Elp_min_total{i, j} = mphglobal(model, 'comp3.E_lp');

            data.T_max(i, j) = max(mphglobal(model, 'T_max', 'unit', 'degC'));
            data.T_avg(i, j) = max(mphglobal(model, 'T_avg', 'unit', 'degC'));
            data.Elp_avg(i, j) = min(mphglobal(model, 'comp1.E_lp'));
            data.Elp_min(i, j) = min(mphglobal(model, 'comp3.E_lp'));

            [data.SOC{i, j}, unique_idx] = unique(mphglobal(model, 'SOC'));
            t_values = mphglobal(model, 't', 'unit', 'min');

            data.t{i, j} = t_values(unique_idx);

            data.t95(i, j) = interp1(data.SOC{i, j}, data.t{i, j}, 0.95);

            fprintf('Done; the last case took %3.1f seconds. Completed %u out of %u cases (%3.1f%%). \n',...
                toc(tic2), (i - 1) * M + j, N * M, round(100 * ((i - 1) * M + j) / (N * M)))

            fprintf('Elp_avg: %f, Elp_min: %f, T_max: %f, T_avg: %f at time %f minutes.\n',  ...
                data.Elp_avg(i, j), data.Elp_min(i, j), data.T_max(i, j), data.T_avg(i, j), data.t95(i, j));

        catch ME
            % Handle the error: log it and assign NaN or a specific value
            fprintf('Error encountered at case i=%u, j=%u: %s\n', i, j, ME.message);

            % Option 1: Assign NaN to indicate failure
            data.T_max(i, j) = NaN;
            data.T_avg(i, j) = NaN;
            data.Elp_avg(i, j) = NaN;
            data.Elp_min(i, j) = NaN;
            data.t95(i, j) = NaN;

            % Option 2: Store the error message (optional)
            % data.ErrorMessage{i, j} = ME.message;

            % Optionally, you can log the failed cases
            if ~isfield(data, 'FailedCases')
                data.FailedCases = {};
            end
            data.FailedCases{end+1, 1} = i;
            data.FailedCases{end, 2} = j;
            data.FailedCases{end, 3} = ME.message;
        end

        % Update last_i and last_j for resuming
        data.last_i = i;
        data.last_j = j + 1;

        save(result_fullfile, 'data');

    end
    data.last_j = 1; % Reset last_j for the next iteration
end

t_total = toc(tic1);
fprintf('\n\n\n\nTotal calculation time is %4.3f hours.\n\n', t_total / 3600)
