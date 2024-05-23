import flixel.FlxG;
#if sys
import sys.io.File;
import sys.io.FileOutput;
import sys.io.FileInput;
#end
import haxe.Json;

class PlayerPrefs {
    public static var prefsFile:String = "preferences/preferences.json";
    public static var censorNaughty:Bool = false;
    public static var downScroll:Bool = false;
    public static var flashingMenu:Bool = true;
    public static var cameraZoom:Bool = true;
    public static var fpsCounter:Bool = true;
    public static var autoPause:Bool = false;

    public static function initPrefs():Void {
        #if sys
        if (sys.FileSystem.exists(prefsFile)) {
            var jsonString:String = sys.io.File.getContent(prefsFile);
            var jsonData:Dynamic = Json.parse(jsonString);

            if (jsonData.censorNaughty != null) {
                censorNaughty = jsonData.censorNaughty;
            }

            if (jsonData.downScroll != null) {
                downScroll = jsonData.downScroll;
            }

            if (jsonData.flashingMenu != null) {
                flashingMenu = jsonData.flashingMenu;
            }

            if (jsonData.cameraZoom != null) {
                cameraZoom = jsonData.cameraZoom;
            }

            if (jsonData.fpsCounter != null) {
                fpsCounter = jsonData.fpsCounter;
            }

            if (jsonData.autoPause != null) {
                autoPause = jsonData.autoPause;
            }

            /*
            trace(jsonString);
            trace(jsonData);
            */
        }
        #end

        if (PlayerPrefs.autoPause)
			FlxG.autoPause = PlayerPrefs.autoPause;

    }

    /*public static function getPref(pref:String):Dynamic {
        return Reflect.getProperty(PlayerPrefs, pref);
        trace(pref);
    }
    
    public static function setPref(pref:String, value:Dynamic):Void {
        Reflect.setProperty(PlayerPrefs, pref, value);
        trace(pref);
    }*/

    public static function saveSettings():Void {
        var jsonData:Dynamic = 
        {
            "censorNaughty": censorNaughty,
            "downScroll": downScroll,
            "flashingMenu": flashingMenu,
            "cameraZoom": cameraZoom,
            "fpsCounter": fpsCounter,
            "autoPause": autoPause
        };

        var jsonString:String = Json.stringify(jsonData, "\t");
        #if sys
        sys.io.File.saveContent(prefsFile, jsonString);
        #end

        if (PlayerPrefs.autoPause)
			FlxG.autoPause = PlayerPrefs.autoPause;

        /* 
        trace(jsonData);
        trace(jsonString); 
        */
    }
}
