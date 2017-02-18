module battery.d;

import std.experimental.logger;
import core.time : Duration, dur;

enum BatteryStatus : ubyte {
	DISCHARGING,
	CHARGING,
	FULL
}

class Battery(bool UpdateOnRead = false) {
	private {
		string bname;
		string[string] rawdata;
		float lvl;
		Duration untilfull;
		Duration untilempty;
		BatteryStatus stat;
	}

	this(string battery_name) {
		this.bname = battery_name;
		this.update;
	}

	this() {
		import std.file : dirEntries, SpanMode;
		import std.algorithm : filter, startsWith;
		import std.path : baseName;
		this("/sys/class/power_supply".dirEntries(SpanMode.shallow)
			.filter!(a => a.name.baseName.startsWith("BAT"))
			.front
			.baseName);
	}

	void update() {
		import std.stdio : File;
		import std.array : split, replaceFirst;
		import std.conv : to, parse;
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
			rate = this.rawdata["CURRENT_NOW"].parse!size_t;
			full = this.rawdata["CHARGE_FULL"].parse!size_t;
			curr = this.rawdata["CHARGE_NOW"].parse!size_t;
		} catch (RangeError e) {
			rate = this.rawdata["POWER_NOW"].parse!size_t;
			full = this.rawdata["ENERGY_FULL"].parse!size_t;
			curr = this.rawdata["ENERGY_NOW"].parse!size_t;
		}

		this.lvl = (float(curr) / full) * 100;

		if(rate) {
			switch(this.rawdata["STATUS"]) {
			case "Discharging":
				this.untilempty = ((float(curr) / rate) * 3600)
					.to!long
					.dur!"seconds";
				this.untilfull = Duration.zero;
				this.stat = BatteryStatus.DISCHARGING;
				break;
			case "Charging":
				this.untilempty = Duration.zero;
				this.untilfull = ((float(full - curr) / rate) * 3600)
					.to!long
					.dur!"seconds";
				this.stat = BatteryStatus.CHARGING;
				break;
			case "Full":
				this.stat = BatteryStatus.FULL;
				goto default;
			default:
				this.untilempty = Duration.zero;
				this.untilfull = Duration.zero;
				break;
			}
		} else {
			this.untilempty = Duration.zero;
			this.untilfull = Duration.zero;
		}
	}

	float level() {
		return this.lvl;
	}

	Duration timeUntilFull() {
		return this.untilfull;
	}

	Duration timeUntilEmpty() {
		return this.untilempty;
	}

	BatteryStatus status() {
		return this.stat;
	}
}