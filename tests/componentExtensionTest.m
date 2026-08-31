classdef componentExtensionTest < matlab.unittest.TestCase
    %COMPONENTEXTENSIONTEST Verify arbitrary user-defined component variants.

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
        function arbitraryIDsAreDiscoveredPreservedAndSimulated(testCase)
            root=string(tempname); mkdir(root);
            cleanup=onCleanup(@()rmdir(root,'s'));
            batteryFolder=fullfile(root,'batteries');
            motorFolder=fullfile(root,'motors');
            gensetFolder=fullfile(root,'gensets');
            mkdir(fullfile(batteryFolder,'custom'));
            mkdir(fullfile(motorFolder,'custom'));
            mkdir(fullfile(gensetFolder,'custom'));

            cloneScript(fullfile(testCase.ProjectFolder,'data','batteries','BAT_12.m'), ...
                fullfile(batteryFolder,'custom','My_Battery_AddOn.m'), ...
                ["BAT-12","Bat_Series_1"]);
            cloneScript(fullfile(testCase.ProjectFolder,'data','motors','MOT_12.m'), ...
                fullfile(motorFolder,'custom','My_Motor_AddOn.m'), ...
                ["MOT-12","Motor_HighTorque_A"]);
            cloneScript(fullfile(testCase.ProjectFolder,'data','gensets','GEN_12.m'), ...
                fullfile(gensetFolder,'custom','My_Genset_AddOn.m'), ...
                ["GEN-12","Gen_Euro7_300kW"; ...
                 "ENG-12","Diesel_Engine_A"; ...
                 "GNR-12","Generator_800V_A"]);

            % Regenerating built-ins must not delete independently named add-ons.
            write_component_m_files(batteryFolder,testCase.Database.Battery_Catalog(1,:),"Battery");
            write_component_m_files(motorFolder,testCase.Database.Motor_Catalog(1,:),"Motor");
            write_genset_m_files(gensetFolder,testCase.Database.Genset_Catalog(1,:), ...
                testCase.Database.Engine_Catalog(1,:),testCase.Database.Generator_Catalog(1,:), ...
                testCase.Database.Engine_Fuel_Map,testCase.Database.Generator_Efficiency_Map);

            batteries=load_component_m_files(batteryFolder,"Battery");
            motors=load_component_m_files(motorFolder,"Motor");
            gensets=load_genset_m_files(gensetFolder);
            testCase.verifyTrue(any(string(batteries.Catalog.ComponentID)=="Bat_Series_1"));
            testCase.verifyTrue(any(string(motors.Catalog.ComponentID)=="Motor_HighTorque_A"));
            link=gensets.AssemblyCatalog( ...
                gensets.AssemblyCatalog.GensetID=="Gen_Euro7_300kW",:);
            testCase.verifyEqual(link.EngineID,"Diesel_Engine_A");
            testCase.verifyEqual(link.GeneratorID,"Generator_800V_A");

            database=testCase.Database;
            database.BatteryFiles=batteries.Files;
            database.Battery_Catalog=batteries.Catalog;
            database.Battery_Maps=batteries.Maps;
            database.MotorFiles=motors.Files;
            database.Motor_Catalog=motors.Catalog;
            database.Motor_Maps=motors.Maps;
            database.GensetFiles=gensets.Files;
            database.Genset_Catalog=gensets.GensetCatalog;
            database.Engine_Catalog=gensets.EngineCatalog;
            database.Generator_Catalog=gensets.GeneratorCatalog;
            database.Genset_Assembly=gensets.AssemblyCatalog;
            database.Engine_Fuel_Map=gensets.EngineFuelMap;
            database.Generator_Efficiency_Map=gensets.GeneratorEfficiencyMap;
            validation=validate_hybrid_bus_database(database);
            testCase.verifyEmpty(validation.Errors);

            input=prepare_hybrid_bus_inputs(database,struct( ...
                'SelectedBattery1',"Bat_Series_1", ...
                'SelectedBattery2',"Bat_Series_1", ...
                'SelectedMotor',"Motor_HighTorque_A", ...
                'SelectedGenset',"Gen_Euro7_300kW"));
            result=simulate_hybrid_bus_core(input);
            testCase.verifyEqual(string(result.SelectedConfiguration.Battery1),"Bat_Series_1");
            testCase.verifyEqual(string(result.SelectedConfiguration.Motor),"Motor_HighTorque_A");
            testCase.verifyEqual(string(result.SelectedConfiguration.Genset),"Gen_Euro7_300kW");
        end

        function duplicateIDsAreRejectedCaseInsensitively(testCase)
            folder=string(tempname); mkdir(folder);
            cleanup=onCleanup(@()rmdir(folder,'s'));
            source=fullfile(testCase.ProjectFolder,'data','motors','MOT_12.m');
            cloneScript(source,fullfile(folder,'first.m'),["MOT-12","Motor_Custom"]);
            cloneScript(source,fullfile(folder,'second.m'),["MOT-12","motor_custom"]);
            testCase.verifyError(@()load_component_m_files(folder,"Motor"), ...
                'HybridBus:ComponentMDuplicate');
        end
    end
end

function cloneScript(source,destination,replacements)
lines=readlines(source);
lines=lines(~contains(lines,'.StorageOrder='));
for index=1:size(replacements,1)
    lines=replace(lines,replacements(index,1),replacements(index,2));
end
writelines(lines,destination);
end
