classdef scaleTimeForDisplayTest < matlab.unittest.TestCase
    %SCALETIMEFORDISPLAYTEST Tests adaptive time-axis scaling.

    methods (TestClassSetup)
        function addProjectToPath(testCase)
            projectFolder=fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(projectFolder,'src')));
        end
    end

    methods (Test)
        function testShortMissionUsesMinutes(testCase)
            [time,label,format]=scale_time_for_display([0;30*60;90*60]);

            testCase.verifyEqual(time,[0;30;90],AbsTol=1e-12);
            testCase.verifyEqual(label,'Time (min)');
            testCase.verifyEqual(format,'%.0f');
        end

        function testLongMissionUsesHours(testCase)
            [time,label,format]=scale_time_for_display([0;90*60;3*3600]);

            testCase.verifyEqual(time,[0;1.5;3],AbsTol=1e-12);
            testCase.verifyEqual(label,'Time (h)');
            testCase.verifyEqual(format,'%.1f');
        end

        function testTwoHourBoundaryUsesHours(testCase)
            [time,label]=scale_time_for_display([0;2*3600]);

            testCase.verifyEqual(time,[0;2],AbsTol=1e-12);
            testCase.verifyEqual(label,'Time (h)');
        end
    end
end
