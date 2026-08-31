classdef HybridBusApp < handle
    %HYBRIDBUSAPP Explorer UI for manual and optimized hybrid-bus studies.
    properties (Access=private)
        Figure matlab.ui.Figure
        DatabaseField matlab.ui.control.EditField
        RouteDropDown matlab.ui.control.DropDown
        Battery1DropDown matlab.ui.control.DropDown
        Battery2DropDown matlab.ui.control.DropDown
        MotorDropDown matlab.ui.control.DropDown
        GensetDropDown matlab.ui.control.DropDown
        AuxDropDown matlab.ui.control.DropDown
        LoadTonnesField matlab.ui.control.NumericEditField
        CurbMassTonnesField matlab.ui.control.NumericEditField
        TotalMassTonnesField matlab.ui.control.NumericEditField
        SOE1Field matlab.ui.control.NumericEditField
        SOE2Field matlab.ui.control.NumericEditField
        FuelPriceField matlab.ui.control.NumericEditField
        ElectricityPriceField matlab.ui.control.NumericEditField
        MaxConfigurationsField matlab.ui.control.NumericEditField
        BatterySetMultiplierField matlab.ui.control.NumericEditField
        RepeatRouteCheckBox matlab.ui.control.CheckBox
        RunBEVThenHybridCheckBox matlab.ui.control.CheckBox
        SimulationFormulationSwitch matlab.ui.control.DropDown
        StatusLabel matlab.ui.control.Label
        KPICards struct = struct
        KPIStatusLabel matlab.ui.control.Label
        KPIContextLabel matlab.ui.control.Label
        KPIRunScopeLabel matlab.ui.control.Label
        KPIRecommendationLabel matlab.ui.control.Label
        KPIRecommendationDetailLabel matlab.ui.control.Label
        KPIExecutiveTables struct = struct
        KPIExecutiveInsightLabels struct = struct
        KPIScorecardHeaderLabel matlab.ui.control.Label
        KPIScorecardGateLabels struct = struct
        KPIScorecardTable matlab.ui.control.Table
        KPIPerformanceHeaderLabel matlab.ui.control.Label
        KPIPerformanceSpeedAxes matlab.ui.control.UIAxes
        KPIPerformanceComparisonAxes matlab.ui.control.UIAxes
        KPIPerformanceTable matlab.ui.control.Table
        KPIPerformanceAssessmentLabel matlab.ui.control.Label
        KPIRobustnessHeaderLabel matlab.ui.control.Label
        KPIRobustnessAxes matlab.ui.control.UIAxes
        KPIRobustnessTable matlab.ui.control.Table
        KPIRobustnessSummaryLabel matlab.ui.control.Label
        AnalysisHeaderLabel matlab.ui.control.Label
        AnalysisEnergyAxes matlab.ui.control.UIAxes
        AnalysisDutyAxes matlab.ui.control.UIAxes
        AnalysisTable matlab.ui.control.Table
        CredibilityHeaderLabel matlab.ui.control.Label
        CredibilityGateTable matlab.ui.control.Table
        CredibilityBaselineTable matlab.ui.control.Table
        CredibilityAxes matlab.ui.control.UIAxes
        RankingTable matlab.ui.control.Table
        SpeedAxes matlab.ui.control.UIAxes
        PowerAxes matlab.ui.control.UIAxes
        BatteryAxes matlab.ui.control.UIAxes
        GensetAxes matlab.ui.control.UIAxes
        SignalsXAxisSwitch matlab.ui.control.Switch
        DetailedPlotDropDown matlab.ui.control.DropDown
        DetailedXAxisSwitch matlab.ui.control.Switch
        DetailedAxes matlab.ui.control.UIAxes
        RouteMapModeSwitch matlab.ui.control.Switch
        Route3DMetricLabel matlab.ui.control.Label
        Route3DMetricSwitchGrid matlab.ui.container.GridLayout
        Route3DMetricSwitch matlab.ui.control.Switch
        RouteMap2DPanel matlab.ui.container.Panel
        RouteMap3DPanel matlab.ui.container.Panel
        RouteMapAxes matlab.graphics.axis.GeographicAxes
        Route3DAxes matlab.ui.control.UIAxes
        RouteMapTable matlab.ui.control.Table
        ArchitectureAxes matlab.ui.control.UIAxes
        PowertrainModeSwitch matlab.ui.control.Switch
        ArchitectureNoteLabel matlab.ui.control.Label
        Database struct = struct
        CurrentResults = []
        CurrentPowertrainSequence = []
        CurrentOptimization = []
        CancelRequested logical = false
        HybridSOE1Cache double = 85
        HybridSOE2Cache double = 20
        LastValidBatterySetMultiplier double = 1
    end

    methods
        function app=HybridBusApp()
            appRoot=fileparts(mfilename('fullpath'));
            addpath(fullfile(appRoot,'src'),fullfile(appRoot,'models'), ...
                fullfile(appRoot,'project'));
            app.buildUI();
            defaultFile=fullfile(appRoot,'data','HybridBus_ComponentDatabase.xlsx');
            app.loadDatabase(defaultFile);
            app.Figure.Visible='on';
        end
    end

    methods (Access=private)
        function buildUI(app)
            app.Figure=uifigure('Name','Hybrid-Electric Bus Configuration Explorer', ...
                'Position',[80 60 1400 820],'Visible','off');
            app.Figure.CloseRequestFcn=@(~,~)app.closeApp();
            root=uigridlayout(app.Figure,[2 2]);
            root.RowHeight={'1x','fit'}; root.ColumnWidth={350,'1x'};
            root.Padding=[0 0 0 0]; root.ColumnSpacing=8;
            side=uipanel(root,'Title','Configuration'); side.Layout.Row=1; side.Layout.Column=1;
            sideGrid=uigridlayout(side,[19 2]);
            sideGrid.RowHeight=[repmat({'fit'},1,18),{'1x'}];
            sideGrid.ColumnWidth={140,'1x'}; sideGrid.Padding=[10 10 10 10];
            addLabel(sideGrid,'Database',1); dbGrid=uigridlayout(sideGrid,[1 2]);
            dbGrid.Layout.Row=1; dbGrid.Layout.Column=2; dbGrid.ColumnWidth={'1x','fit'};
            dbGrid.Padding=[0 0 0 0];
            app.DatabaseField=uieditfield(dbGrid,'text','Editable','off');
            uibutton(dbGrid,'Text','...','ButtonPushedFcn',@(~,~)app.browseDatabase());

            missionPanel=uipanel(sideGrid,'Title','Mission Inputs');
            missionPanel.Layout.Row=2; missionPanel.Layout.Column=[1 2];
            missionGrid=uigridlayout(missionPanel,[5 2]);
            missionGrid.RowHeight={'fit','fit','fit','fit','fit'};
            missionGrid.ColumnWidth={120,'1x'};
            missionGrid.Padding=[8 6 8 6]; missionGrid.RowSpacing=5;
            app.RouteDropDown=app.addDropDown(missionGrid,'Route',1);
            app.RouteDropDown.ValueChangedFcn=@(~,~)app.updateRouteMap();
            app.LoadTonnesField=app.addNumber(missionGrid,'Load (tonnes)',2,0,[0 inf]);
            app.LoadTonnesField.Tooltip='Passenger, luggage, and cargo load in metric tonnes.';
            app.LoadTonnesField.ValueChangedFcn=@(~,~)app.updateCalculatedMass();
            app.CurbMassTonnesField=app.addNumber(missionGrid,'Calculated curb (t)',3,15,[0 inf]);
            app.CurbMassTonnesField.Editable='off';
            app.CurbMassTonnesField.Tooltip='15 t base vehicle + installed batteries + Hybrid genset.';
            app.TotalMassTonnesField=app.addNumber(missionGrid,'Total mass (t)',4,15,[0 inf]);
            app.TotalMassTonnesField.Editable='off';
            app.TotalMassTonnesField.Tooltip='Calculated curb mass + entered load.';
            app.AuxDropDown=app.addDropDown(missionGrid,'Auxiliary',5);

            app.Battery1DropDown=app.addDropDown(sideGrid,'Battery 1',3);
            app.Battery2DropDown=app.addDropDown(sideGrid,'Battery 2',4);
            app.MotorDropDown=app.addDropDown(sideGrid,'Hub motor pair',5);
            app.GensetDropDown=app.addDropDown(sideGrid,'Genset',6);
            app.Battery1DropDown.ValueChangedFcn=@(~,~)app.updateCalculatedMass();
            app.Battery2DropDown.ValueChangedFcn=@(~,~)app.updateCalculatedMass();
            app.GensetDropDown.ValueChangedFcn=@(~,~)app.updateCalculatedMass();
            app.BatterySetMultiplierField=app.addNumber(sideGrid,'Battery set multiplier',7,1,[0.5 inf]);
            app.BatterySetMultiplierField.Tooltip=[ ...
                'Hybrid: positive whole sets; each set has one active and one standby pack. ' ...
                'BEV: positive half-set steps; 0.5/1/1.5 sets mean 1/2/3 connected packs.'];
            app.BatterySetMultiplierField.ValueChangedFcn=@(~,~)app.updateBatterySetMultiplier();
            app.SOE1Field=app.addNumber(sideGrid,'Initial B1 SOE (%)',8,85,[10 95]);
            app.SOE2Field=app.addNumber(sideGrid,'Initial B2 SOE (%)',9,20,[10 95]);
            app.SOE1Field.ValueChangedFcn=@(~,~)app.synchronizeBEVSOE(1);
            app.SOE2Field.ValueChangedFcn=@(~,~)app.synchronizeBEVSOE(2);
            app.FuelPriceField=app.addNumber(sideGrid,'Fuel price (EUR/L)',10,2.10,[0 inf]);
            app.ElectricityPriceField=app.addNumber(sideGrid,'Electricity (EUR/kWh)',11,0.40,[0 inf]);
            app.MaxConfigurationsField=app.addNumber(sideGrid,'Max configurations',12,40,[1 1000]);
            addLabel(sideGrid,'Simulation formulation',13);
            app.SimulationFormulationSwitch=uidropdown(sideGrid, ...
                'Items',{'Backward','Constrained','Performance'},'Value','Backward', ...
                'ValueChangedFcn',@(~,~)app.updateSimulationFormulation(), ...
                'Tooltip',['Backward prescribes route speed. Constrained performs one fast route-time ' ...
                'pass with current/torque/force-limited achieved speed. Performance continues the ' ...
                'detailed forward mission calculation.']);
            app.SimulationFormulationSwitch.Layout.Row=13;
            app.SimulationFormulationSwitch.Layout.Column=2;
            app.RepeatRouteCheckBox=uicheckbox(sideGrid,'Text','Repeat route until depleted', ...
                'Value',false,'Tooltip',['Continuously repeat the selected route until the fuel tank ' ...
                'is empty and both batteries reach their usable-energy limits.']);
            app.RepeatRouteCheckBox.Layout.Row=14; app.RepeatRouteCheckBox.Layout.Column=[1 2];
            app.RunBEVThenHybridCheckBox=uicheckbox(sideGrid, ...
                'Text','Run BEV first, then Hybrid','Value',false, ...
                'Tooltip',['When Run Manual is pressed, simulate BEV first and Hybrid second ' ...
                'with the same mission configuration. Leave unchecked to run the slider selection.']);
            app.RunBEVThenHybridCheckBox.Layout.Row=15;
            app.RunBEVThenHybridCheckBox.Layout.Column=[1 2];
            buttonGrid=uigridlayout(sideGrid,[2 2]); buttonGrid.Layout.Row=[16 17];
            buttonGrid.Layout.Column=[1 2]; buttonGrid.ColumnWidth={'1x','1x'};
            buttonGrid.RowHeight={'fit','fit'}; buttonGrid.Padding=[0 0 0 0];
            uibutton(buttonGrid,'Text','Run Manual','ButtonPushedFcn',@(~,~)app.runManual());
            uibutton(buttonGrid,'Text','Optimize','ButtonPushedFcn',@(~,~)app.runOptimization());
            uibutton(buttonGrid,'Text','Cancel','ButtonPushedFcn',@(~,~)app.requestCancel());
            uibutton(buttonGrid,'Text','Export','ButtonPushedFcn',@(~,~)app.exportCurrent());
            app.StatusLabel=uilabel(sideGrid,'Text','Ready','WordWrap','on');
            app.StatusLabel.Layout.Row=18; app.StatusLabel.Layout.Column=[1 2];

            tabs=uitabgroup(root); tabs.Layout.Row=1; tabs.Layout.Column=2;
            % Creation order defines the user-facing workflow and initial tab.
            architectureTab=uitab(tabs,'Title','Powertrain Architecture');
            routeMapTab=uitab(tabs,'Title','Route Map');
            summaryTab=uitab(tabs,'Title','KPIs');
            analysisTab=uitab(tabs,'Title','Simulation Analysis');
            credibilityTab=uitab(tabs,'Title','Model Credibility');
            rankTab=uitab(tabs,'Title','Optimization Ranking');
            plotTab=uitab(tabs,'Title','Signals');
            detailedTab=uitab(tabs,'Title','Detailed Plot');

            signalsGrid=uigridlayout(plotTab,[2 1]);
            signalsGrid.RowHeight={'fit','1x'}; signalsGrid.ColumnWidth={'1x'};
            signalsControlGrid=uigridlayout(signalsGrid,[1 3]);
            signalsControlGrid.Layout.Row=1; signalsControlGrid.Layout.Column=1;
            signalsControlGrid.ColumnWidth={'1x','fit','fit'};
            signalsControlGrid.Padding=[6 3 6 3];
            uilabel(signalsControlGrid,'Text','Signal histories','FontWeight','bold', ...
                'FontColor',[0.18 0.25 0.33]);
            uilabel(signalsControlGrid,'Text','X-axis:','HorizontalAlignment','right');
            [app.SignalsXAxisSwitch,signalsSwitchGrid]=createColoredModeSwitch( ...
                signalsControlGrid,{"Time","Distance"},"Time", ...
                @(src,~)app.updateXAxisMode(src.Value), ...
                'Toggle all signal plots between elapsed time and cumulative distance.');
            signalsSwitchGrid.Layout.Row=1; signalsSwitchGrid.Layout.Column=3;
            plotGrid=uigridlayout(signalsGrid,[2 2]);
            plotGrid.Layout.Row=2; plotGrid.Layout.Column=1;
            app.SpeedAxes=uiaxes(plotGrid); title(app.SpeedAxes,'Route speed'); grid(app.SpeedAxes,'on');
            app.PowerAxes=uiaxes(plotGrid); title(app.PowerAxes,'Power flow'); grid(app.PowerAxes,'on');
            app.BatteryAxes=uiaxes(plotGrid); title(app.BatteryAxes,'Battery SOE'); grid(app.BatteryAxes,'on');
            app.GensetAxes=uiaxes(plotGrid); title(app.GensetAxes,'Genset and fuel'); grid(app.GensetAxes,'on');
            detailedGrid=uigridlayout(detailedTab,[2 1]);
            detailedGrid.RowHeight={'fit','1x'}; detailedGrid.ColumnWidth={'1x'};
            selectorGrid=uigridlayout(detailedGrid,[1 4]);
            selectorGrid.Layout.Row=1; selectorGrid.Layout.Column=1;
            selectorGrid.ColumnWidth={'fit','1x','fit','fit'}; selectorGrid.Padding=[0 0 0 0];
            uilabel(selectorGrid,'Text','Plot:','FontWeight','bold');
            plotItems={'Vehicle Acceleration (m/s^2)','Vehicle Speed (km/h)', ...
                'Vehicle Distance (km)','Net Torque at the Wheels','Motor Torques', ...
                'Reduction Gear Torques','Wheel Power','Motor Power', ...
                'Battery Power','Engine Power','Blended Braking Power', ...
                'Pneumatic Brake Power'};
            app.DetailedPlotDropDown=uidropdown(selectorGrid,'Items',plotItems, ...
                'Value',plotItems{1},'ValueChangedFcn',@(~,~)app.updateDetailedPlot());
            uilabel(selectorGrid,'Text','X-axis:','HorizontalAlignment','right', ...
                'FontWeight','bold');
            [app.DetailedXAxisSwitch,detailedSwitchGrid]=createColoredModeSwitch( ...
                selectorGrid,{"Time","Distance"},"Time", ...
                @(src,~)app.updateXAxisMode(src.Value), ...
                'Toggle all signal plots between elapsed time and cumulative distance.');
            detailedSwitchGrid.Layout.Row=1; detailedSwitchGrid.Layout.Column=4;
            app.DetailedAxes=uiaxes(detailedGrid);
            app.DetailedAxes.Layout.Row=2; app.DetailedAxes.Layout.Column=1;
            title(app.DetailedAxes,'Run a simulation to view detailed signals');
            xlabel(app.DetailedAxes,'Time (min)'); grid(app.DetailedAxes,'on');
            routeMapGrid=uigridlayout(routeMapTab,[3 1]);
            routeMapGrid.RowHeight={'fit','1x',165}; routeMapGrid.ColumnWidth={'1x'};
            routeModeGrid=uigridlayout(routeMapGrid,[1 5]);
            routeModeGrid.Layout.Row=1; routeModeGrid.Layout.Column=1;
            routeModeGrid.ColumnWidth={'1x','fit','fit','fit','fit'};
            routeModeGrid.Padding=[6 3 6 3];
            uilabel(routeModeGrid,'Text','Route visualization', ...
                'FontWeight','bold','FontColor',[0.18 0.25 0.33]);
            uilabel(routeModeGrid,'Text','Map mode:','HorizontalAlignment','right');
            [app.RouteMapModeSwitch,routeMapSwitchGrid]=createColoredModeSwitch( ...
                routeModeGrid,{"2D","3D"},"2D", ...
                @(~,~)app.updateRouteMapMode(), ...
                'Toggle between the geographic 2D map and the 3D route profile.');
            routeMapSwitchGrid.Layout.Row=1; routeMapSwitchGrid.Layout.Column=3;
            app.Route3DMetricLabel=uilabel(routeModeGrid,'Text','3D quantity:', ...
                'HorizontalAlignment','right','Visible','off');
            app.Route3DMetricLabel.Layout.Row=1; app.Route3DMetricLabel.Layout.Column=4;
            [app.Route3DMetricSwitch,app.Route3DMetricSwitchGrid]=createColoredModeSwitch( ...
                routeModeGrid,{"Elevation","Slope"},"Elevation", ...
                @(~,~)app.updateRoute3DMetric(), ...
                'Show the 3D route using elevation in metres or road slope in percent.');
            app.Route3DMetricSwitchGrid.Layout.Row=1;
            app.Route3DMetricSwitchGrid.Layout.Column=5;
            app.Route3DMetricSwitchGrid.Visible='off';
            app.RouteMap2DPanel=uipanel(routeMapGrid,'BorderType','none');
            app.RouteMap2DPanel.Layout.Row=2; app.RouteMap2DPanel.Layout.Column=1;
            route2DGrid=uigridlayout(app.RouteMap2DPanel,[1 1]);
            route2DGrid.Padding=[0 0 0 0];
            app.RouteMapAxes=geoaxes(route2DGrid);
            app.RouteMap3DPanel=uipanel(routeMapGrid,'BorderType','none','Visible','off');
            app.RouteMap3DPanel.Layout.Row=2; app.RouteMap3DPanel.Layout.Column=1;
            route3DGrid=uigridlayout(app.RouteMap3DPanel,[1 1]);
            route3DGrid.Padding=[0 0 0 0];
            app.Route3DAxes=uiaxes(route3DGrid);
            app.RouteMapTable=uitable(routeMapGrid,'ColumnName',{'Property','Value'}, ...
                'ColumnWidth',{190,'auto'},'RowName',{});
            app.RouteMapTable.Layout.Row=3; app.RouteMapTable.Layout.Column=1;
            architectureGrid=uigridlayout(architectureTab,[3 1]);
            architectureGrid.RowHeight={'fit','fit','1x'}; architectureGrid.ColumnWidth={'1x'};
            architectureControls=uigridlayout(architectureGrid,[1 3]);
            architectureControls.Layout.Row=1; architectureControls.Layout.Column=1;
            architectureControls.ColumnWidth={'1x','fit','fit'};
            architectureControls.Padding=[6 3 6 3];
            uilabel(architectureControls,'Text','Selectable powertrain architecture', ...
                'FontWeight','bold','FontColor',[0.18 0.25 0.33]);
            uilabel(architectureControls,'Text','Powertrain:','HorizontalAlignment','right');
            [app.PowertrainModeSwitch,powertrainSwitchGrid]=createColoredModeSwitch( ...
                architectureControls,{"Hybrid","BEV"},"Hybrid", ...
                @(~,~)app.updatePowertrainMode(), ...
                'Toggle between isolated-genset hybrid and battery-electric operation.');
            powertrainSwitchGrid.Layout.Row=1; powertrainSwitchGrid.Layout.Column=3;
            app.ArchitectureNoteLabel=uilabel(architectureGrid,'WordWrap','on', ...
                'Text',['First-principles view: the genset is isolated from the traction DC bus and ' ...
                'charges only the standby battery at constant best-efficiency power. The active battery ' ...
                'alone supports traction until 30% SOE. Regeneration returns from the wheels through the ' ...
                'fixed reduction and motor-inverters, then supplies auxiliaries first, charges the active ' ...
                'battery second, and dissipates surplus power in the resistor load bank third. ' ...
                'Pneumatic friction brakes supply wheel-braking demand beyond regenerative capability. ' ...
                'Click any component block to inspect its selected specification and implemented role.']);
            app.ArchitectureNoteLabel.Layout.Row=2; app.ArchitectureNoteLabel.Layout.Column=1;
            app.ArchitectureAxes=uiaxes(architectureGrid);
            app.ArchitectureAxes.Layout.Row=3; app.ArchitectureAxes.Layout.Column=1;
            app.updateCalculatedMass();
            app.buildKPIDashboard(summaryTab);
            app.buildSimulationAnalysis(analysisTab);
            app.buildCredibilityDashboard(credibilityTab);
            app.loadCredibilityEvidence();
            rankGrid=uigridlayout(rankTab,[1 1]);
            app.RankingTable=uitable(rankGrid);
            app.StatusLabel=uilabel(root,'Text','Ready');
            app.StatusLabel.Layout.Row=2; app.StatusLabel.Layout.Column=[1 2];
        end

        function control=addDropDown(~,parent,labelText,row)
            addLabel(parent,labelText,row);
            control=uidropdown(parent,'Items',{'Loading...'});
            control.Layout.Row=row; control.Layout.Column=2;
        end

        function control=addNumber(~,parent,labelText,row,value,limits)
            addLabel(parent,labelText,row);
            control=uieditfield(parent,'numeric','Value',value,'Limits',limits);
            control.Layout.Row=row; control.Layout.Column=2;
        end

        function browseDatabase(app)
            [file,path]=uigetfile('*.xlsx','Select HybridBus database');
            if isequal(file,0),return,end
            app.loadDatabase(fullfile(path,file));
        end

        function loadDatabase(app,file)
            try
                db=load_hybrid_bus_database(string(file));
                report=validate_hybrid_bus_database(db);
                if ~report.IsValid,error('HybridBus:InvalidDatabase','%s',strjoin(report.Errors,newline));end
                app.Database=db; app.DatabaseField.Value=char(file);
                app.DatabaseField.Tooltip=char(file);
                if isfield(db,'Route_Catalog')
                    routeLabels=db.Route_Catalog.RouteName+" — "+db.Route_Catalog.RouteType;
                    app.RouteDropDown.Items=cellstr(routeLabels);
                    app.RouteDropDown.ItemsData=cellstr(db.Route_Catalog.RouteID);
                else
                    routeIDs=unique(db.Route_Time_Speed.RouteID,'stable');
                    app.RouteDropDown.Items=cellstr(routeIDs);
                    app.RouteDropDown.ItemsData=cellstr(routeIDs);
                end
                app.Battery1DropDown.Items=cellstr(db.Battery_Catalog.ComponentID);
                app.Battery2DropDown.Items=cellstr(db.Battery_Catalog.ComponentID);
                app.MotorDropDown.Items=cellstr(db.Motor_Catalog.ComponentID);
                app.GensetDropDown.Items=cellstr(db.Genset_Catalog.ComponentID);
                app.AuxDropDown.Items=cellstr(db.Aux_Load_Profiles.ComponentID);
                app.setDashboardSelections();
                app.updateRouteMap();
                app.StatusLabel.Text=sprintf('Validated database %s',db.Version);
            catch exception
                app.Figure.Visible='on';
                app.StatusLabel.Text='Database validation failed';
                drawnow;
                uialert(app.Figure,exception.message,'Database validation error');
            end
        end

        function setDashboardSelections(app)
            D=app.Database.Dashboard;
            app.RouteDropDown.Value=char(D.SelectedRoute);
            app.Battery1DropDown.Value=char(D.SelectedBattery1);
            app.Battery2DropDown.Value=char(D.SelectedBattery2);
            app.MotorDropDown.Value=char(D.SelectedMotor);
            app.GensetDropDown.Value=char(D.SelectedGenset);
            app.AuxDropDown.Value=char(D.SelectedAuxProfile);
            if isfield(D,'LoadMass_t'), app.LoadTonnesField.Value=double(D.LoadMass_t);
            else, app.LoadTonnesField.Value=0; end
            app.SOE1Field.Value=100*double(D.InitialBattery1SOE);
            app.SOE2Field.Value=100*double(D.InitialBattery2SOE);
            app.FuelPriceField.Value=double(D.FuelPrice);
            app.ElectricityPriceField.Value=double(D.ElectricityPrice);
            if isfield(D,'BatterySetMultiplier')
                app.BatterySetMultiplierField.Value=double(D.BatterySetMultiplier);
            else
                app.BatterySetMultiplierField.Value=1;
            end
            app.LastValidBatterySetMultiplier=app.BatterySetMultiplierField.Value;
            app.HybridSOE1Cache=app.SOE1Field.Value;
            app.HybridSOE2Cache=app.SOE2Field.Value;
            app.SimulationFormulationSwitch.Value='Backward';
            app.RepeatRouteCheckBox.Enable='on';
            app.updateCalculatedMass();
        end

        function updateSimulationFormulation(app)
            switch string(app.SimulationFormulationSwitch.Value)
                case "Constrained"
                    app.RepeatRouteCheckBox.Value=false;
                    app.RepeatRouteCheckBox.Enable='off';
                    app.StatusLabel.Text=[ ...
                        'Fast constrained mode: one route-time pass with current, torque, power, force, ' ...
                        'grade, and energy-limited achieved speed.'];
                case "Performance"
                    app.RepeatRouteCheckBox.Enable='on';
                    app.StatusLabel.Text= ...
                        'Forward performance mode: route speed is a target; actual speed follows available traction.';
                otherwise
                    app.RepeatRouteCheckBox.Enable='on';
                    app.StatusLabel.Text='Backward demand mode: route speed is prescribed.';
            end
        end

        function updatePowertrainMode(app)
            styleColoredModeSwitch(app.PowertrainModeSwitch);
            isBEV=strcmpi(string(app.PowertrainModeSwitch.Value),"BEV");
            if ~isBEV && abs(app.BatterySetMultiplierField.Value- ...
                    round(app.BatterySetMultiplierField.Value))>1e-9
                app.BatterySetMultiplierField.Value=max(1,round(app.BatterySetMultiplierField.Value));
                app.LastValidBatterySetMultiplier=app.BatterySetMultiplierField.Value;
            end
            if isBEV
                app.HybridSOE1Cache=app.SOE1Field.Value;
                app.HybridSOE2Cache=app.SOE2Field.Value;
                app.SOE1Field.Value=85; app.SOE2Field.Value=85;
                app.GensetDropDown.Enable='off';
                app.ArchitectureNoteLabel.Text=[ ...
                    'Battery-electric view: the battery set multiplier connects two packs per set; half-set ' ...
                'increments represent one additional pack. All connected packs start at the same SOE ' ...
                    '(85% by default), and the BMS shares power within each bank''s limits. Regeneration ' ...
                    'supplies auxiliaries first, charges the connected battery pack(s) second, and sends ' ...
                    'surplus to the resistor load bank third. Pneumatic friction brakes supply wheel-braking ' ...
                    'demand beyond regenerative capability. Click any block for specifications.'];
            else
                app.SOE1Field.Value=app.HybridSOE1Cache;
                app.SOE2Field.Value=app.HybridSOE2Cache;
                app.GensetDropDown.Enable='on';
                app.ArchitectureNoteLabel.Text=[ ...
                    'First-principles view: the genset is isolated from the traction DC bus and charges only ' ...
                    'the standby battery bank at constant best-efficiency power. The active battery bank supports ' ...
                    'traction until 30% SOE. Regeneration supplies auxiliaries first, the active battery ' ...
                    'second, and the resistor load bank third. Pneumatic friction brakes supply residual ' ...
                    'wheel-braking demand. Click any block for specifications.'];
            end
            app.updateCalculatedMass();
        end

        function updateBatterySetMultiplier(app)
            value=app.BatterySetMultiplierField.Value;
            isBEV=strcmpi(string(app.PowertrainModeSwitch.Value),"BEV");
            if isBEV
                isValid=value>=0.5 && abs(2*value-round(2*value))<=1e-9;
                requirement='BEV multiplier must be 0.5 or greater in 0.5-set increments.';
            else
                isValid=value>=1 && abs(value-round(value))<=1e-9;
                requirement='Hybrid multiplier must be a positive whole number of sets.';
            end
            if ~isValid
                app.BatterySetMultiplierField.Value=app.LastValidBatterySetMultiplier;
                uialert(app.Figure,requirement,'Invalid battery set multiplier');
                return
            end
            app.LastValidBatterySetMultiplier=value;
            app.updateCalculatedMass();
        end

        function mass=updateCalculatedMass(app)
            mass=struct;
            if isempty(fieldnames(app.Database)) || ...
                    isempty(app.Battery1DropDown.Value) || isempty(app.Battery2DropDown.Value) || ...
                    isempty(app.GensetDropDown.Value)
                return
            end
            battery1=app.Database.Battery_Catalog( ...
                app.Database.Battery_Catalog.ComponentID==string(app.Battery1DropDown.Value),:);
            battery2=app.Database.Battery_Catalog( ...
                app.Database.Battery_Catalog.ComponentID==string(app.Battery2DropDown.Value),:);
            genset=app.Database.Genset_Catalog( ...
                app.Database.Genset_Catalog.ComponentID==string(app.GensetDropDown.Value),:);
            if isempty(battery1) || isempty(battery2) || isempty(genset), return; end
            mode=string(app.PowertrainModeSwitch.Value);
            multiplier=app.BatterySetMultiplierField.Value;
            if mode=="BEV"
                totalPacks=round(2*multiplier);
                battery1Count=ceil(totalPacks/2);
                battery2Count=floor(totalPacks/2);
            else
                battery1Count=round(multiplier);
                battery2Count=round(multiplier);
            end
            mass=calculate_vehicle_mass(battery1.Mass_kg,battery1Count, ...
                battery2.Mass_kg,battery2Count,genset.Mass_kg,mode, ...
                app.LoadTonnesField.Value);
            app.CurbMassTonnesField.Value=mass.CurbMass_kg/1000;
            app.TotalMassTonnesField.Value=mass.TotalVehicleMass_kg/1000;
            app.drawPowertrainArchitecture();
        end

        function synchronizeBEVSOE(app,sourceBattery)
            if ~strcmpi(string(app.PowertrainModeSwitch.Value),"BEV"), return; end
            if sourceBattery==1, app.SOE2Field.Value=app.SOE1Field.Value;
            else, app.SOE1Field.Value=app.SOE2Field.Value; end
        end

        function O=gatherOverrides(app)
            dashboard=app.Database.Dashboard;
            O=struct('SelectedRoute',string(app.RouteDropDown.Value), ...
                'SelectedBattery1',string(app.Battery1DropDown.Value), ...
                'SelectedBattery2',string(app.Battery2DropDown.Value), ...
                'SelectedMotor',string(app.MotorDropDown.Value), ...
                'SelectedGenset',string(app.GensetDropDown.Value), ...
                'SelectedTyre',string(dashboard.SelectedTyre), ...
                'SelectedFinalDrive',string(dashboard.SelectedFinalDrive), ...
                'SelectedMass',string(dashboard.SelectedMass), ...
                'SelectedAuxProfile',string(app.AuxDropDown.Value), ...
                'SelectedEnvironment',string(dashboard.SelectedEnvironment), ...
                'SelectedControl',string(dashboard.SelectedControl), ...
                'InitialBattery1SOE',app.SOE1Field.Value/100, ...
                'InitialBattery2SOE',app.SOE2Field.Value/100, ...
                'InitialActiveBattery',double(dashboard.InitialActiveBattery), ...
                'AuxiliaryScalarOverride',double(dashboard.AuxiliaryScalarOverride), ...
                'FuelTankCapacity',double(dashboard.FuelTankCapacity), ...
                'FuelPrice',app.FuelPriceField.Value, ...
                'ElectricityPrice',app.ElectricityPriceField.Value, ...
                'SimulationFormulation',app.formulationValue(), ...
                'RepeatUntilDepleted',app.RepeatRouteCheckBox.Value, ...
                'LoadMass_t',app.LoadTonnesField.Value);
            O.PowertrainMode=string(app.PowertrainModeSwitch.Value);
            O.BatterySetMultiplier=app.BatterySetMultiplierField.Value;
            if O.PowertrainMode=="BEV", O.InitialBattery2SOE=O.InitialBattery1SOE; end
        end

        function value=formulationValue(app)
            switch string(app.SimulationFormulationSwitch.Value)
                case "Constrained"
                    value="ConstrainedBackward";
                case "Performance"
                    value="ForwardPerformance";
                otherwise
                    value="BackwardDemand";
            end
        end

        function updateRouteMap(app)
            if isempty(fieldnames(app.Database)) || ~isfield(app.Database,'Route_Catalog')
                return
            end
            routeID=string(app.RouteDropDown.Value);
            catalog=app.Database.Route_Catalog;
            row=catalog(catalog.RouteID==routeID,:);
            if isempty(row),return,end
            app.RouteDropDown.Tooltip=char(row.RouteName+" - "+row.RouteType);
            ax=app.RouteMapAxes; cla(ax); hold(ax,'on');
            ax3=app.Route3DAxes; cla(ax3,'reset'); hold(ax3,'on');
            hasGeometry=isfield(app.Database,'Route_Geometry') && ...
                any(app.Database.Route_Geometry.RouteID==routeID);
            if hasGeometry
                geometry=app.Database.Route_Geometry( ...
                    app.Database.Route_Geometry.RouteID==routeID,:);
                geometry=sortrows(geometry,'Sequence');
                geoplot(ax,geometry.Latitude_deg,geometry.Longitude_deg, ...
                    'Color',[0.02 0.42 0.68],'LineWidth',2.2,'DisplayName','Route');
                geoscatter(ax,geometry.Latitude_deg(1),geometry.Longitude_deg(1), ...
                    70,[0.12 0.58 0.29],'filled','DisplayName','Start');
                geoscatter(ax,geometry.Latitude_deg(end),geometry.Longitude_deg(end), ...
                    70,[0.78 0.20 0.15],'filled','DisplayName','Destination');
                latitudeSpan=max(geometry.Latitude_deg)-min(geometry.Latitude_deg);
                longitudeSpan=max(geometry.Longitude_deg)-min(geometry.Longitude_deg);
                latitudeMargin=max(0.02,0.08*latitudeSpan);
                longitudeMargin=max(0.02,0.08*longitudeSpan);
                geolimits(ax,[min(geometry.Latitude_deg)-latitudeMargin, ...
                    max(geometry.Latitude_deg)+latitudeMargin], ...
                    [min(geometry.Longitude_deg)-longitudeMargin, ...
                    max(geometry.Longitude_deg)+longitudeMargin]);
                legend(ax,'Location','best');
                locationText=sprintf('%.5f, %.5f  to  %.5f, %.5f', ...
                    geometry.Latitude_deg(1),geometry.Longitude_deg(1), ...
                    geometry.Latitude_deg(end),geometry.Longitude_deg(end));
                geometryText=sprintf('%d coordinate samples; %.1f km geographic polyline', ...
                    height(geometry),geometry.CumulativeDistance_km(end));
                if ismember('Elevation_m',geometry.Properties.VariableNames) && ...
                        all(isfinite(geometry.Elevation_m))
                    elevation=geometry.Elevation_m;
                    slope=compute_route_slope_percent( ...
                        geometry.CumulativeDistance_km,elevation);
                    showSlope=strcmp(app.Route3DMetricSwitch.Value,'Slope');
                    if showSlope
                        displayValues=slope;
                        quantityName='Road slope'; quantityUnit='%';
                        titleSuffix='3D road slope';
                    else
                        displayValues=elevation;
                        quantityName='Elevation'; quantityUnit='m';
                        titleSuffix='3D terrain elevation';
                    end
                    axis(ax3,'on');
                    surface(ax3,[geometry.Longitude_deg geometry.Longitude_deg], ...
                        [geometry.Latitude_deg geometry.Latitude_deg], ...
                        [displayValues displayValues],[displayValues displayValues], ...
                        'FaceColor','none','EdgeColor','interp','LineWidth',2.8, ...
                        'DisplayName',quantityName);
                    valueSpan=max(displayValues)-min(displayValues);
                    if showSlope
                        displayFloor=min(displayValues)-max(1,0.08*valueSpan);
                    else
                        displayFloor=min(displayValues)-max(10,0.05*valueSpan);
                    end
                    plot3(ax3,geometry.Longitude_deg,geometry.Latitude_deg, ...
                        repmat(displayFloor,height(geometry),1), ...
                        'Color',[0.73 0.77 0.82],'LineWidth',0.8, ...
                        'DisplayName','Reference projection');
                    scatter3(ax3,geometry.Longitude_deg(1),geometry.Latitude_deg(1), ...
                        displayValues(1),75,[0.12 0.58 0.29],'filled', ...
                        'DisplayName','Start');
                    scatter3(ax3,geometry.Longitude_deg(end),geometry.Latitude_deg(end), ...
                        displayValues(end),75,[0.78 0.20 0.15],'filled', ...
                        'DisplayName','Destination');
                    xlabel(ax3,'Longitude (deg)'); ylabel(ax3,'Latitude (deg)');
                    zlabel(ax3,sprintf('%s (%s)',quantityName,quantityUnit));
                    grid(ax3,'on'); box(ax3,'on');
                    view(ax3,[-42 26]); colormap(ax3,turbo(256));
                    colorScale=colorbar(ax3);
                    colorScale.Label.String=sprintf('%s (%s)',quantityName,quantityUnit);
                    title(ax3,char(row.RouteName+" - "+titleSuffix));
                    legend(ax3,'Location','best');
                    elevationGain=sum(max(diff(elevation),0));
                    elevationText=sprintf('%.0f to %.0f m; total ascent %.0f m', ...
                        min(elevation),max(elevation),elevationGain);
                    slopeText=sprintf('%.1f%% downhill to %.1f%% uphill; derived from elevation/path distance', ...
                        min(slope),max(slope));
                    displayText=sprintf('%s (%s)',quantityName,quantityUnit);
                    elevationSource=char(geometry.ElevationSource(1));
                else
                    app.showUnavailable3DRoute('Elevation data are unavailable for this route');
                    elevationText='Not available';
                    slopeText='Not available';
                    displayText='Not available';
                    elevationSource='No elevation source stored';
                end
            else
                geolimits(ax,[35 65],[-15 30]);
                geoplot(ax,NaN,NaN);
                locationText='Not applicable - this mission is not tied to a real road corridor';
                geometryText='No latitude/longitude geometry stored; coordinates are intentionally not fabricated';
                app.showUnavailable3DRoute('No geographic route geometry is available');
                elevationText='Not applicable';
                slopeText='Not applicable';
                displayText='Not applicable';
                elevationSource='Not applicable';
            end
            try
                geobasemap(ax,'streets-light');
            catch
                geobasemap(ax,'none');
            end
            title(ax,char(row.RouteName+" - "+row.RouteType));
            hold(ax,'off');
            hold(ax3,'off');
            app.RouteMapTable.Data={ ...
                'Route ID',char(routeID); ...
                'Region',char(row.Region); ...
                'Catalog distance',sprintf('%.1f km',row.Distance_km); ...
                'Coordinates',locationText; ...
                'Geometry',geometryText; ...
                'Elevation',elevationText; ...
                'Slope',slopeText; ...
                '3D display',displayText; ...
                'Elevation source',elevationSource; ...
                'Source',char(row.SourceOrganization); ...
                'License',char(row.License)};
            app.updateRouteMapMode();
        end

        function updateRouteMapMode(app)
            show3D=strcmp(app.RouteMapModeSwitch.Value,'3D');
            styleColoredModeSwitch(app.RouteMapModeSwitch);
            if show3D
                app.RouteMap2DPanel.Visible='off';
                app.RouteMap3DPanel.Visible='on';
                app.Route3DMetricLabel.Visible='on';
                app.Route3DMetricSwitchGrid.Visible='on';
            else
                app.RouteMap2DPanel.Visible='on';
                app.RouteMap3DPanel.Visible='off';
                app.Route3DMetricLabel.Visible='off';
                app.Route3DMetricSwitchGrid.Visible='off';
            end
        end

        function updateRoute3DMetric(app)
            styleColoredModeSwitch(app.Route3DMetricSwitch);
            app.updateRouteMap();
        end

        function showUnavailable3DRoute(app,message)
            ax=app.Route3DAxes;
            text(ax,0.5,0.5,0.5,message,'HorizontalAlignment','center', ...
                'FontWeight','bold','Color',[0.35 0.40 0.46]);
            xlim(ax,[0 1]); ylim(ax,[0 1]); zlim(ax,[0 1]);
            view(ax,3); axis(ax,'off');
        end

        function runManual(app)
            app.CancelRequested=false; app.StatusLabel.Text='Running manual configuration...'; drawnow;
            try
                app.CurrentPowertrainSequence=[];
                app.CurrentPowertrainSequence=run_powertrain_sequence(app.Database, ...
                    app.gatherOverrides(),app.RunBEVThenHybridCheckBox.Value, ...
                    ProgressFcn=@(mode,index,total)app.powertrainSequenceProgress(mode,index,total), ...
                    CancelFcn=@()app.CancelRequested);
                app.CurrentResults=app.CurrentPowertrainSequence.SelectedResult;
                app.updateResults(app.CurrentResults);
                if app.RunBEVThenHybridCheckBox.Value
                    bev=app.CurrentPowertrainSequence.BEV.Summary;
                    hybrid=app.CurrentPowertrainSequence.Hybrid.Summary;
                    app.StatusLabel.Text=sprintf( ...
                        'Comparison complete (BEV -> Hybrid): %.4f vs %.4f EUR/km', ...
                        bev.CostPer_km,hybrid.CostPer_km);
                    app.AnalysisHeaderLabel.Text=sprintf([ ...
                        'BEV -> HYBRID COMPARISON | BEV %.4f EUR/km, %.1f kWh grid equivalent | ' ...
                        'Hybrid %.4f EUR/km, %.1f L fuel | plots show Hybrid'], ...
                        bev.CostPer_km,bev.GridEquivalentEnergy_kWh, ...
                        hybrid.CostPer_km,hybrid.Fuel_L);
                else
                    app.StatusLabel.Text=sprintf('Complete: %.4f cost/km', ...
                        app.CurrentResults.Summary.CostPer_km);
                end
            catch exception
                app.StatusLabel.Text='Run failed'; uialert(app.Figure,exception.message,'Simulation error');
            end
        end

        function powertrainSequenceProgress(app,mode,index,total)
            app.StatusLabel.Text=sprintf('Running %s (%d/%d)...',mode,index,total);
            drawnow;
        end

        function runOptimization(app)
            app.CancelRequested=false; app.StatusLabel.Text='Optimizing...'; drawnow;
            try
                app.CurrentPowertrainSequence=[];
                if strcmpi(string(app.PowertrainModeSwitch.Value),"BEV")
                    varyComponents=["Battery1","Battery2","Motor","FinalDrive"];
                else
                    varyComponents=["Battery1","Motor","Genset","FinalDrive"];
                end
                app.CurrentOptimization=optimize_hybrid_bus_configuration( ...
                    string(app.DatabaseField.Value),Vary=varyComponents, ...
                    MaxConfigurations=round(app.MaxConfigurationsField.Value), ...
                    BaseOverrides=app.gatherOverrides(), ...
                    ProgressFcn=@(n,total,row)app.progress(n,total,row), ...
                    CancelFcn=@()app.CancelRequested,SaveResults=false);
                app.RankingTable.Data=app.CurrentOptimization.TopConfigurations;
                if ~isempty(app.CurrentOptimization.BestResult)
                    app.CurrentResults=app.CurrentOptimization.BestResult;
                    app.updateResults(app.CurrentResults);
                end
                app.StatusLabel.Text=sprintf('Optimization complete: %d evaluated', ...
                    height(app.CurrentOptimization.EvaluatedConfigurations));
            catch exception
                app.StatusLabel.Text='Optimization failed';
                uialert(app.Figure,exception.message,'Optimization error');
            end
        end

        function progress(app,n,total,row)
            app.StatusLabel.Text=sprintf('Evaluated %d/%d; latest cost %.4f',n,total,row.CostPer_km);
            drawnow limitrate;
        end

        function requestCancel(app)
            app.CancelRequested=true; app.StatusLabel.Text='Cancellation requested...'; drawnow;
        end

        function updateResults(app,R)
            tSeconds=R.Time(:);
            [x,xLabel,tickFormat]=select_plot_x_axis(tSeconds, ...
                R.Signals.Vehicle.Distance_m(:),string(app.SignalsXAxisSwitch.Value));
            if isfield(R.Signals.Vehicle,'DesiredSpeed_m_s') && ...
                    any(abs(R.Signals.Vehicle.DesiredSpeed_m_s-R.Signals.Vehicle.Speed_m_s)>1e-9)
                plot(app.SpeedAxes,x,R.Signals.Vehicle.DesiredSpeed_m_s*3.6,'--', ...
                    x,R.Signals.Vehicle.Speed_m_s*3.6,'LineWidth',1.2);
                legend(app.SpeedAxes,{'Desired','Achieved'},'Location','best');
            else
                plot(app.SpeedAxes,x,R.Signals.Vehicle.Speed_m_s*3.6,'LineWidth',1.2);
                legend(app.SpeedAxes,{'Vehicle speed'},'Location','best');
            end
            xlabel(app.SpeedAxes,xLabel); ylabel(app.SpeedAxes,'km/h');
            xtickformat(app.SpeedAxes,tickFormat);
            plot(app.PowerAxes,x,R.Signals.Wheel.Demand_kW,x,R.Signals.Motors.ElectricalPower_kW, ...
                x,R.Signals.Auxiliary.Power_kW,x,R.Signals.Regeneration.ResistorLoadBank_kW, ...
                x,R.Signals.Wheel.FrictionBrakePower_kW, ...
                'LineWidth',1.0);
            legend(app.PowerAxes,{'Wheel demand','Motor DC','Auxiliary', ...
                'Resistor load bank','Pneumatic brake'}, ...
                'Location','best');
            xlabel(app.PowerAxes,xLabel); ylabel(app.PowerAxes,'kW');
            xtickformat(app.PowerAxes,tickFormat);
            plot(app.BatteryAxes,x,100*R.Signals.Battery1.SOE, ...
                x,100*R.Signals.Battery2.SOE,'LineWidth',1.2);
            legend(app.BatteryAxes,{'Battery 1','Battery 2'},'Location','best');
            xlabel(app.BatteryAxes,xLabel); ylabel(app.BatteryAxes,'SOE (%)');
            xtickformat(app.BatteryAxes,tickFormat);
            ytickformat(app.BatteryAxes,'%.0f%%');
            yyaxis(app.GensetAxes,'left'); plot(app.GensetAxes,x,R.Signals.Genset.ElectricalPower_kW);
            ylabel(app.GensetAxes,'kW'); yyaxis(app.GensetAxes,'right');
            timeStep_s=[diff(tSeconds);median(diff(tSeconds))];
            plot(app.GensetAxes,x,cumsum(R.Signals.Genset.FuelRate_L_s.*timeStep_s));
            ylabel(app.GensetAxes,'Fuel (L)'); xlabel(app.GensetAxes,xLabel);
            xtickformat(app.GensetAxes,tickFormat);
            app.updateKPIDashboard(R);
            app.updateSimulationAnalysis(R);
            app.updateDetailedPlot();
        end

        function buildSimulationAnalysis(app,parent)
            layout=uigridlayout(parent,[3 2]);
            layout.RowHeight={68,'1x',230}; layout.ColumnWidth={'1x','1x'};
            layout.Padding=[16 14 16 16]; layout.RowSpacing=12; layout.ColumnSpacing=12;
            header=uipanel(layout,'BorderType','line');
            header.Layout.Row=1; header.Layout.Column=[1 2];
            headerGrid=uigridlayout(header,[1 1]); headerGrid.Padding=[16 8 16 8];
            app.AnalysisHeaderLabel=uilabel(headerGrid,'WordWrap','on','FontSize',12, ...
                'Text',['Run a manual case or optimization to generate an engineering interpretation ' ...
                'of energy use, battery duty, genset operation, and limiting constraints.']);
            app.AnalysisEnergyAxes=uiaxes(layout); app.AnalysisEnergyAxes.Layout.Row=2;
            app.AnalysisEnergyAxes.Layout.Column=1; title(app.AnalysisEnergyAxes,'Mission energy allocation');
            ylabel(app.AnalysisEnergyAxes,'Energy (kWh)'); grid(app.AnalysisEnergyAxes,'on');
            app.AnalysisDutyAxes=uiaxes(layout); app.AnalysisDutyAxes.Layout.Row=2;
            app.AnalysisDutyAxes.Layout.Column=2; title(app.AnalysisDutyAxes,'Active-battery duty share');
            app.AnalysisTable=uitable(layout,'ColumnName',{'Area','Value','Unit','Engineering assessment'}, ...
                'ColumnWidth',{155,90,80,'auto'},'RowName',{});
            app.AnalysisTable.Layout.Row=3; app.AnalysisTable.Layout.Column=[1 2];
        end

        function buildCredibilityDashboard(app,parent)
            layout=uigridlayout(parent,[3 2]);
            layout.RowHeight={62,'1x',245}; layout.ColumnWidth={'1x','1x'};
            layout.Padding=[16 14 16 16]; layout.RowSpacing=12; layout.ColumnSpacing=12;
            header=uipanel(layout,'BorderType','line');
            header.Layout.Row=1; header.Layout.Column=[1 2];
            headerGrid=uigridlayout(header,[1 2]); headerGrid.ColumnWidth={'1x','fit'};
            headerGrid.Padding=[14 7 14 7];
            app.CredibilityHeaderLabel=uilabel(headerGrid,'Text','No credibility evidence generated yet.', ...
                'FontSize',13,'FontWeight','bold','WordWrap','on');
            uibutton(headerGrid,'Text','Regenerate Evidence', ...
                'ButtonPushedFcn',@(~,~)app.regenerateCredibilityEvidence());
            app.CredibilityGateTable=uitable(layout,'ColumnName',{'Gate','Status','Evidence','Decision'}, ...
                'ColumnWidth',{180,125,260,'auto'},'RowName',{});
            app.CredibilityGateTable.Layout.Row=2; app.CredibilityGateTable.Layout.Column=[1 2];
            app.CredibilityAxes=uiaxes(layout); app.CredibilityAxes.Layout.Row=3;
            app.CredibilityAxes.Layout.Column=1; title(app.CredibilityAxes,'Cost sensitivity span');
            xlabel(app.CredibilityAxes,'Cost swing across low/high cases (%)'); grid(app.CredibilityAxes,'on');
            app.CredibilityBaselineTable=uitable(layout,'ColumnName', ...
                {'Concept','Cost (EUR/km)','Source energy (kWh/km)','Evidence level'}, ...
                'ColumnWidth',{190,95,120,'auto'},'RowName',{});
            app.CredibilityBaselineTable.Layout.Row=3; app.CredibilityBaselineTable.Layout.Column=2;
        end

        function regenerateCredibilityEvidence(app)
            app.StatusLabel.Text='Regenerating model credibility evidence...'; drawnow;
            try
                generate_model_credibility_report(string(app.DatabaseField.Value));
                app.loadCredibilityEvidence();
                app.StatusLabel.Text='Model credibility evidence refreshed';
            catch exception
                app.StatusLabel.Text='Credibility generation failed';
                uialert(app.Figure,exception.message,'Credibility report error');
            end
        end

        function loadCredibilityEvidence(app)
            evidenceFile=fullfile(fileparts(mfilename('fullpath')),'results','HybridBus_Credibility.mat');
            if ~isfile(evidenceFile),return,end
            loaded=load(evidenceFile,'Credibility'); C=loaded.Credibility;
            app.CredibilityGateTable.Data=C.GateSummary;
            B=C.BaselineComparison;
            app.CredibilityBaselineTable.Data=table(B.Concept,B.Cost_EUR_per_km, ...
                B.SourceEnergy_kWh_per_km,B.EvidenceLevel,'VariableNames', ...
                {'Concept','Cost_EUR_per_km','SourceEnergy_kWh_per_km','EvidenceLevel'});
            S=C.Sensitivity.Results;
            ax=app.CredibilityAxes; cla(ax);
            barh(ax,categorical(S.Parameter,S.Parameter),S.CostSwing_pct,'FaceColor',[0.05 0.45 0.63]);
            xlabel(ax,'Cost swing across low/high cases (%)'); title(ax,'Cost sensitivity span'); grid(ax,'on');
            behavior=C.GateSummary.Status(C.GateSummary.Gate=="Physics and control verification");
            equivalence=C.GateSummary.Status(C.GateSummary.Gate=="MATLAB-Simulink equivalence");
            app.CredibilityHeaderLabel.Text=sprintf( ...
                'CONCEPT VERIFICATION: %s   |   IMPLEMENTATION EQUIVALENCE: %s   |   VEHICLE VALIDATION: NOT AVAILABLE', ...
                behavior,equivalence);
        end

        function updateSimulationAnalysis(app,R)
            S=R.Summary; theme=kpiTheme();
            ax=app.AnalysisEnergyAxes; cla(ax);
            labels={'Grid equivalent','Genset output','Regenerated','Auxiliary', ...
                'Battery throughput','Load-bank waste','Friction braking'};
            energy=[S.GridEquivalentEnergy_kWh,S.GensetElectricalEnergy_kWh, ...
                S.RegeneratedEnergy_kWh,S.AuxiliaryEnergy_kWh,S.BatteryThroughput_kWh, ...
                S.ResistorLoadBankEnergy_kWh,S.FrictionBrakeEnergy_kWh];
            bar(ax,categorical(labels,labels),energy,'FaceColor',theme.primary);
            ylabel(ax,'Energy (kWh)'); title(ax,'Mission energy allocation'); grid(ax,'on');
            ax.XTickLabelRotation=18;

            dutyAx=app.AnalysisDutyAxes; cla(dutyAx);
            t=R.Time(:); dt=[diff(t);0]; active=R.Signals.Controller.ActiveBattery(:);
            duty=[sum(dt(active==1)),sum(dt(active==2))]/max(sum(dt),eps)*100;
            if any(duty>0)
                pie(dutyAx,duty,{sprintf('Battery 1  %.1f%%',duty(1)), ...
                    sprintf('Battery 2  %.1f%%',duty(2))});
                colororder(dutyAx,[theme.primary;theme.secondary]);
            end
            title(dutyAx,'Active-battery duty share');

            regenAccepted=S.RegenerationToAuxiliaryEnergy_kWh+S.RegenerationToActiveBatteryEnergy_kWh;
            regenUtilization=100*regenAccepted/max(S.RegeneratedEnergy_kWh,eps);
            runtimeMinutes=S.GensetRuntime_s/60;
            routeAssessment='Completed selected route';
            if isfield(S,'RouteCompleted') && ~S.RouteCompleted
                routeAssessment=sprintf('Incomplete: %.1f%% covered; %s', ...
                    S.RouteCompletion_pct,S.TerminationReason);
            elseif S.UnmetTractionEnergy_kWh>1e-3
                routeAssessment='Demand exceeded available propulsion energy';
            end
            b1Assessment=soeAssessment(S.FinalBattery1SOE,R.Signals.Controller.BatteryRoleSwitchSOE(1));
            b2Assessment=soeAssessment(S.FinalBattery2SOE,R.Signals.Controller.BatteryRoleSwitchSOE(1));
            unmetAssessment='No material unmet traction/DC energy';
            if S.UnmetTractionEnergy_kWh>1e-3, unmetAssessment='Review power sizing or depleted-energy endpoint'; end
            balanceAssessment='Conservation check passed';
            if S.EnergyBalanceError_kWh>1e-6, balanceAssessment='Review numerical energy residual'; end
            loadAssessment='No surplus regeneration was wasted';
            if S.ResistorLoadBankEnergy_kWh>1e-3, loadAssessment='Surplus regen safely dissipated after aux and battery limits'; end
            brakeAssessment='Regeneration and pneumatic braking satisfy the prescribed wheel demand';
            if S.UnmetBrakingEnergy_kWh>1e-6
                brakeAssessment='Braking demand is not fully satisfied; review actuator limits';
            end
            performanceRows=cell(0,4);
            if isfield(S,'SimulationFormulation') && ...
                    ~strcmpi(string(S.SimulationFormulation),"BackwardDemand")
                trackingAssessment='Target speed was achieved within the configured tolerance';
                if S.TimeBelowTarget_s>0
                    trackingAssessment=sprintf('Dominant limit: %s',S.PerformanceLimitingCause);
                end
                performanceRows={ ...
                    'Route completion',sprintf('%.1f',S.RouteCompletion_pct),'%',routeAssessment; ...
                    'Distance shortfall',sprintf('%.2f',S.DistanceShortfall_km),'km',S.TerminationReason; ...
                    'Maximum achieved speed',sprintf('%.1f',S.MaximumAchievedSpeed_kmh),'km/h','Forward plant response'; ...
                    'RMS speed tracking error',sprintf('%.2f',S.RMSSpeedError_kmh),'km/h',trackingAssessment; ...
                    'Time below target',sprintf('%.1f',S.TimeBelowTarget_s/60),'min',trackingAssessment};
            end
            app.AnalysisTable.Data=[performanceRows; { ...
                'Mission distance',sprintf('%.1f',S.RouteDistance_km),'km',routeAssessment; ...
                'Battery 1 final SOE',sprintf('%.1f',100*S.FinalBattery1SOE),'%',b1Assessment; ...
                'Battery 2 final SOE',sprintf('%.1f',100*S.FinalBattery2SOE),'%',b2Assessment; ...
                'Regeneration utilization',sprintf('%.1f',regenUtilization),'%', ...
                    'Auxiliary-first and active-battery-second recovery'; ...
                'Resistor load bank',sprintf('%.2f',S.ResistorLoadBankEnergy_kWh),'kWh',loadAssessment; ...
                'Pneumatic friction braking',sprintf('%.2f',S.FrictionBrakeEnergy_kWh),'kWh',brakeAssessment; ...
                'Genset operation',sprintf('%.1f / %d',runtimeMinutes,S.GensetStarts),'min / starts', ...
                    'Standby-only charging at the selected efficiency point'; ...
                'Unmet traction energy',sprintf('%.3f',S.UnmetTractionEnergy_kWh),'kWh',unmetAssessment; ...
                'Energy-balance error',formatSmallKPI(S.EnergyBalanceError_kWh),'kWh',balanceAssessment}];
            status='FEASIBLE';
            if ~R.Validation.IsFeasible, status='ENGINEERING ATTENTION'; end
            app.AnalysisHeaderLabel.Text=sprintf('%s | %.1f km simulated | %.2f EUR/km | %.1f L fuel | %d genset start(s)', ...
                status,S.RouteDistance_km,S.CostPer_km,S.Fuel_L,S.GensetStarts);
        end

        function buildKPIDashboard(app,parent)
            theme=kpiTheme();
            host=uigridlayout(parent,[1 1]); host.Padding=[0 0 0 0];
            subTabs=uitabgroup(host);
            executiveTab=uitab(subTabs,'Title','Executive Decision');
            scorecardTab=uitab(subTabs,'Title','Engineering Scorecard');
            performanceTab=uitab(subTabs,'Title','Vehicle Performance');
            robustnessTab=uitab(subTabs,'Title','Robustness');

            dashboard=uigridlayout(executiveTab,[4 2]);
            dashboard.RowHeight={68,82,'1x',132};
            dashboard.ColumnWidth={'1x','1x'};
            dashboard.Padding=[14 12 14 14];
            dashboard.RowSpacing=10; dashboard.ColumnSpacing=10;

            header=uipanel(dashboard,'BorderType','line','HighlightColor',theme.border);
            header.Layout.Row=1; header.Layout.Column=[1 2];
            headerGrid=uigridlayout(header,[2 2]);
            headerGrid.RowHeight={'fit','1x'}; headerGrid.ColumnWidth={'1x','fit'};
            headerGrid.Padding=[14 7 14 7];
            titleLabel=uilabel(headerGrid,'Text','ARCHITECTURE DECISION FOR THE SELECTED MISSION', ...
                'FontWeight','bold','FontSize',16,'FontColor',theme.primary);
            titleLabel.Layout.Row=1; titleLabel.Layout.Column=1;
            app.KPIStatusLabel=uilabel(headerGrid,'Text','AWAITING RUN', ...
                'FontWeight','bold','HorizontalAlignment','center', ...
                'FontColor',theme.warning);
            app.KPIStatusLabel.Layout.Row=1; app.KPIStatusLabel.Layout.Column=2;
            app.KPIContextLabel=uilabel(headerGrid, ...
                'Text','Run a manual case or optimization to populate the decision views.', ...
                'FontSize',11,'WordWrap','on');
            app.KPIContextLabel.Layout.Row=2; app.KPIContextLabel.Layout.Column=1;
            app.KPIRunScopeLabel=uilabel(headerGrid,'Text','No simulation evidence', ...
                'FontSize',10,'FontWeight','bold','FontColor',[0.40 0.44 0.48], ...
                'HorizontalAlignment','right');
            app.KPIRunScopeLabel.Layout.Row=2; app.KPIRunScopeLabel.Layout.Column=2;

            recommendation=uipanel(dashboard,'BorderType','line','HighlightColor',theme.primary);
            recommendation.Layout.Row=2; recommendation.Layout.Column=[1 2];
            recommendationGrid=uigridlayout(recommendation,[2 1]);
            recommendationGrid.RowHeight={'fit','1x'}; recommendationGrid.Padding=[16 8 16 8];
            app.KPIRecommendationLabel=uilabel(recommendationGrid,'Text','RUN A STUDY', ...
                'FontSize',20,'FontWeight','bold','FontColor',theme.primary);
            app.KPIRecommendationDetailLabel=uilabel(recommendationGrid, ...
                'Text','A cross-architecture recommendation requires both BEV and Hybrid results.', ...
                'WordWrap','on','FontSize',11);

            modes={'BEV','Hybrid'};
            colors={theme.success,theme.primary};
            for index=1:2
                mode=modes{index};
                panel=uipanel(dashboard,'Title',upper(mode),'FontWeight','bold', ...
                    'ForegroundColor',colors{index},'HighlightColor',colors{index});
                panel.Layout.Row=3; panel.Layout.Column=index;
                panelGrid=uigridlayout(panel,[1 1]); panelGrid.Padding=[8 6 8 8];
                resultTable=uitable(panelGrid,'ColumnName',{'Metric','Value','Unit'}, ...
                    'ColumnWidth',{175,105,'auto'},'RowName',{});
                resultTable.Data={'Run status','NOT RUN',''};
                app.KPIExecutiveTables.(mode)=resultTable;
            end

            insightGrid=uigridlayout(dashboard,[1 3]);
            insightGrid.Layout.Row=4; insightGrid.Layout.Column=[1 2];
            insightGrid.ColumnWidth={'1x','1x','1x'}; insightGrid.Padding=[0 0 0 0];
            insightGrid.ColumnSpacing=10;
            insightKeys={'Why','Alternative','Limits'};
            insightTitles={'WHY THIS RESULT','ALTERNATIVE VALUE','DECISION LIMITS'};
            insightColors={theme.success,theme.primary,theme.warning};
            for index=1:3
                panel=uipanel(insightGrid,'Title',insightTitles{index}, ...
                    'FontWeight','bold','ForegroundColor',insightColors{index}, ...
                    'HighlightColor',insightColors{index});
                panel.Layout.Column=index;
                panelGrid=uigridlayout(panel,[1 1]); panelGrid.Padding=[10 8 10 8];
                label=uilabel(panelGrid,'Text','Awaiting simulation evidence.', ...
                    'WordWrap','on','VerticalAlignment','top','FontSize',10);
                app.KPIExecutiveInsightLabels.(insightKeys{index})=label;
            end

            scoreLayout=uigridlayout(scorecardTab,[3 1]);
            scoreLayout.RowHeight={64,174,'1x'}; scoreLayout.Padding=[14 12 14 14];
            scoreLayout.RowSpacing=10;
            scoreHeader=uipanel(scoreLayout,'BorderType','line','HighlightColor',theme.border);
            scoreHeader.Layout.Row=1;
            scoreHeaderGrid=uigridlayout(scoreHeader,[1 1]); scoreHeaderGrid.Padding=[14 7 14 7];
            app.KPIScorecardHeaderLabel=uilabel(scoreHeaderGrid, ...
                'Text','FIRST-PRINCIPLES GATES — feasibility precedes economics', ...
                'FontSize',14,'FontWeight','bold','FontColor',theme.primary,'WordWrap','on');
            gateGrid=uigridlayout(scoreLayout,[1 4]); gateGrid.Layout.Row=2;
            gateGrid.ColumnWidth={'1x','1x','1x','1x'}; gateGrid.Padding=[0 0 0 0];
            gateGrid.ColumnSpacing=10;
            gateKeys={'Completion','Power','Energy','Economics'};
            gateTitles={'1  CAN IT COMPLETE?','2  CAN IT DELIVER POWER?', ...
                '3  DOES ENERGY BALANCE?','4  WHAT DOES IT COST?'};
            gateCriteria={'Mission or depletion endpoint','No unintended propulsion shortfall', ...
                'Conservation and terminal condition','Finite modeled operating cost'};
            for index=1:4
                panel=uipanel(gateGrid,'Title',gateTitles{index},'FontWeight','bold', ...
                    'HighlightColor',theme.border);
                panel.Layout.Column=index;
                panelGrid=uigridlayout(panel,[3 1]);
                panelGrid.RowHeight={'1x','fit','fit'}; panelGrid.Padding=[10 8 10 8];
                uilabel(panelGrid,'Text',gateCriteria{index},'WordWrap','on', ...
                    'VerticalAlignment','top','FontSize',10);
                bevLabel=uilabel(panelGrid,'Text','BEV   NOT RUN','FontWeight','bold', ...
                    'FontColor',[0.45 0.49 0.53]);
                hybridLabel=uilabel(panelGrid,'Text','HYBRID   NOT RUN','FontWeight','bold', ...
                    'FontColor',[0.45 0.49 0.53]);
                app.KPIScorecardGateLabels.(gateKeys{index})=struct( ...
                    'BEV',bevLabel,'Hybrid',hybridLabel);
            end
            app.KPIScorecardTable=uitable(scoreLayout, ...
                'ColumnName',{'Metric','Unit','Preference','BEV','Hybrid'}, ...
                'ColumnWidth',{185,105,145,120,120},'RowName',{});
            app.KPIScorecardTable.Layout.Row=3;

            performanceLayout=uigridlayout(performanceTab,[4 2]);
            performanceLayout.RowHeight={64,'1x',188,92};
            performanceLayout.ColumnWidth={'3x','2x'};
            performanceLayout.Padding=[14 12 14 14];
            performanceLayout.RowSpacing=10; performanceLayout.ColumnSpacing=10;
            performanceHeader=uipanel(performanceLayout,'BorderType','line', ...
                'HighlightColor',theme.border);
            performanceHeader.Layout.Row=1; performanceHeader.Layout.Column=[1 2];
            performanceHeaderGrid=uigridlayout(performanceHeader,[1 1]);
            performanceHeaderGrid.Padding=[14 7 14 7];
            app.KPIPerformanceHeaderLabel=uilabel(performanceHeaderGrid, ...
                'Text','VEHICLE PERFORMANCE — achievable speed and route delivery', ...
                'FontSize',14,'FontWeight','bold','FontColor',theme.primary,'WordWrap','on');
            app.KPIPerformanceSpeedAxes=uiaxes(performanceLayout);
            app.KPIPerformanceSpeedAxes.Layout.Row=2;
            app.KPIPerformanceSpeedAxes.Layout.Column=1;
            title(app.KPIPerformanceSpeedAxes,'Target versus achieved vehicle speed');
            xlabel(app.KPIPerformanceSpeedAxes,'Elapsed time');
            ylabel(app.KPIPerformanceSpeedAxes,'Speed (km/h)');
            grid(app.KPIPerformanceSpeedAxes,'on');
            app.KPIPerformanceComparisonAxes=uiaxes(performanceLayout);
            app.KPIPerformanceComparisonAxes.Layout.Row=2;
            app.KPIPerformanceComparisonAxes.Layout.Column=2;
            title(app.KPIPerformanceComparisonAxes,'Performance delivery');
            ylabel(app.KPIPerformanceComparisonAxes,'Achievement (%)');
            grid(app.KPIPerformanceComparisonAxes,'on');
            app.KPIPerformanceTable=uitable(performanceLayout, ...
                'ColumnName',{'Powertrain','Formulation','Route completion','Distance shortfall', ...
                'Max achieved speed','RMS / max speed error','Time below target','Dominant limit','Termination'}, ...
                'ColumnWidth',{80,115,105,105,115,130,110,145,'auto'},'RowName',{});
            app.KPIPerformanceTable.Layout.Row=3;
            app.KPIPerformanceTable.Layout.Column=[1 2];
            performanceAssessment=uipanel(performanceLayout,'Title','PERFORMANCE DECISION', ...
                'FontWeight','bold','HighlightColor',theme.primary);
            performanceAssessment.Layout.Row=4;
            performanceAssessment.Layout.Column=[1 2];
            performanceAssessmentGrid=uigridlayout(performanceAssessment,[1 1]);
            performanceAssessmentGrid.Padding=[12 7 12 7];
            app.KPIPerformanceAssessmentLabel=uilabel(performanceAssessmentGrid, ...
                'Text',['Select Constrained or Performance and run the mission to assess ' ...
                'achievable speed under battery, motor, force, and energy limits.'], ...
                'WordWrap','on','VerticalAlignment','top','FontSize',11);

            robustnessLayout=uigridlayout(robustnessTab,[3 2]);
            robustnessLayout.RowHeight={64,'1x',180};
            robustnessLayout.ColumnWidth={'3x','2x'};
            robustnessLayout.Padding=[14 12 14 14];
            robustnessLayout.RowSpacing=10; robustnessLayout.ColumnSpacing=10;
            robustnessHeader=uipanel(robustnessLayout,'BorderType','line', ...
                'HighlightColor',theme.border);
            robustnessHeader.Layout.Row=1; robustnessHeader.Layout.Column=[1 2];
            robustnessHeaderGrid=uigridlayout(robustnessHeader,[1 1]);
            robustnessHeaderGrid.Padding=[14 7 14 7];
            app.KPIRobustnessHeaderLabel=uilabel(robustnessHeaderGrid, ...
                'Text','MISSION ROBUSTNESS — nominal evidence and unassessed scenarios', ...
                'FontSize',14,'FontWeight','bold','FontColor',theme.primary,'WordWrap','on');
            app.KPIRobustnessAxes=uiaxes(robustnessLayout);
            app.KPIRobustnessAxes.Layout.Row=2; app.KPIRobustnessAxes.Layout.Column=1;
            title(app.KPIRobustnessAxes,'Operating cost vs source energy');
            xlabel(app.KPIRobustnessAxes,'Source energy (kWh/km) — lower is better');
            ylabel(app.KPIRobustnessAxes,'Operating cost (EUR/km) — lower is better');
            grid(app.KPIRobustnessAxes,'on');
            app.KPIRobustnessTable=uitable(robustnessLayout, ...
                'ColumnName',{'Scenario','BEV','Hybrid'}, ...
                'ColumnWidth',{'auto','auto','auto'},'RowName',{});
            app.KPIRobustnessTable.Layout.Row=2; app.KPIRobustnessTable.Layout.Column=2;
            summaryPanel=uipanel(robustnessLayout,'Title','WHAT MANAGEMENT SHOULD KNOW', ...
                'FontWeight','bold','HighlightColor',theme.primary);
            summaryPanel.Layout.Row=3; summaryPanel.Layout.Column=[1 2];
            summaryGrid=uigridlayout(summaryPanel,[1 1]); summaryGrid.Padding=[12 8 12 8];
            app.KPIRobustnessSummaryLabel=uilabel(summaryGrid, ...
                'Text',['Choose by mission feasibility first, then operating economics, ' ...
                'then robustness and evidence confidence.'],'WordWrap','on', ...
                'VerticalAlignment','top','FontSize',11);
        end

        function createKPICard(app,parent,row,column,key,titleText,unitText,iconType,accent)
            panel=uipanel(parent,'BorderType','line','HighlightColor',accent);
            panel.Layout.Row=row; panel.Layout.Column=column;
            gridLayout=uigridlayout(panel,[3 2]);
            gridLayout.RowHeight={'fit','1x','fit'};
            gridLayout.ColumnWidth={48,'1x'}; gridLayout.Padding=[12 10 12 10];
            gridLayout.RowSpacing=2; gridLayout.ColumnSpacing=10;
            iconAxes=uiaxes(gridLayout,'Visible','off','Color','none');
            iconAxes.Layout.Row=[1 3]; iconAxes.Layout.Column=1;
            app.drawKPIIcon(iconAxes,iconType,accent);
            heading=uilabel(gridLayout,'Text',titleText,'FontSize',11, ...
                'FontWeight','bold','WordWrap','on');
            heading.Layout.Row=1; heading.Layout.Column=2;
            value=uilabel(gridLayout,'Text','--','FontSize',24,'FontWeight','bold');
            value.Layout.Row=2; value.Layout.Column=2;
            unit=uilabel(gridLayout,'Text',unitText,'FontSize',10,'FontColor',[0.36 0.40 0.45]);
            unit.Layout.Row=3; unit.Layout.Column=2;
            app.KPICards.(key)=struct('Value',value,'Unit',unit,'Panel',panel);
        end

        function drawKPIIcon(~,ax,iconType,color)
            hold(ax,'on'); axis(ax,[0 1 0 1]); axis(ax,'equal'); ax.XTick=[]; ax.YTick=[];
            lw=2.2;
            switch iconType
                case 'route'
                    plot(ax,[.18 .38 .66 .82],[.22 .72 .38 .78],'-o','Color',color, ...
                        'LineWidth',lw,'MarkerFaceColor',[1 1 1],'MarkerSize',5);
                case 'cost'
                    rectangle(ax,'Position',[.22 .18 .56 .64],'Curvature',.18,'EdgeColor',color,'LineWidth',lw);
                    text(ax,.5,.5,char(8364),'HorizontalAlignment','center','FontWeight','bold','FontSize',18,'Color',color);
                case 'fuel'
                    rectangle(ax,'Position',[.22 .2 .42 .62],'Curvature',.08,'EdgeColor',color,'LineWidth',lw);
                    plot(ax,[.64 .78 .78],[.68 .62 .3],'Color',color,'LineWidth',lw);
                    plot(ax,[.31 .55],[.67 .67],'Color',color,'LineWidth',lw);
                case 'energy'
                    patch(ax,[.55 .3 .49 .42 .7 .52],[.9 .48 .48 .12 .58 .58],color,'EdgeColor','none');
                case 'grid'
                    rectangle(ax,'Position',[.18 .22 .64 .56],'Curvature',.08,'EdgeColor',color,'LineWidth',lw);
                    plot(ax,[.38 .38],[.47 .68],'Color',color,'LineWidth',lw); plot(ax,[.62 .62],[.47 .68],'Color',color,'LineWidth',lw);
                    plot(ax,[.5 .5],[.22 .42],'Color',color,'LineWidth',lw);
                case 'regen'
                    th=linspace(.3,1.8*pi,40); plot(ax,.5+.29*cos(th),.5+.29*sin(th),'Color',color,'LineWidth',lw);
                    patch(ax,[.17 .34 .25],[.37 .35 .53],color,'EdgeColor','none');
                case 'aux'
                    plot(ax,[.5 .5],[.18 .82],'Color',color,'LineWidth',lw); plot(ax,[.18 .82],[.5 .5],'Color',color,'LineWidth',lw);
                    rectangle(ax,'Position',[.25 .25 .5 .5],'Curvature',[1 1],'EdgeColor',color,'LineWidth',lw);
                case 'battery'
                    rectangle(ax,'Position',[.16 .27 .66 .46],'Curvature',.08,'EdgeColor',color,'LineWidth',lw);
                    rectangle(ax,'Position',[.82 .4 .07 .2],'FaceColor',color,'EdgeColor',color);
                    plot(ax,[.34 .34],[.38 .62],'Color',color,'LineWidth',lw); plot(ax,[.27 .41],[.5 .5],'Color',color,'LineWidth',lw);
                case 'alert'
                    patch(ax,[.5 .15 .85],[.84 .2 .2],[1 1 1],'EdgeColor',color,'LineWidth',lw);
                    text(ax,.5,.39,'!','HorizontalAlignment','center','FontWeight','bold','FontSize',18,'Color',color);
                otherwise
                    plot(ax,[.18 .35 .48 .62 .82],[.62 .43 .55 .3 .7],'Color',color,'LineWidth',lw);
                    plot(ax,[.18 .82],[.2 .2],'Color',color,'LineWidth',1.2);
            end
            hold(ax,'off');
        end

        function updateKPIDashboard(app,R)
            [bev,hybrid,scope]=app.resolveKPIResults(R);
            isRepeat=app.kpiRepeatMode(R);
            routeName=string(app.RouteDropDown.Value);
            app.KPIContextLabel.Text=sprintf('%s  |  %.2f t total mass  |  %s  |  %s', ...
                routeName,R.Summary.EstimatedVehicleMass_kg/1000, ...
                string(app.AuxDropDown.Value),scope);
            app.KPIRunScopeLabel.Text=scope;
            app.KPIExecutiveTables.BEV.Data=app.executiveKPIData(bev,isRepeat);
            app.KPIExecutiveTables.Hybrid.Data=app.executiveKPIData(hybrid,isRepeat);

            [headline,detail,whyText,alternativeText]=app.kpiDecision(bev,hybrid,isRepeat);
            app.KPIRecommendationLabel.Text=headline;
            app.KPIRecommendationDetailLabel.Text=detail;
            app.KPIExecutiveInsightLabels.Why.Text=whyText;
            app.KPIExecutiveInsightLabels.Alternative.Text=alternativeText;
            app.KPIExecutiveInsightLabels.Limits.Text=[ ...
                'Concept-screening limits: charging/refuelling turnaround, battery thermal ageing, ' ...
                'emissions, weather derating, traffic variability, and measured-vehicle validation ' ...
                'are not yet complete decision evidence.'];

            app.KPIScorecardHeaderLabel.Text=sprintf( ...
                'FIRST-PRINCIPLES GATES | %s | feasibility precedes economics',scope);
            gateKeys={'Completion','Power','Energy','Economics'};
            for index=1:numel(gateKeys)
                key=gateKeys{index};
                bevStatus=app.kpiGateStatus(bev,key,isRepeat);
                hybridStatus=app.kpiGateStatus(hybrid,key,isRepeat);
                app.setGateLabel(app.KPIScorecardGateLabels.(key).BEV,'BEV',bevStatus);
                app.setGateLabel(app.KPIScorecardGateLabels.(key).Hybrid,'HYBRID',hybridStatus);
            end
            app.KPIScorecardTable.Data=app.scorecardKPIData(bev,hybrid,isRepeat);

            app.KPIRobustnessHeaderLabel.Text=sprintf( ...
                'MISSION ROBUSTNESS | %s | only executed cases are treated as evidence',scope);
            app.updateKPITradeSpace(bev,hybrid);
            app.KPIRobustnessTable.Data=app.robustnessKPIData(bev,hybrid,isRepeat);
            if isRepeat
                app.KPIRobustnessSummaryLabel.Text=[ ...
                    'Repeat-until-depleted is a controlled range study. Compare achieved range, ' ...
                    'source energy, and operating cost; low terminal SOE or a final depletion event ' ...
                    'is the intended endpoint, not an ordinary route-feasibility failure. ' ...
                    'Cold-weather, high-auxiliary, and infrastructure cases remain NOT ASSESSED.'];
            elseif isempty(bev) || isempty(hybrid)
                app.KPIRobustnessSummaryLabel.Text=[ ...
                    'Only one architecture was simulated. The dashboard can assess that result, ' ...
                    'but it cannot make a defensible BEV-versus-Hybrid recommendation until the ordered ' ...
                    'comparison is run. Non-nominal scenarios remain NOT ASSESSED.'];
            else
                app.KPIRobustnessSummaryLabel.Text=[ ...
                    'Both architectures were simulated on the same selected mission. Choose by ' ...
                    'feasibility first, then operating economics and source energy. Operational ' ...
                    'infrastructure and non-nominal scenarios remain separate evidence gaps.'];
            end
            app.updateKPIPerformance(bev,hybrid,scope);

            theme=kpiTheme();
            if isRepeat
                app.KPIStatusLabel.Text='RANGE STUDY'; app.KPIStatusLabel.FontColor=theme.primary;
            elseif ~isempty(bev) && ~isempty(hybrid)
                app.KPIStatusLabel.Text='COMPARISON COMPLETE'; app.KPIStatusLabel.FontColor=theme.success;
            elseif R.Validation.IsFeasible
                app.KPIStatusLabel.Text='SINGLE MODE ASSESSED'; app.KPIStatusLabel.FontColor=theme.primary;
            else
                app.KPIStatusLabel.Text='ENGINEERING ATTENTION'; app.KPIStatusLabel.FontColor=theme.error;
            end
        end

        function [bev,hybrid,scope]=resolveKPIResults(app,R)
            bev=[]; hybrid=[];
            sequence=app.CurrentPowertrainSequence;
            if ~isempty(sequence) && isstruct(sequence) && isfield(sequence,'Results')
                if isfield(sequence,'BEV'), bev=sequence.BEV; end
                if isfield(sequence,'Hybrid'), hybrid=sequence.Hybrid; end
            else
                mode=string(R.Summary.PowertrainMode);
                if strcmpi(mode,'BEV'), bev=R; else, hybrid=R; end
            end
            if ~isempty(bev) && ~isempty(hybrid)
                scope='ORDERED BEV -> HYBRID';
            elseif ~isempty(bev)
                scope='BEV ONLY';
            else
                scope='HYBRID ONLY';
            end
            if app.kpiRepeatMode(R), scope=[scope ' | REPEAT TO DEPLETION']; end
        end

        function tf=kpiRepeatMode(~,R)
            tf=isfield(R,'InputParameters') && isfield(R.InputParameters,'RepeatUntilDepleted') && ...
                logical(R.InputParameters.RepeatUntilDepleted);
        end

        function data=executiveKPIData(app,R,isRepeat)
            if isempty(R)
                data={'Run status','NOT RUN','';'Mission evidence','Unavailable',''};
                return
            end
            S=R.Summary;
            if isRepeat, distanceName='Achieved range'; else, distanceName='Mission distance'; end
            data={ ...
                'Run status',app.kpiGateStatus(R,'Completion',isRepeat),''; ...
                distanceName,sprintf('%.1f',S.RouteDistance_km),'km'; ...
                'Operating cost',sprintf('%.3f',S.CostPer_km),'EUR/km'; ...
                'Source energy',sprintf('%.3f',S.TotalSourceEnergy_kWh_per_km),'kWh/km'; ...
                'Fuel use',sprintf('%.2f',S.Fuel_L_per_100km),'L/100 km'; ...
                'Terminal battery reserve',sprintf('%.1f',app.combinedReservePercent(R)),'%'; ...
                'Unmet traction/DC energy',formatSmallKPI(S.UnmetTractionEnergy_kWh),'kWh'; ...
                'Energy-balance error',formatSmallKPI(S.EnergyBalanceError_kWh),'kWh'};
        end

        function [headline,detail,whyText,alternativeText]=kpiDecision(app,bev,hybrid,isRepeat)
            if isempty(bev) || isempty(hybrid)
                if ~isempty(bev), mode='BEV'; result=bev; else, mode='HYBRID'; result=hybrid; end
                if isRepeat
                    headline=[mode ' RANGE RESULT'];
                    detail=sprintf('%.1f km achieved before the controlled depletion endpoint. Comparison was not run.', ...
                        result.Summary.RouteDistance_km);
                    whyText='This view reports achieved range, energy intensity, and endpoint evidence for the selected architecture.';
                else
                    headline=[mode ' RESULT — COMPARISON NOT RUN'];
                    detail='The selected architecture has been assessed, but the alternative has no result for this mission.';
                    whyText='Use its feasibility gates, operating cost, source energy, and terminal reserve as a single-design assessment.';
                end
                alternativeText=['Run BEV first, then Hybrid to create a like-for-like decision. ' ...
                    'The unrun architecture is shown as NOT RUN, never estimated.'];
                return
            end

            if isRepeat
                bevRange=bev.Summary.RouteDistance_km; hybridRange=hybrid.Summary.RouteDistance_km;
                if abs(bevRange-hybridRange)<=0.01*max([bevRange,hybridRange,eps])
                    if bev.Summary.CostPer_km<=hybrid.Summary.CostPer_km, winner='BEV'; else, winner='HYBRID'; end
                    reason='Ranges are within 1%; lower modeled cost per kilometre is the tie-break.';
                elseif bevRange>hybridRange
                    winner='BEV'; reason='It achieves the longer controlled range-to-depletion.';
                else
                    winner='HYBRID'; reason='It achieves the longer controlled range-to-depletion.';
                end
                headline=['RANGE LEADER: ' winner];
                detail=sprintf('BEV %.1f km | Hybrid %.1f km. %s',bevRange,hybridRange,reason);
                whyText='Range is the primary repeat-study outcome; cost and source energy explain the operational trade-off.';
                alternativeText='The shorter-range architecture may still be preferable where charging/refuelling access, emissions, or duty scheduling dominate.';
                return
            end

            bevFeasible=app.normalMissionFeasible(bev);
            hybridFeasible=app.normalMissionFeasible(hybrid);
            if bevFeasible && ~hybridFeasible
                winner='BEV'; reason='BEV passes the mission gates while Hybrid requires engineering attention.';
            elseif hybridFeasible && ~bevFeasible
                winner='HYBRID'; reason='Hybrid passes the mission gates while BEV requires engineering attention.';
            elseif ~bevFeasible && ~hybridFeasible
                headline='NO FEASIBLE CHOICE';
                detail='Neither architecture satisfies the current mission gates. Resolve capability or energy shortfalls before comparing cost.';
                whyText='Feasibility is a hard gate; low modeled cost cannot compensate for undelivered traction/DC energy.';
                alternativeText='Review battery multiplier, motor sizing, vehicle load, auxiliaries, route severity, and energy replenishment.';
                return
            elseif bev.Summary.CostPer_km<=hybrid.Summary.CostPer_km
                winner='BEV'; reason='Both pass; BEV has the lower modeled operating cost per kilometre.';
            else
                winner='HYBRID'; reason='Both pass; Hybrid has the lower modeled operating cost per kilometre.';
            end
            headline=['RECOMMENDED FOR THIS MISSION: ' winner];
            detail=sprintf('%s BEV %.3f EUR/km | Hybrid %.3f EUR/km.', ...
                reason,bev.Summary.CostPer_km,hybrid.Summary.CostPer_km);
            whyText='The recommendation applies a feasibility-first rule, followed by modeled operating cost. Source energy and reserve remain visible supporting evidence.';
            alternativeText='The non-selected architecture remains relevant if infrastructure, turnaround, resilience, emissions, or validation evidence changes the operating case.';
        end

        function tf=normalMissionFeasible(~,R)
            tf=~isempty(R) && R.Validation.IsFeasible && ...
                R.Summary.UnmetTractionEnergy_kWh<=1e-3;
        end

        function status=kpiGateStatus(app,R,gate,isRepeat)
            if isempty(R), status='NOT RUN'; return; end
            S=R.Summary;
            switch gate
                case 'Completion'
                    if isRepeat
                        status='RANGE ESTABLISHED';
                    elseif app.normalMissionFeasible(R)
                        status='PASS';
                    else
                        status='ATTENTION';
                    end
                case 'Power'
                    if isRepeat
                        status='CONTROLLED ENDPOINT';
                    elseif S.UnmetTractionEnergy_kWh<=1e-3
                        status='PASS';
                    else
                        status='SHORTFALL';
                    end
                case 'Energy'
                    tolerance=R.InputParameters.Vehicle.EnergyBalanceTolerance_kWh;
                    if S.EnergyBalanceError_kWh<=tolerance
                        if isRepeat, status='BALANCED / DEPLETED'; else, status='PASS'; end
                    else
                        status='RESIDUAL';
                    end
                otherwise
                    if isfinite(S.CostPer_km), status='AVAILABLE'; else, status='REVIEW'; end
            end
        end

        function setGateLabel(~,label,mode,status)
            label.Text=sprintf('%s   %s',mode,status);
            theme=kpiTheme();
            if any(contains(status,{'PASS','AVAILABLE','ESTABLISHED','BALANCED'}))
                label.FontColor=theme.success;
            elseif any(contains(status,{'ATTENTION','SHORTFALL','RESIDUAL','REVIEW'}))
                label.FontColor=theme.error;
            elseif any(contains(status,{'ENDPOINT','DEPLETED'}))
                label.FontColor=theme.primary;
            else
                label.FontColor=[0.45 0.49 0.53];
            end
        end

        function data=scorecardKPIData(app,bev,hybrid,isRepeat)
            if isRepeat, distanceMetric='Achieved range'; distancePreference='Higher';
            else, distanceMetric='Mission distance'; distancePreference='Complete selected route'; end
            data={ ...
                distanceMetric,'km',distancePreference,app.kpiValue(bev,'RouteDistance_km','%.1f'),app.kpiValue(hybrid,'RouteDistance_km','%.1f'); ...
                'Total vehicle mass','t','Context',app.kpiValue(bev,'EstimatedVehicleMass_kg','%.2f',1/1000),app.kpiValue(hybrid,'EstimatedVehicleMass_kg','%.2f',1/1000); ...
                'Operating cost','EUR/km','Lower',app.kpiValue(bev,'CostPer_km','%.3f'),app.kpiValue(hybrid,'CostPer_km','%.3f'); ...
                'Source energy','kWh/km','Lower',app.kpiValue(bev,'TotalSourceEnergy_kWh_per_km','%.3f'),app.kpiValue(hybrid,'TotalSourceEnergy_kWh_per_km','%.3f'); ...
                'Fuel consumption','L/100 km','Lower',app.kpiValue(bev,'Fuel_L_per_100km','%.2f'),app.kpiValue(hybrid,'Fuel_L_per_100km','%.2f'); ...
                'Terminal battery reserve','%','Higher in normal mission',app.kpiReserveValue(bev),app.kpiReserveValue(hybrid); ...
                'Unmet traction/DC energy','kWh','Zero except controlled endpoint',app.kpiValue(bev,'UnmetTractionEnergy_kWh','%.3f'),app.kpiValue(hybrid,'UnmetTractionEnergy_kWh','%.3f'); ...
                'Energy-balance error','kWh','Within tolerance',app.kpiValue(bev,'EnergyBalanceError_kWh','%.3g'),app.kpiValue(hybrid,'EnergyBalanceError_kWh','%.3g')};
        end

        function value=kpiValue(~,R,fieldName,format,scale)
            if nargin<5, scale=1; end
            if isempty(R), value='NOT RUN'; return; end
            value=sprintf(format,scale*R.Summary.(fieldName));
        end

        function value=kpiReserveValue(app,R)
            if isempty(R), value='NOT RUN'; else, value=sprintf('%.1f',app.combinedReservePercent(R)); end
        end

        function reserve=combinedReservePercent(~,R)
            S=R.Summary; I=R.InputParameters;
            count1=max(0,S.Battery1PackCount); count2=max(0,S.Battery2PackCount);
            capacity1=count1*I.Battery1.UsableEnergy_kWh;
            capacity2=count2*I.Battery2.UsableEnergy_kWh;
            reserve=100*(capacity1*S.FinalBattery1SOE+capacity2*S.FinalBattery2SOE)/ ...
                max(capacity1+capacity2,eps);
        end

        function updateKPITradeSpace(app,bev,hybrid)
            ax=app.KPIRobustnessAxes; cla(ax); hold(ax,'on');
            theme=kpiTheme(); plotted=false; xValues=[]; yValues=[];
            if ~isempty(bev)
                scatter(ax,bev.Summary.TotalSourceEnergy_kWh_per_km,bev.Summary.CostPer_km, ...
                    110,theme.success,'filled');
                text(ax,bev.Summary.TotalSourceEnergy_kWh_per_km,bev.Summary.CostPer_km, ...
                    '  BEV','FontWeight','bold','Color',theme.success, ...
                    'VerticalAlignment','bottom');
                xValues(end+1)=bev.Summary.TotalSourceEnergy_kWh_per_km;
                yValues(end+1)=bev.Summary.CostPer_km;
                plotted=true;
            end
            if ~isempty(hybrid)
                scatter(ax,hybrid.Summary.TotalSourceEnergy_kWh_per_km,hybrid.Summary.CostPer_km, ...
                    110,theme.primary,'filled');
                text(ax,hybrid.Summary.TotalSourceEnergy_kWh_per_km,hybrid.Summary.CostPer_km, ...
                    '  Hybrid','FontWeight','bold','Color',theme.primary, ...
                    'VerticalAlignment','top');
                xValues(end+1)=hybrid.Summary.TotalSourceEnergy_kWh_per_km;
                yValues(end+1)=hybrid.Summary.CostPer_km;
                plotted=true;
            end
            hold(ax,'off'); grid(ax,'on'); box(ax,'on');
            title(ax,'Operating cost vs source energy — nominal executed results');
            xlabel(ax,'Source energy (kWh/km) — lower is better');
            ylabel(ax,'Operating cost (EUR/km) — lower is better');
            if plotted
                xSpan=max(xValues)-min(xValues); ySpan=max(yValues)-min(yValues);
                xMargin=max(0.05,0.12*max(xSpan,max(abs(xValues))));
                yMargin=max(0.05,0.12*max(ySpan,max(abs(yValues))));
                xlim(ax,[max(0,min(xValues)-xMargin),max(xValues)+xMargin]);
                ylim(ax,[max(0,min(yValues)-yMargin),max(yValues)+yMargin]);
            else
                text(ax,0.5,0.5,'Run a study to populate the trade space', ...
                    'Units','normalized','HorizontalAlignment','center');
            end
        end

        function updateKPIPerformance(app,bev,hybrid,scope)
            app.KPIPerformanceHeaderLabel.Text=sprintf( ...
                'VEHICLE PERFORMANCE | %s | target tracking after physical power and force limits',scope);
            results={}; labels={}; colors={};
            theme=kpiTheme();
            if ~isempty(bev)
                results{end+1}=bev; labels{end+1}='BEV'; colors{end+1}=theme.success;
            end
            if ~isempty(hybrid)
                results{end+1}=hybrid; labels{end+1}='Hybrid'; colors{end+1}=theme.primary;
            end

            speedAx=app.KPIPerformanceSpeedAxes;
            comparisonAx=app.KPIPerformanceComparisonAxes;
            cla(speedAx); cla(comparisonAx);
            evaluated=false(1,numel(results));
            tableData=cell(numel(results),9);
            metrics=zeros(numel(results),3);
            hold(speedAx,'on');
            targetPlotted=false;
            legendText=cell(1,numel(results)+1);
            legendCount=0;
            for index=1:numel(results)
                result=results{index}; summary=result.Summary;
                formulation=string(summary.SimulationFormulation);
                isEvaluated=~strcmpi(formulation,"BackwardDemand");
                evaluated(index)=isEvaluated;
                if ~isEvaluated
                    tableData(index,:)={labels{index},'Backward (prescribed)', ...
                        'NOT EVALUATED','—','—','—','—', ...
                        'Prescribed route speed','Achievable response not simulated'};
                    continue
                end

                [timeDisplay,timeLabel,timeTickFormat]=select_plot_x_axis( ...
                    result.Time(:),result.Signals.Vehicle.Distance_m(:),"Time");
                desired=result.Signals.Vehicle.DesiredSpeed_m_s(:)*3.6;
                achieved=result.Signals.Vehicle.Speed_m_s(:)*3.6;
                if ~targetPlotted
                    plot(speedAx,timeDisplay,desired,'--','Color',[0.32 0.35 0.39], ...
                        'LineWidth',1.25);
                    legendCount=legendCount+1;
                    legendText{legendCount}='Route target'; targetPlotted=true;
                end
                plot(speedAx,timeDisplay,achieved,'Color',colors{index},'LineWidth',1.45);
                legendCount=legendCount+1;
                legendText{legendCount}=[labels{index} ' achieved'];
                xlabel(speedAx,timeLabel);
                xtickformat(speedAx,timeTickFormat);

                compliance=app.performanceTrackingCompliance(result);
                speedAdequacy=100*min(1,summary.MaximumAchievedSpeed_kmh/ ...
                    max(max(desired),eps));
                metrics(index,:)=[summary.RouteCompletion_pct,compliance,speedAdequacy];
                tableData(index,:)={labels{index},app.performanceFormulationName(formulation), ...
                    sprintf('%.1f %%',summary.RouteCompletion_pct), ...
                    sprintf('%.2f km',summary.DistanceShortfall_km), ...
                    sprintf('%.1f km/h',summary.MaximumAchievedSpeed_kmh), ...
                    sprintf('%.2f / %.2f km/h',summary.RMSSpeedError_kmh,summary.MaximumSpeedError_kmh), ...
                    sprintf('%.1f min',summary.TimeBelowTarget_s/60), ...
                    char(summary.PerformanceLimitingCause),char(summary.TerminationReason)};
            end
            hold(speedAx,'off'); grid(speedAx,'on'); box(speedAx,'on');
            ylabel(speedAx,'Speed (km/h)');
            title(speedAx,'Target versus achieved vehicle speed');
            if any(evaluated)
                legend(speedAx,legendText(1:legendCount),'Location','best');
            else
                text(speedAx,0.5,0.5,['Achievable vehicle performance is not evaluated in ' ...
                    'prescribed-speed Backward mode.'],'Units','normalized', ...
                    'HorizontalAlignment','center','FontWeight','bold','Color',[0.4 0.44 0.48]);
                xlim(speedAx,[0 1]); ylim(speedAx,[0 1]);
                xlabel(speedAx,''); ylabel(speedAx,'');
            end

            app.KPIPerformanceTable.Data=tableData;
            evaluatedLabels=labels(evaluated);
            evaluatedMetrics=metrics(evaluated,:);
            if ~isempty(evaluatedMetrics)
                bars=bar(comparisonAx,categorical({'Route completion','Tracking compliance', ...
                    'Speed adequacy'}),evaluatedMetrics','grouped');
                evaluatedIndices=find(evaluated);
                for index=1:numel(bars)
                    bars(index).FaceColor=colors{evaluatedIndices(index)};
                end
                ylim(comparisonAx,[0 105]); yline(comparisonAx,100,'--','Target');
                legend(comparisonAx,evaluatedLabels,'Location','southoutside', ...
                    'Orientation','horizontal');
                comparisonAx.XTickLabelRotation=14;
            else
                text(comparisonAx,0.5,0.5,'Run Constrained or Performance mode', ...
                    'Units','normalized','HorizontalAlignment','center','FontWeight','bold', ...
                    'Color',[0.4 0.44 0.48]);
                xlim(comparisonAx,[0 1]); ylim(comparisonAx,[0 1]);
            end
            title(comparisonAx,'Performance delivery'); ylabel(comparisonAx,'Achievement (%)');
            grid(comparisonAx,'on'); box(comparisonAx,'on');
            app.KPIPerformanceAssessmentLabel.Text=app.performanceAssessment( ...
                results,labels,evaluated);
        end

        function compliance=performanceTrackingCompliance(~,result)
            target=result.Signals.Vehicle.DesiredSpeed_m_s(:);
            error=max(0,target-result.Signals.Vehicle.Speed_m_s(:));
            threshold=1.0;
            if isfield(result.InputParameters,'Performance') && ...
                    isfield(result.InputParameters.Performance,'SpeedTrackingTolerance_m_s')
                threshold=result.InputParameters.Performance.SpeedTrackingTolerance_m_s;
            end
            moving=target>0.5;
            if ~any(moving), compliance=100; return; end
            time=result.Time(:);
            if numel(time)>1
                timeStep=[diff(time);median(diff(time))];
            else
                timeStep=1;
            end
            movingTime=sum(timeStep(moving));
            belowTime=sum(timeStep(moving & error>threshold));
            compliance=100*max(0,1-belowTime/max(movingTime,eps));
        end

        function name=performanceFormulationName(~,formulation)
            if strcmpi(formulation,"ConstrainedBackward")
                name='Fast constrained';
            elseif strcmpi(formulation,"ForwardPerformance")
                name='Forward performance';
            else
                name=char(formulation);
            end
        end

        function textValue=performanceAssessment(~,results,labels,evaluated)
            if isempty(results)
                textValue='Run a mission to generate vehicle-performance evidence.'; return
            end
            if ~any(evaluated)
                textValue=['Backward mode prescribes route speed, so it evaluates energy demand but ' ...
                    'does not prove the vehicle can achieve that speed. Select Constrained for a fast ' ...
                    'capability screen or Performance for forward plant response.'];
                return
            end
            scores=-inf(1,numel(results));
            for index=find(evaluated)
                summary=results{index}.Summary;
                scores(index)=1000*double(summary.RouteCompleted)+summary.RouteCompletion_pct- ...
                    summary.RMSSpeedError_kmh-0.05*summary.TimeBelowTarget_s/60;
            end
            [~,winnerIndex]=max(scores);
            winner=results{winnerIndex}.Summary;
            if nnz(evaluated)==1
                if winner.RouteCompleted && winner.TimeBelowTarget_s<=1
                    prefix='PASS';
                elseif winner.RouteCompleted
                    prefix='COMPLETE WITH TRACKING LIMITS';
                else
                    prefix='CAPABILITY SHORTFALL';
                end
                textValue=sprintf(['%s — %s completes %.1f%% of the selected route, reaches %.1f km/h, ' ...
                    'and has %.2f km/h RMS speed error. Dominant constraint: %s.'], ...
                    prefix,labels{winnerIndex},winner.RouteCompletion_pct, ...
                    winner.MaximumAchievedSpeed_kmh,winner.RMSSpeedError_kmh, ...
                    winner.PerformanceLimitingCause);
            else
                evaluatedIndices=find(evaluated);
                firstIndex=evaluatedIndices(1); secondIndex=evaluatedIndices(2);
                textValue=sprintf(['PERFORMANCE LEADER: %s — feasibility and route completion are ' ...
                    'ranked before speed-tracking error. BEV: %.1f%% / %.2f km/h RMS; Hybrid: ' ...
                    '%.1f%% / %.2f km/h RMS. Use Executive Decision for the economics trade-off.'], ...
                    upper(labels{winnerIndex}),results{firstIndex}.Summary.RouteCompletion_pct, ...
                    results{firstIndex}.Summary.RMSSpeedError_kmh, ...
                    results{secondIndex}.Summary.RouteCompletion_pct, ...
                    results{secondIndex}.Summary.RMSSpeedError_kmh);
            end
        end

        function data=robustnessKPIData(app,bev,hybrid,isRepeat)
            data={ ...
                'Nominal executed mission',app.robustnessNominalStatus(bev,isRepeat),app.robustnessNominalStatus(hybrid,isRepeat); ...
                'Repeat-to-depletion endpoint',app.robustnessRepeatStatus(bev,isRepeat),app.robustnessRepeatStatus(hybrid,isRepeat); ...
                'Cold-weather battery capability',app.unassessedStatus(bev),app.unassessedStatus(hybrid); ...
                'High auxiliary-load scenario',app.unassessedStatus(bev),app.unassessedStatus(hybrid); ...
                'Charging / refuelling turnaround',app.unassessedStatus(bev),app.unassessedStatus(hybrid); ...
                'Measured-vehicle validation',app.unassessedStatus(bev),app.unassessedStatus(hybrid)};
        end

        function status=robustnessNominalStatus(app,R,isRepeat)
            if isempty(R)
                status='NOT RUN';
            elseif isRepeat
                status='RANGE';
            elseif app.normalMissionFeasible(R)
                status='PASS';
            else
                status='ATTENTION';
            end
        end

        function status=robustnessRepeatStatus(~,R,isRepeat)
            if isempty(R)
                status='NOT RUN';
            elseif isRepeat
                status='ACTIVE';
            else
                status='NOT REQUESTED';
            end
        end

        function status=unassessedStatus(~,R)
            if isempty(R), status='NOT RUN'; else, status='NOT ASSESSED'; end
        end

        function updateDetailedPlot(app)
            ax=app.DetailedAxes;
            cla(ax); legend(ax,'off'); grid(ax,'on');
            selection=string(app.DetailedPlotDropDown.Value);
            title(ax,selection); xlabel(ax,'Time (min)');
            if isempty(app.CurrentResults)
                ylabel(ax,'');
                text(ax,0.5,0.5,'Run a manual case or optimization first.', ...
                    'Units','normalized','HorizontalAlignment','center');
                return
            end

            R=app.CurrentResults; S=R.Signals;
            [x,xLabel,tickFormat]=select_plot_x_axis(R.Time(:), ...
                S.Vehicle.Distance_m(:),string(app.DetailedXAxisSwitch.Value));
            xlabel(ax,xLabel); xtickformat(ax,tickFormat);
            labels=strings(0,1);
            switch selection
                case "Vehicle Acceleration (m/s^2)"
                    values=S.Vehicle.Acceleration_m_s2;
                    yLabel='Acceleration (m/s^2)';
                case "Vehicle Speed (km/h)"
                    values=3.6*S.Vehicle.Speed_m_s;
                    yLabel='Speed (km/h)';
                case "Vehicle Distance (km)"
                    values=S.Vehicle.Distance_m/1000;
                    yLabel='Distance (km)';
                case "Net Torque at the Wheels"
                    values=S.Vehicle.TractiveForce_N*R.InputParameters.Tyre.LoadedRadius_m;
                    yLabel='Torque (N m)';
                case {"Motor Torques","Reduction Gear Torques","Motor Power"}
                    tyreRadius=max(R.InputParameters.Tyre.LoadedRadius_m,eps);
                    wheelSpeed=S.Vehicle.Speed_m_s/tyreRadius;
                    deliveredWheelTorque=zeros(size(x));
                    moving=abs(wheelSpeed)>1e-9;
                    deliveredWheelTorque(moving)=1000*S.Wheel.Delivered_kW(moving)./wheelSpeed(moving);
                    ratio=max(R.InputParameters.FinalDrive.Ratio,eps);
                    motorPairTorque=zeros(size(x));
                    motoring=deliveredWheelTorque>=0;
                    motorPairTorque(motoring)=deliveredWheelTorque(motoring)/ ...
                        (ratio*R.InputParameters.FinalDrive.MotoringEfficiency);
                    motorPairTorque(~motoring)=deliveredWheelTorque(~motoring)* ...
                        R.InputParameters.FinalDrive.RegenEfficiency/ratio;
                    if selection=="Motor Torques"
                        values=[motorPairTorque/2,motorPairTorque/2];
                        labels=["Motor 1","Motor 2"];
                        yLabel='Torque per motor (N m)';
                    elseif selection=="Reduction Gear Torques"
                        values=[motorPairTorque,deliveredWheelTorque];
                        labels=["Combined gear input","Gear output at wheels"];
                        yLabel='Torque (N m)';
                    else
                        motorMechanical=S.Wheel.Delivered_kW;
                        motorMechanical(motoring)=motorMechanical(motoring)/ ...
                            R.InputParameters.FinalDrive.MotoringEfficiency;
                        motorMechanical(~motoring)=motorMechanical(~motoring)* ...
                            R.InputParameters.FinalDrive.RegenEfficiency;
                        values=[motorMechanical,S.Motors.ElectricalPower_kW];
                        labels=["Motor shaft mechanical","Motor DC electrical"];
                        yLabel='Power (kW)';
                    end
                case "Wheel Power"
                    values=[S.Wheel.Demand_kW,S.Wheel.Delivered_kW, ...
                        S.Wheel.TotalDelivered_kW];
                    labels=["Demand","Motor/regen path","Total with friction brake"];
                    yLabel='Power (kW)';
                case "Battery Power"
                    values=[S.Battery1.Power_kW,S.Battery2.Power_kW, ...
                        S.Battery1.Power_kW+S.Battery2.Power_kW];
                    labels=["Battery 1","Battery 2","Total battery"];
                    yLabel='Power (kW)';
                case "Engine Power"
                    values=[S.Genset.MechanicalPower_kW,S.Genset.ElectricalPower_kW];
                    labels=["Engine mechanical","Generator electrical"];
                    yLabel='Power (kW)';
                case "Blended Braking Power"
                    values=[S.Wheel.BrakingDemand_kW,S.Wheel.RegenerativeBraking_kW, ...
                        S.Wheel.FrictionBrakePower_kW,S.Wheel.UnmetBraking_kW];
                    labels=["Braking demand","Regenerative braking", ...
                        "Pneumatic friction braking","Unmet braking"];
                    yLabel='Braking power magnitude (kW)';
                case "Pneumatic Brake Power"
                    values=S.Wheel.FrictionBrakePower_kW;
                    yLabel='Friction-brake power (kW)';
                otherwise
                    error('HybridBus:DetailedPlot','Unsupported detailed plot selection: %s',selection);
            end

            plot(ax,x,values,'LineWidth',1.2);
            ylabel(ax,yLabel); xlim(ax,[x(1),x(end)]);
            if ~isempty(labels)
                legend(ax,cellstr(labels),'Location','best');
            end
        end

        function updateXAxisMode(app,mode)
            app.SignalsXAxisSwitch.Value=mode;
            app.DetailedXAxisSwitch.Value=mode;
            styleColoredModeSwitch(app.SignalsXAxisSwitch);
            styleColoredModeSwitch(app.DetailedXAxisSwitch);
            if isempty(app.CurrentResults)
                if strcmp(mode,'Distance')
                    xLabel='Distance (km)';
                else
                    xLabel='Time (min)';
                end
                xlabel(app.SpeedAxes,xLabel); xlabel(app.PowerAxes,xLabel);
                xlabel(app.BatteryAxes,xLabel); xlabel(app.GensetAxes,xLabel);
                xlabel(app.DetailedAxes,xLabel);
                return
            end
            app.updateResults(app.CurrentResults);
        end

        function drawPowertrainArchitecture(app)
            if ~isempty(app.PowertrainModeSwitch) && ...
                    strcmpi(string(app.PowertrainModeSwitch.Value),"BEV")
                app.drawBEVPowertrainArchitecture();
                return
            end
            ax=app.ArchitectureAxes;
            setCount=max(1,round(app.BatterySetMultiplierField.Value));
            cla(ax); hold(ax,'on'); axis(ax,[0 142 0 60]); axis(ax,'off');
            daspect(ax,[1 1 1]); ax.Color=[0.975 0.985 0.99];

            fuel=[0.85 0.42 0.05]; mechanical=[0.49 0.24 0.74];
            electric=[0.02 0.49 0.50]; regen=[0.10 0.38 0.78];
            control=[0.38 0.44 0.50]; road=[0.16 0.50 0.35];
            charge=[0.92 0.48 0.08];
            dump=[0.72 0.26 0.12];
            friction=[0.62 0.25 0.16];

            % Subtle lanes keep the two energy domains visually separate.
            plot(ax,[2 140],[35 35],'Color',[0.86 0.89 0.91],'LineWidth',0.8);
            text(ax,2,49.5,'STANDBY CHARGING PATH','Color',charge,'FontSize',8.5, ...
                'FontWeight','bold','VerticalAlignment','bottom');
            text(ax,2,30,'ACTIVE TRACTION PATH','Color',electric,'FontSize',8.5, ...
                'FontWeight','bold','VerticalAlignment','bottom');
            text(ax,104,31.5, ...
                'REGEN RETURN (RIGHT TO LEFT):  WHEELS  >  FIXED REDUCTION  >  MOTOR / INVERTERS  >  PRIORITY SPLIT', ...
                'Color',regen,'FontSize',7.5,'FontWeight','bold', ...
                'HorizontalAlignment','center','VerticalAlignment','middle');
            text(ax,2,56,'SUPERVISORY CONTROL','Color',control,'FontSize',8.5, ...
                'FontWeight','bold','VerticalAlignment','middle');

            % Isolated genset-to-standby charging lane.
            architectureArrow(ax,11,43,14,43,fuel,2.1,'-');
            architectureArrow(ax,23,43,26,43,mechanical,2.1,'-');
            architectureArrow(ax,35,43,38,43,electric,2.1,'-');
            architectureArrow(ax,50,43,54,43,charge,2.1,'-');
            plot(ax,[61 61 43],[38 33 33],'Color',charge,'LineWidth',1.7);
            architectureArrow(ax,43,33,43,28,charge,1.7,'-');
            plot(ax,[61 79],[33 33],'Color',charge,'LineWidth',1.7);
            architectureArrow(ax,79,33,79,28,charge,1.7,'-');

            % Active-battery traction lane. Offset arrows make forward traction
            % and reverse regeneration directions independently traceable.
            architectureArrow(ax,49,21.5,54,21.5,electric,2.1,'-');
            architectureArrow(ax,54,24.5,49,24.5,regen,1.8,'-');
            architectureArrow(ax,73,21.5,68,21.5,electric,2.1,'-');
            architectureArrow(ax,68,24.5,73,24.5,regen,1.8,'-');
            plot(ax,[68 68 95],[26 31 31],'Color',electric,'LineWidth',2.1);
            architectureArrow(ax,95,31,95,29,electric,2.1,'-');
            architectureArrow(ax,100,21.5,104,21.5,electric,2.1,'-');
            architectureArrow(ax,104,24.5,100,24.5,regen,1.8,'-');
            architectureArrow(ax,117,21.5,121,21.5,mechanical,2.1,'-');
            architectureArrow(ax,121,24.5,117,24.5,regen,1.8,'-');
            architectureArrow(ax,129,21.5,133,21.5,road,2.1,'-');
            architectureArrow(ax,133,24.5,129,24.5,regen,1.8,'-');

            % The inverter DC-side regen node makes allocation order explicit:
            % (1) auxiliary loads, (2) traction bus to active battery, and
            % (3) resistor bank for the active pack's rejected remainder.
            plot(ax,103,24.5,'o','MarkerSize',5,'MarkerFaceColor',regen, ...
                'MarkerEdgeColor',regen);
            plot(ax,[103 103 109.5],[24.5 15 15],'Color',regen,'LineWidth',1.8);
            architectureArrow(ax,109.5,15,109.5,13,regen,1.8,'-');
            plot(ax,[103 103 91.5],[24.5 15 15],'Color',dump,'LineWidth',1.6);
            architectureArrow(ax,91.5,15,91.5,13,dump,1.6,'-');
            % Mechanical blended-braking branch at the wheels: motor
            % regeneration acts first; pneumatic friction brakes supply the residual.
            plot(ax,[137.5 137.5 132.5],[18 15 15],'Color',friction,'LineWidth',1.7);
            architectureArrow(ax,132.5,15,132.5,13,friction,1.7,'-');

            % Only two command links are needed: one for each selector.
            architectureArrow(ax,61,51.5,61,48,control,1.0,'--');
            plot(ax,[70 70 61],[51.5 31 31],'Color',control,'LineWidth',1.0,'LineStyle','--');
            architectureArrow(ax,61,31,61,28,control,1.0,'--');

            % Components are placed after links so every line terminates cleanly at a box edge.
            architectureBlock(ax,[2 39 9 8],'Diesel fuel','fuel',[1.00 0.95 0.87],fuel, ...
                @(~,~)app.showArchitectureSpecification("fuel"),"fuel");
            architectureBlock(ax,[14 39 9 8],'Engine','engine',[0.97 0.91 1.00],mechanical, ...
                @(~,~)app.showArchitectureSpecification("engine"),"engine");
            architectureBlock(ax,[26 39 9 8],'Generator','generator',[0.88 0.97 0.97],electric, ...
                @(~,~)app.showArchitectureSpecification("generator"),"generator");
            architectureBlock(ax,[38 38 12 10],sprintf('Fixed-point\ncharger'),'charger', ...
                [1.00 0.94 0.86],charge,@(~,~)app.showArchitectureSpecification("charger"),"charger");
            architectureBlock(ax,[54 38 14 10],sprintf('Standby\nselector'),'bus', ...
                [1.00 0.94 0.86],charge,@(~,~)app.showArchitectureSpecification("standby_selector"), ...
                "standby_selector");
            architectureBlock(ax,[37 18 12 10],sprintf('Battery 1 bank\n%d pack(s)',setCount),'battery', ...
                [0.89 0.94 1.00],regen,@(~,~)app.showArchitectureSpecification("battery1"),"battery1");
            architectureBlock(ax,[54 18 14 10],sprintf('2  Active battery\nselector'),'bus', ...
                [0.89 0.94 1.00],electric,@(~,~)app.showArchitectureSpecification("active_selector"), ...
                "active_selector");
            architectureBlock(ax,[73 18 12 10],sprintf('Battery 2 bank\n%d pack(s)',setCount),'battery', ...
                [0.89 0.94 1.00],regen,@(~,~)app.showArchitectureSpecification("battery2"),"battery2");
            architectureBlock(ax,[90 17 10 12],sprintf('Traction\nDC bus'),'bus', ...
                [0.88 0.97 0.97],electric,@(~,~)app.showArchitectureSpecification("traction_bus"), ...
                "traction_bus");
            architectureBlock(ax,[104 18 13 10],sprintf('Motor pair\n+ inverters'),'motor', ...
                [0.88 0.97 0.97],electric,@(~,~)app.showArchitectureSpecification("motors"),"motors");
            architectureBlock(ax,[121 18 8 10],sprintf('Fixed\nreduction'),'gear', ...
                [0.95 0.92 0.99],mechanical,@(~,~)app.showArchitectureSpecification("reduction"), ...
                "reduction");
            architectureBlock(ax,[133 18 9 10],sprintf('Wheels +\nvehicle'),'vehicle', ...
                [0.90 0.97 0.92],road,@(~,~)app.showArchitectureSpecification("vehicle"),"vehicle");
            architectureBlock(ax,[103 5 13 8],sprintf('1  DC auxiliary\nloads'),'aux', ...
                [0.91 0.97 0.95],electric,@(~,~)app.showArchitectureSpecification("auxiliary"), ...
                "auxiliary");
            architectureBlock(ax,[86 5 11 8],sprintf('3  Resistor\nload bank'),'resistor', ...
                [1.00 0.92 0.89],dump,@(~,~)app.showArchitectureSpecification("resistor"),"resistor");
            architectureBlock(ax,[125 5 15 8],sprintf('Pneumatic\nfriction brakes'),'brake', ...
                [1.00 0.93 0.90],friction,@(~,~)app.showArchitectureSpecification("friction_brake"), ...
                "friction_brake");
            architectureBlock(ax,[53 51.5 24 7],sprintf('Supervisory energy manager\n30%% role-swap rule'),'controller', ...
                [0.94 0.95 0.96],control,@(~,~)app.showArchitectureSpecification("controller"), ...
                "controller");

            % Compact key stays outside the flow lanes.
            legendY=59; legendX=[70 79.5 89 98.5 108 117.5 127];
            legendColors={fuel,mechanical,electric,regen,dump,friction,control};
            legendLabels={'Fuel','Shaft','Traction','Regen','Dump','Brake','Control'};
            for index=1:numel(legendX)
                lineStyle='-';
                if index==6,lineStyle='--';end
                plot(ax,[legendX(index) legendX(index)+2.5],[legendY legendY], ...
                    'Color',legendColors{index},'LineWidth',2, ...
                    'LineStyle',lineStyle);
                text(ax,legendX(index)+3,legendY,legendLabels{index}, ...
                    'VerticalAlignment','middle','FontSize',7,'Color',[0.18 0.23 0.28]);
            end
            hold(ax,'off');
        end

        function drawBEVPowertrainArchitecture(app)
            ax=app.ArchitectureAxes;
            cla(ax); hold(ax,'on'); axis(ax,[0 142 0 60]); axis(ax,'off');
            daspect(ax,[1 1 1]); ax.Color=[0.975 0.985 0.99];
            electric=[0.02 0.49 0.50]; regen=[0.10 0.38 0.78];
            mechanical=[0.49 0.24 0.74]; road=[0.16 0.50 0.35];
            control=[0.38 0.44 0.50]; dump=[0.72 0.26 0.12]; gridColor=[0.05 0.45 0.72];
            friction=[0.62 0.25 0.16];
            multiplier=app.BatterySetMultiplierField.Value;
            totalPacks=max(1,round(2*multiplier));
            battery1Count=ceil(totalPacks/2);
            battery2Count=floor(totalPacks/2);

            text(ax,3,54,'BATTERY-ELECTRIC POWERTRAIN','FontSize',9,'FontWeight','bold', ...
                'Color',electric);
            text(ax,72,52,'TRACTION: BATTERIES  >  DC BUS  >  MOTOR / INVERTERS  >  REDUCTION  >  WHEELS', ...
                'HorizontalAlignment','center','FontSize',8,'FontWeight','bold','Color',electric);
            text(ax,91,2,'REGEN PRIORITY: 1 AUXILIARIES   2 CONNECTED BATTERY PACK(S)   3 RESISTOR BANK', ...
                'HorizontalAlignment','center','FontSize',8,'FontWeight','bold','Color',regen);

            % Charging and parallel battery connection.
            architectureArrow(ax,13,37,18,37,gridColor,2,'-');
            plot(ax,[31 38 38],[37 37 32],'Color',gridColor,'LineWidth',1.8);
            architectureArrow(ax,38,32,38,29,gridColor,1.8,'-');
            plot(ax,[31 38 38],[37 37 20],'Color',gridColor,'LineWidth',1.8);
            architectureArrow(ax,38,20,38,17,gridColor,1.8,'-');
            architectureArrow(ax,50,25,57,25,electric,2.2,'-');
            architectureArrow(ax,57,28,50,28,regen,1.8,'-');
            plot(ax,[44 44 52 52],[29 32 32 28],'Color',electric,'LineWidth',1.8);
            if battery2Count>0
                plot(ax,[44 44 52 52],[17 14 14 25],'Color',electric,'LineWidth',1.8);
            else
                plot(ax,[44 52],[17 17],'Color',[0.60 0.64 0.68],'LineWidth',1.2,'LineStyle','--');
                text(ax,48,14.8,'disconnected','HorizontalAlignment','center','FontSize',7, ...
                    'Color',[0.45 0.48 0.52]);
            end

            % Bidirectional traction chain.
            architectureArrow(ax,70,25,77,25,electric,2.2,'-');
            architectureArrow(ax,77,28,70,28,regen,1.8,'-');
            architectureArrow(ax,91,25,98,25,mechanical,2.2,'-');
            architectureArrow(ax,98,28,91,28,regen,1.8,'-');
            architectureArrow(ax,110,25,117,25,road,2.2,'-');
            architectureArrow(ax,117,28,110,28,regen,1.8,'-');
            plot(ax,[76 76 71],[25 15 15],'Color',electric,'LineWidth',1.7);
            architectureArrow(ax,71,15,71,13,electric,1.7,'-');
            plot(ax,[76 76 88],[28 15 15],'Color',dump,'LineWidth',1.5);
            architectureArrow(ax,88,15,88,13,dump,1.5,'-');
            plot(ax,[124 124 120.5],[20 15 15],'Color',friction,'LineWidth',1.7);
            architectureArrow(ax,120.5,15,120.5,13,friction,1.7,'-');
            plot(ax,[64 64],[47 32],'Color',control,'LineStyle','--','LineWidth',1.0);

            architectureBlock(ax,[3 33 10 8],sprintf('Grid / depot\ncharger'),'charger', ...
                [0.89 0.95 1.00],gridColor,@(~,~)app.showArchitectureSpecification("grid_charger"),"grid_charger");
            architectureBlock(ax,[18 33 13 8],sprintf('Charge inlet +\nBMS'),'bus', ...
                [0.90 0.96 0.98],electric,@(~,~)app.showArchitectureSpecification("bev_controller"),"bev_controller");
            architectureBlock(ax,[32 20 12 9],sprintf('Battery 1 bank\n%d pack(s)',battery1Count),'battery', ...
                [0.89 0.94 1.00],regen,@(~,~)app.showArchitectureSpecification("battery1"),"battery1");
            if battery2Count>0, battery2Fill=[0.89 0.94 1.00]; battery2Edge=regen; battery2Text=sprintf('Battery 2 bank\n%d pack(s)',battery2Count);
            else, battery2Fill=[0.94 0.94 0.94]; battery2Edge=[0.55 0.58 0.61]; battery2Text='Battery 2\ndisconnected'; end
            architectureBlock(ax,[32 8 12 9],sprintf(battery2Text),'battery', ...
                battery2Fill,battery2Edge,@(~,~)app.showArchitectureSpecification("battery2"),"battery2");
            architectureBlock(ax,[52 20 18 12],sprintf('Parallel contactor + BMS\n%d connected pack(s)',totalPacks),'bus', ...
                [0.88 0.97 0.97],electric,@(~,~)app.showArchitectureSpecification("bev_controller"),"bev_controller");
            architectureBlock(ax,[77 20 14 12],sprintf('Motor pair\n+ inverters'),'motor', ...
                [0.88 0.97 0.97],electric,@(~,~)app.showArchitectureSpecification("motors"),"motors");
            architectureBlock(ax,[98 20 12 12],sprintf('Fixed\nreduction'),'gear', ...
                [0.95 0.92 0.99],mechanical,@(~,~)app.showArchitectureSpecification("reduction"),"reduction");
            architectureBlock(ax,[117 20 14 12],sprintf('Wheels +\nvehicle'),'vehicle', ...
                [0.90 0.97 0.92],road,@(~,~)app.showArchitectureSpecification("vehicle"),"vehicle");
            architectureBlock(ax,[64 5 14 8],sprintf('1  DC auxiliary\nloads'),'aux', ...
                [0.91 0.97 0.95],electric,@(~,~)app.showArchitectureSpecification("auxiliary"),"auxiliary");
            architectureBlock(ax,[82 5 13 8],sprintf('3  Resistor\nload bank'),'resistor', ...
                [1.00 0.92 0.89],dump,@(~,~)app.showArchitectureSpecification("resistor"),"resistor");
            architectureBlock(ax,[112 5 17 8],sprintf('Pneumatic\nfriction brakes'),'brake', ...
                [1.00 0.93 0.90],friction,@(~,~)app.showArchitectureSpecification("friction_brake"), ...
                "friction_brake");
            architectureBlock(ax,[52 47 24 7],sprintf('BEV supervisory controller\nparallel power sharing'),'controller', ...
                [0.94 0.95 0.96],control,@(~,~)app.showArchitectureSpecification("bev_controller"),"bev_controller");
            hold(ax,'off');
        end

        function showArchitectureSpecification(app,componentKey)
            try
                selections=app.architectureSelections();
                specification=architecture_component_specification( ...
                    app.Database,selections,string(componentKey));
                runtime=architecture_component_runtime_data( ...
                    app.CurrentResults,string(componentKey));
                if ~isempty(app.CurrentPowertrainSequence) && ...
                        app.CurrentPowertrainSequence.IsComparison
                    runtime.ScopeText="Hybrid displayed result | second result of ordered BEV then Hybrid run";
                end
                existing=findall(groot,'Type','figure','Tag','HybridBusComponentSpecification');
                if ~isempty(existing),delete(existing);end
                dialog=uifigure('Name',char(specification.Title+" Component Inspector"), ...
                    'Tag','HybridBusComponentSpecification','Position',[320 110 900 700], ...
                    'Resize','on');
                layout=uigridlayout(dialog,[2 1]);
                layout.RowHeight={'1x','fit'};
                layout.ColumnWidth={'1x'}; layout.Padding=[18 16 18 14];

                tabs=uitabgroup(layout);
                tabs.Layout.Row=1;
                specificationTab=uitab(tabs,'Title','Specification Information');
                kpiTab=uitab(tabs,'Title','Component KPIs');
                signalTab=uitab(tabs,'Title','Physical Signals');

                specificationLayout=uigridlayout(specificationTab,[3 1]);
                specificationLayout.RowHeight={'fit','fit','1x'};
                specificationLayout.ColumnWidth={'1x'};
                specificationLayout.Padding=[14 14 14 14];
                uilabel(specificationLayout,'Text',char(specification.Title), ...
                    'FontSize',20,'FontWeight','bold','FontColor',[0.12 0.25 0.36]);
                role=uilabel(specificationLayout,'Text',char(specification.Role),'WordWrap','on', ...
                    'FontSize',11,'FontColor',[0.28 0.34 0.39]);
                role.Layout.Row=2;
                tableView=uitable(specificationLayout,'Data',specification.Rows, ...
                    'ColumnName',specification.ColumnNames,'RowName',{}, ...
                    'ColumnWidth',{245,330,85});
                tableView.Layout.Row=3;

                kpiLayout=uigridlayout(kpiTab,[3 1]);
                kpiLayout.RowHeight={'fit','fit','1x'};
                kpiLayout.ColumnWidth={'1x'}; kpiLayout.Padding=[14 14 14 14];
                uilabel(kpiLayout,'Text',char(specification.Title+" — simulation KPIs"), ...
                    'FontSize',18,'FontWeight','bold','FontColor',[0.12 0.25 0.36]);
                scope=uilabel(kpiLayout,'Text',char(runtime.ScopeText),'WordWrap','on', ...
                    'FontSize',11,'FontColor',[0.30 0.38 0.44]);
                scope.Layout.Row=2;
                kpiTable=uitable(kpiLayout,'Data',runtime.KPIRows, ...
                    'ColumnName',{'Metric','Value','Unit','Interpretation'},'RowName',{}, ...
                    'ColumnWidth',{205,190,85,300});
                kpiTable.Layout.Row=3;

                signalLayout=uigridlayout(signalTab,[6 1]);
                signalLayout.RowHeight={'fit','fit','fit','1x','fit','1x'};
                signalLayout.ColumnWidth={'1x'}; signalLayout.Padding=[14 12 14 12];
                uilabel(signalLayout,'Text',char(specification.Title+" — physical signals"), ...
                    'FontSize',18,'FontWeight','bold','FontColor',[0.12 0.25 0.36]);
                signalNote=uilabel(signalLayout,'Text',char(runtime.SignalNote), ...
                    'WordWrap','on','FontSize',10,'FontColor',[0.30 0.38 0.44]);
                signalNote.Layout.Row=2;
                signalItems=cellstr(string({runtime.SignalOptions.Title}));
                signalItemData=num2cell(1:numel(runtime.SignalOptions));
                firstSelector=uidropdown(signalLayout,'Items',signalItems, ...
                    'ItemsData',signalItemData,'Value',1, ...
                    'Tooltip','Select the physical signal shown in the upper plot');
                firstSelector.Layout.Row=3;
                firstAxes=uiaxes(signalLayout); firstAxes.Layout.Row=4;
                secondDefault=min(2,numel(runtime.SignalOptions));
                secondSelector=uidropdown(signalLayout,'Items',signalItems, ...
                    'ItemsData',signalItemData,'Value',secondDefault, ...
                    'Tooltip','Select the physical signal shown in the lower plot');
                secondSelector.Layout.Row=5;
                secondAxes=uiaxes(signalLayout); secondAxes.Layout.Row=6;
                firstSelector.ValueChangedFcn=@(source,~) ...
                    app.plotArchitectureRuntimeSignal(firstAxes, ...
                    runtime.SignalOptions(source.Value));
                secondSelector.ValueChangedFcn=@(source,~) ...
                    app.plotArchitectureRuntimeSignal(secondAxes, ...
                    runtime.SignalOptions(source.Value));
                if ~runtime.HasResult
                    firstSelector.Enable='off'; secondSelector.Enable='off';
                end
                app.plotArchitectureRuntimeSignal(firstAxes, ...
                    runtime.SignalOptions(firstSelector.Value));
                app.plotArchitectureRuntimeSignal(secondAxes, ...
                    runtime.SignalOptions(secondSelector.Value));

                closeButton=uibutton(layout,'push','Text','Close', ...
                    'ButtonPushedFcn',@(~,~)delete(dialog));
                closeButton.Layout.Row=2;
                movegui(dialog,'center');
            catch exception
                uialert(app.Figure,exception.message,'Specification unavailable');
            end
        end

        function plotArchitectureRuntimeSignal(app,ax,group)
            cla(ax);
            if isempty(app.CurrentResults) || ~group.Available
                ax.Visible='off';
                text(ax,0.5,0.55,char(group.Title),'Units','normalized', ...
                    'HorizontalAlignment','center','FontWeight','bold', ...
                    'Color',[0.18 0.29 0.38]);
                text(ax,0.5,0.40,char(group.Message),'Units','normalized', ...
                    'HorizontalAlignment','center','VerticalAlignment','top', ...
                    'Color',[0.42 0.47 0.52]);
                return
            end
            values=group.Values;
            R=app.CurrentResults;
            if size(values,1)~=numel(R.Time)
                ax.Visible='off';
                text(ax,0.5,0.5,'Signal length does not match the displayed result.', ...
                    'Units','normalized','HorizontalAlignment','center');
                return
            end
            ax.Visible='on';
            [x,xLabel,tickFormat]=select_plot_x_axis(R.Time(:), ...
                R.Signals.Vehicle.Distance_m(:),"Time");
            plot(ax,x,values,'LineWidth',1.25);
            title(ax,char(group.Title),'FontWeight','bold');
            xlabel(ax,char(xLabel)); ylabel(ax,char(group.YLabel));
            grid(ax,'on'); xtickformat(ax,char(tickFormat));
            if numel(group.Names)>1
                legend(ax,cellstr(group.Names),'Location','best');
            end
        end

        function selections=architectureSelections(app)
            selections=app.Database.Dashboard;
            selections.SelectedBattery1=string(app.Battery1DropDown.Value);
            selections.SelectedBattery2=string(app.Battery2DropDown.Value);
            selections.SelectedMotor=string(app.MotorDropDown.Value);
            selections.SelectedGenset=string(app.GensetDropDown.Value);
            selections.SelectedMass=string(app.Database.Dashboard.SelectedMass);
            selections.SelectedAuxProfile=string(app.AuxDropDown.Value);
            selections.LoadMass_t=app.LoadTonnesField.Value;
            selections.InitialBattery1SOE=app.SOE1Field.Value/100;
            selections.InitialBattery2SOE=app.SOE2Field.Value/100;
            selections.PowertrainMode=string(app.PowertrainModeSwitch.Value);
            selections.BatterySetMultiplier=app.BatterySetMultiplierField.Value;
            if ~isempty(app.CurrentResults) && ...
                    isfield(app.CurrentResults,'InputParameters') && ...
                    isfield(app.CurrentResults.InputParameters,'SelectedIDs')
                ids=app.CurrentResults.InputParameters.SelectedIDs;
                selections.SelectedTyre=string(ids.Tyre);
                selections.SelectedFinalDrive=string(ids.FinalDrive);
                selections.SelectedControl=string(ids.Control);
            end
        end

        function exportCurrent(app)
            if isempty(app.CurrentResults)
                uialert(app.Figure,'Run a simulation first.','Nothing to export'); return
            end
            files=export_hybrid_bus_results(app.CurrentResults, ...
                fullfile(fileparts(mfilename('fullpath')),'results'));
            app.StatusLabel.Text='Exported '+string(files.MAT);
        end

        function closeApp(app)
            app.CancelRequested=true;
            if isvalid(app.Figure),delete(app.Figure);end
        end
    end
end

function label=addLabel(parent,textValue,row)
label=uilabel(parent,'Text',textValue);
label.Layout.Row=row; label.Layout.Column=1;
end

function architectureArrow(ax,x1,y1,x2,y2,color,lineWidth,lineStyle)
quiver(ax,x1,y1,x2-x1,y2-y1,0,'Color',color,'LineWidth',lineWidth, ...
    'LineStyle',lineStyle,'MaxHeadSize',0.55,'AutoScale','off');
end

function architectureBlock(ax,position,labelText,iconType,fillColor,edgeColor,clickCallback,componentKey)
x=position(1); y=position(2); width=position(3); height=position(4);
rectangle(ax,'Position',position,'Curvature',[0.12 0.12], ...
    'FaceColor',fillColor,'EdgeColor',edgeColor,'LineWidth',1.5);
centerX=x+width/2; iconY=y+0.66*height;

switch iconType
    case 'fuel'
        rectangle(ax,'Position',[centerX-1.8 iconY-1.2 3.6 2.4], ...
            'Curvature',[0.2 0.2],'EdgeColor',edgeColor,'LineWidth',1.2);
        plot(ax,[centerX+1.8 centerX+2.4 centerX+2.4], ...
            [iconY+0.7 iconY+0.7 iconY-0.3],'Color',edgeColor,'LineWidth',1.2);
        patch(ax,centerX+[-0.35 0 0.35],iconY+[-0.1 0.7 -0.1],edgeColor, ...
            'EdgeColor','none','FaceAlpha',0.75);
    case 'engine'
        rectangle(ax,'Position',[centerX-2.2 iconY-1.3 4.4 2.6], ...
            'EdgeColor',edgeColor,'LineWidth',1.2);
        for offset=[-1.2 0 1.2]
            plot(ax,[centerX+offset centerX+offset], ...
                [iconY-0.8 iconY+0.8],'Color',edgeColor,'LineWidth',1.1);
        end
        plot(ax,[centerX+2.2 centerX+2.8 centerX+2.8], ...
            [iconY+0.7 iconY+0.7 iconY+1.4],'Color',edgeColor,'LineWidth',1.2);
    case 'generator'
        rectangle(ax,'Position',[centerX-1.6 iconY-1.6 3.2 3.2], ...
            'Curvature',[1 1],'EdgeColor',edgeColor,'LineWidth',1.3);
        text(ax,centerX,iconY,'G','HorizontalAlignment','center', ...
            'VerticalAlignment','middle','Color',edgeColor,'FontWeight','bold','FontSize',10);
    case 'charger'
        rectangle(ax,'Position',[centerX-2.1 iconY-1.35 4.2 2.7], ...
            'Curvature',[0.15 0.15],'EdgeColor',edgeColor,'LineWidth',1.2);
        plot(ax,[centerX-2.8 centerX-2.1],[iconY+0.65 iconY+0.65], ...
            'Color',edgeColor,'LineWidth',1.2);
        plot(ax,[centerX+2.1 centerX+2.8],[iconY-0.65 iconY-0.65], ...
            'Color',edgeColor,'LineWidth',1.2);
        patch(ax,centerX+[-0.45 0.15 -0.05 0.5 -0.1 0.05], ...
            iconY+[1.0 0.25 0.25 -0.95 -0.2 -0.2],edgeColor, ...
            'EdgeColor','none','FaceAlpha',0.8);
    case 'bus'
        plot(ax,[centerX-1 centerX-1],[iconY-2 iconY+2], ...
            'Color',edgeColor,'LineWidth',2.4);
        plot(ax,[centerX+1 centerX+1],[iconY-2 iconY+2], ...
            'Color',edgeColor,'LineWidth',2.4);
        text(ax,centerX-1,iconY+2.5,'+','HorizontalAlignment','center', ...
            'Color',edgeColor,'FontWeight','bold');
        text(ax,centerX+1,iconY+2.5,'-','HorizontalAlignment','center', ...
            'Color',edgeColor,'FontWeight','bold');
    case 'motor'
        for offset=[-2 2]
            rectangle(ax,'Position',[centerX+offset-1.25 iconY-1.25 2.5 2.5], ...
                'Curvature',[1 1],'EdgeColor',edgeColor,'LineWidth',1.2);
            text(ax,centerX+offset,iconY,'M','HorizontalAlignment','center', ...
                'VerticalAlignment','middle','Color',edgeColor,'FontWeight','bold','FontSize',8);
        end
        plot(ax,[centerX-0.75 centerX+0.75],[iconY iconY], ...
            'Color',edgeColor,'LineWidth',1.2);
    case 'gear'
        rectangle(ax,'Position',[centerX-2.0 iconY-1.1 2.2 2.2], ...
            'Curvature',[1 1],'EdgeColor',edgeColor,'LineWidth',1.2);
        rectangle(ax,'Position',[centerX-0.1 iconY-1.8 3.0 3.0], ...
            'Curvature',[1 1],'EdgeColor',edgeColor,'LineWidth',1.2);
        plot(ax,[centerX-0.9 centerX-0.9],[iconY-0.5 iconY+0.5], ...
            'Color',edgeColor,'LineWidth',1.0);
        plot(ax,[centerX+1.4 centerX+1.4],[iconY-0.9 iconY+0.9], ...
            'Color',edgeColor,'LineWidth',1.0);
    case 'vehicle'
        rectangle(ax,'Position',[centerX-3.8 iconY-1.0 7.6 2.5], ...
            'Curvature',[0.18 0.18],'EdgeColor',edgeColor,'LineWidth',1.2);
        for offset=[-2.4 0 2.4]
            rectangle(ax,'Position',[centerX+offset-0.75 iconY+0.15 1.5 0.8], ...
                'FaceColor',[1 1 1],'EdgeColor',edgeColor,'LineWidth',0.7);
        end
        for offset=[-2.6 2.6]
            rectangle(ax,'Position',[centerX+offset-0.55 iconY-1.45 1.1 1.1], ...
                'Curvature',[1 1],'FaceColor',[0.18 0.23 0.28],'EdgeColor','none');
        end
    case 'battery'
        rectangle(ax,'Position',[centerX-2.4 iconY-1.4 4.8 2.8], ...
            'EdgeColor',edgeColor,'LineWidth',1.2);
        rectangle(ax,'Position',[centerX-0.55 iconY+1.4 1.1 0.35], ...
            'FaceColor',edgeColor,'EdgeColor',edgeColor);
        for offset=[-1.2 0 1.2]
            plot(ax,[centerX+offset centerX+offset],[iconY-1.1 iconY+1.1], ...
                'Color',edgeColor,'LineWidth',0.8);
        end
    case 'aux'
        rectangle(ax,'Position',[centerX-1.7 iconY-1.7 3.4 3.4], ...
            'Curvature',[1 1],'EdgeColor',edgeColor,'LineWidth',1.2);
        plot(ax,[centerX-1.2 centerX+1.2],[iconY iconY], ...
            'Color',edgeColor,'LineWidth',1.1);
        plot(ax,[centerX centerX],[iconY-1.2 iconY+1.2], ...
            'Color',edgeColor,'LineWidth',1.1);
        rectangle(ax,'Position',[centerX-0.3 iconY-0.3 0.6 0.6], ...
            'Curvature',[1 1],'FaceColor',edgeColor,'EdgeColor',edgeColor);
    case 'resistor'
        xPoints=centerX+[-2.5 -1.8 -1.1 -0.4 0.4 1.1 1.8 2.5];
        yPoints=iconY+[0 0.9 -0.9 0.9 -0.9 0.9 -0.9 0];
        plot(ax,xPoints,yPoints,'Color',edgeColor,'LineWidth',1.5);
        plot(ax,[centerX-3 centerX-2.5],[iconY iconY], ...
            'Color',edgeColor,'LineWidth',1.2);
        plot(ax,[centerX+2.5 centerX+3],[iconY iconY], ...
            'Color',edgeColor,'LineWidth',1.2);
    case 'brake'
        rectangle(ax,'Position',[centerX-1.55 iconY-1.55 3.1 3.1], ...
            'Curvature',[1 1],'EdgeColor',edgeColor,'LineWidth',1.3);
        rectangle(ax,'Position',[centerX-0.65 iconY-0.65 1.3 1.3], ...
            'Curvature',[1 1],'EdgeColor',edgeColor,'LineWidth',1.0);
        plot(ax,[centerX+1.35 centerX+2.15 centerX+2.15 centerX+1.35], ...
            [iconY+1.05 iconY+0.8 iconY-0.8 iconY-1.05], ...
            'Color',edgeColor,'LineWidth',2.0);
    case 'controller'
        rectangle(ax,'Position',[centerX-2.6 iconY-1.2 5.2 2.4], ...
            'EdgeColor',edgeColor,'LineWidth',1.2);
        for offset=[-1.7 -0.55 0.55 1.7]
            plot(ax,[centerX+offset centerX+offset], ...
                [iconY+1.2 iconY+1.7],'Color',edgeColor,'LineWidth',0.9);
            plot(ax,[centerX+offset centerX+offset], ...
                [iconY-1.2 iconY-1.7],'Color',edgeColor,'LineWidth',0.9);
        end
        text(ax,centerX,iconY,'EMS','HorizontalAlignment','center', ...
            'VerticalAlignment','middle','Color',edgeColor,'FontWeight','bold','FontSize',8);
end

text(ax,centerX,y+1.1,labelText,'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom','FontSize',8,'FontWeight','bold', ...
    'Color',[0.12 0.20 0.27],'Interpreter','none');
patch(ax,[x x+width x+width x],[y y y+height y+height],[1 1 1], ...
    'FaceAlpha',0.001,'EdgeColor','none','HitTest','on','PickableParts','all', ...
    'ButtonDownFcn',clickCallback,'Tag','ArchitectureBlockHitTarget', ...
    'UserData',char(componentKey));
end

function [switchControl,container]=createColoredModeSwitch(parent,modeItems,initialValue,callback,tooltipText)
%CREATECOLOREDMODESWITCH Native slider switch with explicit two-color labels.
container=uigridlayout(parent,[1 3]);
container.RowHeight={'fit'};
container.ColumnWidth={'fit',44,'fit'};
container.Padding=[0 0 0 0]; container.ColumnSpacing=5;
leftLabel=uilabel(container,'Text',char(string(modeItems{1})), ...
    'HorizontalAlignment','right');
switchControl=uiswitch(container,'slider','Items',{'',''}, ...
    'ItemsData',cellstr(string(modeItems)),'Value',char(string(initialValue)), ...
    'Tooltip',tooltipText,'ValueChangedFcn',callback,'Tag','ColoredModeSwitch');
rightLabel=uilabel(container,'Text',char(string(modeItems{2})), ...
    'HorizontalAlignment','left');
switchControl.UserData=struct('LeftLabel',leftLabel,'RightLabel',rightLabel, ...
    'LeftValue',string(modeItems{1}),'RightValue',string(modeItems{2}));
styleColoredModeSwitch(switchControl);
end

function styleColoredModeSwitch(switchControl)
%STYLECOLOREDMODESWITCH Show selected mode in blue and unselected mode in gray.
blue=[0.04 0.38 0.74]; gray=[0.45 0.49 0.53];
style=switchControl.UserData;
leftSelected=string(switchControl.Value)==style.LeftValue;
if leftSelected
    style.LeftLabel.FontColor=blue; style.LeftLabel.FontWeight='bold';
    style.RightLabel.FontColor=gray; style.RightLabel.FontWeight='normal';
else
    style.LeftLabel.FontColor=gray; style.LeftLabel.FontWeight='normal';
    style.RightLabel.FontColor=blue; style.RightLabel.FontWeight='bold';
end
end

function theme=kpiTheme()
%KPITHEME Centralized semantic accents for the management KPI dashboard.
theme=struct( ...
    'primary',[0.05 0.45 0.63], ...
    'secondary',[0.36 0.25 0.70], ...
    'success',[0.10 0.55 0.36], ...
    'warning',[0.91 0.45 0.05], ...
    'error',[0.76 0.20 0.12], ...
    'border',[0.78 0.81 0.84]);
end

function textValue=formatSmallKPI(value)
if abs(value)<1e-3
    textValue='<0.001';
else
    textValue=sprintf('%.3f',value);
end
end

function assessment=soeAssessment(soe,switchSOE)
if soe<=0.10+1e-6
    assessment='At minimum usable-energy limit';
elseif soe<=switchSOE+1e-6
    assessment='At or below the 30% role-switch threshold';
elseif soe>=0.95-1e-6
    assessment='At upper charge limit';
else
    assessment='Within normal operating window';
end
end
