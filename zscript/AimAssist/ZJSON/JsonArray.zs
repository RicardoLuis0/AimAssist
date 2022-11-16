class AimAssist_JsonArray : AimAssist_JsonElement { // pretty much just a wrapper for a dynamic array
	Array<AimAssist_JsonElement> arr;
	
	static AimAssist_JsonArray make(){
		return new("AimAssist_JsonArray");
	}
	
	AimAssist_JsonElement get(uint index){
		return arr[index];
	}
	
	void set(uint index,AimAssist_JsonElement obj){
		arr[index]=obj;
	}
	
	int push(AimAssist_JsonElement obj){
		return arr.push(obj);
	}
	
	bool pop(){
		return arr.pop();
	}
	
	void insert(uint index,AimAssist_JsonElement obj){
		arr.insert(index,obj);
	}
	
	void delete(uint index,int count=1){
		arr.delete(index,count);
	}
	
	uint size(){
		return arr.size();
	}
	
	void shrinkToFit(){
		arr.shrinkToFit();
	}
	
	void grow(uint count){
		arr.grow(count);
	}
	
	void resize(uint count){
		arr.resize(count);
	}
	
	void reserve(uint count){
		arr.reserve(count);
	}
	
	int max(){
		return arr.max();
	}
	
	void clear(){
		arr.clear();
	}
	
	override string serialize(){
		String s;
		bool first=true;
		s.AppendCharacter(AimAssist_JSON.SQUARE_OPEN);
		for(uint i=0;i<arr.size();i++){
			if(!first){
				s.AppendCharacter(AimAssist_JSON.COMMA);
			}
			s.AppendFormat("%s",arr[i].serialize());
			first=false;
		}
		s.AppendCharacter(AimAssist_JSON.SQUARE_CLOSE);
		return s;
	}
}