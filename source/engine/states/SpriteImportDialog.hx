package states;

#if mobile
import sys.io.File;
import sys.FileSystem;
import haxe.Json;
import haxe.io.Bytes;
#end

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;
import flixel.input.touch.FlxTouch;
import flixel.tweens.FlxEase;
import flixel.addons.display.FlxTypedGroup;
import flixel.util.FlxTimer;
import backend.Funkin;
import backend.Mods;
import openfl.display.BitmapData;

class SpriteImportDialog extends MusicBeatState
{
    // Datos del sprite a importar
    var sourceFile:String = "";
    var sourceData:Bytes = null;
    var originalFilename:String = "";
    
    // UI Elements
    var bgOverlay:FlxSprite;
    var dialogBox:FlxSprite;
    var titleText:FlxText;
    var previewImage:FlxSprite;
    var nameField:FlxText;
    var nameInput:String = "";
    var folderButtons:FlxTypedGroup<FlxSprite>;
    var folderLabels:FlxTypedGroup<FlxText>;
    var selectedFolderIndex:Int = 0;
    
    // Carpetas disponibles
    var availableFolders:Array<String> = [];
    
    // Colores Cyberpunk
    static inline var COLOR_BG:Int = 0xFF0D0D1A;
    static inline var COLOR_PANEL:Int = 0xFF1A1A2E;
    static inline var COLOR_PANEL_LIGHT:Int = 0xFF252542;
    static inline var COLOR_ACCENT:Int = 0xFFFF2D6A;
    static inline var COLOR_ACCENT2:Int = 0xFF00F5FF;
    static inline var COLOR_TEXT:Int = 0xFFFFFFFF;
    static inline var COLOR_TEXT_DIM:Int = 0xFFB0B0C0;
    static inline var COLOR_WARNING:Int = 0xFFFFAA00;
    static inline var COLOR_SUCCESS:Int = 0xFF00FF88;
    
    // Extensiones válidas para sprites
    static inline var VALID_EXTENSIONS:Array<String> = [".png", ".gif", ".jpg", ".jpeg", ".bmp", ".webp"];
    
    // Estado de validación
    var fileExists:Bool = false;
    var isValidName:Bool = true;
    var cursorVisible:Bool = true;
    var cursorTimer:Float = 0;
    var suggestedName:String = "";
    var statusText:FlxText = null;
    
    // Datos pendientes de importación
    public static var pendingImport:PendingImportData = null;
    
    public function new()
    {
        super();
    }
    
    override function create()
    {
        #if mobile
        Paths.clearStoredMemory();
        
        // Obtener datos del pending import
        if (pendingImport != null) {
            sourceFile = pendingImport.path;
            sourceData = pendingImport.data;
            var parts = sourceFile.split("/");
            originalFilename = parts[parts.length - 1];
        } else {
            // Volver si no hay datos
            Funkin.switchState(MobileWebViewState);
            return;
        }
        
        createBackground();
        createDialogBox();
        createTitle();
        createPreview();
        createNameInput();
        createFolderSelector();
        createActionButtons();
        createInfoPanel();
        
        super.create();
        
        playEntryAnimation();
        #else
        Funkin.switchState(MobileWebViewState);
        #end
    }
    
    function createBackground():Void
    {
        bgOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bgOverlay.alpha = 0.85;
        add(bgOverlay);
    }
    
    function createDialogBox():Void
    {
        var boxW:Int = FlxG.width - 40;
        var boxH:Int = FlxG.height - 80;
        var boxX:Float = 20;
        var boxY:Float = 40;
        
        dialogBox = new FlxSprite(boxX, boxY).makeGraphic(boxW, boxH, COLOR_PANEL);
        add(dialogBox);
        
        // Borde superior
        var borderTop = new FlxSprite(boxX, boxY).makeGraphic(boxW, 4, COLOR_ACCENT);
        add(borderTop);
        
        // Borde inferior
        var borderBottom = new FlxSprite(boxX, boxY + boxH - 4).makeGraphic(boxW, 4, COLOR_ACCENT2);
        add(borderBottom);
        
        // Esquinas decorativas
        var cornerSize:Int = 20;
        var corners:Array<Array<Int>> = [
            [cast boxX, cast boxY],
            [cast (boxX + boxW - cornerSize), cast boxY],
            [cast boxX, cast (boxY + boxH - cornerSize)],
            [cast (boxX + boxW - cornerSize), cast (boxY + boxH - cornerSize)]
        ];
        
        for (corner in corners) {
            var cornerSprite = new FlxSprite(corner[0], corner[1]).makeGraphic(cornerSize, cornerSize, COLOR_ACCENT);
            cornerSprite.alpha = 0.5;
            add(cornerSprite);
        }
    }
    
    function createTitle():Void
    {
        titleText = new FlxText(40, 50, FlxG.width - 80, "📥 IMPORTAR SPRITE", 22);
        titleText.setFormat("VCR OSD Mono", 22, COLOR_ACCENT, CENTER);
        add(titleText);
        
        var subtitle = new FlxText(40, 78, FlxG.width - 80, "Personaliza el nombre y destino", 12);
        subtitle.setFormat("VCR OSD Mono", 12, COLOR_TEXT_DIM, CENTER);
        add(subtitle);
    }
    
    function createPreview():Void
    {
        var previewX:Float = 45;
        var previewY:Float = 110;
        var previewW:Int = 160;
        var previewH:Int = 160;
        
        // Fondo del preview
        var previewBg = new FlxSprite(previewX, previewY).makeGraphic(previewW, previewH, COLOR_PANEL_LIGHT);
        add(previewBg);
        
        // Borde decorativo
        var previewBorder = new FlxSprite(previewX, previewY).makeGraphic(previewW, 3, COLOR_ACCENT2);
        add(previewBorder);
        var previewBorder2 = new FlxSprite(previewX, previewY + previewH - 3).makeGraphic(previewW, 3, COLOR_ACCENT2);
        add(previewBorder2);
        
        // Placeholder
        var placeholder = new FlxText(previewX, previewY + 50, previewW, "📷\nPreview\nNo disponible", 14);
        placeholder.setFormat("VCR OSD Mono", 14, COLOR_TEXT_DIM, CENTER);
        add(placeholder);
        
        // Intentar cargar la imagen
        loadImagePreview(previewX + 5, previewY + 5, previewW - 10, previewH - 10);
    }
    
    function loadImagePreview(x:Float, y:Float, w:Int, h:Int):Void
    {
        #if mobile
        try {
            if (sourceData != null && sourceData.length > 0) {
                var bitmapData = BitmapData.fromBytes(sourceData);
                if (bitmapData != null) {
                    var loadedGraphic = FlxGraphic.fromBitmapData(bitmapData, false, null);
                    
                    previewImage = new FlxSprite(x, y);
                    previewImage.loadGraphic(loadedGraphic);
                    
                    var scaleX:Float = w / previewImage.width;
                    var scaleY:Float = h / previewImage.height;
                    var scale:Float = Math.min(scaleX, scaleY);
                    
                    if (scale > 1) scale = 1;
                    
                    previewImage.scale.set(scale, scale);
                    previewImage.updateHitbox();
                    previewImage.x = x + (w - previewImage.width) / 2;
                    previewImage.y = y + (h - previewImage.height) / 2;
                    previewImage.antialiasing = true;
                    
                    add(previewImage);
                }
            }
        } catch(e:Dynamic) {
            trace('Error cargando preview: $e');
        }
        #end
    }
    
    function createNameInput():Void
    {
        var inputX:Float = 230;
        var inputY:Float = 110;
        var inputW:Int = FlxG.width - 290;
        var inputH:Int = 50;
        
        // Label
        var nameLabel = new FlxText(inputX, inputY - 25, 200, "Nombre del archivo:", 14);
        nameLabel.setFormat("VCR OSD Mono", 14, COLOR_ACCENT2);
        add(nameLabel);
        
        // Generar nombre sugerido
        suggestedName = generateValidFilename(originalFilename);
        nameInput = suggestedName;
        
        // Campo visual de nombre
        nameField = new FlxText(inputX, inputY, inputW, nameInput + "_", inputH);
        nameField.setFormat("VCR OSD Mono", 18, COLOR_TEXT, LEFT, FlxTextBorderStyle.OUTLINE, COLOR_PANEL_LIGHT);
        nameField.backgroundColor = COLOR_PANEL_LIGHT;
        add(nameField);
        
        // Instrucciones
        var hint = new FlxText(inputX, inputY + inputH + 10, inputW, "Usa teclado para escribir • Enter para guardar", 11);
        hint.setFormat("VCR OSD Mono", 11, COLOR_TEXT_DIM);
        add(hint);
        
        // Indicador de validación
        updateValidationStatus();
    }
    
    function updateValidationStatus():Void
    {
        // Validar nombre
        isValidName = validateFilename(nameInput);
        
        // Verificar si existe
        var fullPath = getFullDestinationPath();
        #if mobile
        fileExists = FileSystem.exists(fullPath);
        #end
        
        // Crear o actualizar texto de estado
        if (statusText != null) {
            remove(statusText);
        }
        
        statusText = new FlxText(230, 185, 350, "", 12);
        statusText.setFormat("VCR OSD Mono", 12, COLOR_SUCCESS);
        
        if (!isValidName) {
            var extError = getExtensionError(nameInput);
            if (extError.length > 0) {
                statusText.text = "✗ " + extError;
            } else {
                statusText.text = "✗ Caracteres no válidos (evita: / \\ : * ? \" < > |)";
            }
            statusText.color = COLOR_WARNING;
        } else if (fileExists) {
            statusText.text = "⚠ Ya existe - se sobrescribirá";
            statusText.color = COLOR_WARNING;
        } else {
            statusText.text = "✓ Listo para guardar";
            statusText.color = COLOR_SUCCESS;
        }
        add(statusText);
    }
    
    function validateFilename(name:String):Bool
    {
        if (name == null || name.length == 0) return false;
        if (name.indexOf("/") != -1) return false;
        if (name.indexOf("\\") != -1) return false;
        if (name.indexOf(":") != -1) return false;
        if (name.indexOf("*") != -1) return false;
        if (name.indexOf("?") != -1) return false;
        if (name.indexOf("\"") != -1) return false;
        if (name.indexOf("<") != -1) return false;
        if (name.indexOf(">") != -1) return false;
        if (name.indexOf("|") != -1) return false;
        
        // Validar extensión de imagen
        var ext = "";
        if (name.indexOf(".") > 0) {
            ext = name.substring(name.lastIndexOf(".")).toLowerCase();
        }
        if (ext.length > 0 && !VALID_EXTENSIONS.contains(ext)) {
            return false;
        }
        
        return true;
    }
    
    function getExtensionError(name:String):String
    {
        if (name.indexOf(".") > 0) {
            var ext = name.substring(name.lastIndexOf(".")).toLowerCase();
            if (!VALID_EXTENSIONS.contains(ext)) {
                return "Extensión '$ext' no válida. Usa: .png, .jpg, .gif, .bmp";
            }
        }
        return "";
    }
    
    function generateValidFilename(original:String):String
    {
        var name = original;
        if (name.indexOf(".") > 0) {
            name = name.substring(0, name.lastIndexOf("."));
        }
        
        name = StringTools.replace(name, " ", "_");
        name = StringTools.replace(name, "-", "_");
        name = StringTools.replace(name, "'", "");
        name = StringTools.replace(name, "\"", "");
        
        return name;
    }
    
    function createFolderSelector():Void
    {
        var folderX:Float = 230;
        var folderY:Float = 210;
        
        // Label
        var folderLabel = new FlxText(folderX, folderY, 200, "Carpeta de destino:", 14);
        folderLabel.setFormat("VCR OSD Mono", 14, COLOR_ACCENT2);
        add(folderLabel);
        
        // Obtener carpetas disponibles
        availableFolders = getAvailableFolders();
        
        // Botones de carpeta
        folderButtons = new FlxTypedGroup<FlxSprite>();
        folderLabels = new FlxTypedGroup<FlxText>();
        var btnY = folderY + 30;
        
        for (i in 0...availableFolders.length) {
            var folder = availableFolders[i];
            var isSelected = (i == selectedFolderIndex);
            
            var btn = new FlxSprite(folderX, btnY + (i * 40));
            btn.makeGraphic(FlxG.width - 290, 35, isSelected ? COLOR_ACCENT : COLOR_PANEL_LIGHT);
            btn.ID = i;
            folderButtons.add(btn);
            
            var label = new FlxText(folderX + 10, btnY + 10 + (i * 40), 300, 
                (isSelected ? "▶ " : "  ") + folder, 14);
            label.setFormat("VCR OSD Mono", 14, 
                isSelected ? COLOR_BG : COLOR_TEXT);
            folderLabels.add(label);
        }
        add(folderButtons);
        add(folderLabels);
    }
    
    function getAvailableFolders():Array<String>
    {
        var folders:Array<String> = [
            "characters/",
            "images/",
            "images/characters/",
            "images/ui/"
        ];
        
        #if mobile
        var modDir:String = Mods.currentModDirectory;
        
        // Agregar carpetas del mod
        var modFolders:Array<String> = [
            "mods/" + modDir + "/images/characters/",
            "mods/" + modDir + "/images/"
        ];
        
        for (folder in modFolders) {
            try {
                var basePath = folder.substring(0, folder.lastIndexOf("/"));
                if (!folders.contains(folder) && (FileSystem.exists(folder) || FileSystem.exists(basePath))) {
                    folders.insert(0, folder);
                }
            } catch(e:Dynamic) {}
        }
        #end
        
        return folders;
    }
    
    function getFullDestinationPath():String
    {
        #if mobile
        var folder = availableFolders[selectedFolderIndex];
        var ext = "";
        if (originalFilename.indexOf(".") > 0) {
            ext = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        
        var finalName = nameInput;
        if (finalName.indexOf(".") < 0) {
            finalName = finalName + ext;
        }
        
        return folder + finalName;
        #else
        return "";
        #end
    }
    
    function createActionButtons():Void
    {
        var btnY:Float = FlxG.height - 120;
        var btnW:Int = 140;
        var btnH:Int = 45;
        var btnSpacing:Int = 15;
        
        // Botón cancelar
        var cancelBg = new FlxSprite(50, btnY).makeGraphic(btnW, btnH, COLOR_PANEL_LIGHT);
        add(cancelBg);
        
        var cancelText = new FlxText(50, btnY + 15, btnW, "Cancelar", 16);
        cancelText.setFormat("VCR OSD Mono", 16, COLOR_TEXT, CENTER);
        cancelText.ID = 1;
        add(cancelText);
        
        // Botón renombrar
        var renameBg = new FlxSprite(50 + btnW + btnSpacing, btnY).makeGraphic(btnW, btnH, COLOR_PANEL_LIGHT);
        add(renameBg);
        
        var renameText = new FlxText(50 + btnW + btnSpacing, btnY + 15, btnW, "Renombrar +", 16);
        renameText.setFormat("VCR OSD Mono", 16, COLOR_ACCENT2, CENTER);
        renameText.ID = 2;
        add(renameText);
        
        // Botón guardar
        var saveBg = new FlxSprite(FlxG.width - 50 - btnW, btnY).makeGraphic(btnW, btnH, COLOR_ACCENT);
        add(saveBg);
        
        var saveText = new FlxText(FlxG.width - 50 - btnW, btnY + 15, btnW, "Guardar ✓", 16);
        saveText.setFormat("VCR OSD Mono", 16, COLOR_BG, CENTER);
        saveText.ID = 3;
        add(saveText);
    }
    
    function createInfoPanel():Void
    {
        var infoY:Float = 380;
        
        var infoBg = new FlxSprite(230, infoY).makeGraphic(FlxG.width - 290, 60, COLOR_PANEL_LIGHT);
        add(infoBg);
        
        var infoText = new FlxText(240, infoY + 10, FlxG.width - 300, 
            "📁 Origen: " + originalFilename + "\n" +
            "📍 Destino: " + availableFolders[selectedFolderIndex] + nameInput, 12);
        infoText.setFormat("VCR OSD Mono", 12, COLOR_TEXT_DIM);
        add(infoText);
    }
    
    function onButtonClick(btnId:Int):Void
    {
        switch(btnId) {
            case 1: // Cancelar
                Funkin.switchState(MobileWebViewState);
            case 2: // Renombrar
                autoRename();
            case 3: // Guardar
                onSave();
        }
    }
    
    function autoRename():Void
    {
        var baseName = nameInput;
        if (baseName.indexOf(".") > 0) {
            baseName = baseName.substring(0, baseName.indexOf("."));
        }
        
        var timestamp = Date.now().getTime();
        nameInput = baseName + "_" + timestamp;
        
        updateNameField();
        updateValidationStatus();
    }
    
    function updateNameField():Void
    {
        if (nameField != null) {
            nameField.text = nameInput + (cursorVisible ? "_" : " ");
        }
    }
    
    function onSave():Void
    {
        if (!isValidName) {
            showNotification("Nombre no válido", COLOR_WARNING);
            return;
        }
        
        #if mobile
        var destPath = getFullDestinationPath();
        
        try {
            // Crear carpeta si no existe
            var folderPath = destPath.substring(0, destPath.lastIndexOf("/"));
            if (!FileSystem.exists(folderPath)) {
                FileSystem.createDirectory(folderPath);
            }
            
            // Guardar archivo
            File.saveBytes(destPath, sourceData);
            
            // Registrar en historial
            registerImport({
                filename: nameInput,
                path: destPath,
                originalName: originalFilename,
                folder: availableFolders[selectedFolderIndex],
                timestamp: Date.now().toString(),
                size: sourceData.length
            });
            
            // Limpiar pending import
            pendingImport = null;
            
            showNotification("✓ Guardado: " + nameInput, COLOR_SUCCESS);
            
            // Volver al WebView
            FlxTimer.globalTimer.add(1.5, function(tmr:FlxTimer) {
                Funkin.switchState(MobileWebViewState);
            });
            
        } catch(e:Dynamic) {
            showNotification("Error: " + Std.string(e), COLOR_WARNING);
        }
        #end
    }
    
    function registerImport(data:ImportRecord):Void
    {
        #if mobile
        var historyFile = "downloads/import_history.json";
        var history:Array<ImportRecord> = [];
        
        try {
            if (FileSystem.exists(historyFile)) {
                history = Json.parse(File.getContent(historyFile));
            }
        } catch(e:Dynamic) {}
        
        history.insert(0, data);
        
        if (history.length > 50) {
            history = history.slice(0, 50);
        }
        
        File.saveContent(historyFile, Json.stringify(history));
        #end
    }
    
    function showNotification(msg:String, color:Int):Void
    {
        var notif = new FlxText(0, FlxG.height - 50, FlxG.width, msg, 16);
        notif.setFormat("VCR OSD Mono", 16, color, CENTER);
        notif.alpha = 0;
        add(notif);
        
        FlxTween.tween(notif, {alpha: 1}, 0.2);
        FlxTimer.globalTimer.add(2, function(tmr:FlxTimer) {
            FlxTween.tween(notif, {alpha: 0}, 0.3, {
                onComplete: function(_) { remove(notif); }
            });
        });
    }
    
    function playEntryAnimation():Void
    {
        dialogBox.alpha = 0;
        dialogBox.y = FlxG.height;
        
        FlxTween.tween(dialogBox, {alpha: 1, y: 40}, 0.4, {ease: FlxEase.quartOut});
        FlxTween.tween(bgOverlay, {alpha: 0.85}, 0.3);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        // Cursor parpadeante
        cursorTimer += elapsed;
        if (cursorTimer > 0.5) {
            cursorTimer = 0;
            cursorVisible = !cursorVisible;
            updateNameField();
        }
        
        // Detectar clicks en botones
        if (FlxG.mouse.justPressed) {
            handlePointerClick(FlxG.mouse.x, FlxG.mouse.y);
        }
        
        // Soporte táctil
        #if mobile
        for (touch in FlxG.touches.list) {
            if (touch.justPressed) {
                handlePointerClick(touch.x, touch.y);
            }
        }
        #end
        
        // Teclado para nombre
        handleKeyboardInput();
        
        // Enter para guardar
        if (FlxG.keys.justPressed.ENTER && isValidName) {
            onSave();
        }
        
        // Escape para cancelar
        if (FlxG.keys.justPressed.ESCAPE) {
            onButtonClick(1);
        }
    }
    
    function handlePointerClick(x:Float, y:Float):Void
    {
        var btnY:Float = FlxG.height - 120;
        
        // Botón cancelar
        if (x >= 50 && x <= 190 && y >= btnY && y <= btnY + 45) {
            onButtonClick(1);
            return;
        }
        
        // Botón renombrar
        if (x >= 205 && x <= 345 && y >= btnY && y <= btnY + 45) {
            onButtonClick(2);
            return;
        }
        
        // Botón guardar
        if (x >= FlxG.width - 190 && x <= FlxG.width - 50 && y >= btnY && y <= btnY + 45) {
            onButtonClick(3);
            return;
        }
        
        // Carpetas
        for (i in 0...availableFolders.length) {
            var folderY = 240 + (i * 40);
            if (x >= 230 && x <= FlxG.width - 70 && y >= folderY && y <= folderY + 35) {
                selectedFolderIndex = i;
                updateFolderSelection();
                updateValidationStatus();
                return;
            }
        }
    }
    
    function updateFolderSelection():Void
    {
        var btnY = 240;
        for (i in 0...folderButtons.length) {
            var btn = folderButtons.getByIndex(i);
            var label = folderLabels.getByIndex(i);
            
            var isSelected = (i == selectedFolderIndex);
            btn.color = isSelected ? COLOR_ACCENT : COLOR_PANEL_LIGHT;
            label.text = (isSelected ? "▶ " : "  ") + availableFolders[i];
            label.color = isSelected ? COLOR_BG : COLOR_TEXT;
        }
    }
    
    function handleKeyboardInput():Void
    {
        // BACKSPACE
        if (FlxG.keys.justPressed.BACKSPACE && nameInput.length > 0) {
            nameInput = nameInput.substring(0, nameInput.length - 1);
            updateNameField();
            updateValidationStatus();
        }

        // Teclas de letras A-Z
        var letterKeys:Array<String> = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
            "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];
        
        for (key in letterKeys) {
            if (FlxG.keys.justPressed.get(key) == JUST_PRESSED_SENTINEL || isKeyJustPressed(key)) {
                nameInput = nameInput + key.toLowerCase();
                updateNameField();
                updateValidationStatus();
                return;
            }
        }
        
        // Números
        if (FlxG.keys.justPressed.ONE) { nameInput += "1"; updateNameField(); updateValidationStatus(); return; }
        if (FlxG.keys.justPressed.TWO) { nameInput += "2"; updateNameField(); updateValidationStatus(); return; }
        if (FlxG.keys.justPressed.THREE) { nameInput += "3"; updateNameField(); updateValidationStatus(); return; }
        if (FlxG.keys.justPressed.FOUR) { nameInput += "4"; updateNameField(); updateValidationStatus(); return; }
        if (FlxG.keys.justPressed.FIVE) { nameInput += "5"; updateNameField(); updateValidationStatus(); return; }
        if (FlxG.keys.justPressed.SIX) { nameInput += "6"; updateNameField(); updateValidationStatus(); return; }
        if (FlxG.keys.justPressed.SEVEN) { nameInput += "7"; updateNameField(); updateValidationStatus(); return; }
        if (FlxG.keys.justPressed.EIGHT) { nameInput += "8"; updateNameField(); updateValidationStatus(); return; }
        if (FlxG.keys.justPressed.NINE) { nameInput += "9"; updateNameField(); updateValidationStatus(); return; }
        if (FlxG.keys.justPressed.ZERO) { nameInput += "0"; updateNameField(); updateValidationStatus(); return; }
        
        // Otros caracteres
        if (FlxG.keys.justPressed.MINUS) { nameInput += "-"; updateNameField(); updateValidationStatus(); return; }
        if (FlxG.keys.justPressed.PERIOD) { nameInput += "."; updateNameField(); updateValidationStatus(); return; }
        if (FlxG.keys.justPressed.SPACE) { nameInput += "_"; updateNameField(); updateValidationStatus(); return; }
    }
    
    // Helper para verificar teclas
    function isKeyJustPressed(key:String):Bool
    {
        return Reflect.field(FlxG.keys.justPressed, key) == true;
    }
    
    // Constante sentinel para comparar
    static inline var JUST_PRESSED_SENTINEL:Bool = true;
}

// ============== TIPOS DE DATOS ==============
typedef ImportRecord = {
    var filename:String;
    var path:String;
    var originalName:String;
    var folder:String;
    var timestamp:String;
    var size:Int;
}

typedef PendingImportData = {
    var path:String;
    var data:Bytes;
    var filename:String;
}