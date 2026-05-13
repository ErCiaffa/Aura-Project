classdef Wave3DVisualizer < handle
    % WAVE3DVISUALIZER Tool professionale per l'analisi 3D di segnali acustici.
    % Implementa validazione rigorosa degli input e rendering grafico ad alta fedeltà.
    
    properties (Constant, Access = private)
        % Design System Config (Dark Mode, Minimalist)
        COLOR_BG    = [0.07, 0.07, 0.08]; % Sfondo scuro elegante
        COLOR_AXES  = [0.12, 0.12, 0.13];
        COLOR_TEXT  = [0.90, 0.90, 0.90];
        FONT_NAME   = 'Helvetica';
        FONT_SIZE   = 11;
        SPEED_SOUND = 343; % m/s
    end
    
    methods (Static, Access = public)
        
        function fig = plotSpatialPropagation(y, fs, max_dist, varargin)
            % PLOTSPATIALPROPAGATION Genera il modello 3D della propagazione fisica.
            %
            % Input:
            %   y        - Vettore del segnale audio (1D)
            %   fs       - Frequenza di campionamento (Hz)
            %   max_dist - Distanza massima di propagazione (Metri)
            %   Name,Value - Opzioni addizionali (es. 'StepDistance')
            
            % 1. Validazione rigorosa degli input
            p = inputParser;
            addRequired(p, 'y', @(x) validateattributes(x, {'numeric'}, {'vector', 'nonempty', 'real'}));
            addRequired(p, 'fs', @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive', 'integer'}));
            addRequired(p, 'max_dist', @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
            addParameter(p, 'StepDistance', 0.5, @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
            parse(p, y, fs, max_dist, varargin{:});
            
            y_sig = p.Results.y(:)'; % Forza vettore riga per le matrici
            step_dist = p.Results.StepDistance;
            
            % 2. Setup domini
            distances = 0:step_dist:max_dist;
            t = (0:length(y_sig)-1) / fs;
            
            % 3. Preallocazione e Calcolo vettorizzato (Ottimizzazione performance)
            Z = zeros(length(distances), length(t));
            
            % Nota: idealmente il Propagator dovrebbe essere vettorizzato, 
            % qui lo richiamiamo iterativamente assumendo che la classe 
            % AdvancedSoundGenerator sia nel path.
            for i = 1:length(distances)
                Z(i, :) = AdvancedSoundGenerator.Propagator(y_sig, fs, distances(i));
            end
            
            % 4. Rendering
            [T, D] = meshgrid(t, distances);
            fig = figure('Name', 'Propagazione Spaziale 3D', 'Color', Wave3DVisualizer.COLOR_BG);
            
            surf(T, D, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.95);
            
            % 5. Applicazione del Design System
            ax = gca;
            Wave3DVisualizer.applyPremiumTheme(ax, 'Tempo (s)', 'Distanza (m)', 'Ampiezza (A)');
            title('Analisi Propagazione Spaziale', 'Color', Wave3DVisualizer.COLOR_TEXT, 'FontWeight', 'normal');
            
            % Illuminazione avanzata
            camlight('headlight');
            lighting gouraud;
            view(-45, 35);
            rotate3d on;
        end
        
        function fig = plotSpectrogram3D(y, fs, varargin)
            % PLOTSPECTROGRAM3D Genera un Waterfall Plot ad alta risoluzione.
            % Utilizza la STFT per analizzare l'evoluzione spettrale nel tempo.
            
            % 1. Input Parsing
            p = inputParser;
            addRequired(p, 'y', @(x) validateattributes(x, {'numeric'}, {'vector', 'nonempty', 'real'}));
            addRequired(p, 'fs', @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive', 'integer'}));
            addParameter(p, 'WindowSize', 0.05, @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
            addParameter(p, 'Overlap', 0.75, @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive', '<', 1}));
            addParameter(p, 'MaxFreq', 8000, @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
            parse(p, y, fs, varargin{:});
            
            % 2. Setup parametri STFT
            window_samples = round(p.Results.WindowSize * fs);
            noverlap = round(window_samples * p.Results.Overlap);
            nfft = max(512, 2^nextpow2(window_samples * 2)); % Zero-padding per interpolazione in frequenza
            
            % 3. Calcolo STFT
            [S, F, T] = spectrogram(p.Results.y, window_samples, noverlap, nfft, fs);
            P_dB = 10 * log10(abs(S).^2 + eps); % Conversione logaritmica sicura
            
            % 4. Rendering
            fig = figure('Name', 'Waterfall Spectrogram', 'Color', Wave3DVisualizer.COLOR_BG);
            surf(T, F, P_dB, 'EdgeColor', 'none');
            
            % 5. Applicazione del Design System
            ax = gca;
            Wave3DVisualizer.applyPremiumTheme(ax, 'Tempo (s)', 'Frequenza (Hz)', 'Potenza (dB)');
            title('Waterfall Spettrale 3D', 'Color', Wave3DVisualizer.COLOR_TEXT, 'FontWeight', 'normal');
            
            ylim([0, p.Results.MaxFreq]);
            colormap(ax, turbo); % Colormap ad alto contrasto per analisi spettrale
            
            view(-35, 55);
            rotate3d on;
        end
        
    end
    
    methods (Static, Access = private)
        
        function applyPremiumTheme(ax, xLabelStr, yLabelStr, zLabelStr)
            % APPLYPREMIUMTHEME Imposta i parametri grafici per un look pulito e moderno.
            
            % Colori e trasparenze
            set(ax, 'Color', Wave3DVisualizer.COLOR_AXES, ...
                    'XColor', Wave3DVisualizer.COLOR_TEXT, ...
                    'YColor', Wave3DVisualizer.COLOR_TEXT, ...
                    'ZColor', Wave3DVisualizer.COLOR_TEXT, ...
                    'GridColor', [0.4 0.4 0.4], ...
                    'GridAlpha', 0.3, ...
                    'FontName', Wave3DVisualizer.FONT_NAME, ...
                    'FontSize', Wave3DVisualizer.FONT_SIZE);
            
            % Etichette
            xlabel(xLabelStr, 'FontWeight', 'bold');
            ylabel(yLabelStr, 'FontWeight', 'bold');
            zlabel(zLabelStr, 'FontWeight', 'bold');
            
            % Shading e box
            shading interp;
            box(ax, 'off');
            grid(ax, 'on');
            
            % Colorbar customizzata
            cb = colorbar;
            cb.Color = Wave3DVisualizer.COLOR_TEXT;
            cb.Label.String = 'Intensità';
            cb.Label.FontWeight = 'bold';
            
            % Migliora l'anti-aliasing (richiede OpenGL supportato)
            if isequal(get(gcf, 'Renderer'), 'opengl')
                set(gcf, 'GraphicsSmoothing', 'on');
            end
        end
        
    end
end