classdef componentMFileStorageTest < matlab.unittest.TestCase
    %COMPONENTMFILESTORAGETEST Verify per-battery and per-motor M-file storage.

    properties
        ProjectFolder string
        Database struct
    end

    methods (TestClassSetup)
        function loadDatabase(testCase)
            testCase.ProjectFolder=string(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.ProjectFolder,'src')));
            testCase.Database=load_hybrid_bus_database(fullfile( ...
                testCase.ProjectFolder,'data','HybridBus_ComponentDatabase.xlsx'));
        end
    end

    methods (Test)
        function workbookContainsNoBatteryOrMotorSheets(testCase)
            sheets=sheetnames(testCase.Database.Filename);
            testCase.verifyFalse(any(ismember(["Battery_Catalog","Motor_Catalog"],sheets)));
        end

        function exactlyOneMFileExistsPerComponent(testCase)
            database=testCase.Database;
            testCase.verifyEqual(numel(database.BatteryFiles),height(database.Battery_Catalog));
            testCase.verifyEqual(numel(database.MotorFiles),height(database.Motor_Catalog));
            testCase.verifyTrue(all(isfile(database.BatteryFiles)));
            testCase.verifyTrue(all(isfile(database.MotorFiles)));
            testCase.verifyTrue(all(endsWith(database.BatteryFiles,'.m')));
            testCase.verifyTrue(all(endsWith(database.MotorFiles,'.m')));
        end

        function scriptsExposeVersionedComponentRecords(testCase)
            BatteryData=[]; MotorData=[];
            run(testCase.Database.BatteryFiles(1));
            run(testCase.Database.MotorFiles(1));
            testCase.verifyEqual(BatteryData.SchemaVersion,"4.0.0");
            testCase.verifyEqual(MotorData.SchemaVersion,"2.0.0");
            testCase.verifyEqual(string(BatteryData.Component.ComponentID), ...
                string(testCase.Database.Battery_Catalog.ComponentID(1)));
            testCase.verifyEqual(string(MotorData.Component.ComponentID), ...
                string(testCase.Database.Motor_Catalog.ComponentID(1)));
            testCase.verifyTrue(all(isfield(BatteryData, ...
                {'SOEBreakpoints','SOCBreakpoints','TemperatureBreakpoints_C', ...
                'MaxDischargeCurrentMap_A','MaxChargeCurrentMap_A', ...
                'OpenCircuitVoltageMap_V','InternalResistanceMap_Ohm'})));
            testCase.verifyTrue(all(isfield(MotorData, ...
                {'TorqueBreakpoints_Nm','SpeedBreakpoints_rpm', ...
                'MotorLossMap_kW','MapBasis'})));
            testCase.verifyEqual(size(MotorData.MotorLossMap_kW), ...
                [numel(MotorData.SpeedBreakpoints_rpm) ...
                numel(MotorData.TorqueBreakpoints_Nm)]);
        end

        function catalogsRemainSimulationCompatible(testCase)
            input=prepare_hybrid_bus_inputs(testCase.Database,struct( ...
                'SelectedBattery1',"BAT-12",'SelectedBattery2',"BAT-12", ...
                'SelectedMotor',"MOT-12"));
            result=simulate_hybrid_bus_core(input);
            testCase.verifyEqual(string(result.SelectedConfiguration.Battery1),"BAT-12");
            testCase.verifyEqual(string(result.SelectedConfiguration.Motor),"MOT-12");
        end
    end
end
