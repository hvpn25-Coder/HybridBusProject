classdef motorLossMapTest < matlab.unittest.TestCase
    %MOTORLOSSMAPTEST Verify motor-map data, simulation, and SLX structure.

    properties
        ProjectFolder string
        Database struct
    end

    methods (TestClassSetup)
        function configureProject(testCase)
            testCase.ProjectFolder=string(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.ProjectFolder,'src')));
            testCase.Database=load_hybrid_bus_database;
        end
    end

    methods (Test)
        function everyMotorHasValidMonotonicLossMap(testCase)
            maps=testCase.Database.Motor_Maps;
            testCase.verifyNumElements(maps,height(testCase.Database.Motor_Catalog));
            for map=maps(:)'
                testCase.verifyEqual(size(map.MotorLossMap_kW), ...
                    [numel(map.SpeedBreakpoints_rpm) numel(map.TorqueBreakpoints_Nm)]);
                testCase.verifyGreaterThan(diff(map.TorqueBreakpoints_Nm),0);
                testCase.verifyGreaterThan(diff(map.SpeedBreakpoints_rpm),0);
                testCase.verifyGreaterThanOrEqual(map.MotorLossMap_kW,0);
                testCase.verifyEqual(map.MotorLossMap_kW(1,1),0);
                testCase.verifyGreaterThanOrEqual(diff(map.MotorLossMap_kW,1,2),-1e-12);
                testCase.verifyGreaterThanOrEqual(diff(map.MotorLossMap_kW,1,1),-1e-12);
            end
        end

        function simulationReportsMappedPairLoss(testCase)
            input=prepare_hybrid_bus_inputs(testCase.Database,struct( ...
                'SelectedMotor',"MOT-12"));
            result=simulate_hybrid_bus_core(input);
            expected=abs(result.Signals.Motors.ElectricalPower_kW- ...
                result.Signals.Motors.MechanicalPower_kW);
            testCase.verifyEqual(result.Signals.Motors.LossPower_kW,expected, ...
                'AbsTol',1e-10);
            testCase.verifyTrue(any(result.Signals.Motors.LossPower_kW>0));
        end

        function bothSimulinkModelsUseTwoDimensionalLossLookup(testCase)
            models=["HybridBus_BackwardModel","HybridBus_BEVModel"];
            for model=models
                load_system(fullfile(testCase.ProjectFolder,'models',model+'.slx'));
                cleanup=onCleanup(@()close_system(model,0));
                scope=model+"/Rear_Hub_Motor_Drive";
                lookup=find_system(scope,'SearchDepth',1,'Name','Motor_Loss_Lookup');
                testCase.verifyNumElements(lookup,1);
                testCase.verifyEqual(get_param(lookup{1},'NumberOfTableDimensions'),'2');
                testCase.verifyEqual(get_param(lookup{1},'Table'),'motor_loss_map_kw');
                testCase.verifyEqual(get_param(lookup{1},'BreakpointsForDimension1'), ...
                    'motor_loss_torque_breakpoints_nm');
                testCase.verifyEqual(get_param(lookup{1},'BreakpointsForDimension2'), ...
                    'motor_loss_speed_breakpoints_rpm');
                testCase.verifyNumElements(find_system(scope,'SearchDepth',1, ...
                    'Name','Pair_Motor_Loss'),1);
                clear cleanup
                close_system(model,0);
            end
        end
    end
end
