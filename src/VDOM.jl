###################################### Virtual DOM ##################################

include("..\\..\\NodeTree.jl\\src\\NodeTree.jl")

using .NodeTree

"""
    mutable struct HTMLData
		const tag::String
		content::String
		attribute::Dict
		raw::String
		inner::String
		style::Dict{String,String}

Representation of an HTML element
"""
mutable struct HTMLData
	const tag::String
	content::String
	attribute::Dict
	raw::String
	inner::String
	style::Dict{String,String}

	## Constructor

	HTMLData(t::String,c::String,attribute::Dict,r::String,i::String=""; style=Dict{String,String}()) = new(t,c,attribute,r,i,style)
	HTMLData(t::String,attribute::Dict,r::String; style=Dict{String,String}()) = new(t,"",attribute,r,"",style)
end

const HTMLElement = Node{HTMLData}

Base.show(h::HTMLData) = show(h.tag, " Attribute : ", h.attribute)
Base.print(h::HTMLData) = print(h.tag, " Attribute : ", h.attribute)
Base.println(h::HTMLData) = println(h.tag, " Attribute : ", h.attribute)

# Should be extended in order to add more orphan node detection
const ORPHAN_NODES = (:br,:img,:input)

"""
    parseHTML(text::String)

this fonction takes an HTML text as input an output a virtual DOM
"""
function parseHTML(text::String)
	i = 1 ## Initial value of our counter
	L = length(text)

	## The VDOM
	tree = ObjectTree()
	current_parent = tree

	## This will allow use to manage memory more efficiently
	# We avoid concatenating everytime with the help of this stack
	start_stack = NTuple{2, Int}[]

	while i <= L
		character = text[i]

		if character == '<'
			next_character = text[i+1]

			## If we are encountering a comment or a CDATA
			if next_character == '!'
				offset = (text[i+2] == '-') ? _get_comment_length(text,i) : _get_cdata_length(text,i)
				i += offset
			## If we are closing a teg
			elseif next_character == '/'
				index = pop!(start_stack) # We get the start index of the tag, thanks to HTML LIFO
				data = nvalue(current_parent) # Return the data of the node
				data.content = text[index[1]:i-1]
				current_parent = get_parent(current_parent) # We reassign the current parent
			# else we are entering a tag
			else
				tag, attribute, offset = _get_tag(text, i)
				data = HTMLData(tag,"",attribute, text[i:i+offset+1])
				node = Node(data)
				add_child(current_parent, node)

				if !_is_orphan(tag)
				    current_parent = node
				end

				push!(start_stack, (i,i+offset))

				i += offset
			end
        end
		i += 1
	end

	return tree
end

"""
    VDOMToHTML(tree::ObjectTree)

Convert back a VDOM into an HTMl text
"""
function VDOMToHTML(tree::ObjectTree)
	root = get_children(get_root(tree))[1]
	data = nvalue(root)

	return data.raw*"\n"*data.content*"</$(data.tag)>"
end

function getElementByTagName(dom::ObjectTree, tag::String)
	iterator = BFS_search(tree)
    result = []

	for elt in iterator
		if nvalue(elt).tag == tag
			push!(result, elt);
		end
	end
end

function getElementByClassName(dom::ObjectTree, class::String)
	iterator = BFS_search(tree)
    result = []

	for elt in iterator
		if "class" in keys((nvalue(elt).attribute))
			if nvalue(elt).class == class
				push!(result, elt);
			end
		end
	end
end

function getElementById(dom::ObjectTree, id::String)
	iterator = BFS_search(dom)

	for elt in iterator
		if "id" in keys((nvalue(elt).attribute))
			if nvalue(elt).attribute["id"] == id
				return elt
			end
		end
	end
end

# ---------------------------------------- Helpers --------------------------------------- #

## This function get the length of the comment
function _get_comment_length(text::String,i::Int)
	L = i
	while text[i:i+2] != "-->"
		i += 1
	end

	return i - L + 3
end

## This function get the length of a CDATA
function _get_cdata_length(text::String,i::Int)
	L = i
	while text[i] != '>'
		i += 1
	end

	return i - L + 1
end

## This function get all the information about a tag
function _get_tag(text::String, pos::Int=1)
	tag = ""
	current_attribute = ""
	current_value = ""
	attrib_idx = 0
	value_idx = 0
	strings = (:STRING, :DSTRING)
	attribute = Dict{String, String}()
	state = :NORMAL
	L = length(text)
	offset = 0
	tag_end = 1

    j = pos+1

    ## First we get the tag
    # while we don't encounter a space
    while text[j] != ' '

    	# IF we encaounter a closing >, then we stop here
    	if text[j] == '>'
    		return (text[(pos+1):j-1], attribute, j-pos-1)
    	end
    	j += 1
    end
    tag = text[(pos+1):(j-1)]
    state = :ATTRIBUTE
    attrib_idx = j

	for i=j:L
		character = text[i]
		if character == ' '

			## If we are actually searching an attribute
			if state == :ATTRIBUTE
				current_attribute = text[attrib_idx:(i-1)]
				(current_attribute != "") && (attribute[current_attribute] = "true")
				current_attribute = ""
				attrib_idx = i+1
			# If we are actually searching a value
			elseif state == :VALUE
				attribute[current_attribute] = current_value
				current_attribute = ""
				current_value = ""
				state = :ATTRIBUTE
				attrib_idx = i+1
			end
		elseif character == '>'
			if state == :VALUE || state == :NORMAL || state == :ATTRIBUTE
				(state == :ATTRIBUTE) && (current_value = "true")
				attribute[current_attribute] = current_value
                return (tag, attribute, offset)
            else
            	error("Cannot do this")
            end
        elseif character == '"'
        	if state == :VALUE
        		state = :DSTRING
        		value_idx = i+1
        	elseif state == :DSTRING
        		state = :VALUE
        		current_value = text[value_idx:(i-1)]
        	else
        		error("Cannot do this")
        	end
        elseif character == '\''
        	if state == :VALUE
        		state = :STRING
        		value_idx = i+1
        	elseif state == :STRING
        		state = :VALUE
        		current_value = text[value_idx:(i-1)]
        	else
        		error("Cannot do this")
        	end
		elseif character == '='
			if state == :ATTRIBUTE
			    state = :VALUE
			    current_attribute = text[attrib_idx:(i-1)]
			else
				println(text[i-10:i])
				error("Cannot do this")
			end
		end

		offset += 1
	end

	return (tag, attribute, offset)
end
 
_is_orphan(s::String) = Symbol(s) in ORPHAN_NODES || Symbol(s[begin:end-1]) in ORPHAN_NODES
_is_orphan(s::Symbol) = _is_orphan(string(s))

# ----------------------------------------- Test ------------------------------------------ #

function main()
	text = """<body>
    <div id="desktop">
    	<div id="container">
	    	<header>
	    		<h1>Quotes Generator</h1>
	    	</header>

	    	<section>
	    		<h1>Your Quotes</h1>
	    		<div id="generator">
	    			<!-- The generated citations will go into this plave -->
	    		</div>
	    	</section>

	    	<div id="disp-container">
	    		<button id="disp">Add Citation</button>
	    	</div>

	    	<div id='add'>
	    		<p>
		    		<label for="author"> Author : </label><input type="text" name="author" id="author" required><br/>
		    		<label for="cit"> Citation : </label><textarea id='cit' placeholder="Enter the citation" required></textarea><br/>
		    	</p>
		    	<p>
		    		<button id="add-button">Add</button>
		    		<button id="cancel">Cancel</button>
		    	</p>
	    	</div>
        </div>
    </div>

    <script src="js/script.js"></script>
</body>"""

	trees = parseHTML(text)
	@time tree2 = parseHTML(text)

	print_tree(tree2)
	#println(txt)
	#root = get_root(tree2)
	#ch = get_children(root)

	#println(nvalue(ch[1]).tag)
	#println(nvalue(ch[1]).content)
end

main()