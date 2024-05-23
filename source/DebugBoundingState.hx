package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import openfl.Assets;
#if sys
import sys.io.File;
#end

class DebugBoundingState extends FlxState
{
	override function create()
	{
		var bf:FlxSprite = new FlxSprite().loadGraphic(Paths.image('characters/temp'));
		add(bf);

		FlxG.stage.window.onDropFile.add(function(path:String)
		{
			trace("DROPPED FILE FROM: " + Std.string(path));
			var newPath = "./" + Paths.image('characters/temp');
			#if sys
			File.copy(path, newPath);
			#end

			var swag = Paths.image('characters/temp');

			if (bf != null)
				remove(bf);
			FlxG.bitmap.removeByKey(Paths.image('characters/temp'));
			Assets.cache.clear();

			bf.loadGraphic(Paths.image('characters/temp'));
			add(bf);
		});

		super.create();
	}
}
