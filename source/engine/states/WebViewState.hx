package states;

#if desktop
import webview.WebView;
import sys.thread.Thread;
import sys.io.File;
import sys.FileSystem;
#end

import flixel.addons.ui.FlxUIState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxPoint;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import haxe.Json;

class WebViewState extends FlxUIState
{
    // URL a cargar
    public static var targetURL:String = 'https://neeeoo.github.io/funkin-packer/';
    
    // Colores del tema (estilo Cyberpunk/Neon)
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
    
    // Dimensiones del WebView
    var viewWidth:Int = 1050;
    var viewHeight:Int = 450;
    var viewX:Int;
    var viewY:Int;
    
    // Historial
    var history:Array<HistoryEntry> = [];
    var historyIndex:Int = -1;
    static var HISTORY_FILE:String = "mods/" + Mods.currentModDirectory + "/data/webview_history.json";
    
    // Descargas
    var downloads:Array<DownloadInfo> = [];
    static var DOWNLOADS_DIR:String = "downloads/";
    
    // Archivos cargados
    var uploadedFiles:Array<String> = [];
    
    // Elementos de UI
    #if desktop
    var webView:WebView;
    var webViewThread:Thread;
    #end
    
    var bgOverlay:FlxSprite;
    var mainPanel:FlxSprite;
    var titleBar:FlxSprite;
    var glowEffect:FlxSprite;
    
    // Botones
    var closeBtn:WebButton;
    var minimizeBtn:WebButton;
    var backBtn:WebButton;
    var forwardBtn:WebButton;
    var refreshBtn:WebButton;
    var homeBtn:WebButton;
    var historyBtn:WebButton;
    var downloadsBtn:WebButton;
    var uploadBtn:WebButton;
    var openExtBtn:WebButton;
    
    // Paneles
    var historyPanel:FlxSprite;
    var downloadsPanel:FlxSprite;
    var historyList:FlxTypedGroup<FlxText>;
    var downloadsList:FlxTypedGroup<FlxText>;
    var isHistoryVisible:Bool = false;
    var isDownloadsVisible:Bool = false;
    
    // Elementos de información
    var titleText:FlxText;
    var urlText:FlxText;
    var statusText:FlxText;
    var loadingBar:FlxSprite;
    var loadingFill:FlxSprite;
    
    // Decoraciones
    var cornerDecorations:Array<FlxSprite> = [];
    
    var isLoading:Bool = true;
    var animProgress:Float = 0;
    var currentURL:String = targetURL;
    
    override function create()
    {
        // Calcular posición centrada
        viewX = Math.floor((FlxG.width - viewWidth) / 2);
        viewY = Math.floor((FlxG.height - viewHeight) / 2) - 30;
        
        // Crear directorio de descargas
        #if desktop
        if (!FileSystem.exists(DOWNLOADS_DIR)) {
            FileSystem.createDirectory(DOWNLOADS_DIR);
        }
        #end
        
        // Cargar historial
        loadHistory();
        
        // Fondo
        createBackground();
        
        // Panel principal
        createMainPanel();
        
        // Barra de título
        createTitleBar();
        
        // WebView
        #if desktop
        createDesktopWebView();
        #else
        createNoSupportMessage();
        #end
        
        // Controles
        createControls();
        
        // Paneles de historial y descargas
        createHistoryPanel();
        createDownloadsPanel();
        
        // Indicadores
        createStatusIndicators();
        
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
        
        glowEffect = new FlxSprite(FlxG.width / 2, viewY + viewHeight / 2);
        glowEffect.makeGraphic(400, 400, FlxColor.TRANSPARENT);
        glowEffect.antialiasing = true;
        add(glowEffect);
    }
    
    function createMainPanel():Void
    {
        mainPanel = new FlxSprite(viewX - 10, viewY - 50);
        mainPanel.makeGraphic(viewWidth + 20, viewHeight + 100, COLOR_PANEL);
        mainPanel.antialiasing = true;
        add(mainPanel);
        
        // Bordes con gradiente
        var borderTop:FlxSprite = new FlxSprite(viewX - 10, viewY - 50);
        borderTop.makeGraphic(viewWidth + 20, 3, COLOR_ACCENT);
        add(borderTop);
        
        var borderBottom:FlxSprite = new FlxSprite(viewX - 10, viewY + viewHeight + 47);
        borderBottom.makeGraphic(viewWidth + 20, 3, COLOR_ACCENT2);
        add(borderBottom);
        
        var leftLine:FlxSprite = new FlxSprite(viewX - 10, viewY - 50);
        leftLine.makeGraphic(2, viewHeight + 100, COLOR_ACCENT);
        add(leftLine);
        
        var rightLine:FlxSprite = new FlxSprite(viewX + viewWidth + 8, viewY - 50);
        rightLine.makeGraphic(2, viewHeight + 100, COLOR_ACCENT2);
        add(rightLine);
    }
    
    function createTitleBar():Void
    {
        titleBar = new FlxSprite(viewX - 5, viewY - 45);
        titleBar.makeGraphic(viewWidth + 10, 40, COLOR_PANEL_LIGHT);
        add(titleBar);
        
        // Icono del navegador
        var browserIcon:FlxSprite = new FlxSprite(viewX + 5, viewY - 40);
        browserIcon.makeGraphic(24, 24, COLOR_ACCENT);
        add(browserIcon);
        
        // Título
        titleText = new FlxText(viewX + 35, viewY - 40, 180, "Funkin Packer");
        titleText.setFormat("VCR OSD Mono", 18, COLOR_TEXT, BOLD);
        add(titleText);
        
        // URL
        urlText = new FlxText(viewX + 220, viewY - 38, viewWidth - 420, currentURL);
        urlText.setFormat("VCR OSD Mono", 12, COLOR_TEXT_DIM);
        urlText.ellipsis = true;
        add(urlText);
        
        // Candado HTTPS
        var lockIcon:FlxSprite = new FlxSprite(viewX + 215, viewY - 38);
        lockIcon.makeGraphic(12, 12, currentURL.startsWith("https") ? COLOR_SUCCESS : COLOR_WARNING);
        add(lockIcon);
    }
    
    #if desktop
    function createDesktopWebView():Void
    {
        try {
            webView = new WebView(false);
            webView.setSize(viewWidth, viewHeight, NONE);
            
            // Inyectar JavaScript para manejar descargas y archivos
            var jsCode:String = '
                // Interceptar clics en enlaces de descarga
                document.addEventListener("click", function(e) {
                    var link = e.target.closest("a");
                    if (link && link.download) {
                        e.preventDefault();
                        window.downloadFile(link.href, link.download);
                    }
                });
                
                // Función para solicitar archivo
                window.requestFile = function() {
                    return new Promise(function(resolve, reject) {
                        var input = document.createElement("input");
                        input.type = "file";
                        input.accept = ".png,.jpg,.jpeg,.gif,.json,.xml,.txt,.fnt,.xml";
                        input.onchange = function(e) {
                            if (this.files && this.files[0]) {
                                var reader = new FileReader();
                                reader.onload = function(e) {
                                    resolve({
                                        name: this.files[0].name,
                                        data: e.target.result
                                    });
                                };
                                reader.readAsDataURL(this.files[0]);
                            } else {
                                reject("No file selected");
                            }
                        };
                        input.click();
                    });
                };
                
                // Función para descargar archivo
                window.downloadFile = function(url, filename) {
                    window.callOnGame("DOWNLOAD:" + url + "|" + (filename || "file"));
                };
            ';
            
            webView.init(jsCode);
            
            // Bind para recibir mensajes del WebView
            webView.bind("callOnGame", function(seq:String, req:String, arg:Dynamic) {
                handleWebViewMessage(req);
                webView.resolve(seq, 0, "");
            }, null);
            
            // Cargar URL inicial
            webView.navigate(targetURL);
            addToHistory(targetURL);
            
            trace('WebView Desktop inicializado');
        } catch(e:Dynamic) {
            trace('Error creando WebView Desktop: $e');
            createErrorMessage('Error: ' + e);
        }
    }
    
    function handleWebViewMessage(message:String):Void
    {
        trace('WebView message: $message');
        
        if (message.startsWith('"DOWNLOAD:')) {
            var parts:Array<String> = message.substring(1, message.length - 1).split(":");
            if (parts.length >= 2) {
                var url:String = parts[1];
                var filename:String = parts.length > 2 ? parts[2] : "download";
                startDownload(url, filename);
            }
        }
    }
    
    function startDownload(url:String, filename:String):Void
    {
        var download:DownloadInfo = {
            url: url,
            filename: filename,
            status: "Iniciando...",
            progress: 0,
            path: DOWNLOADS_DIR + filename
        };
        downloads.push(download);
        updateDownloadsPanel();
        
        statusText.text = "⬇ Descargando: " + filename;
        statusText.color = COLOR_ACCENT2;
        
        // Simular descarga (en realidad el navegador maneja esto)
        // Para una implementación real, necesitarías descargar con sys.net.Http
        #if desktop
        FlxTimer.globalTimer.add(0.5, function(tmr:FlxTimer) {
            download.status = "Completado";
            download.progress = 100;
            updateDownloadsPanel();
            statusText.text = "✓ Descarga: " + filename;
            statusText.color = COLOR_SUCCESS;
        });
        #end
    }
    #else
    function createNoSupportMessage():Void
    {
        var msg:FlxText = new FlxText(0, viewY + 50, FlxG.width, 
            "🌐 WebView no disponible\n\n" +
            "Para esta plataforma, abre el enlace en tu navegador.", 28);
        msg.setFormat("VCR OSD Mono", 28, COLOR_TEXT, CENTER);
        add(msg);
        
        var openBtn:WebButton = new WebButton(FlxG.width / 2 - 80, viewY + viewHeight - 80, "Abrir en Navegador", onOpenBrowser, 160, 45);
        add(openBtn);
        
        isLoading = false;
    }
    
    function onOpenBrowser():Void
    {
        CoolUtil.browserLoad(targetURL);
    }
    #end
    
    function createControls():Void
    {
        var btnY:Int = viewY + viewHeight + 5;
        
        // Botones de ventana
        closeBtn = new WebButton(FlxG.width - 55, viewY - 42, "✕", onClose, 38, 38, COLOR_ERROR);
        add(closeBtn);
        
        minimizeBtn = new WebButton(FlxG.width - 110, viewY - 42, "─", onMinimize, 38, 38, COLOR_TEXT_DIM);
        add(minimizeBtn);
        
        // Navegación
        var navStartX:Int = viewX + 10;
        
        backBtn = new WebButton(navStartX, btnY + 3, "◄", onBack, 45, 35, COLOR_PANEL_LIGHT);
        add(backBtn);
        
        forwardBtn = new WebButton(navStartX + 50, btnY + 3, "►", onForward, 45, 35, COLOR_PANEL_LIGHT);
        add(forwardBtn);
        
        refreshBtn = new WebButton(navStartX + 100, btnY + 3, "⟳", onRefresh, 45, 35, COLOR_ACCENT);
        add(refreshBtn);
        
        homeBtn = new WebButton(navStartX + 150, btnY + 3, "⌂", onHome, 45, 35, COLOR_PANEL_LIGHT);
        add(homeBtn);
        
        // Historial y descargas
        historyBtn = new WebButton(navStartX + 200, btnY + 3, "📜", onToggleHistory, 45, 35, COLOR_PANEL_LIGHT);
        add(historyBtn);
        
        downloadsBtn = new WebButton(navStartX + 250, btnY + 3, "⬇", onToggleDownloads, 45, 35, COLOR_ACCENT2);
        add(downloadsBtn);
        
        // Subir archivos
        uploadBtn = new WebButton(navStartX + 300, btnY + 3, "📁", onUploadFile, 45, 35, COLOR_PANEL_LIGHT);
        add(uploadBtn);
        
        // Abrir externo
        openExtBtn = new WebButton(viewX + viewWidth - 180, btnY + 3, "↗", onOpenExternal, 45, 35, COLOR_ACCENT2);
        add(openExtBtn);
    }
    
    function createHistoryPanel():Void
    {
        historyPanel = new FlxSprite(viewX - 5, viewY + viewHeight + 50);
        historyPanel.makeGraphic(300, 150, COLOR_PANEL);
        historyPanel.visible = false;
        add(historyPanel);
        
        var title:FlxText = new FlxText(viewX + 5, viewY + viewHeight + 55, 290, "Historial");
        title.setFormat("VCR OSD Mono", 14, COLOR_ACCENT, BOLD);
        historyPanel.add(title);
        
        historyList = new FlxTypedGroup<FlxText>();
        add(historyList);
    }
    
    function createDownloadsPanel():Void
    {
        downloadsPanel = new FlxSprite(viewX + 310, viewY + viewHeight + 50);
        downloadsPanel.makeGraphic(350, 150, COLOR_PANEL);
        downloadsPanel.visible = false;
        add(downloadsPanel);
        
        var title:FlxText = new FlxText(viewX + 315, viewY + viewHeight + 55, 340, "Descargas");
        title.setFormat("VCR OSD Mono", 14, COLOR_ACCENT2, BOLD);
        downloadsPanel.add(title);
        
        downloadsList = new FlxTypedGroup<FlxText>();
        add(downloadsList);
    }
    
    function createStatusIndicators():Void
    {
        var barX:Int = viewX + 370;
        var barY:Int = viewY + viewHeight + 12;
        
        loadingBar = new FlxSprite(barX, barY);
        loadingBar.makeGraphic(400, 8, COLOR_PANEL_LIGHT);
        add(loadingBar);
        
        loadingFill = new FlxSprite(barX, barY);
        loadingFill.makeGraphic(1, 8, COLOR_ACCENT);
        add(loadingFill);
        
        statusText = new FlxText(barX + 420, barY - 2, 250, "Cargando...");
        statusText.setFormat("VCR OSD Mono", 14, COLOR_TEXT_DIM);
        add(statusText);
    }
    
    function createCornerDecorations():Void
    {
        var corners:Array<Array<Int>> = [
            [viewX - 10, viewY - 50],
            [viewX + viewWidth + 8, viewY - 50],
            [viewX - 10, viewY + viewHeight + 47],
            [viewX + viewWidth + 8, viewY + viewHeight + 47]
        ];
        
        var colors:Array<Int> = [COLOR_ACCENT, COLOR_ACCENT2, COLOR_ACCENT2, COLOR_ACCENT];
        
        for (i in 0...4) {
            var corner:FlxSprite = new FlxSprite(corners[i][0], corners[i][1]);
            corner.makeGraphic(15, 15, colors[i]);
            add(corner);
            cornerDecorations.push(corner);
        }
    }
    
    function playEntryAnimation():Void
    {
        mainPanel.alpha = 0;
        mainPanel.x = FlxG.width;
        
        FlxTween.tween(mainPanel, {alpha: 1, x: viewX - 10}, 0.4, {ease: FlxEase.quartOut});
        
        var timer1:FlxTimer = new FlxTimer();
        timer1.start(0.1, function(tmr:FlxTimer) {
            for (btn in [closeBtn, minimizeBtn]) {
                if (btn != null) {
                    btn.alpha = 0;
                    btn.y -= 20;
                    FlxTween.tween(btn, {alpha: 1, y: btn.y + 20}, 0.3, {ease: FlxEase.quartOut});
                }
            }
        });
        
        var timer2:FlxTimer = new FlxTimer();
        timer2.start(0.15, function(tmr:FlxTimer) {
            for (btn in [backBtn, forwardBtn, refreshBtn, homeBtn, historyBtn, downloadsBtn, uploadBtn, openExtBtn]) {
                if (btn != null) {
                    btn.alpha = 0;
                    btn.scale.set(0.5, 0.5);
                    FlxTween.tween(btn, {alpha: 1, "scale.x": 1, "scale.y": 1}, 0.3, {ease: FlxEase.backOut});
                }
            }
        });
    }
    
    // ============== HISTORIAL ==============
    function loadHistory():Void
    {
        #if desktop
        try {
            if (FileSystem.exists(HISTORY_FILE)) {
                var content:String = File.getContent(HISTORY_FILE);
                history = Json.parse(content);
            }
        } catch(e:Dynamic) {
            trace('Error cargando historial: $e');
        }
        #end
    }
    
    function saveHistory():Void
    {
        #if desktop
        try {
            // Guardar solo los últimos 50 elementos
            var toSave:Array<HistoryEntry> = history.slice(-50);
            var content:String = Json.stringify(toSave);
            File.saveContent(HISTORY_FILE, content);
        } catch(e:Dynamic) {
            trace('Error guardando historial: $e');
        }
        #end
    }
    
    function addToHistory(url:String):Void
    {
        // Evitar duplicados consecutivos
        if (history.length > 0 && history[history.length - 1].url == url) {
            historyIndex = history.length - 1;
            return;
        }
        
        // Eliminar historial futuro si estamos en medio
        if (historyIndex < history.length - 1) {
            history = history.slice(0, historyIndex + 1);
        }
        
        var entry:HistoryEntry = {
            url: url,
            timestamp: Date.now().toString(),
            title: extractTitle(url)
        };
        
        history.push(entry);
        historyIndex = history.length - 1;
        saveHistory();
        updateHistoryPanel();
    }
    
    function extractTitle(url:String):String
    {
        // Extraer nombre de dominio o última parte de la URL
        try {
            var parts:Array<String> = url.split("/");
            var last:String = parts[parts.length - 1];
            if (last.length > 0 && last.indexOf(".") == -1) {
                return last.substring(0, Math.min(30, last.length));
            }
            return url.split("/")[2];
        } catch(e:Dynamic) {
            return url;
        }
    }
    
    function updateHistoryPanel():Void
    {
        historyList.clear();
        
        var yPos:Float = viewY + viewHeight + 80;
        var maxItems:Int = 5;
        var startIdx:Int = Math.max(0, history.length - maxItems);
        
        for (i in startIdx...history.length) {
            var entry:HistoryEntry = history[i];
            var isCurrent:Bool = (i == historyIndex);
            
            var text:FlxText = new FlxText(viewX + 10, yPos, 280, entry.title);
            text.setFormat("VCR OSD Mono", 12, isCurrent ? COLOR_ACCENT : COLOR_TEXT_DIM);
            if (isCurrent) text.text = "→ " + text.text;
            historyList.add(text);
            yPos += 22;
        }
    }
    
    // ============== DESCARGAS ==============
    function updateDownloadsPanel():Void
    {
        downloadsList.clear();
        
        var yPos:Float = viewY + viewHeight + 80;
        
        if (downloads.length == 0) {
            var text:FlxText = new FlxText(viewX + 315, yPos, 340, "Sin descargas recientes");
            text.setFormat("VCR OSD Mono", 12, COLOR_TEXT_DIM);
            downloadsList.add(text);
            return;
        }
        
        var maxItems:Int = 4;
        var startIdx:Int = Math.max(0, downloads.length - maxItems);
        
        for (i in startIdx...downloads.length) {
            var dl:DownloadInfo = downloads[i];
            var statusIcon:String = switch(dl.status) {
                case "Completado": "✓";
                case "Error": "✗";
                default: "○";
            }
            
            var text:FlxText = new FlxText(viewX + 315, yPos, 340, statusIcon + " " + dl.filename);
            text.setFormat("VCR OSD Mono", 12, dl.status == "Completado" ? COLOR_SUCCESS : COLOR_TEXT);
            downloadsList.add(text);
            yPos += 22;
        }
    }
    
    // ============== NAVEGACIÓN ==============
    #if desktop
    function navigate(url:String):Void
    {
        if (webView != null) {
            webView.navigate(url);
            currentURL = url;
            urlText.text = url;
            addToHistory(url);
            
            isLoading = true;
            statusText.text = "Cargando...";
            statusText.color = COLOR_TEXT_DIM;
        }
    }
    #end
    
    function onBack():Void
    {
        #if desktop
        if (historyIndex > 0) {
            historyIndex--;
            var entry:HistoryEntry = history[historyIndex];
            navigate(entry.url);
        }
        #end
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function onForward():Void
    {
        #if desktop
        if (historyIndex < history.length - 1) {
            historyIndex++;
            var entry:HistoryEntry = history[historyIndex];
            navigate(entry.url);
        }
        #end
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function onRefresh():Void
    {
        #if desktop
        if (webView != null) {
            webView.navigate(currentURL);
            isLoading = true;
            statusText.text = "Recargando...";
            statusText.color = COLOR_TEXT_DIM;
        }
        #else
        CoolUtil.browserLoad(currentURL);
        #end
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function onHome():Void
    {
        navigate(targetURL);
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }
    
    function onToggleHistory():Void
    {
        isHistoryVisible = !isHistoryVisible;
        isDownloadsVisible = false;
        historyPanel.visible = isHistoryVisible;
        downloadsPanel.visible = false;
        updateHistoryPanel();
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function onToggleDownloads():Void
    {
        isDownloadsVisible = !isDownloadsVisible;
        isHistoryVisible = false;
        downloadsPanel.visible = isDownloadsVisible;
        historyPanel.visible = false;
        updateDownloadsPanel();
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function onUploadFile():Void
    {
        #if desktop
        // Enviar mensaje al WebView para abrir selector de archivos
        if (webView != null) {
            webView.eval('window.requestFile().then(function(file) { window.callOnGame("UPLOAD:" + file.name + ":" + file.data); });');
            statusText.text = "Selecciona un archivo...";
            statusText.color = COLOR_WARNING;
        }
        #end
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }
    
    function onOpenExternal():Void
    {
        CoolUtil.browserLoad(currentURL);
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }
    
    function onClose():Void
    {
        saveHistory();
        FlxG.sound.play(Paths.sound('cancelMenu'));
        
        #if desktop
        if (webView != null) {
            webView.terminate();
            webView.destroy();
        }
        #end
        
        Funkin.switchState(MainMenuState);
    }
    
    function onMinimize():Void
    {
        onClose();
    }
    
    function createErrorMessage(error:String):Void
    {
        var msg:FlxText = new FlxText(0, viewY + 80, FlxG.width - 40, 
            "⚠ Error del WebView:\n" + Std.string(error), 22);
        msg.setFormat("VCR OSD Mono", 22, COLOR_ERROR, CENTER);
        add(msg);
        isLoading = false;
    }
    
    override function update(elapsed:Float)
    {
        #if desktop
        if (webView != null) {
            // Actualizar webview si es necesario
        }
        #end
        
        // Animación de carga
        if (isLoading) {
            animProgress += elapsed;
            loadingFill.width = Math.sin(animProgress * 3) * 50 + 50;
        }
        
        // Efecto glow
        if (glowEffect != null) {
            glowEffect.alpha = 0.1 + Math.sin(elapsed * 2) * 0.05;
        }
        
        // Ocultar paneles si se hace clic fuera
        #if desktop
        if (FlxG.mouse.justPressed && isHistoryVisible || isDownloadsVisible) {
            // Check if click is outside panels
        }
        #end
        
        super.update(elapsed);
    }
    
    override function destroy():Void
    {
        #if desktop
        if (webView != null) {
            webView.terminate();
            webView.destroy();
        }
        #end
        super.destroy();
    }
}

// ============== TIPOS DE DATOS ==============
typedef HistoryEntry = {
    var url:String;
    var timestamp:String;
    var title:String;
}

typedef DownloadInfo = {
    var url:String;
    var filename:String;
    var status:String;
    var progress:Float;
    var path:String;
}

// ============== CLASE AUXILIAR: BOTÓN ==============
class WebButton extends FlxSprite
{
    public var label:FlxText;
    var bgColor:Int;
    var hoverColor:Int;
    var isHovered:Bool = false;
    var callback:Void->Void;
    
    public function new(x:Float, y:Float, text:String, onClick:Void->Void, ?w:Int = 45, ?h:Int = 35, ?color:Int = 0xFF252542)
    {
        super(x, y);
        
        this.callback = onClick;
        this.bgColor = color;
        this.hoverColor = FlxColor.lighten(color, 0.3);
        
        makeGraphic(w, h, bgColor);
        antialiasing = true;
        
        label = new FlxText(x, y + (h - 16) / 2, w, text, 16);
        label.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER);
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
                if (callback != null && FlxG.mouse.justPressed) {
                    callback();
                }
            } else {
                scale.set(1, 1);
            }
        }
    }
    
    override function draw():Void
    {
        super.draw();
        
        label.x = x;
        label.y = y + (height - 16) / 2;
        label.scale.copyFrom(scale);
        label.draw();
    }
}