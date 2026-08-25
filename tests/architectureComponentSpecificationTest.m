classdef architectureComponentSpecificationTest < matlab.unittest.TestCase
    methods (TestMethodSetup)
        function addProjectToPath(~)
            projectFolder=fileparts(fileparts(mfilename('fullpath')));
            addpath(projectFolder,fullfile(projectFolder,'src'), ...
                fullfile(projectFolder,'models'));
        end
    end

    methods (Test)
        function everyArchitectureBlockHasSpecifications(testCase)
            projectFolder=fileparts(fileparts(mfilename('fullpath')));
            database=load_hybrid_bus_database( ...
                fullfile(projectFolder,'data','HybridBus_ComponentDatabase.xlsx'));
            selections=database.Dashboard;
            keys=["fuel","engine","generator","charger","standby_selector", ...
                "battery1","active_selector","battery2","traction_bus", ...
                "motors","reduction","vehicle","auxiliary","resistor","controller"];
            for key=keys
                specification=architecture_component_specification(database,selections,key);
                testCase.verifyNotEmpty(specification.Title,key);
                testCase.verifyNotEmpty(specification.Role,key);
                testCase.verifyGreaterThanOrEqual(size(specification.Rows,1),6,key);
                testCase.verifyEqual(size(specification.Rows,2),3,key);
            end
        end

        function selectedBatteryAndMotorValuesAreUsed(testCase)
            projectFolder=fileparts(fileparts(mfilename('fullpath')));
            database=load_hybrid_bus_database( ...
                fullfile(projectFolder,'data','HybridBus_ComponentDatabase.xlsx'));
            selections=database.Dashboard;
            selections.SelectedBattery1="BAT-01";
            selections.SelectedMotor="MOT-02";
            battery=architecture_component_specification(database,selections,"battery1");
            motors=architecture_component_specification(database,selections,"motors");
            testCase.verifyTrue(any(strcmp(battery.Rows(:,2),'BAT-01')));
            testCase.verifyTrue(any(strcmp(motors.Rows(:,2),'MOT-02')));
        end

        function conceptualRatingsAreNotInvented(testCase)
            projectFolder=fileparts(fileparts(mfilename('fullpath')));
            database=load_hybrid_bus_database( ...
                fullfile(projectFolder,'data','HybridBus_ComponentDatabase.xlsx'));
            resistor=architecture_component_specification( ...
                database,database.Dashboard,"resistor");
            testCase.verifyTrue(any(contains(string(resistor.Rows(:,2)), ...
                "Not parameterized")));
        end
    end
end
