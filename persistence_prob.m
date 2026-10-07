function P = persistence_prob(S, phi)
% PERSISTENCE_PROB  Species persistence probability, P_j(S_j)
%   P = persistence_prob(S, phi)
%   P_j = 1 - exp(-phi_j * S_j)
%   Inputs:
%       S   - landscape suitability score(s) for a species (string or vector)
%       phi - saturation parameter (controls how fast P rises toward 1)
%
%   Output:
%       P   - persistence probability, same size as S

    P = 1 - exp(-phi .* S);

end
