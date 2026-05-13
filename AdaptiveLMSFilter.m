classdef AdaptiveLMSFilter < handle
    % ADAPTIVELMSFILTER Filtro adattivo Feed-Forward (LMS/NLMS)
    % Ottimizzato per elaborazione real-time sample-by-sample in ANC.
    
    properties
        N           % Lunghezza del filtro (numero di tap)
        mu          % Passo di adattamento (Learning rate)
        useNLMS     % Flag booleano per abilitare Normalized LMS
        epsilon     % Fattore di regolarizzazione per NLMS
    end
    
    properties (Access = private)
        w           % Vettore dei pesi del filtro (N x 1)
        buffer      % Tapped delay line per i campioni di ingresso (N x 1)
    end
    
    methods
        function obj = AdaptiveLMSFilter(filterLength, stepSize, useNLMS)
            % Costruttore della classe
            if nargin < 3
                useNLMS = true; % Default a NLMS per maggiore stabilità
            end
            
            obj.N = filterLength;
            obj.mu = stepSize;
            obj.useNLMS = useNLMS;
            obj.epsilon = 1e-6; % Previene divisione per zero
            
            % Inizializza lo stato
            obj.reset();
        end
        
        function reset(obj)
            % Resetta i pesi e il buffer circolare
            obj.w = zeros(obj.N, 1);
            obj.buffer = zeros(obj.N, 1);
        end
        
        function [y, e] = step(obj, x_in, d_in)
            % Esecuzione sample-by-sample
            % x_in: Campione di rumore di riferimento al tempo n
            % d_in: Campione di rumore primario (desiderato) al tempo n
            
            % 1. Aggiornamento della Tapped Delay Line (Buffer FIFO)
            % Shift dei campioni verso il basso e inserimento del nuovo campione
            obj.buffer = [x_in; obj.buffer(1:end-1)];
            
            % 2. Calcolo dell'uscita del filtro FIR (y)
            % Prodotto interno tra i pesi e il buffer dei segnali
            y = obj.w' * obj.buffer;
            
            % 3. Calcolo dell'errore (e)
            % Differenza tra il rumore primario e l'anti-rumore generato
            e = d_in - y;
            
            % 4. Aggiornamento dei pesi (Algoritmo LMS/NLMS)
            if obj.useNLMS
                % Calcolo della potenza del segnale nel buffer (Norma L2 al quadrato)
                signal_power = obj.buffer' * obj.buffer;
                % Passo di adattamento normalizzato
                mu_eff = obj.mu / (signal_power + obj.epsilon);
            else
                % Passo di adattamento standard
                mu_eff = obj.mu;
            end
            
            % Regola di aggiornamento: w(n+1) = w(n) + mu * e(n) * x(n)
            obj.w = obj.w + mu_eff * e * obj.buffer;
        end
        
        function weights = getWeights(obj)
            % Metodo getter per ispezionare i pesi finali
            weights = obj.w;
        end
    end
end