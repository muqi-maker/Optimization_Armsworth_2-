% CHECK_S_AND_P
% Put the CSV in this same folder, and update csvFile below if its name
% doesn't match exactly.

csvFile = 'Combined_county_data_labeled_2018-07-23 (5).csv';
costFile = 'Diane_costs_0123_noheaders.csv';  
D = load_county_data(csvFile, costFile); 

% Pack the county-level fields into one struct for compute_S.
county.a  = D.a;
county.r0 = D.r0;
county.d0 = D.d0;
county.d1 = D.d1;
county.c  = D.c;

% Only the 199 priority (VU/EN/CR) species matter for the objective.
Bpri = D.B(:, D.w == 1);
fprintf('priority species columns: %d\n', size(Bpri, 2));

% PARAMETERS
params.alpha = 0.5;   % value of unprotected-unconverted habitat (0-1)
params.delta = 1;     % new protection fully targets at-risk land
params.gamma = 0;     % no displacement of conversion pressure 
% Baseline: check what if there is no new money spent anywhere (x = 0)
x0 = zeros(D.nCounty, 1);
S0 = compute_S(x0, county, Bpri, params);
phi = phiPlaceholder * ones(1, size(Bpri, 2));
P0 = persistence_prob(S0, phi);

fprintf('\n--- Baseline (x = 0, nothing new protected) ---\n');
fprintf('species with S = 0 (range not in any usable county): %d\n', nnz(S0 == 0));
nz = S0(S0 > 0);
fprintf('nonzero S: min %.1f, median %.1f, max %.1f\n', min(nz), median(nz), max(nz));
fprintf('sum of P over all %d priority species: %.2f\n', numel(P0), sum(P0));

% Spend $1000 in every county and see if S goes up as expected.
xTest = 1000000 * ones(D.nCounty, 1);
Stest = compute_S(xTest, county, Bpri, params);
Ptest = persistence_prob(Stest, phi);

fprintf('\n--- Sanity check: $1000 spent in every county ---\n');
fprintf('sum of P: %.2f  (should be a bit higher than the baseline above)\n', sum(Ptest));
fprintf('increase in sum(P): %.4f\n', sum(Ptest) - sum(P0));
