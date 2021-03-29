class OptionMenuItemReverseSlider : OptionMenuCheckSliderBase {
	
	CVar mCVar;
	double mInterval;
	
	OptionMenuItemReverseSlider Init(String label, Name command, double min, double max, double step, int showval = 1, CVar graycheck = NULL) {
		mInterval = max - min;
		Super.Init(label, 0, mInterval, step, showval, command, graycheck);
		mCVar = CVar.FindCVar(command);
		return self;
	}
	
	override double GetSliderValue() {
		if (mCVar != null) {
			return 0 - (mCVar.GetFloat() - mInterval);
		} else {
			return 0;
		}
	}
	
	override void SetSliderValue(double val) {
		if (mCVar != null) {
			mCVar.SetFloat(mMin + (mInterval - val));
		}
	}
	
	override double GetSliderTextValue() {
		if (mCVar != null) {
			return mCVar.GetFloat();
		} else {
			return 0;
		}
	}
}
