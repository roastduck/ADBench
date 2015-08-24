%%
exe_dir = 'C:/Users/t-filsra/Workspace/autodiff/Release/';
python_dir = 'C:/Users/t-filsra/Workspace/autodiff/Python/';
data_dir = 'C:/Users/t-filsra/Workspace/autodiff/gmm_instances/';
% data_dir = 'C:/Users/t-filsra/Workspace/autodiff/gmm_instances/10k/';
% npoints = 10000;

%% tools
executables = {...
    [exe_dir,'Manual_Eigen.exe'],...
    [exe_dir,'Manual_Eigen5.exe'],...
    [exe_dir,'Manual_VS.exe'],...
    [exe_dir,'Tapenade.exe'],...
    [exe_dir,'ADOLC_split.exe'],...
    [exe_dir,'ADOLC_full.exe'],...
    [exe_dir,'DiffSharpRSplit/DiffSharpTests.exe'],...
    [exe_dir,'DiffSharpR/DiffSharpTests.exe'],...
    [exe_dir,'DiffSharpAD/DiffSharpTests.exe'],...
    ['python.exe ' python_dir 'Autograd/autograd_split.py'],...
    ['python.exe ' python_dir 'Autograd/autograd_full.py'],...
    ['python.exe ' python_dir 'Theano/Theano.py'],...
    ['python.exe ' python_dir 'Theano/Theano_vector.py'],...
    [exe_dir,'Adept.exe'],...
    [exe_dir,'Ceres/Ceres'],...
    };
names = {...
    'J_manual',...
    'J_manual_Eigen5',...
    'J_manual_VS',...
    'J_Tapenade_b',...
    'J_ADOLC_split',...
    'J_ADOLC',...
    'J_diffsharpRsplit',...
    'J_diffsharpR',...
    'J_diffsharpAD',...
    'J_Autograd_split',...
    'J_Autograd',...
    'J_Theano',...
    'J_Theano_vector',...
    'J_Adept',...
    'J_Ceres',...
    };
nexe = numel(executables);
tools = {...
    'manual, Eigen',...
    'manual, Eigen5',...
    'manual, C++',...
    'Tapenade,R',...
    'ADOLC, R (split)',...
    'ADOLC, R',...
    'DiffSharp, R (split)',...
    'DiffSharp, R',...
    'DiffSharp',...
    'Autograd, R (split)',...
    'Autograd, R',...
    'Theano',...
    'Theano (vector)',...
    'Adept, R',...
    'Ceres, F',...
    'AdiMat, R',...
    'AdiMat, R (vector)',...
    'MuPAD'...
    };
ntools = numel(tools);
adimat_id = ntools-2;
adimat_vector_id = ntools-1;
mupad_id = ntools;

%% generate parameters and order them
d_all = [2 10 20 32 64];
k_all = [5 10 25 50 100 200];
params = {};
num_params = [];
for d = d_all
    icf_sz = d*(d + 1) / 2;
    for k = k_all
        num_params(end+1) = k + d*k + icf_sz*k;
        params{end+1} = [d k num_params(end)];
    end
end

[num_params, order] = sort(num_params);
params = params(order);
% ignore = [2 3 4 5 8 10];
% params = params(~ismember(1:numel(params),ignore));
for i=1:numel(params)
    disp(num2str(params{i}));
end

fns = {};
for i=1:numel(params)
    d = params{i}(1);
    k = params{i}(2);
    fns{end+1} = [data_dir 'gmm_d' num2str(d) '_K' num2str(k)];
end
ntasks = numel(params);
% save('params_gmm.mat','params');

%% write instances into files
addpath('awful/matlab')
for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    
    d = params{i}(1);
    k = params{i}(2);
    
    rng(1);
    paramsGMM.alphas = randn(1,k);
    paramsGMM.means = au_map(@(i) rand(d,1), cell(k,1));
    paramsGMM.means = [paramsGMM.means{:}];
    paramsGMM.inv_cov_factors = au_map(@(i) randn(d*(d+1)/2,1), cell(k,1));
    paramsGMM.inv_cov_factors = [paramsGMM.inv_cov_factors{:}];
    x = randn(d,npoints);
    hparams = [1 0];
    
    save_gmm_instance([fns{i} '.txt'], paramsGMM, x, hparams);
end

%% write script for running AD tools once
fnFrom = 'run_experiments.bat';
fid = fopen(fnFrom,'w');
for i=1:nexe
    if strcmp('Theano',tools{i})
        cmd = ['START /MIN /WAIT ' executables{i}];
        for j=1:ntasks
            cmd = [cmd ' ' fns{j} ' 1 1'];
        end
        fprintf(fid,[cmd '\r\n']);
    else
        for j=1:ntasks
            if strcmp('Ceres, F',tools{i})
                d = params{j}(1);
                k = params{j}(2);
                fprintf(fid,'START /MIN /WAIT %sd%ik%i.exe %s 1 1\r\n',...
                    executables{i},d,k,fns{j});
            else
                fprintf(fid,'START /MIN /WAIT %s %s 1 1\r\n',executables{i},fns{j});
            end
        end
    end
end
fclose(fid);

%% run experiments for time estimates
tic
system(fnFrom);
toc

%% adimat time estimate
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');
opt = admOptions('independents', [1 2 3],  'functionResults', {1});
times_est_adimat_f = Inf(2,ntasks);
times_est_adimat_J = Inf(2,ntasks);
admTransform(@gmm_objective, admOptions('m', 'r','independents', [1 2 3]));
admTransform(@gmm_objective_vector_repmat, admOptions('m', 'r','independents', [1 2 3]));
for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    d = params{i}(1);
    k = params{i}(2);
    [paramsGMM,x,hparams] = load_gmm_instance([fns{i} '.txt']);
    
    % "looped" objective
    tic
    fval = gmm_objective(paramsGMM.alphas,paramsGMM.means,...
        paramsGMM.inv_cov_factors,x,hparams);
    times_est_adimat_f(1,i) = toc;
    
    tic
    do_F_mode = false;
    do_adimat_vector=false;
    [J, fvalrev] = gmm_objective_adimat(do_F_mode,do_adimat_vector,...
        paramsGMM.alphas,paramsGMM.means,paramsGMM.inv_cov_factors,...
        x,hparams);
    times_est_adimat_J(1,i) = toc;
    disp(times_est_adimat_J(1,i))
    
    % "vectorized" objective
    tic
    fval = gmm_objective_vector_repmat(paramsGMM.alphas,paramsGMM.means,...
        paramsGMM.inv_cov_factors,x,hparams);
    times_est_adimat_f(2,i) = toc;
    
    tic
    do_F_mode = false;
    do_adimat_vector=true;
    [J, fvalrev] = gmm_objective_adimat(do_F_mode,do_adimat_vector,...
        paramsGMM.alphas,paramsGMM.means,paramsGMM.inv_cov_factors,...
        x,hparams);
    times_est_adimat_J(2,i) = toc;    
    disp(times_est_adimat_J(2,i))
end

%% read time estimates
times_est_J = Inf(ntasks,ntools);
times_est_f = Inf(ntasks,ntools);
for i=1:ntasks
    for j=1:nexe
        fnFrom = [fns{i} names{j} '_times.txt'];
        if exist(fnFrom,'file')
            fid = fopen(fnFrom);
            times_est_f(i,j) = fscanf(fid,'%lf',1);
            times_est_J(i,j) = fscanf(fid,'%lf',1);
            fclose(fid);
        end
    end
end
times_est_J(:,adimat_id) = times_est_adimat_J(1,:);
times_est_f(:,adimat_id) = times_est_adimat_f(1,:);
times_est_J(:,adimat_vector_id) = times_est_adimat_J(2,:);
times_est_f(:,adimat_vector_id) = times_est_adimat_f(2,:);

%% determine nruns for everyone
nruns_J = zeros(ntasks,ntools);
for i=1:numel(times_est_J)
    if times_est_J(i) < 5
        nruns_J(i) = 1000;
    elseif times_est_J(i) < 30
        nruns_J(i) = 100;
    elseif times_est_J(i) < 120
        nruns_J(i) = 10;
    elseif ~isinf(times_est_J(i))
%         nruns_J(i) = 1; 
        nruns_J(i) = 0; % it has already ran once
    end
end
nruns_f = zeros(ntasks,ntools);
for i=1:numel(times_est_f)
    if times_est_f(i) < 5
        nruns_f(i) = 1000;
    elseif times_est_f(i) < 30
        nruns_f(i) = 100;
    elseif times_est_f(i) < 120
        nruns_f(i) = 10;
    elseif ~isinf(times_est_f(i))
%         nruns_f(i) = 1; 
        nruns_f(i) = 0; % it has already ran once
    end
end

%% run adimat all
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');
times_adimat_f = Inf(2,ntasks);
times_adimat_J = Inf(2,ntasks);
for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    d = params{i}(1);
    k = params{i}(2);
    [paramsGMM,x,hparams] = load_gmm_instance([fns{i} '.txt']);
    
    % "looped" objective
    nruns_curr_f = nruns_f(i,adimat_id);
    nruns_curr_J = nruns_J(i,adimat_id);
    tic
    for j=1:nruns_curr_f
        fval = gmm_objective(paramsGMM.alphas,paramsGMM.means,...
            paramsGMM.inv_cov_factors,x,hparams);
    end
    times_adimat_f(1,i) = toc/nruns_curr_f;
    
    tic
    for j=1:nruns_curr_J
        do_F_mode = false;
        do_adimat_vector = false;
        [J, fvalrev] = gmm_objective_adimat(do_F_mode,do_adimat_vector,...
            paramsGMM.alphas,paramsGMM.means,paramsGMM.inv_cov_factors,...
            x,hparams);
    end
    times_adimat_J(1,i) = toc/nruns_curr_J;
    
    % "vectorized" objective
    nruns_curr_f = nruns_f(i,adimat_vector_id);
    nruns_curr_J = nruns_J(i,adimat_vector_id);
    tic
    for j=1:nruns_curr_f
        fval = gmm_objective_vector_repmat(paramsGMM.alphas,paramsGMM.means,...
            paramsGMM.inv_cov_factors,x,hparams);
    end
    times_adimat_f(2,i) = toc/nruns_curr_f;
    
    tic
    for j=1:nruns_curr_J
        do_F_mode = false;
        do_adimat_vector = true;
        [J, fvalrev] = gmm_objective_adimat(do_F_mode,do_adimat_vector,...
            paramsGMM.alphas,paramsGMM.means,paramsGMM.inv_cov_factors,...
            x,hparams);
    end
    times_adimat_J(2,i) = toc/nruns_curr_J;
    
%     save([data_dir 'gmm_adimat_times.mat'],'times_adimat_f','times_adimat_J');
end

%% run mupad
addpath('awful\matlab');
times_mupad_f = Inf(1,ntasks);
times_mupad_J = Inf(1,ntasks);
for i=1:ntasks
    disp(['runnning gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    d = params{i}(1);
    k = params{i}(2);
    [paramsGMM,x,hparams] = load_gmm_instance([fns{i} '.txt']);
    
    nruns_curr = 1000;
    
    tic
    [ J, err ] = gmm_objective_d_symbolic(nruns_curr, paramsGMM, x, ...
        hparams, false);
    if ~isempty(J)
        times_mupad_f(i) = toc/nruns_curr;
    end
    
    tic
    [ J, err ] = gmm_objective_d_symbolic(nruns_curr, paramsGMM, x,...
        hparams, true);
    
    if ~isempty(J)
        times_mupad_J(i) = toc/nruns_curr;
    end
    
%     save([data_dir 'gmm_mupad_times.mat'],'times_mupad_f','times_mupad_J');
end

%% generate script for others
fnFrom = 'run_experiments_final.bat';
fid = fopen(fnFrom,'w');
for i=1:nexe
    if strcmp('Theano',tools{i}(1:6))
        cmd = ['START /MIN /WAIT ' executables{i}];
        for j=1:ntasks
            if nruns_f(j,i)+nruns_J(j,i) > 0
                cmd = [cmd ' ' fns{j}...
                  ' ' num2str(nruns_f(j,i)) ' ' num2str(nruns_J(j,i))];
            end
        end
        fprintf(fid,[cmd '\r\n']);
    else
        for j=1:ntasks
            if nruns_f(j,i)+nruns_J(j,i) == 0
                continue
            end
            if strcmp('Ceres, F',tools{i})
                d = params{j}(1);
                k = params{j}(2);
                fprintf(fid,'START /MIN /WAIT %sd%ik%i.exe %s %i %i\r\n',...
                    executables{i},d,k,fns{j},nruns_f(j,i),nruns_J(j,i));
            else
                fprintf(fid,'START /MIN /WAIT %s %s %i %i\r\n',...
                    executables{i},fns{j},nruns_f(j,i),nruns_J(j,i));
            end
        end
    end
end
fclose(fid);

%% run others
tic
system(fnFrom);
toc

%% verify results
addpath('adimat-0.6.0-4971');
start_adimat
addpath('awful\matlab');
opt = admOptions('independents', [1 2 3],  'functionResults', {1});
bad = {};
num_ok = 0;
num_not_comp = 0;
for i=1:ntasks
    disp(['comparing to adimat: gmm: ' num2str(i) '; params: ' num2str(params{i})]);
    d = params{i}(1);
    k = params{i}(2);
    [paramsGMM,x,hparams] = load_gmm_instance([fns{i} '.txt']);
    [Jrev,fvalrev] = admDiffRev(@gmm_objective_vector_repmat, 1, paramsGMM.alphas,...
        paramsGMM.means, paramsGMM.inv_cov_factors, x, hparams, opt);
    
    for j=1:nexe
        fnFrom = [fns{i} names{j} '.txt'];
        if exist(fnFrom,'file')
            Jexternal = load_J(fnFrom);
            tmp = norm(Jrev(:) - Jexternal(:)) / norm(Jrev(:));
%             disp([names{j} ': ' num2str(tmp)]);
            if tmp < 1e-5
                num_ok = num_ok + 1;
            else
                bad{end+1} = {fnFrom, tmp};
            end
        else
            disp([names{j} ': not computed']);
            num_not_comp = num_not_comp + 1;
        end
    end
end
disp(['num ok: ' num2str(num_ok)]);
disp(['num bad: ' num2str(numel(bad))]);
disp(['num not computed: ' num2str(num_not_comp)]);
for i=1:numel(bad)
    disp([bad{i}{1} ' : ' num2str(bad{i}{2})]);
end

%% read final times
times_f = Inf(ntasks,nexe+3);
times_J = Inf(ntasks,nexe+3);
for i=1:ntasks
    for j=1:nexe
        fnFrom = [fns{i} names{j} '_times.txt'];
        if exist(fnFrom,'file')
            fid = fopen(fnFrom);
            times_f(i,j) = fscanf(fid,'%lf',1);
            times_J(i,j) = fscanf(fid,'%lf',1);
            fclose(fid);
        end
    end
end
ld = load([data_dir 'gmm_adimat_times.mat']);
times_f(:,adimat_id) = ld.times_adimat_f(1,:);
times_J(:,adimat_id) = ld.times_adimat_J(1,:);
times_f(:,adimat_vector_id) = ld.times_adimat_f(2,:);
times_J(:,adimat_vector_id) = ld.times_adimat_J(2,:);
% ld = load([data_dir 'gmm_mupad_times.mat']);
% times_f(:,mupad_id) = ld.times_mupad_f;
% times_J(:,mupad_id) = ld.times_mupad_J;

times_relative = times_J./times_f;
times_relative(isnan(times_relative)) = Inf;
times_relative(times_relative==0) = Inf;

%% output results
save([data_dir 'times_' date],'times_f','times_J','times_relative','params','tools');

%% plot times
set(groot,'defaultAxesColorOrder',...
    [.8 .1 0;0 .7 0;.2 .2 1; 0 0 0; .8 .8 0],...
    'defaultAxesLineStyleOrder', '-|s-|x-|^-')
lw = 2;
msz = 7;
x=[params{:}]; x=x(3:3:end);

% ordering
[tmp,preorder]=sort(times_J,2);
preorder(isinf(tmp)) = NaN;
scores=zeros(ntools,1);
mask=~isnan(preorder);
tmp=repmat(fliplr((1:ntools)),ntasks,1);
scores(preorder(mask)) = scores(preorder(mask)) + tmp(mask);
[~, order] = sort(scores);

% Runtime
figure
loglog(x, times_J(:, order),'linewidth',lw,'markersize',msz);
legend({tools{order}}, 'location', 'nw');
set(gca,'FontSize',14)
xlim([min(x) max(x)])
title('runtimes (seconds)')
xlabel('# parameters')
ylabel('runtime [seconds]')

% Relative
figure
loglog(x, times_relative(:, order),'linewidth',lw,'markersize',msz);
legend({tools{order}}, 'location', 'nw');
set(gca,'FontSize',14)
xlim([min(x) max(x)])
title('relative runtimes')
xlabel('# parameters')
ylabel('relative runtime')

% Objective function
figure
loglog(x, times_f(:, order),'linewidth',lw,'markersize',msz);
legend({tools{order}}, 'location', 'nw');
set(gca,'FontSize',14)
xlim([min(x) max(x)])
title('objective runtimes (seconds)')
xlabel('# parameters')
ylabel('runtime [seconds]')

%% do 2D plots
tool_id = adimat_id-1;
vals_J = zeros(numel(d_all),numel(k_all));
vals_relative = vals_J;
for i=1:ntasks
    d = params{i}(1);
    k = params{i}(2);
    vals_relative(d_all==d,k_all==k) = times_relative(i,tool_id);
    vals_J(d_all==d,k_all==k) = times_J(i,tool_id);
end
[x,y]=meshgrid(k_all,d_all);
figure
surf(x,y,vals_J);
xlabel('d')
ylabel('K')
set(gca,'FontSize',14,'ZScale','log')
title(['Runtime (seconds): ' tools{tool_id}])
figure
surf(x,y,vals_relative);
xlabel('d')
ylabel('K')
set(gca,'FontSize',14)
title(['Runtime (relative): ' tools{tool_id}])

%% output into excel/csv
csvwrite('tmp.csv',times_J*1000,2,1);
csvwrite('tmp2.csv',times_relative,2,1);
labels = {};
for i=1:ntasks
    labels{end+1} = [num2str(params{i}(1)) ',' num2str(params{i}(2)) ...
        '->' num2str(params{i}(3))];
end
xlswrite('tmp.xlsx',labels')
xlswrite('tmp.xlsx',tools,1,'B1')

%% mupad compilation
mupad_compile_times = Inf(1,ntasks);
mupad_compile_times(1:13) = [0.0014, 0.0019, 0.014, 0.15, 0.089,...
    0.6, 0.5, 3.3, 4.25, 8.7, 15.1, 26, 50];

vals = zeros(numel(d_all),numel(k_all));
for i=1:ntasks
    d = params{i}(1);
    k = params{i}(2);
    vals(d_all==d,k_all==k) = mupad_compile_times(i);
end
[x,y]=meshgrid(k_all,d_all);
figure
surf(x,y,vals);
xlabel('d')
ylabel('K')
set(gca,'FontSize',14,'ZScale','log')
title('Compile time (hours): MuPAD')

figure
x=[params{:}]; x=x(3:3:end);
loglog(x,mupad_compile_times,'linewidth',2)
xmax = find(~isinf(mupad_compile_times)); xmax=x(xmax(end));
xlim([x(1) xmax])
xlabel('# parameters')
ylabel('compile time [hours]')
title('Compile time (hours): MuPAD')

%% Transport objective runtimes
fromID = 10;
toID = 9;
for i=1:ntasks
    fnFrom = [fns{i} names{fromID} '_times.txt'];
    fnTo = [fns{i} names{toID} '_times.txt'];
    if exist(fnFrom,'file') && exist(fnTo,'file')
        fid = fopen(fnFrom);
        time_f_from = fscanf(fid,'%lf',1);
        fclose(fid);
        fid = fopen(fnTo,'r');
        time_f_to = fscanf(fid,'%lf',1);
        time_J_to = fscanf(fid,'%lf',1);
        fclose(fid);
        fid = fopen(fnTo,'w');
        fprintf(fid,'%f %f %f\n',time_f_from,time_J_to,time_J_to/time_f_from);
        fprintf(fid,'tf tJ tJ/tf');
        fclose(fid);
    end
end
