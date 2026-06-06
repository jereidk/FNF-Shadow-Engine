package states;

#if desktop
import hxwebview.WebView;
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
    
    // Dimensiones del WebView
    var viewWidth:Int = 1100;
    var viewHeight:Int = 480;
    var viewX:Int;
    var viewY:Int;
    
    // Elementos de UI
    #if desktop
    var webView:WebView;
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
    var openExtBtn:WebButton;
    
    // Elementos de información
    var titleText:FlxText;
    var urlText:FlxText;
    var statusText:FlxText;
    var loadingBar:FlxSprite;
    var loadingFill:FlxSprite;
    
    // Decoraciones
    var cornerDecorations:Array<FlxSprite> = [];
    var scanlineEffect:FlxSprite;
    
    var isLoading:Bool = true;
    var loadingProgress:Float = 0;
    var animProgress:Float = 0;
    
    override function create()
    {
        // Calcular posición centrada
        viewX = Math.floor((FlxG.width - viewWidth) / 2);
        viewY = Math.floor((FlxG.height - viewHeight) / 2) - 20;
        
        // Fondo con gradiente oscuro
        createBackground();
        
        // Panel principal con bordes redondeados simulados
        createMainPanel();
        
        // Barra de título con efectos
        createTitleBar();
        
        // Elementos del WebView
        #if desktop
        createDesktopWebView();
        #else
        createNoSupportMessage();
        #end
        
        // Controles de navegación
        createControls();
        
        // Indicadores de estado
        createStatusIndicators();
        
        // Decoraciones de esquinas (estilo gaming)
        createCornerDecorations();
        
        // Efecto de scanline retro
        createScanlineEffect();
        
        super.create();
        
        // Animación de entrada
        playEntryAnimation();
        
        #if desktop
        if (webView != null) {
            webView.init();
        }
        #end
    }
    
    function createBackground():Void
    {
        // Fondo oscuro con slight blur effect
        bgOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, COLOR_BG);
        bgOverlay.alpha = 0.95;
        add(bgOverlay);
        
        // Glow effect central
        glowEffect = new FlxSprite(FlxG.width / 2, viewY + viewHeight / 2);
        glowEffect.makeGraphic(400, 400, FlxColor.TRANSPARENT);
        glowEffect.antialiasing = true;
        add(glowEffect);
    }
    
    function createMainPanel():Void
    {
        // Panel principal con borde
        mainPanel = new FlxSprite(viewX - 10, viewY - 50);
        mainPanel.makeGraphic(viewWidth + 20, viewHeight + 100, COLOR_PANEL);
        mainPanel.antialiasing = true;
        add(mainPanel);
        
        // Borde con gradiente (simulado con sprites)
        var borderTop:FlxSprite = new FlxSprite(viewX - 10, viewY - 50);
        borderTop.makeGraphic(viewWidth + 20, 3, COLOR_ACCENT);
        add(borderTop);
        
        var borderBottom:FlxSprite = new FlxSprite(viewX - 10, viewY + viewHeight + 47);
        borderBottom.makeGraphic(viewWidth + 20, 3, COLOR_ACCENT2);
        add(borderBottom);
        
        // Líneas decorativas verticales
        var leftLine:FlxSprite = new FlxSprite(viewX - 10, viewY - 50);
        leftLine.makeGraphic(2, viewHeight + 100, COLOR_ACCENT);
        add(leftLine);
        
        var rightLine:FlxSprite = new FlxSprite(viewX + viewWidth + 8, viewY - 50);
        rightLine.makeGraphic(2, viewHeight + 100, COLOR_ACCENT2);
        add(rightLine);
    }
    
    function createTitleBar():Void
    {
        // Barra de título
        titleBar = new FlxSprite(viewX - 5, viewY - 45);
        titleBar.makeGraphic(viewWidth + 10, 40, COLOR_PANEL_LIGHT);
        add(titleBar);
        
        // Icono del navegador (hexágono estilizado)
        var browserIcon:FlxSprite = new FlxSprite(viewX + 5, viewY - 40);
        browserIcon.makeGraphic(24, 24, COLOR_ACCENT);
        add(browserIcon);
        
        // Título
        titleText = new FlxText(viewX + 35, viewY - 40, 200, "Funkin Packer");
        titleText.setFormat("VCR OSD Mono", 18, COLOR_TEXT, BOLD);
        add(titleText);
        
        // URL actual
        urlText = new FlxText(viewX + 200, viewY - 38, viewWidth - 400, targetURL);
        urlText.setFormat("VCR OSD Mono", 12, COLOR_TEXT_DIM);
        urlText.ellipsis = true;
        add(urlText);
        
        // Indicador de candado (https)
        var lockIcon:FlxSprite = new FlxSprite(viewX + 195, viewY - 38);
        lockIcon.makeGraphic(12, 12, COLOR_SUCCESS);
        add(lockIcon);
    }
    
    #if desktop
    function createDesktopWebView():Void
    {
        try {
            webView = new WebView(viewX, viewY, viewWidth, viewHeight);
            webView.loadURL(targetURL);
            
            // Callbacks
            webView.onLoadComplete = onLoadComplete;
            webView.onLoadError = onLoadError;
            
            trace('WebView Desktop inicializado: $targetURL');
        } catch(e:Dynamic) {
            trace('Error creando WebView Desktop: $e');
            createErrorMessage('Error: ' + e);
        }
    }
    #else
    function createNoSupportMessage():Void
    {
        // Mensaje centrado
        var msg:FlxText = new FlxText(0, viewY + 50, FlxG.width, 
            "🌐 WebView no disponible\n\n" +
            "Para esta plataforma, abre el enlace en tu navegador.", 28);
        msg.setFormat("VCR OSD Mono", 28, COLOR_TEXT, CENTER);
        add(msg);
        
        // Botón para abrir en navegador
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
        var btnSize:Int = 40;
        
        // Botón cerrar
        closeBtn = new WebButton(FlxG.width - 55, viewY - 42, "✕", onClose, 38, 38, COLOR_ERROR);
        add(closeBtn);
        
        // Botón minimizar
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
        
        // Botón abrir en navegador externo
        openExtBtn = new WebButton(viewX + viewWidth - 180, btnY + 3, "↗ Abrir en Navegador", onOpenExternal, 170, 35, COLOR_ACCENT2);
        add(openExtBtn);
    }
    
    function createStatusIndicators():Void
    {
        // Barra de carga
        var barX:Int = viewX + 210;
        var barY:Int = viewY + viewHeight + 12;
        
        loadingBar = new FlxSprite(barX, barY);
        loadingBar.makeGraphic(400, 8, COLOR_PANEL_LIGHT);
        add(loadingBar);
        
        loadingFill = new FlxSprite(barX, barY);
        loadingFill.makeGraphic(1, 8, COLOR_ACCENT);
        add(loadingFill);
        
        // Texto de estado
        statusText = new FlxText(barX + 420, barY - 2, 200, "Cargando...");
        statusText.setFormat("VCR OSD Mono", 14, COLOR_TEXT_DIM);
        add(statusText);
    }
    
    function createCornerDecorations():Void
    {
        // Esquinas decorativas estilo gaming
        var corners:Array<Array<Int>> = [
            [viewX - 10, viewY - 50],      // Superior izquierda
            [viewX + viewWidth + 8, viewY - 50],  // Superior derecha
            [viewX - 10, viewY + viewHeight + 47], // Inferior izquierda
            [viewX + viewWidth + 8, viewY + viewHeight + 47] // Inferior derecha
        ];
        
        var colors:Array<Int> = [COLOR_ACCENT, COLOR_ACCENT2, COLOR_ACCENT2, COLOR_ACCENT];
        
        for (i in 0...4) {
            var corner:FlxSprite = new FlxSprite(corners[i][0], corners[i][1]);
            corner.makeGraphic(15, 15, colors[i]);
            add(corner);
            cornerDecorations.push(corner);
        }
    }
    
    function createScanlineEffect():Void
    {
        // Efecto scanline retro (subtle)
        scanlineEffect = new FlxSprite(viewX, viewY);
        scanlineEffect.makeGraphic(viewWidth, viewHeight, FlxColor.TRANSPARENT);
        add(scanlineEffect);
    }
    
    function playEntryAnimation():Void
    {
        // Animación de entrada escalonada
        mainPanel.alpha = 0;
        mainPanel.x = FlxG.width;
        
        FlxTween.tween(mainPanel, {alpha: 1, x: viewX - 10}, 0.4, {ease: FlxEase.quartOut});
        
        // Los demás elementos con delay usando FlxTimer
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
            for (btn in [backBtn, forwardBtn, refreshBtn, homeBtn]) {
                if (btn != null) {
                    btn.alpha = 0;
                    btn.scale.set(0.5, 0.5);
                    FlxTween.tween(btn, {alpha: 1, "scale.x": 1, "scale.y": 1}, 0.3, {ease: FlxEase.backOut});
                }
            }
        });
    }
    
    #if desktop
    function onLoadComplete():Void
    {
        isLoading = false;
        loadingProgress = 1;
        statusText.text = "✓ Listo";
        statusText.color = COLOR_SUCCESS;
        
        // Animación de éxito
        loadingFill.color = COLOR_SUCCESS;
        FlxTween.tween(loadingFill, {width: 400}, 0.3, {ease: FlxEase.quartOut});
        
        trace('WebView cargó completamente');
    }
    
    function onLoadError(error:String):Void
    {
        isLoading = false;
        statusText.text = "✗ Error";
        statusText.color = COLOR_ERROR;
        trace('WebView error: $error');
    }
    #end
    
    function onClose():Void
    {
        FlxG.sound.play(Paths.sound('cancelMenu'));
        Funkin.switchState(MainMenuState);
    }
    
    function onMinimize():Void
    {
        // Simula minimizar (vuelve al menú)
        FlxG.sound.play(Paths.sound('cancelMenu'));
        Funkin.switchState(MainMenuState);
    }
    
    function onBack():Void
    {
        #if desktop
        if (webView != null) {
            webView.goBack();
        }
        #end
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function onForward():Void
    {
        #if desktop
        if (webView != null) {
            webView.goForward();
        }
        #end
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function onRefresh():Void
    {
        #if desktop
        if (webView != null) {
            isLoading = true;
            loadingProgress = 0;
            statusText.text = "⟳ Recargando...";
            statusText.color = COLOR_TEXT_DIM;
            loadingFill.color = COLOR_ACCENT;
            loadingFill.width = 1;
            webView.loadURL(targetURL);
        }
        #else
        CoolUtil.browserLoad(targetURL);
        #end
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function onHome():Void
    {
        #if desktop
        if (webView != null) {
            webView.loadURL(targetURL);
        }
        #end
        FlxG.sound.play(Paths.sound('confirmMenu'));
    }
    
    function onOpenExternal():Void
    {
        CoolUtil.browserLoad(targetURL);
        FlxG.sound.play(Paths.sound('confirmMenu'));
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
            webView.update();
        }
        #end
        
        // Animación de carga
        if (isLoading) {
            animProgress += elapsed;
            loadingFill.width = Math.sin(animProgress * 3) * 50 + 50;
        }
        
        // Efecto de glow pulsante
        if (glowEffect != null) {
            glowEffect.alpha = 0.1 + Math.sin(elapsed * 2) * 0.05;
        }
        
        super.update(elapsed);
    }
    
    override function destroy():Void
    {
        #if desktop
        if (webView != null) {
            webView.destroy();
        }
        #end
        
        super.destroy();
    }
}

// Clase auxiliar para botones estilizados
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
        
        // Texto del botón
        label = new FlxText(x, y + (h - 16) / 2, w, text, 16);
        label.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER);
        label.alpha = 0.9;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        // Detectar hover
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
        
        // Dibujar texto encima
        label.x = x;
        label.y = y + (height - 16) / 2;
        label.scale.copyFrom(scale);
        label.draw();
    }
}