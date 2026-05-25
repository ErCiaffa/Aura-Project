classdef SourceGeneratorSystem < matlab.System
    % SourceGeneratorSystem  Sorgente di rumore selezionabile per il testbench ANC.
    %
    % Genera l'intero buffer di durata 'Duration' una sola volta in setup
    % (via AdvancedSoundGenerator) e lo riproduce campione per campione.
    %
    % Sorgenti supportate (selezionabili da dropdown nella mask Simulink):
    %   'Jackhammer'  - AdvancedSoundGenerator.Jackhammer
    %   'ClubNoise'   - AdvancedSoundGenerator.ClubNoise
    %   'PinkNoise'   - AdvancedSoundGenerator.PinkNoise
    %
    % In loop continuo: quando il buffer si esaurisce ricomincia da 0.

    properties (Nontunable)
        SourceType = 'PinkNoise'
        SampleRate = 48000
        Duration = 10
        Amplitude = 1.0
    end

    properties (Hidden, Constant)
        SourceTypeSet = matlab.system.StringSet({'Jackhammer','ClubNoise','PinkNoise'})
    end

    properties (Access = private)
        Buffer
        Index
    end

    methods (Access = protected)
        function setupImpl(obj)
            switch obj.SourceType
                case 'Jackhammer'
                    [y, ~] = AdvancedSoundGenerator.Jackhammer(obj.Duration, obj.SampleRate);
                case 'ClubNoise'
                    [y, ~] = AdvancedSoundGenerator.ClubNoise(obj.Duration, obj.SampleRate);
                case 'PinkNoise'
                    [y, ~] = AdvancedSoundGenerator.PinkNoise(obj.Duration, obj.SampleRate);
            end
            obj.Buffer = obj.Amplitude * y(:);
            obj.Index = 1;
        end

        function y = stepImpl(obj)
            y = obj.Buffer(obj.Index);
            obj.Index = obj.Index + 1;
            if obj.Index > numel(obj.Buffer)
                obj.Index = 1;
            end
        end

        function resetImpl(obj)
            obj.Index = 1;
        end

        function num = getNumInputsImpl(~)
            num = 0;
        end

        function num = getNumOutputsImpl(~)
            num = 1;
        end

        function s = getOutputSizeImpl(~)
            s = [1 1];
        end

        function d = getOutputDataTypeImpl(~)
            d = 'double';
        end

        function c = isOutputComplexImpl(~)
            c = false;
        end

        function f = isOutputFixedSizeImpl(~)
            f = true;
        end
    end
end
