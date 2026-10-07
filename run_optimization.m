% RUN_OPTIMIZATION
% Task 3: find how to spend a budget across counties to maximize sum(P).
%
% Uses a REDUCED subset of counties (150, not all 3062) so fmincon runs
% in a reasonable time on a first try. See the notes at the end about
% scaling this up.

csvFile = 'Combined_county_data_labeled_2018-07-23 (5).csv';
costFile = 'Diane_costs_0123_noheaders.csv';  
D = load_county_data(csvFile, costFile); 


Bfull = D.B(:, D.w == 1);   % 3062 x 199, priority species only
% drop species with zero total range (phi would be Inf for these)
totalRangeAll = sum(Bfull, 1);
validSpecies  = totalRangeAll > 0;
fprintf('dropping %d species with zero total range (out of %d)\n', ...
    nnz(~validSpecies), numel(validSpecies));
Bfull = Bfull(:, validSpecies);
% run phi function
phi = compute_phi(Bfull, 0.85); 

%Pick a subset of counties
% Deterministic choice (not random), so results are reproducible:
% take the 300 counties where the priority species collectively have the
% most range area from the 2020 SI. These are the counties where 
% spending money has the
% best chance of moving S_j for species that matter to the objective.
nSub          = 300;
totalRange    = sum(Bfull, 2);              % 3062 x 1
[~, order]    = sort(totalRange, 'descend');
idx           = order(1:nSub);

county.a  = D.a(idx);
county.r0 = D.r0(idx);
county.d0 = D.d0(idx);
county.d1 = D.d1(idx);
county.c  = D.c(idx);
B         = Bfull(idx, :);

fprintf('optimizing over %d counties, %d priority species\n', nSub, size(B, 2));

% PARAMETERS
params.alpha = 0.25; %From 2020 SI 
params.delta = 0.5;
params.gamma = 0;
budget = 5e10;   % $50000 million
%  before optimizing when there's 0 dollar invested
x0 = zeros(nSub, 1);
S0 = compute_S(x0, county, B, params);
P0 = persistence_prob(S0, phi);
fprintf('baseline sum(P) on this subset (x = 0): %.4f\n', sum(P0));

% Set up and call fmincon 
scale = 1e6;                 
objFun = @(z) neg_sum_P(z * scale, county, B, params, phi);
A  = ones(1, nSub);
b  = budget / scale;
lb = zeros(nSub, 1);
ub = [];
zStart = (budget / scale / nSub) * ones(nSub, 1);
options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp', ...
    'MaxIterations', 3000, 'MaxFunctionEvaluations', 1e7, ...
    'OptimalityTolerance', 1e-6);
[zOpt, fval] = fmincon(objFun, zStart, A, b, [], [], lb, ub, [], options);
xOpt = zOpt * scale;                           % back to dollars
fprintf('\n--- Result ---\n');
fprintf('optimized sum(P): %.4f\n', -fval);
fprintf('total spent: %.2f (budget was %.2e)\n', sum(xOpt), budget);
fprintf('counties receiving more than $1: %d out of %d\n', nnz(xOpt > 1), nSub);

% show the per-county allocation, sorted by $ amount 
countyNames = D.countyName(idx); % find county name
stateNames  = D.stateName(idx);  % find state name 

[sortedX, order2] = sort(xOpt, 'descend');
sortedNames = countyNames(order2);
sortedStates = stateNames(order2);
fprintf('\n--- Data of all 300 counties ---\n');
for k = 1:300
    fprintf('%-25s %-15s $%.2f\n', sortedNames(k), sortedStates(k), sortedX(k));
end
