classdef routeMatStorageTest < matlab.unittest.TestCase
    %ROUTEMATSTORAGETEST Verify one-file-per-route database storage.

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
        function workbookContainsNoRouteSheets(testCase)
            sheets=sheetnames(testCase.Database.Filename);
            routeSheets=["Route_Catalog","Route_Time_Speed", ...
                "Route_Distance_Speed","Route_Grade","Route_Geometry"];
            testCase.verifyFalse(any(ismember(routeSheets,sheets)));
        end

        function exactlyOneMatFileExistsPerRoute(testCase)
            database=testCase.Database;
            testCase.verifyEqual(numel(database.RouteFiles),height(database.Route_Catalog));
            testCase.verifyTrue(all(isfile(database.RouteFiles)));
            for index=1:numel(database.RouteFiles)
                payload=load(database.RouteFiles(index),'RouteData');
                testCase.verifyTrue(isfield(payload,'RouteData'));
                testCase.verifyEqual(string(payload.RouteData.Metadata.RouteID), ...
                    string(database.Route_Catalog.RouteID(index)));
                testCase.verifyGreaterThanOrEqual(height(payload.RouteData.TimeSpeed),2);
            end
        end

        function combinedTablesRemainSimulationCompatible(testCase)
            database=testCase.Database;
            testCase.verifyEqual(numel(unique(database.Route_Time_Speed.RouteID)), ...
                height(database.Route_Catalog));
            input=prepare_hybrid_bus_inputs(database);
            result=simulate_hybrid_bus_core(input);
            testCase.verifyGreaterThan(result.Summary.RouteDistance_km,0);
        end
    end
end
