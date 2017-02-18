import std.stdio;
import battery.d;
import std.getopt;
import core.stdc.stdlib: exit;
import core.time : Duration;

void showInfo(Battery b) {
	switch(b.status) with(BatteryStatus) {
		case DISCHARGING:
			writefln("%s: discharging, %.1f%%, %s remaining",
				b.name,
				b.level,
				b.timeRemaining.toString);
			break;
		case CHARGING:
			writefln("%s: charging, %.1f%%, %s until charged",
				b.name,
				b.level,
				b.timeUntilFull.toString);
			break;
		case FULL:
			writefln("%s: full, %.1f%%",
				b.name,
				b.level);
			break;
		default: break;
	}
}

void showRaw(Battery b) {
	writeln("Raw data:");
	foreach(k, v; b.raw) {
		writefln("\t%s=%s", k, v);
	}
}

int main(string[] args) {
	bool verbose = false;
	bool customize = false;
	string battery_name = getBatteryList.front;
	string[2][float] thresholds = [
		20: ["%F{red}", "%%%f"],
		50: ["%F{yellow}", "%%%f"],
		100: ["%F{green}", "%%%f"]
	];

	void percent() {
		Battery b;
		float min;
		try {
			b = new Battery(battery_name);
		} catch (BatteryException e) {
			writeln("Exception:", e.msg);
			exit(-1);
		}
		if(customize) {
			min = 100;
			foreach(k, v; thresholds)
				if(b.level <= k)
					min = k;
			write(thresholds[min][0]);
		}
		if(verbose) {
			writef("%.2f",
			       b.level);
		} else {
			writef("%.0f",
			       b.level);
		}
		if(customize) {
			write(thresholds[min][1]);
		}
		exit(0);
	}

	void status() {
		Battery b;
		try {
			b = new Battery(battery_name);
		} catch (BatteryException e) {
			writeln("Exception:", e.msg);
			exit(-1);
		}
		switch(b.status) with(BatteryStatus) {
			case DISCHARGING:
				write("Discharging");
				break;
			case CHARGING:
				write("Charging");
				break;
			case FULL:
				write("Full");
				break;
			default: break;
		}
		exit(0);
	}

	void time() {
		Battery b;
		try {
			b = new Battery(battery_name);
		} catch (BatteryException e) {
			writeln("Error: ", e.msg);
			exit(-1);
		}
		switch(b.status) with(BatteryStatus) {
			case DISCHARGING:
				auto s = b.timeRemaining.split!("hours", "minutes", "seconds");
				writef("%02d:%02d:%02d", s.hours, s.minutes, s.seconds);
				break;
			case CHARGING:
				auto s = b.timeUntilFull
					.split!("hours", "minutes", "seconds");
				writef("%02d:%02d:%02d",
					s.hours,
					s.minutes,
					s.seconds);
				break;
			default:
				break;
		}
		exit(0);
	}

	auto result = getopt(
		args,
		std.getopt.config.bundling,
		"battery", "specify battery name", &battery_name,
		"verbose|v", "show all fields", &verbose,
		"customize|c", "customize output of -p", &customize,
		"threshold", "custom thresholds", &thresholds,
		"percent|p", "print percent and exit", &percent,
		"status|s", "print status(discharging, charging, full) and exit", &status,
		"time|t", "print time remaining or until charged and exit", &time
);

	if(result.helpWanted) {
		defaultGetoptPrinter("battery-d - simple way to get battery info", result.options);
		exit(0);
	}

	Battery b;
	try {
		b = new Battery(battery_name);
	} catch (BatteryException e) {
		writeln("Exception:", e.msg);
		exit(-1);
	}
	b.showInfo;
	if(verbose)
		b.showRaw;

	return 0;
}
