; HTTP request textobjects (ir/ar, ]r/[r in lua/plugins/treeshitter.lua)
; inner: the request itself (method line, headers, body)
; outer: its whole section (### title line, # comments such as @name, request)
(request) @request.inner
(section) @request.outer
