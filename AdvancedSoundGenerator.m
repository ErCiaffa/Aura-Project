classdef AdvancedSoundGenerator
%ADVANCEDSOUNDGENERATOR  Generatore professionale per test ANC.
%
%  Metodi pubblici (tutti restituiscono [y, fs] con y normalizzato):
%   - Jackhammer(duration, fs, opts)
%   - ClubNoise(duration, fs, opts)
%   - Propagator(x, fs, distance, opts)
%   - PinkNoise(duration, fs, opts)
%   - LoadAudioFile(filePath, fsTarget, opts)
%   - LoadAudioFolder(folderPath, fsTarget, opts)
%
%  DSP notes:
%   - Fractional delay: dsp.VariableFractionalDelay (Farrow/Lagrange interno, streaming-ready).
%   - Risonanza metallica: comb feedback con damping (LP nel loop).
%   - Assorbimento atmosferico: ISO 9613-1 -> alpha(f) [dB/m], poi FIR magnitude shaping.
%
%  Requisito ANC: jitter + non stazionarietà (slow AM / micro-bursts) per evitare cancellazione banale.

    methods (Static)

        function [y, fs] = Jackhammer(duration, fs, opts)
            %JACKHAMMER  Martello pneumatico avanzato.
            %
            % Include:
            %  - Impatto LF (thump) + hiss HF (scarico aria)
            %  - Jitter temporale (non perfettamente periodico)
            %  - Burst multi-impulso per colpo (micro-rimbalzi)
            %  - Slow AM (fatica / variazione pressione)
            %  - Risonanza metallica (comb feedback con damping)
            %  - Hiss continuo + "valve bursts" random
            %
            if nargin < 2 || isempty(fs), fs = 48000; end
            if nargin < 3, opts = struct(); end
            opts = AdvancedSoundGenerator.mergeDefaults(opts, struct( ...
                'bpm', 450, ...
                'jitterStd', 0.08, ...          % std relativa sul periodo
                'hitDur', 0.16, ...             % durata kernel base colpo [s]
                'thumpCutoffHz', 280, ...
                'hissBandHz', [2500 7500], ...
                'hissLevel', 0.35, ...
                'resDelayMs', 2.2, ...
                'resFeedback', 0.55, ...
                'resDampHz', 3500, ...
                'microBurstCount', [2 4], ...   % range impulsi per colpo
                'microBurstMaxMs', 8, ...       % max separazione burst [ms]
                'microBurstDecay', 0.55, ...    % quanto calano i burst successivi
                'slowAM_Hz', [0.25 0.9], ...    % drift lento ampiezza
                'slowAM_Depth', 0.35, ...
                'airLevel', 0.04, ...
                'valveBurstRateHz', 0.4, ...
                'valveBurstLevel', 0.10, ...
                'valveBurstDur', 0.12));

            N = max(1, round(duration * fs));
            y = zeros(N, 1);

            % Periodo medio
            periodAvg = 60 / opts.bpm;

            % ----- Slow AM (fatica/pressione) -----
            % Rumore low-passed in banda sub-Hz, poi mappato a [1-depth, 1+depth]
            slow = randn(N,1);
            fc = mean(opts.slowAM_Hz);
            [bAM, aAM] = butter(2, min(0.999, fc/(fs/2)), 'low');
            slow = filter(bAM, aAM, slow);
            slow = slow / (max(abs(slow))+eps);
            slowGain = 1 + opts.slowAM_Depth * slow;

            % ----- Kernel base del colpo (thump + hiss + risonanza) -----
            Nh = max(2, round(opts.hitDur * fs));
            th = (0:Nh-1)'/fs;

            envMain = (1 - exp(-th*500)) .* exp(-th*16);
            envHiss = (1 - exp(-th*1200)) .* exp(-th*40);

            wl = randn(Nh,1);
            [bL, aL] = butter(2, min(0.99, opts.thumpCutoffHz/(fs/2)), 'low');
            thump = filter(bL, aL, wl) .* envMain;

            wh = randn(Nh,1);
            bp = opts.hissBandHz/(fs/2);
            bp(1) = max(1e-3, bp(1)); bp(2) = min(0.999, bp(2));
            [bB, aB] = butter(2, bp, 'bandpass');
            hiss = filter(bB, aB, wh) .* envHiss;

            baseHit = thump + opts.hissLevel*hiss;

            % Risonanza metallica (comb feedback + damping LP nel loop)
            M = max(1, round((opts.resDelayMs*1e-3) * fs));
            baseHit = AdvancedSoundGenerator.feedbackCombDamped(baseHit, M, opts.resFeedback, opts.resDampHz, fs);

            % ----- Sequenziamento colpi: jitter + micro-bursts -----
            idx = 1;
            while idx <= N
                % Numero burst per colpo
                nb = randi([opts.microBurstCount(1), opts.microBurstCount(2)]);
                % Offsets in campioni (0..maxMs), ordinati
                maxOff = max(1, round(opts.microBurstMaxMs*1e-3*fs));
                offs = sort(randi([0, maxOff], nb, 1));

                for k = 1:nb
                    gainK = (opts.microBurstDecay)^(k-1) * (0.85 + 0.3*rand); % variabilità
                    start = idx + offs(k);
                    if start > N, continue; end
                    L = min(Nh, N-start+1);
                    y(start:start+L-1) = y(start:start+L-1) + gainK * baseHit(1:L);
                end

                % jitter gaussiano relativo sul periodo, clampato
                per = periodAvg * (1 + opts.jitterStd*randn());
                per = min(max(per, 0.45*periodAvg), 1.8*periodAvg);
                step = max(1, round(per * fs));
                idx = idx + step;
            end

            % Applica slow AM (non stazionarietà globale)
            y = y .* slowGain;

            % ----- Hiss continuo + "valve bursts" -----
            if opts.airLevel > 0
                w = randn(N,1);
                [bAir, aAir] = butter(2, min(0.99, 9000/(fs/2)), 'low');
                air = filter(bAir, aAir, w);
                y = y + opts.airLevel * air;
            end

            if opts.valveBurstLevel > 0 && opts.valveBurstRateHz > 0
                % Processo Poisson-like: eventi con rate ~ valveBurstRateHz
                p = opts.valveBurstRateHz / fs;
                trig = rand(N,1) < p;
                burstLen = max(8, round(opts.valveBurstDur * fs));
                burstEnv = (1 - exp(-(0:burstLen-1)'/fs*800)) .* exp(-(0:burstLen-1)'/fs*25);

                % burst hiss bandpass più stretto (valvola/aria)
                wb = randn(N,1);
                [bVB, aVB] = butter(2, [3500 9000]/(fs/2), 'bandpass');
                vbNoise = filter(bVB, aVB, wb);

                for n = 1:N
                    if trig(n)
                        L = min(burstLen, N-n+1);
                        y(n:n+L-1) = y(n:n+L-1) + opts.valveBurstLevel * vbNoise(n:n+L-1) .* burstEnv(1:L);
                    end
                end
            end

            [y, fs] = AdvancedSoundGenerator.formatOutput(y, fs);
        end

        function [y, x_ref, distVec, fs] = MovingJackhammer(duration, fs, opts)
            %MOVINGJACKHAMMER  Martello pneumatico in movimento (delay+atten+assorbimento time-varying).
            %
            % Output:
            %   y       : segnale al mic (propagato dinamicamente)
            %   x_ref   : reference mic “near-field” (propagato a distanza piccola costante)
            %   distVec : distanza istantanea (ground truth)
            %   fs
            
                if nargin < 2 || isempty(fs), fs = 48000; end
                if nargin < 3, opts = struct(); end
            
                opts = AdvancedSoundGenerator.mergeDefaults(opts, struct( ...
                    'startPos', [2, 5], ...
                    'endPos',   [0.5, 0], ...
                    'c', 343, ...
                    'refDistance', 0.25, ...      % reference mic vicino (metri)
                    'chunkSec', 0.020, ...
                    'absFIROrder', 128, ...
                    'tempC', 20, 'relHum', 50, 'pressurekPa', 101.325, ...
                    'normalize', false));         % per ANC: default false
            
                % 1) sorgente “dry”
                [x_dry, fs] = AdvancedSoundGenerator.Jackhammer(duration, fs, opts);
                N = numel(x_dry);
            
                % 2) traiettoria distanza
                d_front = linspace(opts.startPos(1), opts.endPos(1), N).';
                d_lat   = linspace(opts.startPos(2), opts.endPos(2), N).';
                distVec = sqrt(d_front.^2 + d_lat.^2);
            
                % 3) delay variabile (include Doppler “naturale” del time-warp)
                maxDelay = ceil(max(distVec)/opts.c * fs) + 64;
                vfd = dsp.VariableFractionalDelay('InterpolationMethod','Farrow', ...
                    'MaximumDelay', maxDelay); % ok: delay input time-varying :contentReference[oaicite:2]{index=2}
            
                delaySamples = (distVec ./ opts.c) .* fs;
                y_delayed = vfd(x_dry, delaySamples);
            
                % 4) reference mic (near field): usa Propagator statico a distanza piccola
                %    (più realistico di x_dry nudo)
                x_ref = AdvancedSoundGenerator.Propagator(x_dry, fs, opts.refDistance, struct( ...
                    'useISO9613', false, 'normalize', false));
            
                % 5) chunk processing: attenuazione + assorbimento ISO (FIR) aggiornato a blocchi
                chunkSize = max(32, round(opts.chunkSec * fs));
                y = zeros(N,1);
            
                % crossfade per evitare click quando il FIR cambia tra chunk
                xfLen = min(round(0.003*fs), floor(chunkSize/4)); % ~3ms o meno
                wIn  = (0:xfLen-1)'/(xfLen-1 + eps);
                wOut = 1 - wIn;
            
                prevChunkTail = zeros(xfLen,1);
            
                numChunks = ceil(N / chunkSize);
                prevFilteredTail = zeros(xfLen,1);
            
                for c = 1:numChunks
                    i1 = (c-1)*chunkSize + 1;
                    i2 = min(c*chunkSize, N);
                    idx = i1:i2;
            
                    midDist = distVec(round((i1+i2)/2));
            
                    % geometrical spreading
                    gain = 1 / (midDist + 1e-6);
            
                    % FIR assorbimento (ISO 9613-1)
                    f = linspace(0, fs/2, 256);
                    alpha = AdvancedSoundGenerator.iso9613_alpha_db_per_m(f, opts.tempC, opts.relHum, opts.pressurekPa);
                    mag = 10.^(-(alpha * midDist) / 20);
            
                    b = fir2(opts.absFIROrder, f/(fs/2), mag); % order = absFIROrder
            
                    chunk = y_delayed(idx);
                    chunkF = filter(b, 1, chunk) * gain;
            
                    % crossfade tra chunk per evitare discontinuità (b cambia => stato non trasferibile)
                    if c == 1
                        y(idx) = chunkF;
                    else
                        % mixa l’inizio del chunk corrente con la coda del precedente
                        L = min(xfLen, numel(chunkF));
                        chunkF(1:L) = chunkF(1:L).*wIn(1:L) + prevFilteredTail(1:L).*wOut(1:L);
                        y(idx) = chunkF;
                    end
            
                    % salva tail filtrata del chunk corrente
                    Ltail = min(xfLen, numel(chunkF));
                    prevFilteredTail = chunkF(end-Ltail+1:end);
                    if Ltail < xfLen
                        prevFilteredTail = [zeros(xfLen-Ltail,1); prevFilteredTail];
                    end
                end
            
                % Normalizzazione: per ANC meglio NON normalizzare qui
                if opts.normalize
                    scale = max(abs([y; x_ref])) + eps;
                    y = y/scale;
                    x_ref = x_ref/scale;
                end
            end

        function [y, fs] = ClubNoise(duration, fs, opts)
            %CLUBNOISE  Club esterno: kick pitch-drop + low-pass muro + saturazione.
            if nargin < 2 || isempty(fs), fs = 48000; end
            if nargin < 3, opts = struct(); end
            opts = AdvancedSoundGenerator.mergeDefaults(opts, struct( ...
                'bpm', 128, ...
                'kickDur', 0.22, ...
                'fStartHz', 150, ...
                'fEndHz', 40, ...
                'pitchDropRate', 22, ...
                'kickDecay', 9, ...
                'wallCutoffHz', 140, ...
                'wallOrder', 5, ...
                'speakerDrive', 1.6, ...
                'roomThrobLevel', 0.08));

            N = max(1, round(duration * fs));
            y = zeros(N, 1);

            Nk = max(2, round(opts.kickDur * fs));
            tk = (0:Nk-1)'/fs;
            fInst = opts.fEndHz + (opts.fStartHz - opts.fEndHz) * exp(-opts.pitchDropRate * tk);
            phi = 2*pi*cumsum(fInst)/fs;
            env = (1 - exp(-tk*900)) .* exp(-opts.kickDecay * tk);
            kick = sin(phi) .* env;

            click = zeros(Nk,1); click(1:min(12,Nk)) = linspace(1,0,min(12,Nk))';
            kick = kick + 0.15*click;

            spb = max(1, round(fs * (60/opts.bpm)));
            idx = 1;
            while idx <= N
                L = min(Nk, N-idx+1);
                y(idx:idx+L-1) = y(idx:idx+L-1) + kick(1:L);
                idx = idx + spb;
            end

            if opts.roomThrobLevel > 0
                w = randn(N,1);
                [bLF, aLF] = butter(2, min(0.99, 90/(fs/2)), 'low');
                throb = filter(bLF, aLF, w);
                y = y + opts.roomThrobLevel * throb;
            end

            [bW, aW] = butter(opts.wallOrder, min(0.99, opts.wallCutoffHz/(fs/2)), 'low');
            y = filter(bW, aW, y);

            y = tanh(opts.speakerDrive * y);
            
            [y, fs] = AdvancedSoundGenerator.formatOutput(y, fs);
        end


        function [yProp, fs] = Propagator(x, fs, distance, opts)
            if nargin < 2 || isempty(fs), fs = 48000; end
            if nargin < 3, distance = 1; end
            if nargin < 4, opts = struct(); end
            opts = AdvancedSoundGenerator.mergeDefaults(opts, struct( ...
                'c', 343, ...
                'attenEps', 1e-6, ... % Evita divisione per zero
                'useISO9613', true, ...
                'tempC', 20, ...
                'relHum', 50, ...
                'pressurekPa', 101.325, ...
                'absFIRLen', 254, ... % fir2 preferisce numeri pari (ordine dispari)
                'absMaxHz', 20000, ...
                'normalize', true));
            
            x = x(:);
            % ---- Fractional delay (Farrow) ----
            delaySec = distance / opts.c;
            D = delaySec * fs;
            % MATLAB dsp.VariableFractionalDelay richiede System Toolbox
            vfd = dsp.VariableFractionalDelay('InterpolationMethod','Farrow','MaximumDelay', ceil(D)+10);
            yDel = vfd(x, D * ones(size(x)));

            % ---- Attenuazione Geometrica ----
            yProp = yDel * (1 / (distance + opts.attenEps));

            % ---- Assorbimento Atmosferico (FIXED) ----
            if opts.useISO9613 && distance > 0
                L = opts.absFIRLen;
                numFreqs = 512;
                f = linspace(0, fs/2, numFreqs); % Arriva fino a Nyquist
                alpha = AdvancedSoundGenerator.iso9613_alpha_db_per_m(f, opts.tempC, opts.relHum, opts.pressurekPa);
                
                % Conversione alpha (dB/m) in guadagno lineare
                mag = 10.^(-(alpha * distance) / 20);
                
                % Normalizzazione frequenze per fir2 (0 a 1)
                fn = f / (fs/2);
                b = fir2(L, fn, mag);
                yProp = filter(b, 1, yProp);
            end

            if opts.normalize
                [yProp, fs] = AdvancedSoundGenerator.formatOutput(yProp, fs);
            end
        end

        function [y, fs] = PinkNoise(duration, fs, opts)
            %PINKNOISE  Rumore rosa (Kellet).
            if nargin < 2 || isempty(fs), fs = 48000; end
            if nargin < 3, opts = struct(); end %#ok<NASGU>
            N = max(1, round(duration * fs));
            white = randn(N,1);
            white = white - mean(white);

            b0=0; b1=0; b2=0; b3=0; b4=0; b5=0; b6=0;
            y = zeros(N,1);
            for n = 1:N
                w = white(n);
                b0 = 0.99886 * b0 + w * 0.0555179;
                b1 = 0.99332 * b1 + w * 0.0750759;
                b2 = 0.96900 * b2 + w * 0.1538520;
                b3 = 0.86650 * b3 + w * 0.3104856;
                b4 = 0.55000 * b4 + w * 0.5329522;
                b5 = -0.7616 * b5 - w * 0.0168980;
                y(n) = b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362;
                b6 = w * 0.115926;
            end

            [y, fs] = AdvancedSoundGenerator.formatOutput(y, fs);
        end


        function [y, fs] = LoadAudioFile(filePath, fsTarget, opts)
            %LOADAUDIOFILE  Carica un file reale, converte mono, resample, normalizza.
            %
            %  [y,fs] = LoadAudioFile("C:\...\file.wav", 48000)
            %
            % opts:
            %   .toMono = true
            %   .normalize = true
            %   .trimSilence = false
            %   .silenceThreshDB = -45
            %
            if nargin < 2 || isempty(fsTarget), fsTarget = []; end
            if nargin < 3, opts = struct(); end
            opts = AdvancedSoundGenerator.mergeDefaults(opts, struct( ...
                'toMono', true, ...
                'normalize', true, ...
                'trimSilence', false, ...
                'silenceThreshDB', -45));

            [x, fsIn] = audioread(filePath);
            if size(x,2) > 1 && opts.toMono
                x = mean(x, 2);
            end

            if ~isempty(fsTarget) && fsIn ~= fsTarget
                x = resample(x, fsTarget, fsIn);
                fs = fsTarget;
            else
                fs = fsIn;
            end

            if opts.trimSilence
                x = AdvancedSoundGenerator.trim_silence(x, opts.silenceThreshDB);
            end

            if opts.normalize
                [y, fs] = AdvancedSoundGenerator.formatOutput(x, fs);
            else
                y = x(:);
            end
        end


        function [signals, fs] = LoadAudioFolder(folderPath, fsTarget, opts)
            %LOADAUDIOFOLDER  Carica tutti i file audio in una cartella (audioDatastore).
            %
            % Ritorna:
            %   signals: cell array {Kx1}, ciascuno Nx1 (lunghezze variabili)
            %   fs: fsTarget (se specificato) o fs del primo file
            %
            if nargin < 2 || isempty(fsTarget), fsTarget = []; end
            if nargin < 3, opts = struct(); end
            opts = AdvancedSoundGenerator.mergeDefaults(opts, struct( ...
                'includeSubfolders', true, ...
                'toMono', true, ...
                'normalize', true, ...
                'trimSilence', false, ...
                'silenceThreshDB', -45));

            ads = audioDatastore(folderPath, ...
                'IncludeSubfolders', opts.includeSubfolders);

            K = numel(ads.Files);
            signals = cell(K,1);
            fs = fsTarget;

            for k = 1:K
                [sig, fsk] = audioread(ads.Files{k});
                if size(sig,2) > 1 && opts.toMono
                    sig = mean(sig,2);
                end
                if isempty(fs) % non specified
                    fs = fsk;
                end
                if ~isempty(fsTarget) && fsk ~= fsTarget
                    sig = resample(sig, fsTarget, fsk);
                    fs = fsTarget;
                end
                if opts.trimSilence
                    sig = AdvancedSoundGenerator.trim_silence(sig, opts.silenceThreshDB);
                end
                if opts.normalize
                    sig = sig(:);
                    m = max(abs(sig)); if m>0, sig = sig/m; end
                else
                    sig = sig(:);
                end
                signals{k} = sig;
            end
        end

    end


    methods (Static, Access = private)

        function [y, fs] = formatOutput(y, fs)
            y = y(:);
            m = max(abs(y));
            if m > 0, y = y / m; end
            if nargin < 2, fs = []; end
        end

        function opts = mergeDefaults(opts, defs)
            f = fieldnames(defs);
            for k = 1:numel(f)
                if ~isfield(opts, f{k}) || isempty(opts.(f{k}))
                    opts.(f{k}) = defs.(f{k});
                end
            end
        end

        function y = feedbackCombDamped(x, M, g, dampHz, fs)
            x = x(:);
            N = numel(x);
            y = zeros(N,1);

            a = exp(-2*pi*dampHz/fs);
            lpState = 0;

            for n = 1:N
                fb = 0;
                if n - M > 0
                    fb = y(n-M);
                end
                lpState = (1-a)*fb + a*lpState;
                y(n) = x(n) + g * lpState;
            end
        end

        function alpha = iso9613_alpha_db_per_m(fHz, tempC, relHum, pressurekPa)
            %ISO9613_ALPHA_DB_PER_M  Attenuazione atmosferica (ISO 9613-1) in dB/m.
            %
            % Implementazione delle equazioni standard (forma “engineering”).
            % Scopo: produrre una curva alpha(f) fisicamente sensata (HF assorbite di più).
            %
            % fHz può essere vettore.
            fHz = max(0, fHz(:));
            T = tempC + 273.15;         % K
            T0 = 293.15;                % 20°C
            p = pressurekPa;            % kPa
            p0 = 101.325;               % kPa
            h = relHum/100;

            % Saturation vapor pressure (approx) -> molar concentration of water vapor
            % (forma compatta comunemente usata per ISO 9613-1)
            C = -6.8346*(273.16./T).^1.261 + 4.6151;
            psat = p0 * 10.^C;          % kPa approx
            H = h * psat / p;           % molar fraction (approx)

            % Relaxation frequencies (oxygen, nitrogen)
            frO = (p/p0) * (24 + 4.04e4*H*(0.02+H)/(0.391+H));
            frN = (p/p0) * (T/T0)^(-0.5) * (9 + 280*H*exp(-4.17*((T/T0)^(-1/3)-1)));

            % Classical + relaxation absorption (Nepers/m -> dB/m)
            % alpha = 8.686 * f^2 * [ 1.84e-11*(p0/p)*sqrt(T/T0) + (T/T0)^(-2.5) * (...) ]
            f2 = fHz.^2;
            termClass = 1.84e-11 * (p0/p) * sqrt(T/T0);
            termO = 0.01275 * exp(-2239.1/T) ./ (frO + (fHz.^2)./frO);
            termN = 0.1068  * exp(-3352.0/T) ./ (frN + (fHz.^2)./frN);
            termRelax = (T/T0)^(-2.5) * (termO + termN);

            alpha = 8.686 * f2 .* (termClass + termRelax); % dB/m
        end

        function x = trim_silence(x, threshDB)
            x = x(:);
            if isempty(x), return; end
            thr = 10^(threshDB/20);
            a = abs(x);
            idx = find(a > thr);
            if isempty(idx)
                x = zeros(1,1);
            else
                x = x(idx(1):idx(end));
            end
        end

    end
end