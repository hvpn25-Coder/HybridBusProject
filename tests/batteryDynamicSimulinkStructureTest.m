classdef batteryDynamicSimulinkStructureTest < matlab.unittest.TestCase
    %BATTERYDYNAMICSIMULINKSTRUCTURETEST Verify dynamic limits in both SLX models.

    properties
        ProjectFolder string
    end

    methods (TestClassSetup)
        function configurePath(testCase)
            testCase.ProjectFolder=string(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(testCase.ProjectFolder,'src')));
        end
    end

    methods (Test)
        function bothModelsUseDynamicBatterySaturation(testCase)
            models=["HybridBus_BackwardModel","HybridBus_BEVModel"];
            modelFolder=fullfile(testCase.ProjectFolder,'models');
            for model=models
                load_system(fullfile(modelFolder,model+'.slx'));
                cleanup=onCleanup(@()close_system(model,0));
                for pack=[1 2]
                    scope=model+"/Battery_Pack_"+pack;
                    dynamic=find_system(scope,'SearchDepth',1, ...
                        'Name','Terminal_Power_Limit');
                    lookup=find_system(scope,'SearchDepth',1,'BlockType','Lookup_n-D');
                    conversion=find_system(scope,'SearchDepth',1,'Regexp','on', ...
                        'Name','W_to_kW$','BlockType','Gain');
                    testCase.verifyNumElements(dynamic,1);
                    testCase.verifyNumElements(lookup,4);
                    testCase.verifyNumElements(conversion,2);
                    reference=regexprep(string(get_param(dynamic{1},'ReferenceBlock')),'\s','');
                    testCase.verifyTrue(endsWith(reference,"SaturationDynamic"));
                    ports=get_param(dynamic{1},'PortConnectivity');
                    testCase.verifyTrue(all(arrayfun(@(p)p.SrcBlock~=-1,ports(1:3))));
                    sourceNames=arrayfun(@(port)string(get_param(port.SrcBlock,'Name')), ...
                        ports(1:3));
                    testCase.verifyEqual(sourceNames(:), ...
                        ["Discharge_W_to_kW";"P_battery_cmd_kW";"Negative_Charge_Limit"]);
                    names=string(get_param(lookup,'Name'));
                    testCase.verifyTrue(all(ismember( ...
                        ["Discharge_Current_Limit_A","Charge_Current_Limit_A", ...
                        "OCV_Lookup","Resistance_Lookup"],names)));
                    direction=find_system(scope,'SearchDepth',1, ...
                        'Name','Discharge_Direction');
                    testCase.verifyEqual(string(get_param(direction{1},'Operator')),">=");
                    effectiveCurrent=find_system(scope,'SearchDepth',1,'BlockType','MinMax');
                    effectiveNames=string(get_param(effectiveCurrent,'Name'));
                    testCase.verifyTrue(all(ismember( ...
                        ["Effective_Discharge_Current","Effective_Charge_Current"], ...
                        effectiveNames)));
                end
                clear cleanup
                close_system(model,0);
            end
        end
    end
end
