classdef batteryDynamicMapTest < matlab.unittest.TestCase
    %BATTERYDYNAMICMAPTEST Verify SOE/temperature-dependent battery behavior.

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
        function everyBatteryHasValidMaps(testCase)
            testCase.verifyEqual(numel(testCase.Database.Battery_Maps), ...
                height(testCase.Database.Battery_Catalog));
            for index=1:numel(testCase.Database.BatteryFiles)
                BatteryData=[];
                run(testCase.Database.BatteryFiles(index));
                testCase.verifyEqual(BatteryData.SchemaVersion,"4.0.0");
                expected=[numel(BatteryData.TemperatureBreakpoints_C), ...
                    numel(BatteryData.SOEBreakpoints)];
                testCase.verifyEqual(BatteryData.SOCBreakpoints, ...
                    BatteryData.SOEBreakpoints);
                testCase.verifySize(BatteryData.MaxDischargeCurrentMap_A,expected);
                testCase.verifySize(BatteryData.MaxChargeCurrentMap_A,expected);
                testCase.verifySize(BatteryData.OpenCircuitVoltageMap_V,expected);
                testCase.verifySize(BatteryData.InternalResistanceMap_Ohm,expected);
                testCase.verifyGreaterThan(BatteryData.InternalResistanceMap_Ohm,0);
                testCase.verifyGreaterThan(BatteryData.OpenCircuitVoltageMap_V, ...
                    BatteryData.Component.MinVoltage_V);
                testCase.verifyLessThan(BatteryData.OpenCircuitVoltageMap_V, ...
                    BatteryData.Component.MaxVoltage_V);
            end
        end

        function temperatureDeratesCurrentAndRaisesResistance(testCase)
            warm=testCase.runAt("ENV-08",0.50); cold=testCase.runAt("ENV-01",0.50);
            testCase.verifyLessThan(cold.DischargeCurrentLimit_A(1), ...
                warm.DischargeCurrentLimit_A(1));
            testCase.verifyLessThan(cold.ChargeCurrentLimit_A(1),warm.ChargeCurrentLimit_A(1));
            testCase.verifyGreaterThan(cold.InternalResistance_Ohm(1), ...
                warm.InternalResistance_Ohm(1));
        end

        function highSOEReducesChargeAcceptance(testCase)
            middle=testCase.runAt("ENV-08",0.50); high=testCase.runAt("ENV-08",0.94);
            testCase.verifyLessThan(high.ChargeCurrentLimit_A(1),middle.ChargeCurrentLimit_A(1));
        end

        function ocvRespondsToSOEAndTemperature(testCase)
            low=testCase.runAt("ENV-08",0.20);
            high=testCase.runAt("ENV-08",0.85);
            cold=testCase.runAt("ENV-01",0.50);
            warm=testCase.runAt("ENV-08",0.50);
            testCase.verifyGreaterThan(high.OpenCircuitVoltage_V(1), ...
                low.OpenCircuitVoltage_V(1));
            testCase.verifyLessThan(cold.OpenCircuitVoltage_V(1), ...
                warm.OpenCircuitVoltage_V(1));
        end

        function terminalElectricalIdentitiesClose(testCase)
            battery=testCase.runAt("ENV-08",0.70);
            testCase.verifyLessThan(max(abs(battery.Power_kW- ...
                0.001*battery.Voltage_V.*battery.Current_A)),1e-8);
            testCase.verifyLessThan(max(abs(battery.OhmicLoss_kW- ...
                0.001*battery.Current_A.^2.*battery.InternalResistance_Ohm)),1e-10);
            testCase.verifyLessThanOrEqual(max(battery.Current_A,0), ...
                battery.DischargeCurrentLimit_A+1e-9);
            testCase.verifyLessThanOrEqual(max(-battery.Current_A,0), ...
                battery.ChargeCurrentLimit_A+1e-9);
        end
    end

    methods (Access=private)
        function battery=runAt(testCase,environmentID,initialSOE)
            input=prepare_hybrid_bus_inputs(testCase.Database,struct( ...
                'SelectedEnvironment',environmentID, ...
                'InitialBattery1SOE',initialSOE,'InitialBattery2SOE',initialSOE));
            result=simulate_hybrid_bus_core(input);
            battery=result.Signals.Battery1;
        end
    end
end
