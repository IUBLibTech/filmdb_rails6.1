xml.instruct! :xml, :version=>"1.0"
xml.filmDb do
	xml.success @success
	xml.message @msg
	xml.request do
		xml.note "The 'request' node will not be in the final version. It's only here for checking that what filmdb received is in fact what POD sent."
		xml.whatWasReceived request.body.read
	end
	xml.error "This xml element will only be present when the above 'success' element is false. It will contain a message stating why filmdb was unable to update the batch specified"
end