module battery.d;

import core.time : Duration, dur;

enum BatteryStatus : ubyte {
	DISCHARGING,
	CHARGING,
	FULL
}

auto getBatteryList() {
	import std.file : dirEntries, SpanMode;
	import std.algorithm : map, filter, startsWith;
	import std.path : baseName;
	return "/sys/class/power_supply".dirEntries(SpanMode.shallow)
		.map!(a => a.name.baseName)
		.filter!(a => a.startsWith("BAT"));
}


class BatteryException : Exception {
	pure nothrow @nogc @safe this(string msg,
		string file = __FILE__,
		size_t line = __LINE__,
		Throwable next = null) {
			super(msg, file, line, next);
	}
}

class Battery {
	private {
		string bname;
		string[string] rawdata;
		float lvl;
		Duration untilfull;
		Duration remaining;
		BatteryStatus stat;
	}

	this(string battery_name) {
		import std.file : exists;
		if(!("/sys/class/power_supply/" ~ battery_name).exists)
			throw new BatteryException("There is no such battery");
		this.bname = battery_name;
		this.update;
	}

	this() {
		this(getBatteryList.front);
	}

	void update() {
		import std.stdio : File;
		import std.array : split, replaceFirst;
		import std.conv : to;
		import core.exception : RangeError;

		auto f = File("/sys/class/power_supply/" ~ this.bname ~ "/uevent");
		foreach(line; f.byLine) {
			auto s = line.split("=");
			this.rawdata[s[0]
				     .replaceFirst("POWER_SUPPLY_", "")
				     .to!string] = s[1].to!string;
		}

		size_t rate, full, curr;
		try {
			rate = this.rawdata["CURRENT_NOW"].to!size_t;
			full = this.rawdata["CHARGE_FULL"].to!size_t;
			curr = this.rawdata["CHARGE_NOW"].to!size_t;
		} catch (RangeError e) {
			rate = this.rawdata["POWER_NOW"].to!size_t;
			full = this.rawdata["ENERGY_FULL"].to!size_t;
			curr = this.rawdata["ENERGY_NOW"].to!size_t;
		}

		this.lvl = (float(curr) / full) * 100;

		if(rate) {
			switch(this.rawdata["STATUS"]) {
			case "Discharging":
				this.remaining = ((float(curr) / rate) * 3600)
					.to!long
					.dur!"seconds";
				this.untilfull = Duration.zero;
				this.stat = BatteryStatus.DISCHARGING;
				break;
			case "Charging":
				this.remaining = Duration.zero;
				this.untilfull = ((float(full - curr) / rate) * 3600)
					.to!long
					.dur!"seconds";
				this.stat = BatteryStatus.CHARGING;
				break;
			case "Full":
				this.stat = BatteryStatus.FULL;
				goto default;
			default:
				this.remaining = Duration.zero;
				this.untilfull = Duration.zero;
				break;
			}
		} else {
			this.remaining = Duration.zero;
			this.untilfull = Duration.zero;
		}
	}

	float level() {
		return this.lvl;
	}

	Duration timeUntilFull() {
		return this.untilfull;
	}

	Duration timeRemaining() {
		return this.remaining;
	}

	BatteryStatus status() {
		return this.stat;
	}

	string[string] raw() {
		return this.rawdata;
	}

	string name() {
		return this.bname;
	}
}
