function debugMatlabSystem()
% debugMatlabSystem  Diagnostica progressiva per isolare il bug
% "No matching constructor found for superclass matlab.system.SystemInterface".
%
% Test in cascata dal piu semplice al piu complesso:
%   1. matlab.System minimal (file MinimalSystemTest.m)
%   2. anc.FxLMSSystem (no StringSet)
%   3. anc.FDTD3DSystem (con StringSet)
%
% Stampa versione MATLAB e i path da cui le classi vengono caricate.
% PRIMA DI ESEGUIRE: dal Command Window, esegui:
%   >> clear classes
%   >> rehash toolboxcache

    fprintf('=== DIAGNOSTICA matlab.System ===\n');
    fprintf('Versione MATLAB: %s\n', version);
    fprintf('CWD: %s\n', pwd);

    fprintf('\nFile risolti:\n');
    fprintf('  MinimalSystemTest: %s\n', which('MinimalSystemTest'));
    fprintf('  anc.FxLMSSystem  : %s\n', which('anc.FxLMSSystem'));
    fprintf('  anc.FDTD3DSystem : %s\n', which('anc.FDTD3DSystem'));
    fprintf('  matlab.System    : %s\n', which('matlab.System'));

    %% TEST 1: classe matlab.System ultra-minimale
    fprintf('\n[TEST 1] matlab.System minimale...\n');
    try
        m = MinimalSystemTest();
        out = m.step(2);
        fprintf('  PASS: minimal step(2) = %g (atteso 3)\n', out);
    catch ME
        fprintf('  FAIL: %s\n', ME.message);
        fprintf('  -> matlab.System non funziona nemmeno con una classe vuota.\n');
        fprintf('     Possibili cause: cache classi, toolbox mancante, versione MATLAB.\n');
        return
    end

    %% TEST 2: una classe del package +anc senza StringSet
    fprintf('\n[TEST 2] anc.FxLMSSystem (senza StringSet)...\n');
    try
        if exist('ANC_Calibration.mat', 'file')
            cal = load('ANC_Calibration.mat');
            s_est = cal.s_est;
        elseif exist('../ANC_Calibration.mat', 'file')
            cal = load('../ANC_Calibration.mat');
            s_est = cal.s_est;
        else
            s_est = zeros(256,1); s_est(20) = 1;
        end
        f = anc.FxLMSSystem('Lw', 64, 'SecondaryPath', s_est);
        [y, e] = f.step(0.1, 0.0); %#ok<ASGLU>
        fprintf('  PASS: FxLMSSystem istanziato e step ok (y=%.3e)\n', y);
    catch ME
        fprintf('  FAIL: %s\n', ME.message);
        fprintf('  Stack:\n');
        for k = 1:length(ME.stack)
            fprintf('    %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
        end
        return
    end

    %% TEST 3: classe con StringSet
    fprintf('\n[TEST 3] anc.FDTD3DSystem (con StringSet)...\n');
    try
        s = anc.FDTD3DSystem('FieldSampleRate', 4000);
        setup(s, 0, 0);
        fprintf('  PASS: FDTD3DSystem istanziato e setup ok\n');
        release(s);
    catch ME
        fprintf('  FAIL: %s\n', ME.message);
        fprintf('  Stack:\n');
        for k = 1:length(ME.stack)
            fprintf('    %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
        end
    end

    fprintf('\n=== FINE ===\n');
end
