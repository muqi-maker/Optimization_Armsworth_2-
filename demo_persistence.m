% DEMO_PERSISTENCE
% the shape of the persistence probability curve.

% 1) Make a range of S values to test, from 0 to 5, 100 points
S = linspace(0, 5, 100);   % linspace(start, stop, how_many_points)

% 2) Pick a phi value (try changing this later to see the effect)
phi = 1;

% 3) Call our function
P = persistence_prob(S, phi);

% 4) Plot it
plot(S, P, 'LineWidth', 2);
xlabel('S_j (landscape suitability score)');
ylabel('P_j (persistence probability)');
title('Species persistence probability curve');
grid on;

% 5) Try a couple of different phi values on the same plot, to see
%    how the saturation speed changes
hold on;
plot(S, persistence_prob(S, 0.3), '--', 'LineWidth', 2);
plot(S, persistence_prob(S, 3),   ':',  'LineWidth', 2);
legend('\phi = 1', '\phi = 0.3 (slower)', '\phi = 3 (faster)');
hold off;
