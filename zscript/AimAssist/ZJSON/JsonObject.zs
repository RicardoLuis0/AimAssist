class AimAssist_JsonObject : AimAssist_JsonElement {
	Map<String,AimAssist_JsonElement> data;
	
	static AimAssist_JsonObject make(){
		return new("AimAssist_JsonObject");
	}
	
	AimAssist_JsonElement Get(String key){
		return data.Get(key);
	}
	
	void Set(String key,AimAssist_JsonElement e){
		data.Insert(key,e);
	}
	
	bool Insert(String key,AimAssist_JsonElement e){//only inserts if key doesn't exist, otherwise fails and returns false
		if(data.CheckKey(key)) return false;
		data.Insert(key,e);
		return true;
	}
	
	bool Delete(String key){
		if(!data.CheckKey(key)) return false;
		data.Remove(key);
		return true;
	}
	
	void GetKeys(out Array<String> keys){
		keys.Clear();
		MapIterator<String,AimAssist_JsonElement> it;
		it.Init(data);
		while(it.Next()){
			keys.Push(it.GetKey());
		}
	}
	
	bool IsEmpty(){
        return data.CountUsed() == 0;
	}
	
	void Clear(){
		data.Clear();
	}
	
	uint Size(){
        return data.CountUsed();
	}
	
	override string serialize(){
		String s;
		s.AppendCharacter(AimAssist_JSON.CURLY_OPEN);
		bool first = true;
		
		MapIterator<String,AimAssist_JsonElement> it;
		it.Init(data);
		
		while(it.Next()){
			if(!first){
				s.AppendCharacter(AimAssist_JSON.COMMA);
			}
			s.AppendFormat("%s:%s", AimAssist_JSON.serialize_string(it.GetKey()), it.GetValue().serialize());
			first = false;
		}
		
		s.AppendCharacter(AimAssist_JSON.CURLY_CLOSE);
		return s;
	}
    
	override string GetPrettyName() {
		return "Object";
	}
}
