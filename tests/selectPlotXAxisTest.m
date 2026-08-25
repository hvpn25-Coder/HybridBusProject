classdef selectPlotXAxisTest < matlab.unittest.TestCase
    %SELECTPLOTXAXISTEST Tests time/distance horizontal-axis selection.

    methods (TestClassSetup)
        function addProjectToPath(testCase)
            projectFolder=fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(projectFolder,'src')));
        end
    end

    methods (Test)
        function testTimeModeUsesAdaptiveMinutes(testCase)
            [x,label,format]=select_plot_x_axis([0;1800;3600],[0;10000;20000],"Time");

            testCase.verifyEqual(x,[0;30;60],AbsTol=1e-12);
            testCase.verifyEqual(label,'Time (min)');
            testCase.verifyEqual(format,'%.0f');
        end

        function testTimeModeUsesAdaptiveHours(testCase)
            [x,label,format]=select_plot_x_axis([0;3600;10800],[0;10000;20000],"Time");

            testCase.verifyEqual(x,[0;1;3],AbsTol=1e-12);
            testCase.verifyEqual(label,'Time (h)');
            testCase.verifyEqual(format,'%.1f');
        end

        function testDistanceModeUsesKilometres(testCase)
            [x,label,format]=select_plot_x_axis([0;10;20],[0;1250;2500],"Distance");

            testCase.verifyEqual(x,[0;1.25;2.5],AbsTol=1e-12);
            testCase.verifyEqual(label,'Distance (km)');
            testCase.verifyEqual(format,'%.1f');
        end

        function testLongDistanceUsesWholeKilometreTicks(testCase)
            [x,label,format]=select_plot_x_axis([0;10],[0;650000],"Distance");

            testCase.verifyEqual(x,[0;650],AbsTol=1e-12);
            testCase.verifyEqual(label,'Distance (km)');
            testCase.verifyEqual(format,'%.0f');
        end
    end
end
