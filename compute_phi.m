function phi = compute_phi(B, Ptarget)
%   phi = compute_phi(B, Ptarget)
%   B       - nCounty x nSpecies matrix (hectares of range per county)
%   Ptarget - target persistence probability at the hockey-stick kink（0.85）
%   1. find the total range for each species(column sum)
%   2. plug range into threshold formula -> fraction of range needed
%   3. S at the kink = threshold fraction * total range
%   4. Ptarget = 1 - exp(-phi * S_j) at S_j = S_kink

    totalRange = sum(B, 1);                      % range of each individual species

    logR  = log10(max(totalRange, 1));            % avoid log10(0) to avoid the -inf outcome
    frac  = 1.0 - 0.45*(logR - 6);                 % log-linear value  0.45 is the slope 
    frac  = min(max(frac, 0.10), 1.00);            % clamp to [10%, 100%](force the value
                                                   % to stay inside a fixed
                                                   % range, if its less
                                                   % than 10%, replace it
                                                   % to 10% if its more
                                                   % than 100 drag it back
                                                   % t0 100
                                                 
    S_kink = frac .* totalRange;                   % the s value at kink point, where the s value stop increasing 
    phi = -log(1 - Ptarget) ./ S_kink;             % solve for phi
end
