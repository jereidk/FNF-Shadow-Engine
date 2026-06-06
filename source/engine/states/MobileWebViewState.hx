package states;

#if mobile
import extension.webview.WebView;
#end

import flixel.addons.ui.FlxUIState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;
import flixel.addons.display.FlxTypedGroup;
import backend.Funkin;
import backend.CoolUtil;

class MobileWebViewState extends MusicBeatState
{
    // URL a cargar
    public static var targetURL:String = 'https://neeeoo.github.io/funkin-packer/';
    
    // Colores del tema (estilo Cyberpunk/Neon) - optimizado para móvil
    static inline var COLOR_BG:Int = 0xFF0D0D1A;
    static inline var COLOR_PANEL:Int = 0xFF1A1A2E;
    static inline var COLOR_PANEL_LIGHT:Int = 0xFF252542;
    static inline var COLOR_ACCENT:Int = 0xFFFF2D6A;
    static inline var COLOR_ACCENT2:Int = 0xFF00F5FF;
    static inline var COLOR_TEXT:Int = 0xFFFFFFFF;
    static inline var COLOR_TEXT_DIM:Int = 0xFFB0B0C0;
    static inline var COLOR_SUCCESS:Int = 0xFF00FF88;
    static inline var COLOR_ERROR:Int = 0xFFFF4444;
    static inline var COLOR_WARNING:Int = 0xFFFFAA00;
    
    // Rutas de archivos
    static var DOWNLOADS_DIR:String = "downloads/sprites/";
    static var PENDING_FILE:String = "downloads/pending_imports.json";
    
    // Descargas pendientes
    var pendingDownloads:Array<PendingDownload> = [];
    
    // Elementos de UI
    var bgOverlay:FlxSprite;
    var mainPanel:FlxSprite;
    var glowEffect:FlxSprite;
    
    // Botones
    var closeBtn:MobileWebButton;
    var refreshBtn:MobileWebButton;
    var homeBtn:MobileWebButton;
    var historyBtn:MobileWebButton;
    var downloadsBtn:MobileWebButton;
    var importBtn:MobileWebButton;
    var openExtBtn:MobileWebButton;
    var customImportBtn:MobileWebButton;
    
    // Paneles
    var downloadsPanel:FlxSprite;
    var downloadsList:FlxTypedGroup<FlxText>;
    var isDownloadsVisible:Bool = false;
    
    // Elementos de información
    var titleText:FlxText;
    var statusText:FlxText;
    var downloadCountBadge:FlxSprite;
    var downloadCountText:FlxText;
    
    // Decoraciones
    var cornerDecorations:Array<FlxSprite> = [];
    
    var animProgress:Float = 0;
    
    override function create()
    {
        // Crear directorio de descargas
        #if mobile
        if (!FileSystem.exists("downloads")) {
            FileSystem.createDirectory("downloads");
        }
        if (!FileSystem.exists(DOWNLOADS_DIR)) {
            FileSystem.createDirectory(DOWNLOADS_DIR);
        }
        #end
        
        // Cargar descargas pendientes
        loadPendingDownloads();
        
        // Fondo
        createBackground();
        
        // Panel principal
        createMainPanel();
        
        // Abrir WebView
        #if mobile
        openMobileWebView();
        #else
        createNoSupportMessage();
        #end
        
        // Controles
        createControls();
        
        // Panel de descargas
        createDownloadsPanel();
        
        // Decoraciones
        createCornerDecorations();
        
        super.create();
        
        // Animación de entrada
        playEntryAnimation();
    }
    
    function createBackground():Void
    {
        bgOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, COLOR_BG);
        bgOverlay.alpha = 0.95;
        add(bgOverlay);
        
        // Glow effect
        glowEffect = new FlxSprite(FlxG.width / 2, 100);
        glowEffect.makeGraphic(200, 200, FlxColor.TRANSPARENT);
        glowEffect.antialiasing = true;
        add(glowEffect);
    }
    
    function createMainPanel():Void
    {
        // Panel superior con controles
        mainPanel = new FlxSprite(0, 0);
        mainPanel.makeGraphic(FlxG.width, 80, COLOR_PANEL);
        add(mainPanel);
        
        // Borde inferior
        var borderBottom:FlxSprite = new FlxSprite(0, 78);
        borderBottom.makeGraphic(FlxG.width, 4, COLOR_ACCENT);
        add(borderBottom);
        
        // Título
        titleText = new FlxText(15, 20, 300, "Funkin Packer");
        titleText.setFormat("VCR OSD Mono", 20, COLOR_TEXT, BOLD);
        add(titleText);
        
        // Indicador de conexión segura
        var lockIcon:FlxSprite = new FlxSprite(10, 50);
        lockIcon.makeGraphic(16, 16, targetURL.startsWith("https") ? COLOR_SUCCESS : COLOR_WARNING);
        add(lockIcon);
        
        var httpsText:FlxText = new FlxText(30, 52, 100, "HTTPS");
        httpsText.setFormat("VCR OSD Mono", 10, COLOR_TEXT_DIM);
        add(httpsText);
        
        // Badge de descargas pendientes
        updateDownloadBadge();
    }
    
    #if mobile
    function openMobileWebView():Void
    {
        try {
            // Abrir WebView en modo flotante (overlay)
            WebView.open(targetURL, true, [targetURL], []);
            
            // Callbacks
            WebView.onClose = onWebViewClose;
            WebView.onURLChanging = onURLChanged;
            
            trace('Mobile WebView abierto: $targetURL');
        } catch(e:Dynamic) {
            trace('Error abriendo Mobile WebView: $e');
            createErrorMessage('Error: ' + e);
        }
    }
    
    function onWebViewClose():Void
    {
        trace('WebView cerrado');
        savePendingDownloads();
        Funkin.switchState(MainMenuState);
    }
    
    function onURLChanged(url:String):Void
    {
        trace('URL cambió a: $url');
        // Aquí puedes detectar si se descargó algo
        checkForNewDownloads(url);
    }
    
    function checkForNewDownloads(url:String):Void
    {
        // Funkin Packer genera archivos para descargar
        // Detectar cuando se complete una descarga
        // Por ahora simulamos la detección
        if (url.indexOf("packer") != -1 || url.indexOf("download") != -1) {
            statusText.text = "↓ Listo para importar";
            statusText.color = COLOR_SUCCESS;
        }
    }
    #else
    function createNoSupportMessage():Void
    {
        var msg:FlxText = new FlxText(0, 120, FlxG.width, 
            "🌐 WebView no disponible\n\n" +
            "Abre el enlace en tu navegador.", 24);
        msg.setFormat("VCR OSD Mono", 24, COLOR_TEXT, CENTER);
        add(msg);
        
        var openBtn:MobileWebButton = new MobileWebButton(
            FlxG.width / 2 - 80, FlxG.height - 150, 
            "Abrir en Navegador", onOpenBrowser, 160, 50, COLOR_ACCENT2
        );
        add(openBtn);
        
        statusText = new FlxText(0, 200, FlxG.width, "Cargando...");
        statusText.setFormat("VCR OSD Mono", 14, COLOR_TEXT_DIM, CENTER);
        add(statusText);
    }
    
    function onOpenBrowser():Void
    {
        CoolUtil.browserLoad(targetURL);
    }
    #end
    
    function createControls():Void
    {
        var btnY:Int = 20;
        var btnSize:Int = 60;
        var startX:Int = FlxG.width - 320;
        
        // Botón cerrar
        closeBtn = new MobileWebButton(FlxG.width - 70, btnY, "✕", onClose, 60, btnSize, COLOR_ERROR);
        add(closeBtn);
        
        // Botón refrescar
        refreshBtn = new MobileWebButton(startX, btnY, "⟳", onRefresh, 60, btnSize, COLOR_ACCENT);
        add(refreshBtn);
        
        // Botón inicio
        homeBtn = new MobileWebButton(startX + 65, btnY, "⌂", onHome, 60, btnSize, COLOR_PANEL_LIGHT);
        add(homeBtn);
        
        // Botón historial
        historyBtn = new MobileWebButton(startX + 130, btnY, "📜", onToggleHistory, 60, btnSize, COLOR_PANEL_LIGHT);
        add(historyBtn);
        
        // Botón descargas (con badge)
        downloadsBtn = new MobileWebButton(startX + 195, btnY, "⬇", onToggleDownloads, 60, btnSize, COLOR_ACCENT2);
        add(downloadsBtn);
        
        // Botón importar al editor
        importBtn = new MobileWebButton(15, FlxG.height - 100, "🎨 Importar al Editor", onImportToEditor, 200, 50, COLOR_SUCCESS);
        add(importBtn);
        
        // Botón de importación personalizada
        customImportBtn = new MobileWebButton(225, FlxG.height - 100, "⚙ Personalizado", openImportDialog, 180, 50, COLOR_ACCENT2);
        add(customImportBtn);
        
        // Botón abrir externo
        openExtBtn = new MobileWebButton(FlxG.width - 100, FlxG.height - 100, "↗", onOpenExternal, 80, 50, COLOR_ACCENT2);
        add(openExtBtn);
        
        // Estado
        statusText = new FlxText(230, 52, 300, "Conectado");
        statusText.setFormat("VCR OSD Mono", 12, COLOR_SUCCESS);
        add(statusText);
    }
    
    function updateDownloadBadge():Void
    {
        if (downloadCountBadge != null) {
            downloadCountBadge.destroy();
            downloadCountText.destroy();
        }
        
        if (pendingDownloads.length > 0) {
            downloadCountBadge = new FlxSprite(FlxG.width - 85, 15);
            downloadCountBadge.makeGraphic(25, 25, COLOR_WARNING);
            downloadCountBadge.x = downloadsBtn.x + downloadsBtn.width - 15;
            add(downloadCountBadge);
            
            downloadCountText = new FlxText(downloadCountBadge.x, downloadCountBadge.y + 3, 25, Std.string(pendingDownloads.length), 16);
            downloadCountText.setFormat("VCR OSD Mono", 16, COLOR_TEXT, CENTER);
            add(downloadCountText);
        }
    }
    
    function createDownloadsPanel():Void
    {
        downloadsPanel = new FlxSprite(0, 84);
        downloadsPanel.makeGraphic(FlxG.width, 200, COLOR_PANEL);
        downloadsPanel.visible = false;
        add(downloadsPanel);
        
        var title:FlxText = new FlxText(15, 90, 300, "📥 Descargas Recientes");
        title.setFormat("VCR OSD Mono", 16, COLOR_ACCENT2, BOLD);
        downloadsPanel.add(title);
        
        downloadsList = new FlxTypedGroup<FlxText>();
        add(downloadsList);
        
        updateDownloadsList();
    }
    
    function updateDownloadsList():Void
    {
        downloadsList.clear();
        
        var yPos:Float = 120;
        
        if (pendingDownloads.length == 0) {
            var text:FlxText = new FlxText(15, yPos, FlxG.width - 30, "Sin descargas pendientes\nUsa el botón ⬇ en Funkin Packer para descargar sprites");
            text.setFormat("VCR OSD Mono", 14, COLOR_TEXT_DIM);
            downloadsList.add(text);
            return;
        }
        
        var maxItems:Int = 5;
        var startIdx:Int = Math.max(0, pendingDownloads.length - maxItems);
        
        for (i in startIdx...pendingDownloads.length) {
            var dl:PendingDownload = pendingDownloads[i];
            var text:FlxText = new FlxText(15, yPos, FlxG.width - 30, "📄 " + dl.filename);
            text.setFormat("VCR OSD Mono", 14, COLOR_TEXT);
            downloadsList.add(text);
            yPos += 28;
        }
    }
    
    function createCornerDecorations():Void
    {
        var colors:Array<Int> = [COLOR_ACCENT, COLOR_ACCENT2, COLOR_ACCENT2, COLOR_ACCENT];
        var positions:Array<Array<Float>> = [
            [0, 78],
            [FlxG.width - 15, 78],
            [0, FlxG.height - 15],
            [FlxG.width - 15, FlxG.height - 15]
        ];
        
        for (i in 0...4) {
            var corner:FlxSprite = new FlxSprite(positions[i][0], positions[i][1]);
            corner.makeGraphic(15, 15, colors[i]);
            add(corner);
            cornerDecorations.push(corner);
        }
    }
    
    function playEntryAnimation():Void
    {
        mainPanel.alpha = 0;
        mainPanel.y = -80;
        
        FlxTween.tween(mainPanel, {alpha: 1, y: 0}, 0.4, {ease: FlxEase.quartOut});
        
        var timer:FlxTimer = new FlxTimer();
        timer.start(0.1, function(tmr:FlxTimer) {
            for (btn in [closeBtn, refreshBtn, homeBtn, historyBtn, downloadsBtn]) {
                if (btn != null) {
                    btn.alpha = 0;
                    btn.scale.set(0.5, 0.5);
                    FlxTween.tween(btn, {alpha: 1, "scale.x": 1, "scale.y": 1}, 0.3, {ease: FlxEase.backOut});
                }
            }
        });
    }
    
    // ============== DESCARGAS ==============
    function loadPendingDownloads():Void
    {
        #if mobile
        try {
            if (FileSystem.exists(PENDING_FILE)) {
                var content:String = File.getContent(PENDING_FILE);
                pendingDownloads = Json.parse(content);
            }
        } catch(e:Dynamic) {
            trace('Error cargando descargas pendientes: $e');
        }
        #end
    }
    
    function savePendingDownloads():Void
    {
        #if mobile
        try {
            var content:String = Json.stringify(pendingDownloads);
            File.saveContent(PENDING_FILE, content);
        } catch(e:Dynamic) {
            trace('Error guardando descargas pendientes: $e');
        }
        #end
    }
    
    function addPendingDownload(filename:String, path:String):Void
    {
        var download:PendingDownload = {
            filename: filename,
            path: path,
            timestamp: Date.now().toString(),
            imported: false
        };
        
        pendingDownloads.push(download);
        savePendingDownloads();
        updateDownloadBadge();
        updateDownloadsList();
        
        statusText.text = "✓ Guardado: " + filename;
        statusText.color = COLOR_SUCCESS;
    }
    
    // ============== NAVEGACIÓN ==============
    function onRefresh():Void
    {
        #if mobile
        WebView.close();
        WebView.open(targetURL, true, [targetURL], []);
        #else
        CoolUtil.browserLoad(targetURL);
        #end
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function onHome():Void
    {
        #if mobile
        WebView.close();
        WebView.open(targetURL, true, [targetURL], []);
        #end
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }
    
    function onToggleHistory():Void
    {
        // En móvil, historial está en el WebView nativo
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function onToggleDownloads():Void
    {
        isDownloadsVisible = !isDownloadsVisible;
        downloadsPanel.visible = isDownloadsVisible;
        updateDownloadsList();
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function onImportToEditor():Void
    {
        if (pendingDownloads.length == 0) {
            statusText.text = "No hay archivos para importar";
            statusText.color = COLOR_WARNING;
            return;
        }
        
        // Guardar info de descargas para el Character Editor
        savePendingDownloads();
        
        // Ir al Character Editor
        FlxG.sound.play(Paths.sound('confirmMenu'));
        Funkin.switchState(states.editors.CharacterEditorState);
    }
    
    // Abrir diálogo de importación personalizado
    function openImportDialog():Void
    {
        if (pendingDownloads.length == 0) {
            showNotification("No hay archivos para importar", COLOR_WARNING);
            return;
        }
        
        showNotification("📥 " + pendingDownloads.length + " archivo(s) pendiente(s)", COLOR_ACCENT2);
        Funkin.switchState(SpriteImportDialog);
    }
    
    // Importar un solo archivo específico
    function importSingleFile(index:Int):Void
    {
        if (index < 0 || index >= pendingDownloads.length) return;
        
        var download = pendingDownloads[index];
        
        #if mobile
        try {
            if (FileSystem.exists(download.path)) {
                var data:Bytes = File.getBytes(download.path);
                
                SpriteImportDialog.pendingImport = {
                    path: download.path,
                    data: data,
                    filename: download.filename
                };
                
                Funkin.switchState(SpriteImportDialog);
            } else {
                showNotification("Archivo no encontrado: " + download.filename, COLOR_ERROR);
            }
        } catch(e:Dynamic) {
            showNotification("Error: " + e, COLOR_ERROR);
        }
        #end
    }
    
    function onOpenExternal():Void
    {
        CoolUtil.browserLoad(targetURL);
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }
    
    function onClose():Void
    {
        savePendingDownloads();
        FlxG.sound.play(Paths.sound('cancelMenu'));
        
        #if mobile
        WebView.close();
        #end
        
        Funkin.switchState(MainMenuState);
    }
    
    function createErrorMessage(error:String):Void
    {
        var msg:FlxText = new FlxText(0, 120, FlxG.width - 40, 
            "⚠ Error del WebView:\n" + Std.string(error), 20);
        msg.setFormat("VCR OSD Mono", 20, COLOR_ERROR, CENTER);
        add(msg);
    }
    
    override function update(elapsed:Float)
    {
        // Efecto glow
        if (glowEffect != null) {
            glowEffect.alpha = 0.1 + Math.sin(elapsed * 2) * 0.05;
        }
        
        super.update(elapsed);
    }
    
    override function destroy():Void
    {
        savePendingDownloads();
        super.destroy();
    }
    
    // Método estático para que CharacterEditorState pueda acceder a las descargas
    public static function getPendingDownloads():Array<PendingDownload>
    {
        var downloads:Array<PendingDownload> = [];
        #if mobile
        try {
            if (FileSystem.exists(PENDING_FILE)) {
                var content:String = File.getContent(PENDING_FILE);
                downloads = Json.parse(content);
            }
        } catch(e:Dynamic) {}
        #end
        return downloads;
    }
    
    public static function clearImportedDownloads():Void
    {
        #if mobile
        try {
            pendingDownloads = [];
            if (FileSystem.exists(PENDING_FILE)) {
                FileSystem.deleteFile(PENDING_FILE);
            }
        } catch(e:Dynamic) {}
        #end
    }
    
    // Mostrar notificación temporal
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
}

// ============== TIPOS DE DATOS ==============
typedef PendingDownload = {
    var filename:String;
    var path:String;
    var timestamp:String;
    var imported:Bool;
}

// ============== CLASE AUXILIAR: BOTÓN MÓVIL ==============
class MobileWebButton extends FlxSprite
{
    public var label:FlxText;
    var bgColor:Int;
    var hoverColor:Int;
    var isHovered:Bool = false;
    var callback:Void->Void;
    
    public function new(x:Float, y:Float, text:String, onClick:Void->Void, ?w:Int = 60, ?h:Int = 60, ?color:Int = 0xFF252542)
    {
        super(x, y);
        
        this.callback = onClick;
        this.bgColor = color;
        this.hoverColor = FlxColor.lighten(color, 0.2);
        
        makeGraphic(w, h, bgColor);
        antialiasing = true;
        
        // Centrar texto verticalmente
        var fontSize:Int = (text.length > 3) ? 12 : 18;
        label = new FlxText(x, y + (h - fontSize) / 2, w, text, fontSize);
        label.setFormat("VCR OSD Mono", fontSize, FlxColor.WHITE, CENTER);
        label.alpha = 0.9;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        var mouseOver:Bool = FlxG.mouse.overlaps(this);
        if (mouseOver != isHovered) {
            isHovered = mouseOver;
            color = isHovered ? hoverColor : bgColor;
            
            if (isHovered) {
                scale.set(1.05, 1.05);
            } else {
                scale.set(1, 1);
            }
        }
    }
    
    override function draw():Void
    {
        super.draw();
        
        label.x = x;
        label.y = y + (height - 14) / 2;
        label.scale.copyFrom(scale);
        label.draw();
    }
}