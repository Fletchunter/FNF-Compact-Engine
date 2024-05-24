package unused;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;

class LatencyState extends FlxState
{
	var offsetText:FlxText;
	var noteGrp:FlxTypedGroup<objects.Note>;
	var strumLine:FlxSprite;

	override function create()
	{
		FlxG.sound.playMusic(backend.Paths.sound('soundTest'));

		noteGrp = new FlxTypedGroup<objects.Note>();
		add(noteGrp);

		for (i in 0...32)
		{
			var note:objects.Note = new objects.Note(backend.Conductor.crochet * i, 1);
			noteGrp.add(note);
		}

		offsetText = new FlxText();
		offsetText.screenCenter();
		add(offsetText);

		strumLine = new FlxSprite(FlxG.width / 2, 100).makeGraphic(FlxG.width, 5);
		add(strumLine);

		backend.Conductor.changeBPM(120);

		super.create();
	}

	override function update(elapsed:Float)
	{
		offsetText.text = "Offset: " + backend.Conductor.offset + "ms";

		backend.Conductor.songPosition = FlxG.sound.music.time - backend.Conductor.offset;

		var multiply:Float = 1;

		if (FlxG.keys.pressed.SHIFT)
			multiply = 10;

		if (FlxG.keys.justPressed.RIGHT)
			backend.Conductor.offset += 1 * multiply;
		if (FlxG.keys.justPressed.LEFT)
			backend.Conductor.offset -= 1 * multiply;

		if (FlxG.keys.justPressed.SPACE)
		{
			FlxG.sound.music.stop();

			FlxG.resetState();
		}

		noteGrp.forEach(function(daNote:objects.Note)
		{
			daNote.y = (strumLine.y - (backend.Conductor.songPosition - daNote.strumTime) * 0.45);
			daNote.x = strumLine.x + 30;

			if (daNote.y < strumLine.y)
				daNote.kill();
		});

		super.update(elapsed);
	}
}
