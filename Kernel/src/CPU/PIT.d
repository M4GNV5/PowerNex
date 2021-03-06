module CPU.PIT;

import CPU.IDT;
import IO.Port;
import IO.Log;
import Data.Register;
import Task.Process;
import Task.Scheduler;

struct PIT {
public:
	static void Init(uint hz = 1000) {
		IDT.Register(IRQ(0), &onTick);
		this.hz = hz;
		uint divisor = 1193180 / hz;
		Out!ubyte(0x43, 0x36);

		ubyte l = cast(ubyte)(divisor & 0xFF);
		ubyte h = cast(ubyte)((divisor >> 8) & 0xFF);

		Out!ubyte(0x40, l);
		Out!ubyte(0x40, h);
	}

	static @property ulong Seconds() {
		if (hz)
			return counter / hz;
		return 0;
	}

	static void Clear() {
		counter = 0;
	}

private:
	__gshared bool enabled;
	__gshared uint hz;
	__gshared ulong counter;
	static void onTick(Registers* regs) {
		import Memory.FrameAllocator;
		import Task.Scheduler : GetScheduler;
		import Data.TextBuffer : scr = GetBootTTY;

		counter++;

		GetScheduler.WakeUp(WaitReason.Timer, &wakeUpTimedSleep);
		GetScheduler.SwitchProcess(true);
	}

	static bool wakeUpTimedSleep(Process* p, void* data) {
		p.waitData--;
		if (p.waitData == 0)
			return true;
		return false;
	}
}
