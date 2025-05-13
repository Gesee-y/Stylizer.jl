################################### CSS Generator ######################################

include("..\\..\\NodeTree.jl\\src\\NodeTree.jl")

using .NodeTree

#= Okay, we want to be able to manage CSS for our VDOM
First we should keep up the syles, for that, we need a Dict
=#

# Default stylesheet
const USER_AGENT_STYLESHEET = Dict{String,Dict{String,String}}(
	"body" => Dict{String,String}("display" => "block", "margin" => "8px"),
    "h1" => Dict{String,String}("display" => "block", "font-size" => "16px" #=2em=#,
    	"margin-block-start" => "2px" #=0.67em=# , "margin-block-end" => "2px" #=0.67em=#, "font-weight" => "bold"),
    "p" => Dict{String,String}("display" => "block", "margin-block-start" => "2px" #=1em=#, "margin-block-end" => "2px" #=1em=#),
    "a" => Dict{String,String}("color" => "-web-kit-link", "text-decoration" => "underline", "cursor" => "pointer"),
    "table" => Dict{String,String}("display" => "table", "border-collapse" => "separate", "border-spacing" => "2px"),
    "ul" => Dict{String,String}("display" => "block", "list-style-type" => "disc", "margin-block-start" => "2px" #= 1em =#,
    	"margin-block-end" => "1px" #= 1em =#)
)

#getStyle(elt::HTMLElement) = nvalue(elt).style

mutable struct CSSRule
    selector::String
    style::Dict
end

mutable struct CSSMedia
    condition::String
    rules
end

function _create_chunck(text::String, n::Int)
    L = length(text)
    chunks = Int[]
    count = 0

    for i=1:L
        character = text[i]
        if character == '}'
            count += 1
            if count == n
                count = 0
                push!(chunks,i)
            end
        end
    end

    count != 0 && push!(chunks, L)

    return chunks
end

parseCSSChunk!(id::Int,c::Int,text::String,s::Int,e::Int) = begin 
    tree = parseCSS(text[s:e]; start=id*c+1)
end

function parallelParsing(text::String; count = 10)
    chunks = _create_chunck(text,count)
    processed = 0
    current = 0
    process = []
    tree = ObjectTree()
    i = 0


    task = map(chunks) do chunk
        i += 1
        if i == 1
            Threads.@spawn parseCSSChunk!(0, count, text, 1, chunks[1])
        else
            Threads.@spawn parseCSSChunk!(i-1, count, text, chunks[i-1]+1, chunks[i])
        end
    end

    for j in 1:length(task)
        data = fetch(task[j])

        merge_tree!(tree, data)
    end
    return tree
end

function parseCSS(text::String; start=0)
    text = replace(text, '\n' => "")
    tree = ObjectTree(;current=start)
    i = 1
    L = length(text)
    start_stack = Int[1]

    current_parent = tree
    name = ""
    setted = false

    while i <= L
        character = text[i]

        if character == '{'
            j = pop!(start_stack)
            if j > 1
                (text[j-1] != '}') && (j -= 1)
            end
            setted = false
            name = text[j:i-1]
            style, offset = _get_data(text,i)

            node = Node(CSSRule(name,style))
            add_child(current_parent, node)
            i += offset+1
        else
            if !setted
                push!(start_stack, i)
                setted = true
            end
        end

        i += 1
    end

    return tree
end

######################################### Helpers ##########################################

function _get_data(text::String, i::Int)
    state = :SKIPA
    L = length(text)
    current_attribute = ""
    values = String[]
    offset = 1
    attrib_idx = 1
    val_idx = 0
    attribute = Dict()

    for j = (i+1):L
        character = text[j]

        if character == ' '
            if state == :VALUE
                g = val_idx
                push!(values, text[g:j-1])
                val_idx = j+1
            end
        elseif character == ';' && state == :VALUE
            state = :SKIPA
            l = length(values)
            g = val_idx
            if l == 0
                attribute[current_attribute] = text[g:j-1]
            else
                push!(values, text[g:j-1])
                values = String[]
            end
            val_idx = 0
            current_attribute = ""
        elseif character != ' ' && character != '}' && state == :SKIPA
            state = :ATTRIBUTE
            attrib_idx = j
        elseif character != ' ' && state == :SKIPV
            state = :VALUE
            val_idx = j
        elseif character == ':' && state == :ATTRIBUTE
            state = :SKIPV
            current_attribute = text[attrib_idx:j-1]
        elseif character == '}'
            return (attribute, offset)
        end

        offset += 1
    end

    return attribute, offset
end
