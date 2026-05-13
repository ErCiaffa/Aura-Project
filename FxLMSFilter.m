classdef FxLMSFilter < handle
    % FXLMSFILTER Classe Custom per Architetture di Controllo Attivo del Rumore.
    % Eredita dalla superclasse 'handle' per garantire l'incapsulamento 
    % e la persistenza mutabile degli stati interni del filtro senza  
    % l'aggravio prestazionale tipico dell'allocazione by-value.
    
    properties (Access = private)
        Lw          % Lunghezza dei Tap del filtro di controllo W(z)
        Ls          % Dimensione della stima del Secondary Path S(z)
        w           % Memoria statica del vettore pesi W(z) [Lw x 1]
        s_est       % Coefficienti discreti stimati del Subwoofer/Ambiente [Ls x 1]
        
        mu          % Fattore limite di discesa (Step-size per NLMS)
        epsilon     % Parametro di addolcimento numerico (Regularization term)
        
        x_buff      % Linea di ritardo FIFO per il rumore primario x(n) [Lw x 1]
        x_s_buff    % Finestra traslante sussidiaria di x(n) per calcolare x'(n) [Ls x 1]
        xf_buff     % Registro di accumulo per il segnale filtrato x'(n) [Lw x 1]
    end
    
    methods
        function obj = FxLMSFilter(Lw, s_est, mu, epsilon)
            % Costruttore: istanziazione preliminare per l'abbattimento
            % dei colli di bottiglia causati dalla re-allocazione a runtime.
            obj.Lw = Lw;
            obj.Ls = length(s_est);
            obj.s_est = s_est(:); % Imposizione vincolante del vettore colonna
            obj.w = zeros(Lw, 1);
            obj.mu = mu;
            obj.epsilon = epsilon;
            
            obj.x_buff = zeros(Lw, 1);
            obj.x_s_buff = zeros(obj.Ls, 1);
            obj.xf_buff = zeros(Lw, 1);
        end
        
        function [y, e_out] = step(obj, x_in, e_in)
            % METODO STEP: Processa il frame univoco in real-time.
            % Parametri di Ingresso:
            %   x_in - Campione quantizzato del rumore esterno acquisito.
            %   e_in - Pressione acustica residua valutata dal sensore di errore
            %          e retro-fornita come dato storico causale.
            
            e_out = e_in; % Esportazione log-friendly del valore per analisi
            
            % 1. AGGIORNAMENTO MATEMATICO NLMS (basato sulla memoria storica)
            % Si valuta l'energia istantanea accumulata dal riferimento filtrato
            power_factor = (obj.xf_buff' * obj.xf_buff) + obj.epsilon;
            % L'incisiva correzione dei pesi converge lungo il vero gradiente
            obj.w = obj.w + obj.mu * (e_in * obj.xf_buff) / power_factor;
            
            % 2. SCORRIMENTO DELLE LINEE DI RITARDO DELL'INGRESSO
            % Si emula l'hardware shift-register impilandone la logica 
            obj.x_buff = [x_in; obj.x_buff(1:end-1)];
            obj.x_s_buff = [x_in; obj.x_s_buff(1:end-1)];
            
            % 3. CREAZIONE DEL SEGNALE FILTERED-X
            % Convoluzione discreta istantanea tra ingresso primario e 
            % l'impronta predittiva del Secondary Path
            xf_current = obj.s_est' * obj.x_s_buff; 
            
            % 4. AGGIORNAMENTO DEL BUFFER DEL SEGNALE FILTRATO
            obj.xf_buff = [xf_current; obj.xf_buff(1:end-1)];
            
            % 5. SINTESI DELL'ANTI-RUMORE
            % Trasduzione lineare dell'uscita propedeutica per il DAC
            y = obj.w' * obj.x_buff;
        end
    end
end