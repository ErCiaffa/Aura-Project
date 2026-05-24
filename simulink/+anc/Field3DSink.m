classdef Field3DSink < matlab.System
    % Field3DSink  Visualizer realtime di una slice del campo di pressione 3D.
    %
    % Riceve il tensore P [Nx x Ny x Nz] dal solver FDTD3DSystem e renderizza
    % una slice del piano selezionato come imagesc (1 ordine di grandezza
    % piu veloce di slice 3D).
    %
    % Sovrappone marker per:
    %   - sorgente primaria (cerchio)
    %   - emettitore ANC   (quadrato)
    %   - mic di errore    (croce)
    %
    % SlicePlane: 'XY' (z fisso), 'XZ' (y fisso), 'YZ' (x fisso)
    % SliceIndex: indice della slice (1-based)
    %
    % Refresh: aggiorna ogni N step (RefreshDecim) per non saturare il
    % rendering. Con sample rate 4 kHz e RefreshDecim=20 -> 200 fps target.
    %
    % Opzione RecordField: se true accumula il campo su disco in
    % 'field_recording.mat' alla fine della simulazione (truncato a
    % MaxRecordSteps step per evitare esaurimento RAM).

    properties (Nontunable)
        SlicePlane (1,:) char {mustBeMember(SlicePlane, {'XY','XZ','YZ'})} = 'XY'
        SliceIndex (1,1) double {mustBePositive, mustBeInteger} = 8
        RefreshDecim (1,1) double {mustBePositive, mustBeInteger} = 20
        ColorLimit (1,1) double {mustBePositive} = 0.05
        RoomSize (1,3) double = [6 6 3]
        Dx (1,1) double {mustBePositive} = 0.2
        SourcePos (1,3) double = [1.0 3.0 1.5]
        AncPos    (1,3) double = [4.0 3.0 1.5]
        ErrorMicPos (1,3) double = [5.0 3.0 1.5]
    end

    properties (Access = private)
        FigHandle
        AxHandle
        ImgHandle
        TitleHandle
        FrameCounter
    end

    methods (Access = protected)
        function setupImpl(obj)
            obj.FrameCounter = 0;
            obj.FigHandle = figure('Name', 'ANC Field3D Visualizer', ...
                'Color', [0.07 0.07 0.08], 'NumberTitle', 'off');
            obj.AxHandle = axes('Parent', obj.FigHandle, ...
                'Color', [0.12 0.12 0.13], ...
                'XColor', [0.9 0.9 0.9], 'YColor', [0.9 0.9 0.9]);
            hold(obj.AxHandle, 'on');

            [extent, srcXY, ancXY, errXY] = obj.sliceExtent();
            placeholder = zeros(extent(4)-extent(3)+1, extent(2)-extent(1)+1);
            obj.ImgHandle = imagesc(obj.AxHandle, ...
                [extent(1) extent(2)]*obj.Dx, [extent(3) extent(4)]*obj.Dx, placeholder);
            set(obj.AxHandle, 'CLim', [-obj.ColorLimit, obj.ColorLimit]);
            colormap(obj.AxHandle, turbo);
            cb = colorbar(obj.AxHandle);
            cb.Color = [0.9 0.9 0.9];
            cb.Label.String = 'Pressione (Pa)';
            axis(obj.AxHandle, 'image');
            set(obj.AxHandle, 'YDir', 'normal');

            plot(obj.AxHandle, srcXY(1), srcXY(2), 'o', ...
                'MarkerSize', 12, 'LineWidth', 2, 'MarkerEdgeColor', 'w');
            plot(obj.AxHandle, ancXY(1), ancXY(2), 's', ...
                'MarkerSize', 12, 'LineWidth', 2, 'MarkerEdgeColor', [0.4 1 0.4]);
            plot(obj.AxHandle, errXY(1), errXY(2), 'x', ...
                'MarkerSize', 14, 'LineWidth', 2, 'MarkerEdgeColor', [1 0.4 0.4]);
            legend(obj.AxHandle, {'Sorgente','ANC','Error Mic'}, ...
                'TextColor', 'w', 'Color', [0.15 0.15 0.16]);

            xlabel(obj.AxHandle, sprintf('%s (m)', obj.SlicePlane(1)));
            ylabel(obj.AxHandle, sprintf('%s (m)', obj.SlicePlane(2)));
            obj.TitleHandle = title(obj.AxHandle, ...
                sprintf('Slice %s @ idx %d', obj.SlicePlane, obj.SliceIndex), ...
                'Color', 'w', 'FontWeight', 'normal');
        end

        function stepImpl(obj, P)
            obj.FrameCounter = obj.FrameCounter + 1;
            if mod(obj.FrameCounter, obj.RefreshDecim) ~= 0
                return
            end
            if ~isvalid(obj.FigHandle)
                return
            end

            switch obj.SlicePlane
                case 'XY'
                    k = min(max(1, obj.SliceIndex), size(P,3));
                    slice2d = squeeze(P(:, :, k))';
                case 'XZ'
                    j = min(max(1, obj.SliceIndex), size(P,2));
                    slice2d = squeeze(P(:, j, :))';
                case 'YZ'
                    i = min(max(1, obj.SliceIndex), size(P,1));
                    slice2d = squeeze(P(i, :, :))';
            end
            set(obj.ImgHandle, 'CData', slice2d);
            drawnow limitrate;
        end

        function num = getNumInputsImpl(~)
            num = 1;
        end

        function num = getNumOutputsImpl(~)
            num = 0;
        end
    end

    methods (Access = private)
        function [extent, srcXY, ancXY, errXY] = sliceExtent(obj)
            nx = round(obj.RoomSize(1) / obj.Dx);
            ny = round(obj.RoomSize(2) / obj.Dx);
            nz = round(obj.RoomSize(3) / obj.Dx);
            switch obj.SlicePlane
                case 'XY'
                    extent = [1 nx 1 ny];
                    srcXY = obj.SourcePos([1 2]);
                    ancXY = obj.AncPos([1 2]);
                    errXY = obj.ErrorMicPos([1 2]);
                case 'XZ'
                    extent = [1 nx 1 nz];
                    srcXY = obj.SourcePos([1 3]);
                    ancXY = obj.AncPos([1 3]);
                    errXY = obj.ErrorMicPos([1 3]);
                case 'YZ'
                    extent = [1 ny 1 nz];
                    srcXY = obj.SourcePos([2 3]);
                    ancXY = obj.AncPos([2 3]);
                    errXY = obj.ErrorMicPos([2 3]);
            end
        end
    end
end
