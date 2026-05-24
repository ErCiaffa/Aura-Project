classdef SourceGeneratorSystem < matlab.System
    % SourceGeneratorSystem  Sorgente di rumore selezionabile per il testbench ANC.
    %
    % Genera l'intero buffer di durata 'Duration' una sola volta in setup
    % (via AdvancedSoundGenerator) e lo riproduce campione per campione.
    % Questo evita la generazione costosa dei kernel a runtime e garantisce
    % una sample-rate stabile.
    %
    % Sorgenti supportate:
    %   'Jackhammer'  - AdvancedSoundGenerator.Jackhammer
    %   'ClubNoise'   - AdvancedSoundGenerator.ClubNoise
    %   'PinkNoise'   - AdvancedSoundGenerator.PinkNoise
    %
    % In loop continuo: quando il buffer si esaurisce ricomincia da 0.

    properties (Nontunable)
        SourceType (1,:) char {mustBeMember(SourceType, ...
            {'Jackhammer','ClubNoise','PinkNoise'})} = 'PinkNoise'
        SampleRate (1,1) double {mustBePositive} = 48000
        Duration (1,1) double {mustBePositive} = 10
        Amplitude (1,1) double = 1.0
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
