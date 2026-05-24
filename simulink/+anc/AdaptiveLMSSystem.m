classdef AdaptiveLMSSystem < matlab.System
    % AdaptiveLMSSystem  Wrapper Simulink per AdaptiveLMSFilter (LMS / NLMS).
    %
    % Porte:
    %   in1: x (riferimento)
    %   in2: d (desiderato / rumore primario)
    % Uscite:
    %   y (output filtro)
    %   e (errore = d - y)

    properties (Nontunable)
        FilterLength = 512
        StepSize = 5e-3
        UseNLMS = true
    end

    properties (Access = private)
        Filter
    end

    methods (Access = protected)
        function setupImpl(obj)
            obj.Filter = AdaptiveLMSFilter(obj.FilterLength, obj.StepSize, logical(obj.UseNLMS));
        end

        function [y, e] = stepImpl(obj, x_in, d_in)
            [y, e] = obj.Filter.step(x_in, d_in);
        end

        function resetImpl(obj)
            obj.Filter.reset();
        end

        function num = getNumInputsImpl(~)
            num = 2;
        end

        function num = getNumOutputsImpl(~)
            num = 2;
        end

        function [s1, s2] = getOutputSizeImpl(~)
            s1 = [1 1]; s2 = [1 1];
        end

        function [d1, d2] = getOutputDataTypeImpl(~)
            d1 = 'double'; d2 = 'double';
        end

        function [c1, c2] = isOutputComplexImpl(~)
            c1 = false; c2 = false;
        end

        function [f1, f2] = isOutputFixedSizeImpl(~)
            f1 = true; f2 = true;
        end
    end
end
