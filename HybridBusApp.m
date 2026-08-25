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
        MassDropDown matlab.ui.control.DropDown
        AuxDropDown matlab.ui.control.DropDown
        SOE1Field matlab.ui.control.NumericEditField
        SOE2Field matlab.ui.control.NumericEditField
        FuelPriceField matlab.ui.control.NumericEditField
        ElectricityPriceField matlab.ui.control.NumericEditField
        MaxConfigurationsField matlab.ui.control.NumericEditField
        BatterySetMultiplierField matlab.ui.control.NumericEditField
        RepeatRouteCheckBox matlab.ui.control.CheckBox
        StatusLabel matlab.ui.control.Label
        KPICards struct = struct
        KPIStatusLabel matlab.ui.control.Label
        KPIContextLabel matlab.ui.control.Label
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
            sideGrid=uigridlayout(side,[17 2]);
            sideGrid.RowHeight=[repmat({'fit'},1,16),{'1x'}];
            sideGrid.ColumnWidth={140,'1x'}; sideGrid.Padding=[10 10 10 10];
            addLabel(sideGrid,'Database',1); dbGrid=uigridlayout(sideGrid,[1 2]);
            dbGrid.Layout.Row=1; dbGrid.Layout.Column=2; dbGrid.ColumnWidth={'1x','fit'};
            dbGrid.Padding=[0 0 0 0];
            app.DatabaseField=uieditfield(dbGrid,'text','Editable','off');
            uibutton(dbGrid,'Text','...','ButtonPushedFcn',@(~,~)app.browseDatabase());

            missionPanel=uipanel(sideGrid,'Title','Mission Inputs');
            missionPanel.Layout.Row=2; missionPanel.Layout.Column=[1 2];
            missionGrid=uigridlayout(missionPanel,[3 2]);
            missionGrid.RowHeight={'fit','fit','fit'};
            missionGrid.ColumnWidth={120,'1x'};
            missionGrid.Padding=[8 6 8 6]; missionGrid.RowSpacing=5;
            app.RouteDropDown=app.addDropDown(missionGrid,'Route',1);
            app.RouteDropDown.ValueChangedFcn=@(~,~)app.updateRouteMap();
            app.MassDropDown=app.addDropDown(missionGrid,'Total vehicle mass',2);
            app.AuxDropDown=app.addDropDown(missionGrid,'Auxiliary',3);

            app.Battery1DropDown=app.addDropDown(sideGrid,'Battery 1',3);
            app.Battery2DropDown=app.addDropDown(sideGrid,'Battery 2',4);
            app.MotorDropDown=app.addDropDown(sideGrid,'Hub motor pair',5);
            app.GensetDropDown=app.addDropDown(sideGrid,'Genset',6);
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
            app.RepeatRouteCheckBox=uicheckbox(sideGrid,'Text','Repeat route until depleted', ...
                'Value',false,'Tooltip',['Continuously repeat the selected route until the fuel tank ' ...
                'is empty and both batteries reach their usable-energy limits.']);
            app.RepeatRouteCheckBox.Layout.Row=13; app.RepeatRouteCheckBox.Layout.Column=[1 2];
            buttonGrid=uigridlayout(sideGrid,[2 2]); buttonGrid.Layout.Row=[14 15];
            buttonGrid.Layout.Column=[1 2]; buttonGrid.ColumnWidth={'1x','1x'};
            buttonGrid.RowHeight={'fit','fit'}; buttonGrid.Padding=[0 0 0 0];
            uibutton(buttonGrid,'Text','Run Manual','ButtonPushedFcn',@(~,~)app.runManual());
            uibutton(buttonGrid,'Text','Optimize','ButtonPushedFcn',@(~,~)app.runOptimization());
            uibutton(buttonGrid,'Text','Cancel','ButtonPushedFcn',@(~,~)app.requestCancel());
            uibutton(buttonGrid,'Text','Export','ButtonPushedFcn',@(~,~)app.exportCurrent());
            app.StatusLabel=uilabel(sideGrid,'Text','Ready','WordWrap','on');
            app.StatusLabel.Layout.Row=16; app.StatusLabel.Layout.Column=[1 2];

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
                'Battery Power','Engine Power'};
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
                'Click any component block to inspect its selected specification and implemented role.']);
            app.ArchitectureNoteLabel.Layout.Row=2; app.ArchitectureNoteLabel.Layout.Column=1;
            app.ArchitectureAxes=uiaxes(architectureGrid);
            app.ArchitectureAxes.Layout.Row=3; app.ArchitectureAxes.Layout.Column=1;
            app.drawPowertrainArchitecture();
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
                massLabels=compose('%.0f kg — %s',db.Bus_Mass_Catalog.TotalVehicleMass_kg, ...
                    db.Bus_Mass_Catalog.ComponentID);
                app.MassDropDown.Items=cellstr(massLabels);
                app.MassDropDown.ItemsData=cellstr(db.Bus_Mass_Catalog.ComponentID);
                app.AuxDropDown.Items=cellstr(db.Aux_Load_Profiles.ComponentID);
                app.setDashboardSelections();
                app.updateRouteMap();
                app.StatusLabel.Text=sprintf('Validated database %s',db.Version);
            catch exception
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
            app.MassDropDown.Value=char(D.SelectedMass);
            app.AuxDropDown.Value=char(D.SelectedAuxProfile);
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
                    'surplus to the resistor load bank third. Click any block for specifications.'];
            else
                app.SOE1Field.Value=app.HybridSOE1Cache;
                app.SOE2Field.Value=app.HybridSOE2Cache;
                app.GensetDropDown.Enable='on';
                app.ArchitectureNoteLabel.Text=[ ...
                    'First-principles view: the genset is isolated from the traction DC bus and charges only ' ...
                    'the standby battery bank at constant best-efficiency power. The active battery bank supports ' ...
                    'traction until 30% SOE. Regeneration supplies auxiliaries first, the active battery ' ...
                    'second, and the resistor load bank third. Click any block for specifications.'];
            end
            app.drawPowertrainArchitecture();
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
                'SelectedMass',string(app.MassDropDown.Value), ...
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
                'RepeatUntilDepleted',app.RepeatRouteCheckBox.Value);
            O.PowertrainMode=string(app.PowertrainModeSwitch.Value);
            O.BatterySetMultiplier=app.BatterySetMultiplierField.Value;
            if O.PowertrainMode=="BEV", O.InitialBattery2SOE=O.InitialBattery1SOE; end
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
            try,geobasemap(ax,'streets-light');catch,geobasemap(ax,'none');end
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
                app.CurrentResults=run_hybrid_bus_simulation(string(app.DatabaseField.Value), ...
                    app.gatherOverrides(),SaveResults=false);
                app.updateResults(app.CurrentResults);
                app.StatusLabel.Text=sprintf('Complete: %.4f cost/km',app.CurrentResults.Summary.CostPer_km);
            catch exception
                app.StatusLabel.Text='Run failed'; uialert(app.Figure,exception.message,'Simulation error');
            end
        end

        function runOptimization(app)
            app.CancelRequested=false; app.StatusLabel.Text='Optimizing...'; drawnow;
            try
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
            plot(app.SpeedAxes,x,R.Signals.Vehicle.Speed_m_s*3.6,'LineWidth',1.2);
            xlabel(app.SpeedAxes,xLabel); ylabel(app.SpeedAxes,'km/h');
            xtickformat(app.SpeedAxes,tickFormat);
            plot(app.PowerAxes,x,R.Signals.Wheel.Demand_kW,x,R.Signals.Motors.ElectricalPower_kW, ...
                x,R.Signals.Auxiliary.Power_kW,x,R.Signals.Regeneration.ResistorLoadBank_kW, ...
                'LineWidth',1.0);
            legend(app.PowerAxes,{'Wheel','Motor DC','Auxiliary','Resistor load bank'}, ...
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
            labels={'Grid equivalent','Genset output','Regenerated','Auxiliary','Battery throughput','Load-bank waste'};
            energy=[S.GridEquivalentEnergy_kWh,S.GensetElectricalEnergy_kWh, ...
                S.RegeneratedEnergy_kWh,S.AuxiliaryEnergy_kWh,S.BatteryThroughput_kWh, ...
                S.ResistorLoadBankEnergy_kWh];
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
            if S.UnmetTractionEnergy_kWh>1e-3, routeAssessment='Demand exceeded available propulsion energy'; end
            b1Assessment=soeAssessment(S.FinalBattery1SOE,R.Signals.Controller.BatteryRoleSwitchSOE(1));
            b2Assessment=soeAssessment(S.FinalBattery2SOE,R.Signals.Controller.BatteryRoleSwitchSOE(1));
            unmetAssessment='No material unmet traction/DC energy';
            if S.UnmetTractionEnergy_kWh>1e-3, unmetAssessment='Review power sizing or depleted-energy endpoint'; end
            balanceAssessment='Conservation check passed';
            if S.EnergyBalanceError_kWh>1e-6, balanceAssessment='Review numerical energy residual'; end
            loadAssessment='No surplus regeneration was wasted';
            if S.ResistorLoadBankEnergy_kWh>1e-3, loadAssessment='Surplus regen safely dissipated after aux and battery limits'; end
            app.AnalysisTable.Data={ ...
                'Mission distance',sprintf('%.1f',S.RouteDistance_km),'km',routeAssessment; ...
                'Battery 1 final SOE',sprintf('%.1f',100*S.FinalBattery1SOE),'%',b1Assessment; ...
                'Battery 2 final SOE',sprintf('%.1f',100*S.FinalBattery2SOE),'%',b2Assessment; ...
                'Regeneration utilization',sprintf('%.1f',regenUtilization),'%', ...
                    'Auxiliary-first and active-battery-second recovery'; ...
                'Resistor load bank',sprintf('%.2f',S.ResistorLoadBankEnergy_kWh),'kWh',loadAssessment; ...
                'Genset operation',sprintf('%.1f / %d',runtimeMinutes,S.GensetStarts),'min / starts', ...
                    'Standby-only charging at the selected efficiency point'; ...
                'Unmet traction energy',sprintf('%.3f',S.UnmetTractionEnergy_kWh),'kWh',unmetAssessment; ...
                'Energy-balance error',formatSmallKPI(S.EnergyBalanceError_kWh),'kWh',balanceAssessment};
            status='FEASIBLE';
            if ~R.Validation.IsFeasible, status='ENGINEERING ATTENTION'; end
            app.AnalysisHeaderLabel.Text=sprintf('%s | %.1f km simulated | %.2f EUR/km | %.1f L fuel | %d genset start(s)', ...
                status,S.RouteDistance_km,S.CostPer_km,S.Fuel_L,S.GensetStarts);
        end

        function buildKPIDashboard(app,parent)
            theme=kpiTheme();
            dashboard=uigridlayout(parent,[4 4]);
            dashboard.RowHeight={72,'1x','1x','1x'};
            dashboard.ColumnWidth={'1x','1x','1x','1x'};
            dashboard.Padding=[16 14 16 16];
            dashboard.RowSpacing=12; dashboard.ColumnSpacing=12;

            header=uipanel(dashboard,'BorderType','line','HighlightColor',theme.border);
            header.Layout.Row=1; header.Layout.Column=[1 4];
            headerGrid=uigridlayout(header,[2 2]);
            headerGrid.RowHeight={'fit','1x'}; headerGrid.ColumnWidth={'1x','fit'};
            headerGrid.Padding=[16 8 16 8];
            titleLabel=uilabel(headerGrid,'Text','MISSION PERFORMANCE', ...
                'FontWeight','bold','FontSize',17,'FontColor',theme.primary);
            titleLabel.Layout.Row=1; titleLabel.Layout.Column=1;
            app.KPIStatusLabel=uilabel(headerGrid,'Text','AWAITING RUN', ...
                'FontWeight','bold','HorizontalAlignment','center', ...
                'FontColor',theme.warning);
            app.KPIStatusLabel.Layout.Row=1; app.KPIStatusLabel.Layout.Column=2;
            app.KPIContextLabel=uilabel(headerGrid, ...
                'Text','Run a manual case or optimization to populate the dashboard.', ...
                'FontSize',11,'WordWrap','on');
            app.KPIContextLabel.Layout.Row=2; app.KPIContextLabel.Layout.Column=[1 2];

            cards={ ...
                'distance','Route distance','km','route',theme.primary; ...
                'cost','Operating cost','EUR/km','cost',theme.success; ...
                'fuelRate','Fuel consumption','L/100 km','fuel',theme.warning; ...
                'sourceEnergy','Source energy','kWh/km','energy',theme.secondary; ...
                'gridEnergy','Grid-equivalent energy','kWh','grid',theme.primary; ...
                'regenEnergy','Regenerated energy','kWh','regen',theme.success; ...
                'auxEnergy','Auxiliary energy','kWh','aux',theme.secondary; ...
                'fuelUsed','Fuel used','L','fuel',theme.warning; ...
                'battery1','Final Battery 1 SOE','%','battery',theme.primary; ...
                'battery2','Final Battery 2 SOE','%','battery',theme.primary; ...
                'unmet','Unmet traction energy','kWh','alert',theme.error; ...
                'balance','Energy-balance error','kWh','balance',theme.success};
            for index=1:size(cards,1)
                row=2+floor((index-1)/4); column=1+mod(index-1,4);
                app.createKPICard(dashboard,row,column,cards{index,:});
            end
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
            S=R.Summary;
            values=struct( ...
                'distance',sprintf('%.1f',S.RouteDistance_km), ...
                'cost',sprintf('%.3f',S.CostPer_km), ...
                'fuelRate',sprintf('%.2f',S.Fuel_L_per_100km), ...
                'sourceEnergy',sprintf('%.3f',S.TotalSourceEnergy_kWh_per_km), ...
                'gridEnergy',sprintf('%.1f',S.GridEquivalentEnergy_kWh), ...
                'regenEnergy',sprintf('%.1f',S.RegeneratedEnergy_kWh), ...
                'auxEnergy',sprintf('%.1f',S.AuxiliaryEnergy_kWh), ...
                'fuelUsed',sprintf('%.1f',S.Fuel_L), ...
                'battery1',sprintf('%.1f',100*S.FinalBattery1SOE), ...
                'battery2',sprintf('%.1f',100*S.FinalBattery2SOE), ...
                'unmet',sprintf('%.3f',S.UnmetTractionEnergy_kWh), ...
                'balance',formatSmallKPI(S.EnergyBalanceError_kWh));
            names=fieldnames(values);
            for index=1:numel(names)
                app.KPICards.(names{index}).Value.Text=values.(names{index});
            end
            routeName=string(app.RouteDropDown.Value);
            app.KPIContextLabel.Text=sprintf('%s  |  %.0f kg total vehicle mass  |  %s + %s', ...
                routeName,S.EstimatedVehicleMass_kg,string(app.Battery1DropDown.Value),string(app.Battery2DropDown.Value));
            theme=kpiTheme();
            if R.Validation.IsFeasible
                app.KPIStatusLabel.Text='FEASIBLE'; app.KPIStatusLabel.FontColor=theme.success;
            else
                app.KPIStatusLabel.Text='ENGINEERING ATTENTION'; app.KPIStatusLabel.FontColor=theme.error;
            end
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
                    values=[S.Wheel.Demand_kW,S.Wheel.Delivered_kW];
                    labels=["Demand","Delivered"];
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
            architectureBlock(ax,[53 51.5 24 7],sprintf('Supervisory energy manager\n30%% role-swap rule'),'controller', ...
                [0.94 0.95 0.96],control,@(~,~)app.showArchitectureSpecification("controller"), ...
                "controller");

            % Compact key stays outside the flow lanes.
            legendY=56; legendX=[73 83.5 94 105 116 127];
            legendColors={fuel,mechanical,electric,regen,dump,control};
            legendLabels={'Fuel','Shaft','Traction','Regen','Dump','Control'};
            for index=1:numel(legendX)
                lineStyle='-';
                if index==6,lineStyle='--';end
                plot(ax,[legendX(index) legendX(index)+2.5],[legendY legendY], ...
                    'Color',legendColors{index},'LineWidth',2, ...
                    'LineStyle',lineStyle);
                text(ax,legendX(index)+3,legendY,legendLabels{index}, ...
                    'VerticalAlignment','middle','FontSize',7.5,'Color',[0.18 0.23 0.28]);
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
            architectureBlock(ax,[52 47 24 7],sprintf('BEV supervisory controller\nparallel power sharing'),'controller', ...
                [0.94 0.95 0.96],control,@(~,~)app.showArchitectureSpecification("bev_controller"),"bev_controller");
            hold(ax,'off');
        end

        function showArchitectureSpecification(app,componentKey)
            try
                selections=app.architectureSelections();
                specification=architecture_component_specification( ...
                    app.Database,selections,string(componentKey));
                existing=findall(groot,'Type','figure','Tag','HybridBusComponentSpecification');
                if ~isempty(existing),delete(existing);end
                dialog=uifigure('Name',char(specification.Title+" Specifications"), ...
                    'Tag','HybridBusComponentSpecification','Position',[420 180 720 590], ...
                    'Resize','on');
                layout=uigridlayout(dialog,[4 1]);
                layout.RowHeight={'fit','fit','1x','fit'};
                layout.ColumnWidth={'1x'}; layout.Padding=[18 16 18 14];
                uilabel(layout,'Text',char(specification.Title), ...
                    'FontSize',20,'FontWeight','bold','FontColor',[0.12 0.25 0.36]);
                role=uilabel(layout,'Text',char(specification.Role),'WordWrap','on', ...
                    'FontSize',11,'FontColor',[0.28 0.34 0.39]);
                role.Layout.Row=2;
                tableView=uitable(layout,'Data',specification.Rows, ...
                    'ColumnName',specification.ColumnNames,'RowName',{}, ...
                    'ColumnWidth',{245,330,85});
                tableView.Layout.Row=3;
                closeButton=uibutton(layout,'push','Text','Close', ...
                    'ButtonPushedFcn',@(~,~)delete(dialog));
                closeButton.Layout.Row=4;
                movegui(dialog,'center');
            catch exception
                uialert(app.Figure,exception.message,'Specification unavailable');
            end
        end

        function selections=architectureSelections(app)
            selections=app.Database.Dashboard;
            selections.SelectedBattery1=string(app.Battery1DropDown.Value);
            selections.SelectedBattery2=string(app.Battery2DropDown.Value);
            selections.SelectedMotor=string(app.MotorDropDown.Value);
            selections.SelectedGenset=string(app.GensetDropDown.Value);
            selections.SelectedMass=string(app.MassDropDown.Value);
            selections.SelectedAuxProfile=string(app.AuxDropDown.Value);
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

function architectureBidirectionalArrow(ax,x1,y1,x2,y2,color,lineWidth)
midX=(x1+x2)/2; midY=(y1+y2)/2;
architectureArrow(ax,midX,midY,x2,y2,color,lineWidth,'-');
architectureArrow(ax,midX,midY,x1,y1,color,lineWidth,'-');
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
