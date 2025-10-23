local M = {}
local config = require('rover.config')

local doc_cache = {}

M.generate_docs = function(keyword, language, hover_docs, callback)
	if not config.config.api_key then
		vim.notify("Rover: API key not configured", vim.log.levels.ERROR)
		return
	end

	local use_cache = not hover_docs or hover_docs == ""
	local cache_key = keyword .. "|" .. language
	if use_cache and doc_cache[cache_key] then
		callback(doc_cache[cache_key])
		return
	end

	local context = hover_docs and hover_docs ~= "" and ("Context from LSP hover:\n" .. hover_docs .. "\n\n") or ""
	local prompt = string.format([[%sGenerate Rust-style technical documentation for: "%s" in %s.

Format your response EXACTLY like this (use proper markdown with code blocks):



4-5 sentence description of what this is and what it does and its application.

----------------------------------------------------------------------------------------------------


### Syntax

```%s
[general syntax and usage]
```


### Example 1

```%s
[brief example 1]
```

### Example 2

```%s
[brief example 2]
```

IMPORTANT: Preserve all the empty lines and spacing exactly as shown above. Do not collapse or remove any blank lines.]],
		context, keyword, language, language, language,
		language)

	local url = string.format(
		"https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
		config.config.model,
		config.config.api_key
	)

	local data = vim.json.encode({
		contents = {
			{
				parts = {
					{ text = prompt }
				}
			}
		}
	})

	local curl_command = string.format(
		"curl -s -X POST '%s' -H 'Content-Type: application/json' -d '%s'",
		url,
		data:gsub("'", "'\\''")
	)

	vim.fn.jobstart(curl_command, {
		stdout_buffered = true,
		on_stdout = function(_, data_lines)
			if data_lines then
				local response_text = table.concat(data_lines, "\n")
				local ok, response = pcall(vim.json.decode, response_text)

				if ok and response.candidates and response.candidates[1] then
					local content = response.candidates[1].content
					if content and content.parts and content.parts[1] then
						local doc_text = content.parts[1].text
						if use_cache then
							doc_cache[cache_key] = doc_text
						end
						callback(doc_text)
						return
					end
				end

				callback("Error: Failed to parse API response")
			end
		end,
		on_stderr = function(_, data_lines)
			if data_lines and #data_lines > 0 then
				vim.notify("Rover API Error: " .. table.concat(data_lines, "\n"), vim.log.levels.ERROR)
			end
		end,
		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				callback("Error: API request failed with exit code " .. exit_code)
			end
		end,
	})
end

M.ask_question = function(question, callback)
	if not config.config.api_key then
		vim.notify("Rover: API key not configured", vim.log.levels.ERROR)
		return
	end

	local prompt = string.format([[Generate Rust-style technical documentation for the question: "%s"

Format your response EXACTLY like this (use proper markdown with code blocks):



4-5 sentence description of what this is and what it does and where it comes from and what is the best application of it.

----------------------------------------------------------------------------------------------------



### Syntax

```
[general syntax and usage]
```


### Example 1

```
[detailed example 1]
```

### Example 2

```
[detailed example 2]
```

IMPORTANT: Preserve all the empty lines and spacing exactly as shown above. Do not collapse or remove any blank lines.]],
		question)

	local url = string.format(
		"https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s",
		config.config.model,
		config.config.api_key
	)

	local data = vim.json.encode({
		contents = {
			{
				parts = {
					{ text = prompt }
				}
			}
		}
	})

	local curl_command = string.format(
		"curl -s -X POST '%s' -H 'Content-Type: application/json' -d '%s'",
		url,
		data:gsub("'", "'\\''")
	)

	vim.fn.jobstart(curl_command, {
		stdout_buffered = true,
		on_stdout = function(_, data_lines)
			if data_lines then
				local response_text = table.concat(data_lines, "\n")
				local ok, response = pcall(vim.json.decode, response_text)

				if ok and response.candidates and response.candidates[1] then
					local content = response.candidates[1].content
					if content and content.parts and content.parts[1] then
						local answer_text = content.parts[1].text
						callback(answer_text)
						return
					end
				end

				callback("Error: Failed to parse API response")
			end
		end,
		on_stderr = function(_, data_lines)
			if data_lines and #data_lines > 0 then
				vim.notify("Rover API Error: " .. table.concat(data_lines, "\n"), vim.log.levels.ERROR)
			end
		end,
		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				callback("Error: API request failed with exit code " .. exit_code)
			end
		end,
	})
end

return M
