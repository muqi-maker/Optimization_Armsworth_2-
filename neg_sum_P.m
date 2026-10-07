function negSumP = neg_sum_P(x, county, B, params, phi)
% NEG_SUM_P  Objective function for fmincon.
%
%   negSumP = neg_sum_P(x, county, B, params, phi)
%
% fmincon only knows how to MINIMIZE. We want to MAXIMIZE sum(P_j), so
% this function returns the negative of that. Minimizing -sum(P) is the
% same thing as maximizing sum(P).
%
% Inputs: same as compute_S, plus phi, a 1 x m  saturation 
%         parameter for each of the m species in B

    S = compute_S(x, county, B, params);   
    P = persistence_prob(S, phi);   
    negSumP = -sum(P);
end
