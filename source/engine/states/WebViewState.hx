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

class WebViewState extends FlxUIState
{
    // URL a cargar
    public static var targetURL:String = 'https://neeeoo.github.io/funkin-packer/';
    
    // Dimensiones del WebView
    var viewWidth:Int = 1100;
    var viewHeight:Int = 500;
    var viewX:Int;
    var viewY:Int;
    
    #if desktop
    var webView:WebView;
    #end
    
    var bgOverlay:FlxSprite;
    var closeButton:FlxButton;
    var backButton:FlxButton;
    var refreshButton:FlxButton;
    var statusText:FlxText;
    
    var isLoading:Bool = true;
    
    override function create()
    {
        // Calcular posición centrada
        viewX = Math.floor((FlxG.width - viewWidth) / 2);
        viewY = Math.floor((FlxG.height - viewHeight) / 2);
        
        // Fondo oscuro semi-transparente
        bgOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bgOverlay.alpha = 0.85;
        add(bgOverlay);
        
        #if desktop
        createDesktopWebView();
        #else
        createNoSupportMessage();
        #end
        
        // Marco decorativo
        createFrame();
        
        // Botones de control
        createControls();
        
        super.create();
        
        #if desktop
        // Iniciar el WebView después de que todo esté creado
        if (webView != null) {
            webView.init();
        }
        #end
    }
    
    #if desktop
    function createDesktopWebView():Void
    {
        try {
            webView = new WebView(viewX, viewY, viewWidth, viewHeight);
            webView.loadURL(targetURL);
            
            // Callback cuando termina de cargar
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
        var msg:FlxText = new FlxText(0, 0, FlxG.width, 
            "WebView no disponible para esta plataforma.\n\n" +
            "Plataformas soportadas:\n" +
            "- Windows (Desktop)\n" +
            "- Mac/Linux (Desktop)\n\n" +
            "Para HTML5/Móvil, abre el enlace en tu navegador.", 24);
        msg.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, CENTER);
        msg.screenCenter();
        add(msg);
        
        // Botón para abrir en navegador
        var openBtn:FlxButton = new FlxButton(0, FlxG.height - 100, "Abrir en Navegador", onOpenBrowser);
        openBtn.screenCenter(X);
        add(openBtn);
        
        isLoading = false;
    }
    
    function onOpenBrowser():Void
    {
        CoolUtil.browserLoad(targetURL);
    }
    #end
    
    function createFrame():Void
    {
        // Marco superior
        var topBar:FlxSprite = new FlxSprite(viewX - 5, viewY - 40).makeGraphic(viewWidth + 10, 45, 0xFF2D2D2D);
        add(topBar);
        
        // Título
        var title:FlxText = new FlxText(viewX + 10, viewY - 32, viewWidth - 70, "Funkin Packer");
        title.setFormat("VCR OSD Mono", 18, FlxColor.WHITE, LEFT);
        add(title);
        
        // Indicador de URL
        var urlText:FlxText = new FlxText(viewX + 10, viewY - 12, viewWidth - 70, targetURL);
        urlText.setFormat("VCR OSD Mono", 12, 0xAAAAAA, LEFT);
        add(urlText);
        
        // Borde del frame (barra inferior)
        var bottomBar:FlxSprite = new FlxSprite(viewX - 5, viewY + viewHeight + 5).makeGraphic(viewWidth + 10, 45, 0xFF2D2D2D);
        add(bottomBar);
    }
    
    function createControls():Void
    {
        // Botón cerrar (X)
        closeButton = new FlxButton(FlxG.width - 50, viewY - 35, "X", onClose);
        closeButton.setGraphicSize(40, 40);
        closeButton.updateHitbox();
        add(closeButton);
        
        // Botón volver
        backButton = new FlxButton(viewX + 5, viewY + viewHeight + 10, "← Volver", onBack);
        backButton.setSize(100, 30);
        add(backButton);
        
        // Botón refrescar
        refreshButton = new FlxButton(viewX + viewWidth - 105, viewY + viewHeight + 10, "↻ Refrescar", onRefresh);
        refreshButton.setSize(100, 30);
        add(refreshButton);
        
        // Estado de carga
        statusText = new FlxText(viewX + 110, viewY + viewHeight + 15, viewWidth - 230, "Cargando...");
        statusText.setFormat("VCR OSD Mono", 14, 0xAAAAAA, CENTER);
        add(statusText);
    }
    
    #if desktop
    function onLoadComplete():Void
    {
        isLoading = false;
        statusText.text = "Listo";
        statusText.color = 0x00FF00;
        trace('WebView cargó completamente');
    }
    
    function onLoadError(error:String):Void
    {
        isLoading = false;
        statusText.text = "Error al cargar";
        statusText.color = 0xFF0000;
        trace('WebView error: $error');
    }
    #end
    
    function onClose():Void
    {
        FlxG.sound.play(Paths.sound('cancelMenu'));
        Funkin.switchState(MainMenuState);
    }
    
    function onBack():Void
    {
        FlxG.sound.play(Paths.sound('cancelMenu'));
        Funkin.switchState(MainMenuState);
    }
    
    function onRefresh():Void
    {
        #if desktop
        if (webView != null) {
            isLoading = true;
            statusText.text = "Recargando...";
            statusText.color = 0xAAAAAA;
            webView.loadURL(targetURL);
        }
        #else
        CoolUtil.browserLoad(targetURL);
        #end
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    
    function createErrorMessage(error:String):Void
    {
        var msg:FlxText = new FlxText(0, 0, FlxG.width - 40, "Error del WebView:\n" + Std.string(error), 20);
        msg.setFormat("VCR OSD Mono", 20, FlxColor.RED, CENTER);
        msg.screenCenter();
        add(msg);
        isLoading = false;
    }
    
    override function update(elapsed:Float)
    {
        #if desktop
        if (webView != null) {
            webView.update(); // Actualizar el WebView
        }
        #end
        
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