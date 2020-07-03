# QuickTour of the Stats-Configurator

---

## Pre-requisites

* ***[Norbyte's Script-Extender](https://github.com/Norbyte/ositools)***
* ***[Stats-Configurator](#ReleasesLink)***

## Quick-Start

It's time to get your feet wet, so let's get started. Once you've installed and activated the mod open up the game and load into a save. The *stats-configurator* item will be added to your inventory. Using it will open up the **Mod-Menu** - from here, you can access most of the important functionality of this mod.

||| IMAGE: ModMenu and Stats-Config Item |||

Before we go any further let's create a **config-file**. Navigate to `\Documents\Larian Studios\Divinity Original Sin 2 Definitive Edition\Osiris Data` folder on your system. This is where the script-extender reads from and writes files to. Create `S7_Config.json` file (make sure its a json file and not a text file. Windows sometimes likes to mess things up - `S7_Config.json.txt` for example). Open this file in your favourite text editor (VSCode, Sublime, Notepad++, regular Notepad).

The stats-configurator reads json files for configuration so we need to follow proper json format. If you're familiar with json, then that's fantastic, otherwise you can look that up on the internet, or you can just follow along with this guide - json isn't exactly indecipherably esoteric.

Inside `S7_Config.json` write the following content:

```json
{
    "Projectile_Fireball":  {"ActionPoints": 4, "Cooldown": 7}
}
```

json files/objects are just **key-value pairs**. you can nest key-value pairs inside other key-value pairs (which can inturn be nested inside other key-value pairs) but basically, you have a **key** and a **value** associated with that key. In this example `Projectile_Fireball` is the **key** and everything after the `:` is its **value**. Within that, we have two key-value pairs:

1. `"ActionPoints": 4`. ActionPoints is the key and 4 is the value.
2. `"Cooldown": 7` . Cooldown is the key and 7 is the value.

Enough about json :P
The block of code is pretty self-explanatory. We want the skill `Projectile_Fireball` to have an `ActionPoints` cost of 4 and a `Cooldown` of 7 turns. `Projectile_Fireball` is the internal name of the skill **"Fireball"**, as are `ActionPoints` and `Cooldown`. If you are familiar with **The Divinity Engine 2** then you'll feel right at home, otherwise you can refer to ||| References link?||| `Enumerations.xml` and `StatObjectDefinitions.xml`. I've provided a few tools to display stat-names and such for your reference, please read ||| Extended Documentation ||| for more details.

Let's go back in the game, but before we load this configuration-file, let's see what the original values of this skill's attributes are.

The script-extender comes with a `Debug Console` which should open up automatically as you open the game (if not enable it using ||| Links here |||). Looks like this
||| Debug Console Image |||

This is where a lot of **useful information** will be outputted. Stats-Configurator comes with a suite of ***console-commands*** to make your life easier. Right now, we want to add `Projectile_Fireball` to our character (if you don't have the skill already).
We will use the `AddSkill` console command for this purpose.

Pressing `enter` on the debug console will allow you to enter console-commands.Write `!S7_Config AddSkill Projectile_Fireball` and hit enter. Type `exit` and press enter to exit the console-command view. This will add `Projectile_Fireball` to all `client` characters.
***Pro-tip:*** use `!S7_Config Help` for a helpful guide on console-commands in this mod.

Now that your characters have the *original*, *unmodified* `Projectile_Fireball`. Take note of its attributes. `ActionPoints` and `Cooldown` specifically.

Now the fun part, open the stats-configurator mod-menu and open `1. [configuration]`. The first option will load the configuration file we just created in `Osiris Data`.
P.S.: watch the magic happen in the debug console.

Now have a look at `Projectile_Fireball` again. It's `ActionPoints` and `Cooldown` have changed to the values you set in the config-file. Take this time to congratulate yourself.

## Config-Data

With the default settings, these changes will not be restored the next time you load the game. Due to a myriad of reasons (that'll take too long to explain in a quick-start guide), the mod compiles all configuration-data into a seperate file (`S7_ConfigData.json` by default). Stat-overrides made here are loaded during `ModuleLoading` i.e. when the game loads. There's a whole lot to Config-Data, but for now we just need to put our configuration in Config-Data so that our changes are saved persistently and are loaded in the game automatically during startup.

Using the mod-menu, in `1.[configuration]`,chosing the second option called **Rebuild Config-Data** will create a Config-Data file by compiling all the sources of configuration-data. Only `S7_Config.json` in our case. Do so now.

You should see `S7_ConfigData.json` appear in `Osiris Data` folder.

Reload the game and keep an eye on the debug-console. You'll see that the Config-Data file is loaded automatically when the game starts. That's it. Congratulations, You're done. Wait for the game to load and check if your changes still exist.

## Sharing Config-Data

Loading Config-Data happen in the `client` context. Every game session in Divinity Original Sin 2 is technically a Multiplayer game, even if you're the only person playing in it. The game creates a `Server` context for the `host` and `Client` context for all the `peers` including the host. Hence, to make sure each `client` has the same stat-modifications, we need to transfer the config-data file to each of our peers.

That's easily done using the mod-menu as well. The `host` can chose to **broadcast** his config-data file to all connected clients. This will save the file on the clients machine, ready to be loaded next time. Warning: this will overwrite their existing config-data, ask them to back it up before you broadcast if they plan to have different sessions with different config-data. You can also change the name of the file to differentiate it using the settings. ||| Links |||

If you're unsure if everyone has the same config-data, or if you think one of your friends is cheating, then the host can verify whether everyone has the same file.

---

That's pretty much it. That's all you need to know to get started with this mod. I'll urge you to read the extensive documentation to learn more about this mod. Don't forget to share your configurations with me and the community!