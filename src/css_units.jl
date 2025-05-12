############################################# CSS Unitful ##################################

abstract type CSSUnit end

struct px <: CSSUnit
	value::Int
end

struct inch <: CSSUnit
	value::Float32
end

struct cm <: CSSUnit
	value::Float32
end

struct mm <: CSSUnit
	value::Float32
end

struct pt <: CSSUnit
	value::Float32
end

struct pc <: CSSUnit
	value::Float32
end

Base.:*(n::Number, unit::Type{T}) where T<:CSSUnit = T(n)

"""
    to_px(c::CSSUnit)

Convert an unit to pixels. Actually, a navigator is unable to get the DPI(Dot Per Inch) of your screen.
So the default value is 96px/inch
"""
to_px(i::inch) = (i.value*96)px
to_px(c::cm) = (c.value*38)px
to_px(m::mm) = (m.value*4)px
to_px(p::pt) = (p.value*2)px
to_px(p::pc) = (p.value*16)px
to_px(p::px) = p

Base.show(u::T) where T<:CSSUnit = show("$(u.value)$T")
Base.print(u::T) where T<:CSSUnit = print("$(u.value)$T")
Base.println(u::T) where T<:CSSUnit = println("$(u.value)$T")

############################### Test ################################

function main()
	@time p = 15inch
	@time b = to_px(p)
	println(p)
	println(b)
end

main()