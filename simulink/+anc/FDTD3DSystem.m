classdef FDTD3DSystem < matlab.System
    % FDTD3DSystem  Solver FDTD 3D in pressione per il visualizer del campo.
    %
    % Risolve l'equazione delle onde scalare in pressione:
    %   p[n+1] = 2 p[n] - p[n-1] + (c*dt/dx)^2 * Laplaciano(p[n])
    %
    % Sorgenti acustiche iniettate come termine soft (additivo) alle celle
    % delle rispettive posizioni: sorgente primaria + emettitore ANC.
    %
    % Stabilita di Courant 3D:  c * dt / dx <= 1/sqrt(3)
    % Default: dx = 0.2 m, fs_field = 4000 Hz -> Courant ~= 0.43 (stabile).
    %
    % Bordi: assorbenti di primo ordine (Mur) oppure riflettenti rigidi.
    %
    % Porte:
    %   in1: x_src  (campione sorgente primaria)
    %   in2: y_anc  (campione emettitore ANC)
    % Uscite:
    %   P     : tensore di pressione [Nx x Ny x Nz]
    %   p_err : pressione campionata alla posizione del mic di errore

    properties (Nontunable)
        RoomSize = [6 6 3]
        Dx = 0.2
        FieldSampleRate = 4000
        SoundSpeed = 343

        SourcePos   = [1.0 3.0 1.5]
        AncPos      = [4.0 3.0 1.5]
        ErrorMicPos = [5.0 3.0 1.5]

        BoundaryType = 'Mur'
        SourceGain = 1.0
        AncGain    = 1.0
    end

    properties (Hidden, Constant)
        BoundaryTypeSet = matlab.system.StringSet({'Mur','Rigid'})
    end

    properties (Access = private)
        Nx
        Ny
        Nz
        CourantSq
        MurCoeff
        Pcur
        Pprev
        SrcIdx
        AncIdx
        ErrIdx
    end

    methods (Access = protected)
        function setupImpl(obj)
            obj.Nx = max(3, round(obj.RoomSize(1) / obj.Dx));
            obj.Ny = max(3, round(obj.RoomSize(2) / obj.Dx));
            obj.Nz = max(3, round(obj.RoomSize(3) / obj.Dx));

            dt = 1 / obj.FieldSampleRate;
            courant = obj.SoundSpeed * dt / obj.Dx;
            if courant > 1/sqrt(3)
                error('FDTD3DSystem:Unstable', ...
                    ['Numero di Courant %.3f > 1/sqrt(3) = %.3f. ' ...
                     'Aumenta FieldSampleRate o Dx.'], courant, 1/sqrt(3));
            end
            obj.CourantSq = courant^2;
            obj.MurCoeff = (obj.SoundSpeed*dt - obj.Dx) / (obj.SoundSpeed*dt + obj.Dx);

            obj.Pcur  = zeros(obj.Nx, obj.Ny, obj.Nz);
            obj.Pprev = zeros(obj.Nx, obj.Ny, obj.Nz);

            obj.SrcIdx = obj.posToIdx(obj.SourcePos);
            obj.AncIdx = obj.posToIdx(obj.AncPos);
            obj.ErrIdx = obj.posToIdx(obj.ErrorMicPos);
        end

        function [P, p_err] = stepImpl(obj, x_src, y_anc)
            p = obj.Pcur;
            pp = obj.Pprev;

            lap = zeros(size(p));
            lap(2:end-1, 2:end-1, 2:end-1) = ...
                  p(3:end,   2:end-1, 2:end-1) ...
                + p(1:end-2, 2:end-1, 2:end-1) ...
                + p(2:end-1, 3:end,   2:end-1) ...
                + p(2:end-1, 1:end-2, 2:end-1) ...
                + p(2:end-1, 2:end-1, 3:end  ) ...
                + p(2:end-1, 2:end-1, 1:end-2) ...
                - 6 * p(2:end-1, 2:end-1, 2:end-1);

            pnext = 2*p - pp + obj.CourantSq * lap;

            pnext(obj.SrcIdx(1), obj.SrcIdx(2), obj.SrcIdx(3)) = ...
                pnext(obj.SrcIdx(1), obj.SrcIdx(2), obj.SrcIdx(3)) + obj.SourceGain * x_src;
            pnext(obj.AncIdx(1), obj.AncIdx(2), obj.AncIdx(3)) = ...
                pnext(obj.AncIdx(1), obj.AncIdx(2), obj.AncIdx(3)) + obj.AncGain * y_anc;

            if strcmp(obj.BoundaryType, 'Mur')
                m = obj.MurCoeff;
                pnext(1,:,:)   = p(2,:,:)     + m*(pnext(2,:,:)     - p(1,:,:));
                pnext(end,:,:) = p(end-1,:,:) + m*(pnext(end-1,:,:) - p(end,:,:));
                pnext(:,1,:)   = p(:,2,:)     + m*(pnext(:,2,:)     - p(:,1,:));
                pnext(:,end,:) = p(:,end-1,:) + m*(pnext(:,end-1,:) - p(:,end,:));
                pnext(:,:,1)   = p(:,:,2)     + m*(pnext(:,:,2)     - p(:,:,1));
                pnext(:,:,end) = p(:,:,end-1) + m*(pnext(:,:,end-1) - p(:,:,end));
            else
                pnext(1,:,:)   = 0; pnext(end,:,:) = 0;
                pnext(:,1,:)   = 0; pnext(:,end,:) = 0;
                pnext(:,:,1)   = 0; pnext(:,:,end) = 0;
            end

            obj.Pprev = p;
            obj.Pcur  = pnext;

            P = pnext;
            p_err = pnext(obj.ErrIdx(1), obj.ErrIdx(2), obj.ErrIdx(3));
        end

        function resetImpl(obj)
            obj.Pcur  = zeros(obj.Nx, obj.Ny, obj.Nz);
            obj.Pprev = zeros(obj.Nx, obj.Ny, obj.Nz);
        end

        function num = getNumInputsImpl(~)
            num = 2;
        end

        function num = getNumOutputsImpl(~)
            num = 2;
        end

        function [s1, s2] = getOutputSizeImpl(obj)
            nx = max(3, round(obj.RoomSize(1) / obj.Dx));
            ny = max(3, round(obj.RoomSize(2) / obj.Dx));
            nz = max(3, round(obj.RoomSize(3) / obj.Dx));
            s1 = [nx ny nz];
            s2 = [1 1];
        end

        function [d1, d2] = getOutputDataTypeImpl(~)
            d1 = 'double'; d2 = 'double';
        end

        function [c1, c2] = isOutputComplexImpl(~)
            c1 = false; c2 = false;
        end

        function [f1, f2] = isOutputFixedSizeImpl(~)
            f1 = true; f2 = true;
        end
    end

    methods (Access = private)
        function idx = posToIdx(obj, pos)
            i = round(pos(1) / obj.Dx) + 1;
            j = round(pos(2) / obj.Dx) + 1;
            k = round(pos(3) / obj.Dx) + 1;
            i = max(2, min(obj.Nx-1, i));
            j = max(2, min(obj.Ny-1, j));
            k = max(2, min(obj.Nz-1, k));
            idx = [i j k];
        end
    end
end
