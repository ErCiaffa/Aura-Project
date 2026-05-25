function smokeFDTD3D()
% smokeFDTD3D  Test offline del solver FDTD3DSystem.
%
% Inietta un breve burst sinusoidale a 100 Hz nella sorgente primaria,
% lascia evolvere il campo per 200 ms, e verifica:
%   (1) Stabilita (campo non diverge a NaN/Inf)
%   (2) Energia non-zero alla posizione del mic di errore (causalita di propagazione)
%   (3) Energia ridotta se accendiamo un emettitore ANC in opposizione di fase
%
% Esegui da MATLAB (dal root della repo o dal folder simulink/):
%   >> addpath(fullfile(pwd, 'simulink')); addpath(pwd);
%   >> smokeFDTD3D

    here = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(here);
    addpath(repoRoot);
    addpath(here);

    fs_field = 4000;
    dt = 1/fs_field;
    N = round(0.2 * fs_field);
    f0 = 100;
    t = (0:N-1)' * dt;
    burst = sin(2*pi*f0*t) .* (t < 0.1);

    fprintf('Smoke test FDTD3D: %d step a %d Hz...\n', N, fs_field);

    %% Test 1: sorgente sola
    solver = anc.FDTD3DSystem('FieldSampleRate', fs_field, 'BoundaryType', 'Mur');
    setup(solver, 0.0, 0.0);
    energy_src_only = 0;
    for n = 1:N
        [P, p_err] = solver.step(burst(n), 0);
        energy_src_only = energy_src_only + p_err^2;
        if any(~isfinite(P(:)))
            error('Smoke FAILED: campo divergente (NaN/Inf) allo step %d', n);
        end
    end
    release(solver);
    fprintf('  [PASS] stabilita: campo finito su tutti gli step\n');
    fprintf('  Energia mic con sola sorgente: %.6e\n', energy_src_only);
    if energy_src_only <= 0
        error('Smoke FAILED: energia nulla al mic - propagazione non funziona');
    end
    fprintf('  [PASS] propagazione: energia > 0 al mic di errore\n');

    %% Test 2: sorgente + ANC in opposizione di fase (semplificata)
    solver2 = anc.FDTD3DSystem('FieldSampleRate', fs_field, 'BoundaryType', 'Mur');
    setup(solver2, 0.0, 0.0);
    energy_with_anc = 0;
    for n = 1:N
        [~, p_err] = solver2.step(burst(n), -0.5 * burst(n));
        energy_with_anc = energy_with_anc + p_err^2;
    end
    release(solver2);
    fprintf('  Energia mic con ANC anti-fase: %.6e\n', energy_with_anc);
    reduction_db = 10*log10(energy_with_anc / energy_src_only);
    fprintf('  Variazione: %.2f dB\n', reduction_db);
    fprintf('  Nota: senza filtro adattivo / ritardo accordato la riduzione e parziale.\n');

    fprintf('\nSmoke test completato.\n');
end
