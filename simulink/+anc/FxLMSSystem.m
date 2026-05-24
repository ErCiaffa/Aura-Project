classdef FxLMSSystem < matlab.System
    % FxLMSSystem  Wrapper Simulink (matlab.System) per FxLMSFilter.
    %
    % Porte:
    %   in1: x  (riferimento, scalare, sample-by-sample)
    %   in2: e  (errore microfonico, scalare)
    % Uscite:
    %   y     (anti-rumore, scalare)
    %   e_out (errore registrato per logging, scalare)

    properties (Nontunable)
        Lw = 512
        SecondaryPath = zeros(256,1)
        StepSize = 5e-3
        Epsilon = 1e-2
    end

    properties (Access = private)
        Filter
    end

    methods (Access = protected)
        function setupImpl(obj)
            s_est = obj.SecondaryPath(:);
            if isempty(s_est) || all(s_est == 0)
                error('FxLMSSystem:EmptySecondaryPath', ...
                    'SecondaryPath e vuoto. Carica ANC_Calibration.mat e passa s_est.');
            end
            obj.Filter = FxLMSFilter(obj.Lw, s_est, obj.StepSize, obj.Epsilon);
        end

        function [y, e_out] = stepImpl(obj, x_in, e_in)
            [y, e_out] = obj.Filter.step(x_in, e_in);
        end

        function resetImpl(obj)
            obj.Filter = FxLMSFilter(obj.Lw, obj.SecondaryPath(:), obj.StepSize, obj.Epsilon);
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
