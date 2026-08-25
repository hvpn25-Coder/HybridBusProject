classdef routeSlopeDisplayTest < matlab.unittest.TestCase
    methods (TestMethodSetup)
        function addProjectToPath(~)
            projectFolder=fileparts(fileparts(mfilename('fullpath')));
            addpath(projectFolder,fullfile(projectFolder,'src'));
        end
    end

    methods (Test)
        function constantUphillGrade(testCase)
            slope=compute_route_slope_percent([0;0.1;0.2],[10;15;20]);
            testCase.verifyEqual(slope,5*ones(3,1),'AbsTol',1e-12);
        end

        function constantDownhillGrade(testCase)
            slope=compute_route_slope_percent([0;0.25;0.5],[20;15;10]);
            testCase.verifyEqual(slope,-2*ones(3,1),'AbsTol',1e-12);
        end

        function repeatedDistanceRemainsFinite(testCase)
            slope=compute_route_slope_percent([0;0;0.1],[10;10;12]);
            testCase.verifyTrue(all(isfinite(slope)));
            testCase.verifyEqual(slope,[0;1;2],'AbsTol',1e-12);
        end

        function everyGeographicRouteHasFiniteSlope(testCase)
            projectFolder=fileparts(fileparts(mfilename('fullpath')));
            database=load_hybrid_bus_database( ...
                fullfile(projectFolder,'data','HybridBus_ComponentDatabase.xlsx'));
            routeIDs=unique(database.Route_Geometry.RouteID,'stable');
            for routeID=routeIDs'
                geometry=database.Route_Geometry( ...
                    database.Route_Geometry.RouteID==routeID,:);
                geometry=sortrows(geometry,'Sequence');
                slope=compute_route_slope_percent( ...
                    geometry.CumulativeDistance_km,geometry.Elevation_m);
                testCase.verifySize(slope,[height(geometry),1],routeID);
                testCase.verifyTrue(all(isfinite(slope)),routeID);
            end
        end
    end
end
