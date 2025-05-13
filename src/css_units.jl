############################################# CSS Unitful ##################################

include("..\\..\\SimpleRatio.jl\\src\\SimpleRatio.jl")

using .SimpleRatio

abstract type CSSUnit end
abstract type PhysicalUnit <: CSSUnit end
abstract type RelativeUnit <: CSSUnit end

const DEFAULT_PRECISION = 2 # Number of digits that should be taken when creating from a float
const OP = ('+', '-')

struct px <: PhysicalUnit
	value::MRational
	px(v::Number) = new(MRational(Float64(v), DEFAULT_PRECISION))
	px(m::MRational) = new(m)
end

struct inch <: PhysicalUnit
	value::MRational
	inch(v::Number) = new(MRational(Float64(v), DEFAULT_PRECISION))
	inch(m::MRational) = new(m)
end

struct cm <: PhysicalUnit
	value::MRational
	cm(v::Number) = new(MRational(Float64(v), DEFAULT_PRECISION))
	cm(m::MRational) = new(m)
end

struct mm <: PhysicalUnit
	value::MRational
	mm(v::Number) = new(MRational(Float64(v), DEFAULT_PRECISION))
	mm(m::MRational) = new(m)
end

struct pt <: PhysicalUnit
	value::MRational
	pt(v::Number) = new(MRational(Float64(v), DEFAULT_PRECISION))
	pt(m::MRational) = new(m)
end

struct pc <: PhysicalUnit
	value::MRational
	pc(v::Number) = new(MRational(Float64(v), DEFAULT_PRECISION))
	pc(m::MRational) = new(m)
end

const CSS_RATIOS = Dict(
    px => 1,
    inch => 96,
    cm => 38,
    mm => 4,
    pt => 2,
    pc => 16
)

################################### Relative Units ####################################

struct percent <: RelativeUnit
	value::MRational
	percent(v::Number) = new(MRational(Float64(v)))
	percent(m::MRational) = new(m)
end

struct vh <: RelativeUnit
	value::MRational
	vh(v::Number) = new(MRational(Float64(v)))
	vh(m::MRational) = new(m)
end

struct vw <: RelativeUnit
	value::MRational
	vw(v::Number) = new(MRational(Float64(v)))
	vw(m::MRational) = new(m)
end

const ViewUnit = Union{vw,vh}

struct em <: RelativeUnit
	value::MRational
	em(v::Number) = new(MRational(Float64(v)))
	em(m::MRational) = new(m)
end

struct CSSContext
	viewport_size::NTuple{2,px}
	parent_size::NTuple{2,px}
end

struct CSSCalc
	property::String
	context::CSSContext
	expr::String
end

####################################### Operations ##################################################

Base.:*(n::Number, unit::Type{T}) where T<:CSSUnit = T(n)
Base.:+(a::PhysicalUnit, b::PhysicalUnit) = to_px(a) + to_px(b)
Base.:+(a::px, b::px) = (a.value + b.value)px
Base.:-(p::px) = (-p.value)px
Base.:-(a::PhysicalUnit, b::PhysicalUnit) = to_px(a) - to_px(b)
Base.:-(a::px, b::px) = (a.value - b.value)px
Base.:*(a::Number, b::CSSUnit) = typeof(b)(b.value * a)
Base.:*(b::CSSUnit, a::Number) = typeof(b)(b.value * a)
Base.:/(b::CSSUnit, a::Number) = typeof(b)(b.value / a)

function Base.:+(p::percent, c::PhysicalUnit, context::CSSContext, property::String)
	if _is_horizontal(property)
	    return to_px(context.parent_size[1],p) + to_px(c)
	elseif _is_vertical(property)
	    return to_px(context.parent_size[2],p) + to_px(c)
	end
end
Base.:+(c::PhysicalUnit,p::percent,con::CSSContext, property::String) = +(p,c,con)

function Base.:-(p::percent, c::PhysicalUnit, context::CSSContext, property::String)
	if _is_horizontal(property)
	    return to_px(context.parent_size[1],p) - to_px(c)
	elseif _is_vertical(property)
	    return to_px(context.parent_size[2],p) - to_px(c)
	end
end
Base.:-(c::PhysicalUnit,p::percent,con::CSSContext, property::String) = -(-(p,c,con))

## Percent and percent OP

function Base.:+(p1::percent, p2::percent, context::CSSContext, property::String)
	if _is_horizontal(property)
	    return to_px(context.parent_size[1],p1) + to_px(context.parent_size[1], p2)
	elseif _is_vertical(property)
	    return to_px(context.parent_size[2],p1) + to_px(context.parent_size[2], p2)
	end
end

function Base.:-(p1::percent, p2::percent, context::CSSContext, property::String)
	if _is_horizontal(property)
	    return to_px(context.parent_size[1],p1) - to_px(context.parent_size[1], p2)
	elseif _is_vertical(property)
	    return to_px(context.parent_size[2],p1) - to_px(context.parent_size[2], p2)
	end
end

## Viewport OP

function Base.:+(v::ViewUnit, p::PhysicalUnit, c::CSSContext, property::String)
	return to_px(c.viewport_size[_get_pos(v)], v) + to_px(c)
end

Base.:+(p::PhysicalUnit, v::ViewUnit, c::CSSContext, property::String) = +(v,p,c,property)

function Base.:-(v::ViewUnit, p::PhysicalUnit, c::CSSContext, property::String)
	return to_px(c.viewport_size[_get_pos(v)], v) - to_px(c)
end

Base.:-(p::PhysicalUnit, v::ViewUnit, c::CSSContext, property::String) = -(-(v,p,c,property))

## Viewport and percent OP

function Base.:+(p::percent, v::ViewUnit, context::CSSContext, property::String)
	if _is_horizontal(property)
	    return to_px(context.parent_size[1],p) + to_px(context.viewport_size[_get_pos(v)], v)
	elseif _is_vertical(property)
	    return to_px(context.parent_size[2],p) + to_px(context.viewport_size[_get_pos(v)], v)
	end
end

Base.:+(v::ViewUnit, p::percent, context::CSSContext, property::String) = +(p,v,context,property)

function Base.:-(p::percent, v::ViewUnit, context::CSSContext, property::String)
	if _is_horizontal(property)
	    return to_px(context.parent_size[1],p) - to_px(context.viewport_size[_get_pos(v)], v)
	elseif _is_vertical(property)
	    return to_px(context.parent_size[2],p) - to_px(context.viewport_size[_get_pos(v)], v)
	end
end

Base.:-(v::ViewUnit, p::percent, context::CSSContext, property::String) = -(-(p,v,context,property))

evaluate_calc(calc::CSSCalc) = process_calc(calc.expr, calc.context, calc.property)

"""
    to_px(c::CSSUnit)

Convert an unit to pixels. Actually, a navigator is unable to get the DPI(Dot Per Inch) of your screen.
So the default value is 96px/inch
"""
to_px(u::PhysicalUnit) = (u.value * CSS_RATIOS[typeof(u)])px
to_px(m::MRational) = px(m)
to_px(parent_value::PhysicalUnit,p::percent) = (parent_value.value * p.value/100)px
to_px(view_h::px,v::vh) = (view_h.value * v.value/100)px
to_px(view_w::px,v::vw) = (view_w.value * v.value/100)px
to_px(size::PhysicalUnit,e::em) = (size.value * e.value)px
to_px(c::CSSUnit) = error("Conversion to px not implemented for unit $(typeof(c))")

Base.show(io::IO,u::T) where T<:CSSUnit = show(io,"$(convert(Float64,u.value)) $T")
Base.show(u::CSSUnit) = show(stdout, u)
Base.print(io::IO,u::T) where T<:CSSUnit = print(io,"$(convert(Float64,u.value)) $T")
Base.print(u::CSSUnit) = print(stdout, u)
Base.println(io::IO,u::T) where T<:CSSUnit = println(io,"$(convert(Float64,u.value)) $T")
Base.println(u::CSSUnit) = println(stdout, u)

function get_from_str(str::String)
	for i in 1:length(str)
		character = Int(str[i])

		if !(48 <= character <= 57)
			return (parse(Float64,str[begin:i-1]))*_get_type(str[i:end])
		end
	end
end

############################################## Mini Arithmetical Parser #########################################

function process_calc(str::String,context::CSSContext,property::String)
	str = replace(str, ' ' => "")
	tokens = get_tokens(str)
	parsed = parse_token(tokens)
	return process_tokens(parsed, context, property)
end

process_tokens(tokens::Vector,context::CSSContext,property::String) = tokens[1](tokens[2], 
	(tokens[3] isa Vector) ? process_tokens(tokens[3],context,property) : tokens[3],context,property)


function get_tokens(str::String)
	tokens = []
	str = replace(str, ' ' => "")
	L = length(str)
	i = 1
	found = false
	opening = findfirst(str, "(")
	closing = findfirst(str, ")")
	mul = findfirst(str, "*")
	div = findfirst(str, "/")

	if opening != nothing
		if closing != nothing
			push!(tokens, get_tokens(str[opening+1:closing-1]))
			
			if opening > 1
				push!(tokens, get_tokens(str[begin:opening-1]))
			end

			if closing < L
			    push!(tokens, get_tokens(next))
			end

			return tokens
		else
			error("Parenthesis not closed.")
		end
	end

	if mul != nothing
		push!('*', get_tokens(str[begin:mul-1]), get_tokens(str[mul+1:end]))

		return tokens
	end

	if div != nothing
		push!('*', get_tokens(str[begin:div-1]), get_tokens(str[div+1:end]))

		return tokens
	end

	while i <= L
		character = str[i]

		if character in OP
			next_token = get_tokens(str[i+1:end])
			push!(tokens,character,str[begin:i-1], next_token)
			i = L
			found = true
		end

		i += 1
	end

    !found && return str

	return tokens
end

parse_token(c::Char) = begin
	if c == '+'
		return +
	elseif c == '-'
		return -
	elseif c == '*'
		return *
	elseif c == '/'
		return /
	else
		error("Insupported operation $c.")
	end
end
parse_token(s::AbstractString) = get_from_str(s)
parse_token(A::Vector) = parse_token.(A)

################################################ Helpers #######################################################

@inline function _get_type(str::String)
	if str == "px"
		return px
	elseif str == "in" || str == "inch"
		return inch
	elseif str == "cm"
		return cm
	elseif str == "mm"
		return mm
	elseif str == "pt"
		return pt
	elseif str == "pc"
		return pc
	elseif str == "%"
		return percent
	elseif str == "em"
		return em
	elseif str == "vw"
		return vw
	elseif str == "vh"
		return vh
	else
		error("Type $str not defined.")
	end
end

_is_horizontal(property::String) = (property == "width" || occursin("left", property) || occursin("rigth", property))
_is_vertical(property::String) = (property == "height" || occursin("top", property) || occursin("bottom", property))
_get_pos(::T) where T<:ViewUnit = T == vw ? 1 : 2
