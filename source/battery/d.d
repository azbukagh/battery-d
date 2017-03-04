/**
 * battery-d - simple library for reading battery info on linux laptops.
 * License: MIT
 * Copyright: Copyright © 2017, Azbuka
 * Authors: Azbuka
 */
module battery.d;

import core.time : Duration, dur;

/**
 * Current battery status
 */
enum BatteryStatus : ubyte {
	/// Discharging
	DISCHARGING,
	/// Charging
	CHARGING,
	/// Full (100%)
	FULL
}

/**
 * Gets list of all aviable batteries in system
 * Examples:
 * ---
 * import std.array;
 * import battery.d;
 * getBatteryList().array; // ["BAT0"], laptops in general have only 1 battery
 * getBatteryList().front; // "BAT1"
 * ---
 * Returns: range of battery names
 */
auto getBatteryList() {
	import std.file : dirEntries, SpanMode;
	import std.algorithm : map, filter, startsWith;
	import std.path : baseName;
	return "/sys/class/power_supply".dirEntries(SpanMode.shallow)
		.map!(a => a.name.baseName)
		.filter!(a => a.startsWith("BAT"));
}

/**
 * Battery exception. Thrown on errors.
 */
class BatteryException : Exception {
	pure nothrow @nogc @safe this(string msg,
		string file = __FILE__,
		size_t line = __LINE__,
		Throwable next = null) {
			super(msg, file, line, next);
	}
}

/**
 * Main battery class
 */
class Battery {
	private {
		string bname;
		string[string] rawdata;
		float lvl;
		Duration untilfull;
		Duration remaining;
		BatteryStatus stat;
	}

	/**
	 * Constructor.
	 * Params:
	 *  battery_name = name of battery (example: BAT0)
	 * Throws: BatteryException if there is no such battery
	 */
	this(string battery_name) {
		import std.file : exists;
		if(!("/sys/class/power_supply/" ~ battery_name).exists)
			throw new BatteryException("There is no such battery");
		this.bname = battery_name;
		this.update;
	}

	/**
	 * Cunstructor. Uses first battery, returned by `getBatteryList()`
	 * Throws: battery exception, if no batteries found
	 */
	this() {
		auto a = getBatteryList;
		if(a.empty)
			throw new BatteryException("Battery not found");
		this(a.front);
	}

	/**
	 * Updates battery info
	 */
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

	/**
	 * Current battery level. 0-100%
	 * Returns: current battery level in %
	 */
	float level() {
		return this.lvl;
	}

	/**
	 * Time until battery is full.
	 * `Duration.zero` if battery full or discharging.
	 * Returns: time until battery is full
	 */
	Duration timeUntilFull() {
		return this.untilfull;
	}

	/**
	 * Time remaining.
	 * `Duration.zero` if battery full or charging.
	 * Returns: time remaining
	 */
	Duration timeRemaining() {
		return this.remaining;
	}

	/**
	 * Current battery status.
	 * Returns: battery status
	 */
	BatteryStatus status() {
		return this.stat;
	}

	/**
	 * Raw battery data.
	 * Returns: raw battery data
	 */
	string[string] raw() {
		return this.rawdata;
	}

	/**
	 * Battery name.
	 * Returns: battery name
	 */
	string name() {
		return this.bname;
	}
}
