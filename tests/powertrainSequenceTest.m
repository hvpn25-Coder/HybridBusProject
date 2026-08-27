classdef powertrainSequenceTest < matlab.unittest.TestCase
    %POWERTRAINSEQUENCETEST Verify selected-mode and ordered comparison runs.

    properties
        Database struct
    end

    methods (TestClassSetup)
        function configureProject(testCase)
            projectFolder=fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(projectFolder,"src")));
            testCase.Database=load_hybrid_bus_database(fullfile(projectFolder, ...
                "data","HybridBus_ComponentDatabase.xlsx"));
        end
    end

    methods (Test)
        function uncheckedRunsSelectedHybridOnly(testCase)
            overrides=defaultOverrides(testCase.Database,"Hybrid");
            sequence=run_powertrain_sequence(testCase.Database,overrides,false);
            testCase.verifyEqual(sequence.RunOrder,"Hybrid");
            testCase.verifyEmpty(sequence.BEV);
            testCase.verifyEqual(sequence.SelectedResult.Summary.PowertrainMode,'Hybrid');
        end

        function uncheckedRunsSelectedBEVOnly(testCase)
            overrides=defaultOverrides(testCase.Database,"BEV");
            sequence=run_powertrain_sequence(testCase.Database,overrides,false);
            testCase.verifyEqual(sequence.RunOrder,"BEV");
            testCase.verifyEmpty(sequence.Hybrid);
            testCase.verifyEqual(sequence.SelectedResult.Summary.PowertrainMode,'BEV');
            testCase.verifyEqual(sequence.BEV.InputParameters.InitialBattery2SOE, ...
                sequence.BEV.InputParameters.InitialBattery1SOE);
        end

        function checkedRunsBEVThenHybrid(testCase)
            overrides=defaultOverrides(testCase.Database,"Hybrid");
            overrides.InitialBattery1SOE=0.85;
            overrides.InitialBattery2SOE=0.20;
            sequence=run_powertrain_sequence(testCase.Database,overrides,true);
            testCase.verifyEqual(sequence.RunOrder,["BEV","Hybrid"]);
            testCase.verifyEqual(sequence.BEV.InputParameters.InitialBattery2SOE,0.85);
            testCase.verifyEqual(sequence.Hybrid.InputParameters.InitialBattery2SOE,0.20);
            testCase.verifyEqual(sequence.SelectedResult.Summary.PowertrainMode,'Hybrid');
        end

        function comparisonRejectsHalfSetMultiplier(testCase)
            overrides=defaultOverrides(testCase.Database,"BEV");
            overrides.BatterySetMultiplier=1.5;
            testCase.verifyError(@()run_powertrain_sequence( ...
                testCase.Database,overrides,true), ...
                'HybridBus:ComparisonRequiresWholeBatterySets');
        end
    end
end

function overrides=defaultOverrides(database,powertrainMode)
D=database.Dashboard;
overrides=struct('PowertrainMode',string(powertrainMode), ...
    'BatterySetMultiplier',1,'InitialBattery1SOE',double(D.InitialBattery1SOE), ...
    'InitialBattery2SOE',double(D.InitialBattery2SOE),'LoadMass_t',double(D.LoadMass_t), ...
    'RepeatUntilDepleted',false);
end
