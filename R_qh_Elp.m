clear; clc; close all;

% Initiate COMSOL
import com.comsol.model.*
import com.comsol.model.util.*

COM_filepath = '/Users/yoorim/Desktop';
COM_filename = 'JYR_1cell_isothermal.mph';
model = mphload(fullfile(COM_filepath, COM_filename));
ModelUtil.showProgress(true);

% Parameters
T_vec = [10 20 30 40 50 70 80 90];      % degC
I_vec = [0.1 0.5 1 2 4 6 8 10 12];      % C-rate

% Output
data_table = table();
I_cc_matrix = zeros(length(T_vec), length(I_vec));

% Current conversion
i_1C_1D = 46.022;  % A/m^2
A_jr    = 0.74471; % m^2

for i = 1:length(T_vec)
    for j = 1:length(I_vec)

        T = T_vec(i);
        I = I_vec(j);

        % Set parameters in COMSOL model
        model.param.set('T0', sprintf('%g[degC]', T));
        model.param.set('C_rate', sprintf('%g', I));

        % Run COMSOL study
        model.study('std1').run;

        % Extract data
        SOC = mphglobal(model, 'SOC');      SOC = SOC(:);
        OCV = mphglobal(model, 'OCV');      OCV = OCV(:);
        V   = mphglobal(model, 'E_cell');   V   = V(:);
        qh  = mphglobal(model, 'q_h');      qh  = qh(:);
        Elp = mphglobal(model, 'E_lp');     Elp = Elp(:);

        % Convert C-rate to actual current
        I_cc = I * i_1C_1D * A_jr;
        I_cc_matrix(i, j) = I_cc;

        % R(t)
        R = (V - OCV) ./ I_cc;

        % make SOC unique
        [SOC_u, ia] = unique(SOC, 'stable');  % keep first occurrence
        R_u   = R(ia);
        qh_u  = qh(ia);
        Elp_u = Elp(ia);

        good = isfinite(SOC_u) & isfinite(R_u) & isfinite(qh_u) & isfinite(Elp_u);
        SOC_u = SOC_u(good); R_u = R_u(good); qh_u = qh_u(good); Elp_u = Elp_u(good);

        % If SOC is not strictly increasing (rare but possible), sort it
        if any(diff(SOC_u) <= 0)
            [SOC_u, ord] = sort(SOC_u);
            R_u   = R_u(ord);
            qh_u  = qh_u(ord);
            Elp_u = Elp_u(ord);
        end

        % build SOC_vec
        SOC_end = SOC_u(end);

        SOC_vec = [0:0.01:0.1, 0.15:0.05:SOC_end];
        if SOC_vec(end) < SOC_end
            SOC_vec = [SOC_vec, SOC_end];
        end
        SOC_vec = SOC_vec(:);

        SOC_vec = unique(SOC_vec, 'stable');

        % Interpolate
        R_vec   = interp1(SOC_u, R_u,   SOC_vec, 'linear', 'extrap');
        qh_vec  = interp1(SOC_u, qh_u,  SOC_vec, 'linear', 'extrap');
        Elp_vec = interp1(SOC_u, Elp_u, SOC_vec, 'linear', 'extrap');

        % Append to table
        n = numel(SOC_vec);
        data_table = [data_table;
            table(T*ones(n,1), I*ones(n,1), SOC_vec, R_vec, qh_vec, Elp_vec, ...
            'VariableNames', {'T','I','SOC','R','q_h','E_lp'})];
    end
end

writetable(data_table, 'R_qh_Elp(SOC_T_I).txt', 'Delimiter', '\t');
