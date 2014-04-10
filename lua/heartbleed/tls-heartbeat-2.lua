-- tls-heartbleed.lua
--
-- Detects TLS heartbeats 
--	alert if you see a heartbeat  mismatch 
-- 
-- content types in 
-- http://www.iana.org/assignments/tls-parameters/tls-parameters.xhtml#tls-parameters-5
--
-- Remember -> you cant look inside the heartbeat (it is encrypted) 
-- 

TrisulPlugin = {

  id = {
    name = "TLS Heartbleed ",
    description = "Log req/resp in one line ",
    author = "trisul-scripts", version_major = 1, version_minor = 0,
  },

  onload = function()
	pending_hb_requests = { } 
  end,


  flowmonitor  = {

	onflowattribute = function(engine,flow,timestamp, nm, valbuff)

	     if nm == "TLS:RECORD" then
		 	local  content_type = valbuff:hval_8(0)

			if content_type == 24 then
				local req_len  = pending_hb_requests[flow:id()]

				-- found pending inflight request, compare sizes and alert 
				if req_len  then 

					if req_len ~= valbuff:size()  then

						engine:add_alert_full( 
						"{9AFD8C08-07EB-47E0-BF05-28B4A7AE8DC9}", -- GUID for IDS 
						flow:id(), 								  -- flow 
						"sid-8000002",							  -- a sigid (private range)
						"trisul-lua-gen",			  			  -- classification
						"sn-1",                                   -- priority 1, 
						"Possible heartbleed situation ")		  -- message 

					end
					pending_hb_requests[flow:id()] = nil 
				else
					-- save size of inflight  TLS hb request 
					pending_hb_requests[flow:id()] = valbuff:size()
				end
			end

	 	 elseif  nm == "^D" then 
		 	-- connection closed, free up map so it can be garbage collected 
		 	pending_hb_requests[flow:id()]=nil 
		 end
		 
    end,

  },

}