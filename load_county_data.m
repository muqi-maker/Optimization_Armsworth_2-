function D = load_county_data(csvFile, costFile)
% LOAD_COUNTY_DATA  Read the combined county / species CSV into a struct.
%
%   D = load_county_data('Combined_county_data_labeled_2018-07-23__4_.csv')
%
% Layout of the CSV (found by inspecting the file):
%   line 1      : column names
%   lines 2-4   : species LABEL rows (name / IUCN status / group). These are
%                 NOT counties; they are filled only in the species columns.
%   lines 5-end : one row per county
%   columns     : ~121 county attribute columns, then 1963 species columns
%                 (named x<digits>). A species cell = hectares of that
%                 species' range inside that county.
%
% Output struct D (n = usable counties, m = species):
%   D.B            n x m  species range area in each county (ha)   -> b0
%   D.w            1 x m  1 if IUCN status is VU / EN / CR, else 0  -> w_j
%   D.a            n x 1  county area (ha)                          -> a
%   D.r0           n x 1  already-protected area which I used GAP 
%                         1 + 2 (ha)    -> r0
%   D.d0           n x 1  already-converted area, 2010 (ha)         -> d0
%   D.d1           n x 1  extra area converted by 2040 (ha)         -> d1
%   D.c            n x 1  land value proxy for cost ($/ha)          -> c
%   D.speciesName / D.speciesIUCN / D.speciesGroup   1 x m strings
%   D.countyName / D.stateName                       n x 1 strings
%
%   - "converted" = urban + cropland + pasture (paper, WebPanel 1)
%   - d0 = converted area in 2010; d1 = converted area in 2040 minus d0
%   - c  = NASS land value per ha (2012) as a stand-in for acquisition cost

    % 1) read column names, find which columns are species 
    opts     = detectImportOptions(csvFile, 'VariableNamingRule', 'preserve');
    allNames = opts.VariableNames;
    isSp     = ~cellfun(@isempty, regexp(allNames, '^x\d+$', 'once'));
    spNames  = allNames(isSp);

    % county columns we need. In the raw file some cells hold TEXT
    % placeholders instead of numbers (e.g. "(D)" or "See 'Note One...'").
    % Forcing these columns to double turns those cells into NaN.
    numNames = {'area_of_county_ha', ...
                'pad_us_area_gapstatus1_pas_ha', 'pad_us_area_gapstatus2_pas_ha', ...
                'wear_urban_area_2010_ha', 'wear_cropland_area_2010_ha', 'wear_pasture_area_2010_ha', ...
                'wear_urban_area_2040_ha', 'wear_cropland_area_2040_ha', 'wear_pasture_area_2040_ha', ...
                'county_id_fips'};

    opts = setvartype(opts, [spNames, numNames], 'double');
    opts.ImportErrorRule = 'fill';   % unreadable cell -> NaN
    opts.MissingRule     = 'fill';   % empty cell      -> NaN
    opts.DataLines       = [5 Inf];  % skip header + 3 label lines
    T = readtable(csvFile, opts);

    % 2) read the 3 label rows (lines 2-4) as text
    lopts = detectImportOptions(csvFile, 'VariableNamingRule', 'preserve');
    lopts = setvartype(lopts, lopts.VariableNames, 'string');
    lopts.DataLines = [2 4];
    L   = readtable(csvFile, lopts);
    Lsp = table2array(L(:, spNames));          % 3 x m string array

    % 3) county quantities
    a   = T.area_of_county_ha;
    r0  = T.pad_us_area_gapstatus1_pas_ha + T.pad_us_area_gapstatus2_pas_ha;
    d0  = T.wear_urban_area_2010_ha + T.wear_cropland_area_2010_ha + T.wear_pasture_area_2010_ha;
    d40 = T.wear_urban_area_2040_ha + T.wear_cropland_area_2040_ha + T.wear_pasture_area_2040_ha;
    % Attach the costfile according to the FIPS, which is an index each species have 
    Cost = readtable(costFile); 
    [tf, loc] = ismember(T.county_id_fips, Cost.fips);
     c = nan(height(T), 1);
     c(tf) = Cost.cost_per_ha(loc(tf));

    % Drop counties with any missing value. 
    keep = ~(isnan(a) | isnan(r0) | isnan(d0) | isnan(d40) | isnan(c));

    D.nCounty  = nnz(keep);
    D.nDropped = nnz(~keep);
    D.nSpecies = numel(spNames);

    D.a  = a(keep);
    D.r0 = r0(keep);
    D.d0 = d0(keep);
    D.c  = c(keep);
    D.nD1Clipped = nnz(d40(keep) - d0(keep) < 0);
    D.d1 = max(d40(keep) - d0(keep), 0);       % conversion can't be negative

    D.countyName = string(T.county_name(keep));
    D.stateName  = string(T.state_name(keep));

    D.B = T{keep, spNames};                    % n x m matrix of range areas

    % ---- 4) species info from the label rows --------------------------
    D.speciesName  = Lsp(1, :);
    D.speciesIUCN  = Lsp(2, :);
    D.speciesGroup = Lsp(3, :);
    D.w = double(ismember(D.speciesIUCN, ["VU", "EN", "CR"]));
end
