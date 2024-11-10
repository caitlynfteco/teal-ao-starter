local bint = require('verification.utils.bint')(2048, 32)
local json = require('json')

-- Define types
global Name: string
global Description: string
global TotalSquarings: number
global NumSegments: number
global Exponent: integer
global SuccessMessage: string

global record ValidateCheckpointData 
  request_id: integer
  checkpoint_input: string
  modulus: string
  expected_output: string
end

global record ResponseData
  Target: string
  Action: string
  Data: string
end

-- Initialize global variables
Name = Name or "Verifier"
Description = Description or "RandAO Verification Process"
TotalSquarings = 1000000
NumSegments = 10
Exponent = 2
SuccessMessage = "200: Success"

-- Helper function to send a response
global function sendResponse(target: string, action: string, data: any): ResponseData
  return {
    Target = target,
    Action = action,
    Data = json.encode(data)
  }
end

-- Handler functions
local function infoHandler(msg: Message)
  ao.send({
    Target = msg.From,
    Name = Name,
    Description = Description
  })
end

global function computedCheckpointOutput(input: string, modulus: string, expectedOutput: string): boolean, string
  print("entered")
  assert((TotalSquarings % NumSegments == 0), "Failure: Total Squarings and Number of Segments")
  local segmentLength = TotalSquarings / NumSegments
  print("Segment Length: " .. json.encode(segmentLength))

  local bintInput = bint.fromstring(input)
  print("Input: " .. json.encode(bint.tobase(bintInput, 10, true)))

  local updatedResult: BigInteger = bintInput

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

local function validateCheckpointHandler(msg: Message)
  print("entered checkpoint")
  local data = (json.decode(msg.Data as string) as ValidateCheckpointData)
  local request_id = data.request_id
  local checkpoint_input = data.checkpoint_input
  local modulus = data.modulus
  local expected_output = data.expected_output

  local success, err = computedCheckpointOutput(checkpoint_input, modulus, expected_output)
  
  if success then
    ao.send(sendResponse(msg.From, "Valid ", SuccessMessage))
  else
    ao.send(sendResponse(msg.From, "Error", {message = "Failed to post VDF Input: " .. err}))
  end
end

-- Add handlers
Handlers.add('info', Handlers.utils.hasMatchingTag('Action', 'Info'), infoHandler)
Handlers.add('validateCheckpoint', Handlers.utils.hasMatchingTag('Action', 'Validate-Checkpoint'), validateCheckpointHandler)