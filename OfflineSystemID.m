%% ANC Offline Secondary Path Identification Testbench
% Senior DSP Architect Version - Production Ready
% Obiettivo: Calcolo del vettore s_est (stima del Secondary Path)

clear; clc; close all;

%% 1. Configurazione Parametri di Sistema
Fs = 48000;               % Frequenza di campionamento (48 kHz)
T_probe = 2;              % Durata segnale di sonda (2 secondi)
N = T_probe * Fs;         % Numero totale di campioni
Ls = 256;                 % Lunghezza del filtro di stima (Tap)
D = 15;                   % Ritardo puro del Secondary Path (campioni)

% Parametri Algoritmo NLMS per Identificazione
mu_id = 0.1;              % Step-size per calibrazione rapida
epsilon_id = 1e-4;        % Regolarizzazione per stabilità numerica

%% 2. Modellazione Fisica del Secondary Path S(z)
% Simulazione di un altoparlante reale: Passa-banda 100-6000 Hz
[b_bp, a_bp] = butter(4, [100 6000]/(Fs/2), 'bandpass');

% Risposta all'impulso base del filtro passa-banda
% Calcoliamo Ls-D campioni per lasciare spazio al ritardo puro
s_impulse_base = impz(b_bp, a_bp, Ls - D);

% Costruzione del modello reale s_real_coeffs con ritardo D (latency)
% Inseriamo D zeri iniziali per simulare il tempo di volo acustico + latenza DAC
s_real_coeffs = [zeros(D, 1); s_impulse_base];
s_real_coeffs = s_real_coeffs(1:Ls); % Trim/Pad a lunghezza Ls
s_real_coeffs = s_real_coeffs / norm(s_real_coeffs); % Normalizzazione energia

%% 3. Generazione Segnale di Sonda e Acquisizione Virtuale
% Eccitazione a larga banda (White Noise) per coprire tutto lo spettro
v_probe = 0.6 * randn(N, 1); 

% Filtrazione attraverso il plant fisico reale S(z)
d_s_clean = filter(s_real_coeffs, 1, v_probe);

% Iniezione di Rumore di Fondo Microfonico (SNR = 30dB)
target_snr = 30;
noise_power = var(d_s_clean) / (10^(target_snr/10));
noise_floor = sqrt(noise_power) * randn(N, 1);
d_s_physical = d_s_clean + noise_floor; 

%% 4. Loop di Identificazione NLMS (Offline System ID)
s_est = zeros(Ls, 1);    
v_buffer = zeros(Ls, 1); 
e_id_monitor = zeros(N, 1);

fprintf('Avvio identificazione secondaria (NLMS)... ');
for n = 1:N
    % Update Buffer (Tapped Delay Line)
    v_buffer = [v_probe(n); v_buffer(1:end-1)];
    
    % Calcolo predizione y_hat
    y_hat = s_est' * v_buffer;
    
    % Errore di modellazione (differenza tra mic reale e stima)
    e_id = d_s_physical(n) - y_hat;
    e_id_monitor(n) = e_id;
    
    % Aggiornamento pesi NLMS (Normalizzato per invarianza all'ampiezza di v)
    % Formula: w(n+1) = w(n) + mu * e(n) * v(n) / (||v||^2 + eps)
    norm_v = (v_buffer' * v_buffer) + epsilon_id;
    s_est = s_est + mu_id * (e_id * v_buffer) / norm_v;
end
fprintf('Conclusa.\n');

%% 5. Analisi Tecnica e Output Grafico
[H_real, f_vec] = freqz(s_real_coeffs, 1, 1024, Fs);
[H_est, ~]  = freqz(s_est, 1, 1024, Fs);

% Setup Figure con dimensioni specifiche
figure('Name', 'ANC Secondary Path ID Analysis', 'Units', 'pixels', 'Position', [100, 100, 900, 800]);

% 1. Impulse Response: Verifica del match temporale e del ritardo D
subplot(3,1,1);
stem(s_real_coeffs, 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'Marker', 'none'); hold on;
plot(s_est, 'r--', 'LineWidth', 1.5);
title('Impulse Response: Reale vs Stimata (Match Temporale)');
legend('Fisico S(z)', 'Stima s\_est');
grid on; ylabel('Ampiezza');

% 2. Frequency Response: Verifica del range 100-6000 Hz
subplot(3,1,2);
semilogx(f_vec, 20*log10(abs(H_real) + 1e-6), 'Color', [0.7 0.7 0.7], 'LineWidth', 2); hold on;
semilogx(f_vec, 20*log10(abs(H_est) + 1e-6), 'r--', 'LineWidth', 1.5);
title('Risposta in Frequenza (Magnitudo)');
ylabel('dB'); grid on; xlim([20 Fs/2]);

% 3. Learning Curve: Verifica convergenza NLMS
subplot(3,1,3);
plot(10*log10(movmean(e_id_monitor.^2, 500) + 1e-12), 'k');
title('Curva di Apprendimento (MSE in dB)');
xlabel('Campioni'); ylabel('MSE [dB]'); grid on;

%% 6. Simulazione Integrazione (Placeholder per FxLMSFilter)
% Se hai già la classe FxLMSFilter definita, questo blocco inizializzerà il controller
mu_anc = 0.005; 
eps_anc = 1e-2;
L_control = 512;

try
    anc_system = FxLMSFilter(L_control, s_est, mu_anc, eps_anc);
    disp('SISTEMA PRONTO: Oggetto anc_system creato con successo.');
catch
    disp('Nota: Classe FxLMSFilter non trovata nel path. Il vettore s_est è comunque pronto.');
end

% Esportazione per verifica
MSE_finale = 10*log10(mean(e_id_monitor(end-1000:end).^2));
fprintf('Identificazione completata con MSE finale: %.2f dB\n', MSE_finale);

save('ANC_Calibration.mat', 's_est', 's_real_coeffs', 'Fs');
disp('Calibrazione salvata su disco.');