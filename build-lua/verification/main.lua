local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local bint = require('verification.utils.bint')(2048, 32)
local json = require('json')









ValidateCheckpointData = {}






ResponseData = {}






Name = Name or "Verifier"
Description = Description or "RandAO Verification Process"
TotalSquarings = 1000000
NumSegments = 10
Exponent = 2
SuccessMessage = "200: Success"


function sendResponse(target, action, data)
   return {
      Target = target,
      Action = action,
      Data = json.encode(data),
   }
end


local function infoHandler(msg)
   ao.send({
      Target = msg.From,
      Name = Name,
      Description = Description,
   })
end

function computedCheckpointOutput(input, modulus, expectedOutput)
   print("entered")
   assert((TotalSquarings % NumSegments == 0), "Failure: Total Squarings and Number of Segments")
   local segmentLength = TotalSquarings / NumSegments
   print("Segment Length: " .. json.encode(segmentLength))

   local bintInput = bint.fromstring(input)
   print("Input: " .. json.encode(bint.tobase(bintInput, 10, true)))

   local updatedResult = bintInput

   local bintModulus = bint.fromstring(modulus)
   print("Modulus: " .. json.encode(bint.tobase(bintModulus, 10, true)))

   local bintExpectedOutput = bint.fromstring(expectedOutput)
   print("Expected Output: " .. json.encode(bint.tobase(bintExpectedOutput, 10, true)))

   for _ = 1, segmentLength do
      updatedResult = bint.upowmod(bintInput, bint.frominteger(2), bintModulus)

   end

   if bint.eq(updatedResult, bintExpectedOutput) then
      print("matched")
      return true, ""
   else
      print("failed")
      return false, "Failure: Expected =/= Computed Output"
   end
end

local function validateCheckpointHandler(msg)
   print("entered checkpoint")
   local data = (json.decode(msg.Data))
   local request_id = data.request_id
   local checkpoint_input = data.checkpoint_input
   local modulus = data.modulus
   local expected_output = data.expected_output

   local success, err = computedCheckpointOutput(checkpoint_input, modulus, expected_output)

   if success then
      ao.send(sendResponse(msg.From, "Valid ", SuccessMessage))
   else
      ao.send(sendResponse(msg.From, "Error", { message = "Failed to post VDF Input: " .. err }))
   end
end


Handlers.add('info', Handlers.utils.hasMatchingTag('Action', 'Info'), infoHandler)
Handlers.add('validateCheckpoint', Handlers.utils.hasMatchingTag('Action', 'Validate-Checkpoint'), validateCheckpointHandler)
