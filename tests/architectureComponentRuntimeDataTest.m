classdef architectureComponentRuntimeDataTest < matlab.unittest.TestCase
    %ARCHITECTURECOMPONENTRUNTIMEDATATEST Verify component inspector evidence.

    properties
        Result struct
    end

    methods (TestClassSetup)
        function prepareSimulation(testCase)
            projectFolder=fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(projectFolder,"src")));
            database=load_hybrid_bus_database(fullfile(projectFolder, ...
                "data","HybridBus_ComponentDatabase.xlsx"));
            input=prepare_hybrid_bus_inputs(database,struct('PowertrainMode',"Hybrid"));
            testCase.Result=simulate_hybrid_bus_core(input);
        end
    end

    methods (Test)
        function preRunStateRequestsSimulation(testCase)
            runtime=architecture_component_runtime_data([],"battery1");
            testCase.verifyFalse(runtime.HasResult);
            testCase.verifyEqual(size(runtime.KPIRows),[1 4]);
            testCase.verifyEqual(string(runtime.KPIRows{1,2}),"Run required");
            testCase.verifyFalse(any([runtime.SignalGroups.Available]));
        end

        function batteryEvidenceHasKPIsAndSignals(testCase)
            runtime=architecture_component_runtime_data(testCase.Result,"battery1");
            metrics=string(runtime.KPIRows(:,1));
            testCase.verifyTrue(any(metrics=="Energy throughput"));
            testCase.verifyTrue(all([runtime.SignalGroups.Available]));
            optionTitles=string({runtime.SignalOptions.Title});
            testCase.verifyTrue(any(contains(optionTitles,"cumulative signed energy")));
            testCase.verifyTrue(any(contains(optionTitles,"cumulative throughput")));
            testCase.verifyEqual(size(runtime.SignalGroups(1).Values,1), ...
                numel(testCase.Result.Time));
            testCase.verifyEqual(size(runtime.SignalGroups(2).Values,1), ...
                numel(testCase.Result.Time));
        end

        function everyArchitectureBlockHasAStableMapping(testCase)
            keys=["fuel","engine","generator","charger","standby_selector", ...
                "battery1","active_selector","battery2","traction_bus", ...
                "motors","reduction","vehicle","auxiliary","resistor", ...
                "friction_brake","controller","grid_charger","bev_controller"];
            for key=keys
                runtime=architecture_component_runtime_data(testCase.Result,key);
                testCase.verifyTrue(runtime.HasResult,key);
                testCase.verifyEqual(size(runtime.KPIRows,2),4,key);
                testCase.verifyEqual(numel(runtime.SignalGroups),2,key);
                testCase.verifyGreaterThanOrEqual(numel(runtime.SignalOptions),2,key);
                for option=runtime.SignalOptions
                    if option.Available
                        testCase.verifyEqual(size(option.Values,1), ...
                            numel(testCase.Result.Time),key);
                    end
                end
            end
        end

        function externalChargerDoesNotInventSignals(testCase)
            runtime=architecture_component_runtime_data(testCase.Result,"grid_charger");
            values=string(runtime.KPIRows(:,2));
            testCase.verifyTrue(any(values=="NOT AVAILABLE"));
            testCase.verifyFalse(any([runtime.SignalGroups.Available]));
            testCase.verifyThat(runtime.SignalNote, ...
                matlab.unittest.constraints.ContainsSubstring("does not simulate"));
        end

        function frictionBrakeInspectorUsesBlendedBrakingEvidence(testCase)
            runtime=architecture_component_runtime_data(testCase.Result,"friction_brake");
            metrics=string(runtime.KPIRows(:,1));
            testCase.verifyTrue(any(metrics=="Pneumatic braking energy"));
            testCase.verifyTrue(any(metrics=="Unmet braking energy"));
            testCase.verifyEqual(runtime.SignalGroups(1).Names, ...
                ["Demand","Regenerative","Pneumatic friction","Unmet"]);
            testCase.verifyTrue(any(contains(string({runtime.SignalOptions.Title}), ...
                "Cumulative braking energy")));
        end
    end
end
