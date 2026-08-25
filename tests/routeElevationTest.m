classdef routeElevationTest < matlab.unittest.TestCase
    %ROUTEELEVATIONTEST Verifies cached terrain data used by the Route Map tab.

    properties
        Database
    end

    methods (TestMethodSetup)
        function loadDatabase(testCase)
            projectFolder=fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(projectFolder,'src')));
            testCase.Database=load_hybrid_bus_database( ...
                fullfile(projectFolder,'data','HybridBus_ComponentDatabase.xlsx'));
        end
    end

    methods (Test)
        function testAllGeographicSamplesHaveElevation(testCase)
            geometry=testCase.Database.Route_Geometry;

            testCase.verifyTrue(all(isfinite(geometry.Elevation_m)));
            testCase.verifyTrue(all(geometry.Elevation_m>=-500));
            testCase.verifyTrue(all(geometry.Elevation_m<=9000));
            testCase.verifyTrue(all(strlength(geometry.ElevationSource)>0));
        end

        function testElevationPreservesGeometryOrdering(testCase)
            geometry=sortrows(testCase.Database.Route_Geometry( ...
                testCase.Database.Route_Geometry.RouteID=="EUR-MUC-ROM",:), ...
                'Sequence');

            testCase.verifyEqual(geometry.Sequence,(1:height(geometry))');
            testCase.verifyGreaterThanOrEqual(diff(geometry.CumulativeDistance_km),0);
            testCase.verifyEqual(height(geometry),1200);
        end

        function testDatabaseVersionIncludesThreeDimensionalMapData(testCase)
            testCase.verifyEqual(testCase.Database.Version,"1.7.0");
        end
    end
end
