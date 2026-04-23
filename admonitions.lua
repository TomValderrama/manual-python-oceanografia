-- admonitions.lua
-- Convierte bloques !!! tip/warning "Título"\n    contenido
-- a texto con negrita para el PDF (pandoc no entiende la sintaxis MkDocs)

function Para(el)
  local text = pandoc.utils.stringify(el)

  -- Buscar patrón:  !!! tipo "Título"  [contenido opcional en el mismo párrafo]
  local atype, title, content = text:match('^!!!%s+(%a+)%s+"([^"]*)"(.*)$')

  if not atype then
    -- Sin comillas: !!! tipo Título
    atype, title = text:match('^!!!%s+(%a+)%s+(.+)$')
    content = ''
  end

  if not atype then return nil end

  content = content:gsub('^%s+', ''):gsub('%s+$', '')

  local prefix = (atype == 'warning') and '⚠  ' or '▶  '
  local header = prefix .. title

  -- Construir inlines: negrita para el encabezado, texto normal para el contenido
  local inlines = pandoc.List({})
  inlines:extend(pandoc.Strong(pandoc.Str(header)).content)
  if content ~= '' then
    inlines:insert(pandoc.Str(' — '))
    local parsed = pandoc.read(content, 'markdown')
    if #parsed.blocks > 0 and parsed.blocks[1].t == 'Para' then
      inlines:extend(parsed.blocks[1].content)
    else
      inlines:insert(pandoc.Str(content))
    end
  end

  return pandoc.Para(inlines)
end
