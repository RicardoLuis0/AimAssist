class AimAssist_JsonObjectElement {
	String key;
	AimAssist_JsonElement e;
	
	static AimAssist_JsonObjectElement make(String key,AimAssist_JsonElement e){
		AimAssist_JsonObjectElement elem=new("AimAssist_JsonObjectElement");
		elem.key=key;
		elem.e=e;
		return elem;
	}
}

class AimAssist_JsonObjectKeys {
	Array<String> keys;
}

class AimAssist_JsonObject : AimAssist_JsonElement {
	const table_size = 256; // rather small for a general hash table, but should be enough for a json object
	private Array<AimAssist_JsonObjectElement> table[table_size];
	private uint elems;
	
	static AimAssist_JsonObject make(){
		return new("AimAssist_JsonObject");
	}
	
	private uint hash(String s){ // djb2 hashing algorithm
		uint h=5381;
		for(uint i=0;i<s.length();i++){
			h=(h*33)+s.byteat(i);
		}
		return h;
	}
	
	private AimAssist_JsonElement getFrom(out Array<AimAssist_JsonObjectElement> arr,String key){
		for(uint i=0;i<arr.size();i++){
			if(arr[i].key==key){
				return arr[i].e;
			}
		}
		return null;
	}
	
	private bool setAt(out Array<AimAssist_JsonObjectElement> arr,String key,AimAssist_JsonElement e,bool replace){
		for(uint i=0;i<arr.size();i++){
			if(arr[i].key==key){
				if(replace){
					arr[i].e=e;
				}
				return replace;
			}
		}
		arr.push(AimAssist_JsonObjectElement.make(key,e));
		elems++;
		return true;
	}
	
	private bool delAt(out Array<AimAssist_JsonObjectElement> arr,String key){
		for(uint i=0;i<arr.size();i++){
			if(arr[i].key==key){
				arr.delete(i);
				elems--;
				return true;
			}
		}
		return false;
	}
	
	AimAssist_JsonElement get(String key){
		uint sz=table_size;
		return getFrom(table[hash(key)%sz],key);
	}
	
	void set(String key,AimAssist_JsonElement e){
		uint sz=table_size;
		setAt(table[hash(key)%sz],key,e,true);
	}
	
	bool insert(String key,AimAssist_JsonElement e){//only inserts if key doesn't exist, otherwise fails and returns false
		uint sz=table_size;
		return setAt(table[hash(key)%sz],key,e,false);
	}
	
	bool delete(String key){
		uint sz=table_size;
		return delAt(table[hash(key)%sz],key);
	}
	
	AimAssist_JsonObjectKeys getKeys(){
		AimAssist_JsonObjectKeys keys = new("AimAssist_JsonObjectKeys");
		for(uint i=0;i<table_size;i++){
			for(uint j=0;j<table[i].size();j++){
				keys.keys.push(table[i][j].key);
			}
		}
		return keys;
	}
	
	bool empty(){
		return elems==0;
	}
	
	void clear(){
		for(uint i=0;i<table_size;i++){
			table[i].clear();
		}
	}
	
	uint size(){
		return elems;
	}
	
	override string serialize(){
		String s;
		s.AppendCharacter(AimAssist_JSON.CURLY_OPEN);
		bool first=true;
		for(uint i=0;i<table_size;i++){
			for(uint j=0;j<table[i].size();j++){
				if(!first){
					s.AppendCharacter(AimAssist_JSON.COMMA);
				}
				s.AppendFormat("%s:%s",AimAssist_JSON.serialize_string(table[i][j].key),table[i][j].e.serialize());
				first=false;
			}
		}
		s.AppendCharacter(AimAssist_JSON.CURLY_CLOSE);
		return s;
	}
}
