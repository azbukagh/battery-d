import std.stdio;
import battery.d;

void main() {
	auto b = new Battery!()();
	switch(b.status) with(BatteryStatus) {
		case DISCHARGING:
			writefln("Discharging, %.1f%%, %s remaining",
				b.level,
				b.timeUntilEmpty.toString);
			break;
		case CHARGING:
			writefln("Charging, %.1f%%, %s until charged",
				b.level,
				b.timeUntilFull.toString);
			break;
		case FULL:
			writefln("Full, %.1f%%",
				 b.level);
			break;
		default: break;
	}
}
