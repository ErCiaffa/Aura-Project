classdef MinimalSystemTest < matlab.System
    % Classe di test minimale per verificare che matlab.System sia funzionante.
    methods (Access = protected)
        function y = stepImpl(~, u)
            y = u + 1;
        end
    end
end
