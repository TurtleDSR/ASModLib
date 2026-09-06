import Peanuts.ButtonMash.ButtonMashWidget;
import Peanuts.ButtonMash.ButtonMashHandleBase;

const FConsoleVariable CVar_ButtonMashAutoPass("Haze.ButtonMashAutoPass", 0);
const FConsoleVariable CVar_ButtonMashBoost_May("Haze.ButtonMashBoost_May", 0.f);
const FConsoleVariable CVar_ButtonMashBoost_Cody("Haze.ButtonMashBoost_Cody", 0.f);

class UButtonMashComponent : UActorComponent
{
	// Capability-classes that are overridden in blueprint
	UPROPERTY(Category = "Capability Classes")
	TSubclassOf<UHazeCapability> DefaultCapabilityClass;

	UPROPERTY(Category = "Capability Classes")
	TSubclassOf<UHazeCapability> ProgressCapabilityClass;

	UButtonMashHandleBase CurrentButtonMash;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Variables for calculating button mash rate
	float TimingWindow = 0.5f;
	float MashTimer = 0.f;

	int PrevMashCount = 0;
	int MashCount = 0;

	void ResetMashRate()
	{
		PrevMashCount = 0;
		MashCount = 0;
		MashTimer = 0.f;
	}

	void StartButtonMash(UButtonMashHandleBase ButtonMash)
	{
		CurrentButtonMash = ButtonMash;
		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CurrentButtonMash == nullptr)
		{
			SetComponentTickEnabled(false);
			return;
		}

		// Auto-mash when the console variable for it is set to on
		if (CVar_ButtonMashAutoPass.GetInt() != 0)
			MashCount += 1;

		MashTimer += DeltaTime;

		// When a window is filled, copy it over and start a new one
		if (MashTimer >= TimingWindow)
		{
			PrevMashCount = MashCount;
			MashCount = 0;
			MashTimer -= TimingWindow;
		}

		// Phase over from the previous window to the next window as it gets more accurate over time
		float PrevRate = GetRatePerSecond(PrevMashCount, TimingWindow);
		float CurRate = GetRatePerSecond(MashCount, MashTimer);

		// Apply the button mash boost
		float Boost = (Owner == Game::May) ? CVar_ButtonMashBoost_May.GetFloat() : CVar_ButtonMashBoost_Cody.GetFloat();
		if (Boost > 0.01f)
		{
			if (PrevMashCount >= 1)
			{
				// If we pressed a button previously, keep the minimum boosted mash rate now as well
				PrevRate = FMath::Max(PrevRate, Boost);
				CurRate = FMath::Max(CurRate, Boost);
			}
			else if (MashCount >= 1)
			{
				// We didn't press before, but we are pressing now, so keep the boosted rate
				CurRate = FMath::Max(CurRate, Boost);
			}
		}

		CurrentButtonMash.MashRateControlSide = FMath::Lerp(PrevRate, CurRate, MashTimer / TimingWindow);
	}

	void DoMashPulse()
	{
		MashCount++;
	}

	private float GetRatePerSecond(int Presses, float Time)
	{
		// Dont divide by 0
		if (Time == 0.f)
			return 0.f;

		return Presses / Time;
	}
}