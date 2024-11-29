component name="xaiapi"{
	variables.api_key 		= "";
	variables.base_url		= "https://api.x.ai/";
	variables.api_version 	= "v1";

	public Grok function init(
		required string api_key
	){

		for(local.key in arguments){
			if(arguments.keyExists(key) && variables.keyExists(key)){
				variables[key] = arguments[key];
			}
		}

		return this;
	}

	/**
	*	api_request() - main function to communicate with api
	*	@endpoint - api endpoint, in the format of "chat/completions"
	*	@method - http verb
	*	@request - body request struct, will be converted to JSON
	**/
	public struct function api_request(
		required string endpoint,
		required string method = "get",
		required struct request = {}
	){
		local.return_data = {
			api_request: {
				"endpoint": arguments.endpoint,
				"method": arguments.method,
				"request": arguments.request
			},
			api_response: {},
			raw_response: {},
			errors:[]
		};

		try {
			local.api_call = new http(
				method: arguments.method,
				charset: "utf-8",
				url: generate_api_url(arguments.endpoint)
			);

			local.api_call.addParam(type="header", name="Content-Type", value="application/json");
			local.api_call.addParam(type="header", name="Authorization", value="Bearer " & variables.api_key );
			local.api_call.addParam(type="body", value=serializeJSON(arguments.request));

			local.return_data.raw_response = local.api_call.send().getPrefix();
			
			local.return_data.api_response = deserializeJSON(local.return_data.raw_response.fileContent);

			if(!local.return_data.raw_response.keyExists("statusCode") || !local.return_data.raw_response.statusCode.findNoCase("200 ok")){
				local.return_data.errors.append( (local.return_data.api_response.keyExists("error")) ? local.return_data.api_response.error : "Error contacting api service" );		
			}
		}
		catch(any err){
			local.return_data.errors.append(err.message & " - " & err.detail);
		}

		return local.return_data;
	}

	/**
	*	crrate_embedding() - Create an embedding vector representation corresponding to the input text
	**/
	public struct function create_embedding(
		required string model_id,
		required any input,
		integer dimensions,
		string encoding_format,
		string user_id
	){
		local.request = {
			"model_id": arguments.model_id,
			"input": arguments.input
		};

		if(arguments.keyExists("dimensions")){
			local.request.append({"dimensions": arguments.dimensions});
		}

		if(arguments.keyExists("encoding_format") && listFindNoCase("float,base64", arguments.encoding_format)){
			local.request.append({"encoding_format": arguments.encoding_format});
		}

		if(arguments.keyExists("user_id")){
			local.request.append({"user": arguments.user});
		}

		return api_request(
			endpoint="embeddings",
			method="post",
			request=local.request
		);
	}

	/**
	*	list_embedding_models() - list embedding models
	**/
	public struct function list_embedding_models(){
		return api_request(endpoint: "embedding-models");
	}

	/**
	*	get_embedding_model() - get a specific embedding model
	*	@model_id - id of embedding model, returned from list_embedding_models
	**/
	public struct function get_embedding_model(
		required string model_id
	){
		return api_request(endpoint: "embedding-models/" & arguments.model_id);
	}

	/**
	*	list_language_models() - list language models
	**/
	public struct function list_language_models(){
		return api_request(endpoint: "language-models");
	}

	/**
	*	get_language_model() - get a specific language model
	*	@model_id - id of language model, returned from list_language_models
	**/
	public struct function get_language_model(
		required string model_id
	){
		return api_request(endpoint: "language-models/" & arguments.model_id);
	}

	/**
	*	list_models() - get all models
	**/
	public struct function list_models(){
		return api_request(endpoint: "models");
	}

	/**
	*	get_model() - get a specific model
	*	@model_id - id of model, returned from list_models
	**/
	public struct function get_model(
		required string model_id
	){
		return api_request(endpoint: "models/" & arguments.model_id);
	}

	/**
	*	generate_api_url() - helper function to generate api url for call
	*	@endpoint - api endpoint from https://docs.x.ai/api/endpoints
	**/
	private string function generate_api_url(
		required string endpoint
	){
		return ((variables.base_url.right(1) == "/") ? variables.base_url : variables.base_url & "/") 
			& ((variables.api_version.right(1) == "/") ? variables.api_version : variables.api_version & "/")
			& arguments.endpoint;

	}
}