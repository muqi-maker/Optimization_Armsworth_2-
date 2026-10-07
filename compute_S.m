function S = compute_S(x, county, B, params)
% COMPUTE_S  Landscape suitability score S_j for each species.
%
%   S = compute_S(x, county, B, params)

% Inputs:
%   x       n x 1  money spent in each county (this is the thing an
%                  optimizer will eventually choose -- see task 3)
%   county  struct with n x 1 fields:
%             .a   county area (ha)
%             .r0  already-protected area (ha)
%             .d0  already-converted area, 2010 (ha)
%             .d1  extra area that would convert by 2040 if nothing is
%                  done (ha)
%             .c   cost per hectare ($/ha)
%   B       n x m  species range area in each county (ha). 
%   params  struct with:
%             .alpha  value of unprotected-but-unconverted habitat
%             .delta  whether new protection targets land that would
%                     otherwise be converted
%             .gamma  how much conversion pressure just moves elsewhere
%                     in the county instead of being avoided %
% Output:
%   S       1 x m  S_j for each of the m species columns in B
    r1 = x ./ county.c;
    % r1 = new area protected this round = money spent / cost per ha
    % Of the d1 ha that would convert, protecting r1 ha removes that
    % threat for min(r1, d1) of it; a fraction gamma of that pressure
    % just shifts onto other unprotected land in the county instead.
    displaced      = (1 - params.gamma) .* params.delta .* min(r1, county.d1);
    convertedByEnd = county.d0 + county.d1 - displaced;

    % Area left over: total minus protected minus converted.
    u2 = county.a - (county.r0 + r1) - convertedByEnd;
    u2 = max(u2, 0);
    
    % Equation 3, as a fraction of county area:
    f = (county.r0 + r1 + params.alpha .* u2) ./ county.a;   % n x 1

    % Equation 2: sum each county's contribution, weighted by how much
    % of each species' range sits in that county.
    S = f' * B;  
end
