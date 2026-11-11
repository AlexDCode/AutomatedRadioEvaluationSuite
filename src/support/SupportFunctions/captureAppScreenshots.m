function captureAppScreenshots(outDir, varargin)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % DESCRIPTION:
    % Opens the ARES app, walks every UI tab in turn, and writes a PNG of each one so the interface images in the
    % documentation can be refreshed without taking screenshots by hand. Intended to support the ReadTheDocs
    % workflow alongside extractDocs. Example usage:
    %
    %   - captureAppScreenshots()
    %   - captureAppScreenshots('./docs/readthedocs/source/assets/auto', 'Size', [1600 1000])
    %
    % Each capture is the whole app window, because exportapp works on figures and not on individual panels. Tabs
    % that live inside the PA or Antenna pages therefore appear alongside whatever panel is next to them.
    %
    % REQUIREMENTS:
    % Needs an interactive desktop session. exportapp captures a rendered on-screen window, so this will not work
    % under a headless session and is deliberately kept out of the default build tasks. Needs R2020b or newer.
    %
    % Tabs that are missing from the running app are skipped with a warning rather than failing the whole run, so
    % this keeps working when the UI gains or loses a tab.
    %
    % TODO:
    %   - The results tabs (CW, MOD, DC, CAL, radiation patterns, reference antenna) only show empty axes here
    %     because nothing is loaded. Drive the app's load path with the files in data/ first so the plot images
    %     can be refreshed the same way.
    %
    % INPUT:
    %   outDir    - (Optional) Folder to write the PNGs into. Defaults to a staging folder under the docs assets
    %               so that curated screenshots are never overwritten without review.
    %   Size      - (Optional) [width height] in pixels for the app window, pinned before capture so images stay
    %               consistent between runs. Defaults to [1280 800].
    %   SettleSec - (Optional) Seconds to wait after selecting a tab before capturing. Defaults to 0.75.
    %
    % OUTPUT:
    %   None   (PNG files are written to outDir).
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nargin < 1 || isempty(outDir)
        outDir = fullfile(pwd, 'docs', 'readthedocs', 'source', 'assets', 'auto');
    end

    ip = inputParser;
    ip.addParameter('Size',      [1280 800], @(v) isnumeric(v) && numel(v) == 2);
    ip.addParameter('SettleSec', 0.75,       @(v) isnumeric(v) && isscalar(v));
    ip.parse(varargin{:});
    figSize   = ip.Results.Size;
    settleSec = ip.Results.SettleSec;

    if isempty(which('exportapp'))
        error('captureAppScreenshots:NoExportApp', ...
            'exportapp is required to capture uifigure windows (R2020b or newer).');
    end

    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    % Output name, top-level tab, inner tab group, inner tab.
    % An empty group means the top-level tab is the whole view.
    views = {
        'info',              'InfoTab',           '',                ''
        'pa_instruments',    'PowerAmplifierTab', 'PASettingsPanel', 'PAInstrumentsTab'
        'pa_power_supply',   'PowerAmplifierTab', 'PASettingsPanel', 'PowerSupplyTab'
        'pa_stimulus',       'PowerAmplifierTab', 'PASettingsPanel', 'StimulusTab'
        'pa_signal_analysis','PowerAmplifierTab', 'PASettingsPanel', 'SignalAnalysisTab'
        'pa_calibration',    'PowerAmplifierTab', 'PASettingsPanel', 'CalibrationTab'
        'pa_safety',         'PowerAmplifierTab', 'PASettingsPanel', 'SafetyTab'
        'pa_plot',           'PowerAmplifierTab', 'PASettingsPanel', 'PAPlotTab'
        'pa_results_cw',     'PowerAmplifierTab', 'PAResultsTabs',   'CWTab'
        'pa_results_mod',    'PowerAmplifierTab', 'PAResultsTabs',   'MODTab'
        'pa_results_dc',     'PowerAmplifierTab', 'PAResultsTabs',   'DCTab'
        'pa_results_cal',    'PowerAmplifierTab', 'PAResultsTabs',   'CALTab'
        'ant_instruments',   'AntennaTab',        'AntennaSettings', 'AntInstrumentsTab'
        'ant_vna',           'AntennaTab',        'AntennaSettings', 'VNATab'
        'ant_tower',         'AntennaTab',        'AntennaSettings', 'TowerTab'
        'ant_linear_slider', 'AntennaTab',        'AntennaSettings', 'LinearSliderTab'
        'ant_plot',          'AntennaTab',        'AntennaSettings', 'AntennaPlotTab'
        'ant_reference',     'AntennaTab',        'AntennaPattern',  'ReferenceAntennaTab'
        'ant_pattern_2d',    'AntennaTab',        'AntennaPattern',  'RadiationPatternTab'
        'ant_pattern_3d',    'AntennaTab',        'AntennaPattern',  'RadiationPattern3DTab'
        'ant_nport',         'AntennaTab',        'AntennaPattern',  'NPortResultsTab'
        'settings_ui',       'SettingsTab',       'TabGroup',        'UITab'
        'settings_config',   'SettingsTab',       'TabGroup',        'LoadSaveConfigurationsTab'
        };

    app = ARES;
    closeApp = onCleanup(@() delete(app));   % close even if a capture throws
    drawnow;
    pause(2 * settleSec);   % let startupFcn finish before touching anything

    app.UIFigure.Position(3:4) = figSize;
    drawnow;

    captured = 0;
    for k = 1:size(views, 1)
        name     = views{k, 1};
        topTab   = views{k, 2};
        groupName = views{k, 3};
        innerTab = views{k, 4};

        if ~selectTab(app, 'MainTabs', topTab)
            continue;
        end
        if ~isempty(groupName) && ~selectTab(app, groupName, innerTab)
            continue;
        end

        drawnow;
        pause(settleSec);

        outFile = fullfile(outDir, [name '.png']);
        try
            exportapp(app.UIFigure, outFile);
            fprintf('  captured %s\n', outFile);
            captured = captured + 1;
        catch ME
            warning('captureAppScreenshots:ExportFailed', ...
                'Could not capture %s: %s', name, ME.message);
        end
    end

    fprintf('Captured %d of %d views to: %s\n', captured, size(views, 1), outDir);
end

function ok = selectTab(app, groupName, tabName)
    % Select tabName within groupName, reporting rather than throwing when the
    % app no longer has either one.
    ok = false;
    if ~isprop(app, groupName)
        warning('captureAppScreenshots:NoTabGroup', ...
            'Tab group "%s" not found in the app; skipping.', groupName);
        return;
    end
    if ~isprop(app, tabName)
        warning('captureAppScreenshots:NoTab', ...
            'Tab "%s" not found in the app; skipping.', tabName);
        return;
    end
    app.(groupName).SelectedTab = app.(tabName);
    ok = true;
end
