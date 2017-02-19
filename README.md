battery-d [![Page on DUB](https://img.shields.io/dub/v/battery-d.svg)](http://code.dlang.org/packages/battery-d) [![License](https://img.shields.io/dub/l/battery-d.svg)](https://github.com/azbukagh/battery-d/blob/master/LICENSE.md) [![CircleCI](https://circleci.com/gh/azbukagh/battery-d.svg?style=svg)](https://circleci.com/gh/azbukagh/battery-d)
=============
battery-d - simple library for reading battery info on linux laptops.
Provides access to battery status (discharging, charging or full), battery level (0-100%), time remaining and time until full.
Also provides access to raw data (which can differ on different laptops).

## Basic usage
```
dub run battery-d
```

## As library
battery-d can be used as library. Just add it to dependencies in `dub.json`.
Example usage:
```
import std.stdio;
import battery.d;

void main() {
	auto b = new Battery();
	writeln("Level: ", b.level);
	writeln("Status: ", b.status);
}
```

## Advanced usage
battery-d have been developed as rewrite of old perl script, which parses output of `acpi` command.
By default `battery-d -pc` outputs coloured battery level:
- <= 20% - red
- <= 50% - yellow
- <= 100% - green

Output can be customized by editing code or cli arguments:
```
battery-d -pc --threshold=30=["%F{orange}","%%%f"]
```
This command adds new threshold, which prepends battery level with `%F{orange}` and appends `%%%f`.
Output will look like this:
````
%F{orange}29%%%f
```
In zsh it produces orange-coloured `29%`.
