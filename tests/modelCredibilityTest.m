classdef modelCredibilityTest < matlab.unittest.TestCase
    %MODELCREDIBILITYTEST Public-interface tests for credibility analyses.
    properties
        RootFolder string
        DatabaseFile string
    end

    methods (TestClassSetup)
        function locateProject(testCase)
            testCase.RootFolder=string(fileparts(fileparts(mfilename('fullpath'))));
            testCase.DatabaseFile=fullfile(testCase.RootFolder,"data", ...
                "HybridBus_ComponentDatabase.xlsx");
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.RootFolder,"src")));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.RootFolder,"models")));
        end
    end

    methods (Test)
        function conceptComparisonIsExplicitlyQualified(testCase)
            database=load_hybrid_bus_database(testCase.DatabaseFile);
            input=prepare_hybrid_bus_inputs(database);
            result=simulate_hybrid_bus_core(input);
            comparison=compare_powertrain_concepts(result,input);

            testCase.verifyEqual(height(comparison),3);
            testCase.verifyEqual(comparison.EvidenceLevel, ...
                ["Implemented model";"Analytical screening";"Analytical screening"]);
            testCase.verifyGreaterThan(comparison.Cost_EUR_per_km,zeros(3,1));
        end

        function sensitivityStudyIsDeterministic(testCase)
            first=run_hybrid_bus_sensitivity_study(testCase.DatabaseFile);
            second=run_hybrid_bus_sensitivity_study(testCase.DatabaseFile);

            testCase.verifyEqual(first.Results,second.Results,AbsTol=1e-12);
            testCase.verifyEqual(height(first.Results),6);
        end

        function equivalenceAssessmentDeclaresTolerances(testCase)
            assessment=assess_matlab_simulink_equivalence(testCase.DatabaseFile, ...
                struct('PowertrainMode',"Hybrid"));
            bevAssessment=assess_matlab_simulink_equivalence(testCase.DatabaseFile, ...
                struct('PowertrainMode',"BEV",'InitialBattery1SOE',0.85, ...
                'InitialBattery2SOE',0.85));

            testCase.verifyEqual(height(assessment.SignalChecks),10);
            testCase.verifyGreaterThan(assessment.SignalChecks.Tolerance, ...
                zeros(height(assessment.SignalChecks),1));
            testCase.verifyTrue(all(ismember(assessment.SignalChecks.Status,["PASS","FAIL"])));
            testCase.verifyEqual(assessment.OverallStatus,"PASS");
            testCase.verifyEqual(bevAssessment.OverallStatus,"PASS");
        end
    end
end
