classdef gensetMFileStorageTest < matlab.unittest.TestCase
    %GENSETMFILESTORAGETEST Verify one self-contained M file per genset.

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
        function workbookContainsNoGensetAssemblySheets(testCase)
            sheets=sheetnames(testCase.Database.Filename);
            removed=["Genset_Catalog","Engine_Catalog","Generator_Catalog", ...
                "Engine_Fuel_Map","Generator_Efficiency_Map"];
            testCase.verifyFalse(any(ismember(removed,sheets)));
        end

        function exactlyOneMFileExistsPerGenset(testCase)
            database=testCase.Database;
            testCase.verifyEqual(numel(database.GensetFiles),height(database.Genset_Catalog));
            testCase.verifyTrue(all(isfile(database.GensetFiles)));
            testCase.verifyTrue(all(endsWith(database.GensetFiles,'.m')));
        end

        function scriptContainsCompleteMatchedAssembly(testCase)
            GensetData=[];
            run(testCase.Database.GensetFiles(end));
            testCase.verifyEqual(GensetData.SchemaVersion,"1.0.0");
            testCase.verifyTrue(all(isfield(GensetData,{'Genset','Engine','Generator', ...
                'EngineFuelMap','GeneratorEfficiencyMap'})));
            suffix=extractAfter(string(GensetData.Genset.ComponentID),"-");
            testCase.verifyEqual(string(GensetData.Engine.ComponentID),"ENG-"+suffix);
            testCase.verifyEqual(string(GensetData.Generator.ComponentID),"GNR-"+suffix);
            testCase.verifyGreaterThan(height(GensetData.EngineFuelMap),1);
            testCase.verifyGreaterThan(height(GensetData.GeneratorEfficiencyMap),1);
            testCase.verifyEqual(min(GensetData.EngineFuelMap.BSFC_g_kWh), ...
                GensetData.Engine.BestBSFC_g_kWh,'AbsTol',1e-10);
            testCase.verifyEqual(max(GensetData.GeneratorEfficiencyMap.Efficiency), ...
                GensetData.Generator.PeakEfficiency,'AbsTol',1e-10);
        end

        function selectedGensetOwnsSimulationMaps(testCase)
            input=prepare_hybrid_bus_inputs(testCase.Database,struct('SelectedGenset',"GEN-12"));
            testCase.verifyFalse(ismember('GensetID',input.FuelMap.Properties.VariableNames));
            testCase.verifyFalse(ismember('GensetID',input.GeneratorMap.Properties.VariableNames));
            result=simulate_hybrid_bus_core(input);
            testCase.verifyEqual(string(result.SelectedConfiguration.Genset),"GEN-12");
        end
    end
end
