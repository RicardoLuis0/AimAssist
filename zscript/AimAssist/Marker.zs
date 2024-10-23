class AimAssistDebugMaker1:Actor{
	Default{
		+NOINTERACTION
		+FORCEXYBILLBOARD
		+NOSAVEGAME
		FloatBobPhase 0;
	}
	States{
		Spawn:
			MARK A -1 BRIGHT;
			Stop;
	}
}

class AimAssistDebugMaker2:AimAssistDebugMaker1{
	States{
		Spawn:
			MARK B -1 BRIGHT;
			Stop;
	}
}

class AimAssistDebugMaker3:AimAssistDebugMaker1{
	States{
		Spawn:
			MARK C -1 BRIGHT;
			Stop;
	}
}

class AimAssistDebugMaker4:AimAssistDebugMaker1{
	States{
		Spawn:
			MARK D -1 BRIGHT;
			Stop;
	}
}