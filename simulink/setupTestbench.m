function setupTestbench()
% setupTestbench  Prepara il workspace e apre AncTestbench.
%
% Operazioni:
%   1. Aggiunge la repo e simulink/ al path (cosi le classi anc.* sono visibili).
%   2. Carica ANC_Calibration.mat -> s_est, Fs nel base workspace.
%   3. Costruisce AncTestbench.slx se non esiste (via buildTestbench).
%   4. Apre il modello.
%
% Esegui:
%   >> cd /path/to/Aura-Project/simulink
%   >> setupTestbench

    here = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(here);
    addpath(repoRoot);
    addpath(here);

    calPath = fullfile(repoRoot, 'ANC_Calibration.mat');
    if ~exist(calPath, 'file')
        error('setupTestbench:NoCalibration', ...
            ['ANC_Calibration.mat non trovato in %s. ' ...
             'Esegui prima OfflineSystemID.m per generarlo.'], repoRoot);
    end
    cal = load(calPath);
    assignin('base', 's_est', cal.s_est);
    assignin('base', 'Fs', cal.Fs);
    fprintf('Caricato s_est (length %d) e Fs = %d Hz nel base workspace.\n', ...
        length(cal.s_est), cal.Fs);

    modelName = 'AncTestbench';
    modelFile = fullfile(here, [modelName '.slx']);
    if ~exist(modelFile, 'file')
        fprintf('Modello non trovato, lo costruisco con buildTestbench...\n');
        oldDir = cd(here);
        cleaner = onCleanup(@() cd(oldDir)); %#ok<NASGU>
        buildTestbench(modelName);
    end

    open_system(modelFile);
    fprintf('Pronto. Premi Run su Simulink (StopTime preimpostato a 5s).\n');
end
