local str = pandoc.utils.stringify

function get_header_data(data)
  local get_headers = {
      Header = function(el)
        local id = el.identifier
        local text = str(el.content):gsub("^[%d.]+ ", "")
        quarto.log.debug("nameref: insert header [" .. id .. "]")
        table.insert(data, {id = id, text = text})
      end,
      
      Div = function(el)
        if el.attributes["link-id"] then
          local id = el.attributes["link-id"]
          local text = el.attributes["link-title"]
          quarto.log.debug("nameref: insert div [" .. id .. "]")
          table.insert(data, {id = id, text = text})
        end
      end
    }
  return get_headers
end

function change_ref(data)
  local change_rawinline = {
    RawInline = function(el)
      for key, value in pairs(data) do
        quarto.log.debug("nameref: RawInline [" .. value.id .. "]")
        if el.text:match("\\nameref{(.*)}") == value.id then
          quarto.log.debug("nameref: \\nameref matched: [" .. value.id .. "]: ")
          local target =  "#" .. value.id 
          local link = pandoc.Link(value.text, target)
          return link
        end
      end
    end
  }
  return change_rawinline
end

local function add_div_id(div)
  return {
   Div = function(elem)
    quarto.log.debug("nameref: add_div_id Div")
    if elem.classes:includes("cell-output-display") 
      or elem.classes:includes("cell-output-stdout")then
      elem.identifier = div.attributes["link-id"]
      return elem
     end
  end
  }
end

function Div(el)
  if el.classes:includes('link') then
    quarto.log.debug("nameref: Div link")
    return el:walk(add_div_id(el))
  end
end

function Pandoc(doc)
  local header_data = {}
  doc:walk(get_header_data(header_data))
  return doc:walk(change_ref(header_data))
end
