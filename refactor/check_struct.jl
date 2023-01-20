abstract type Typer end
abstract type SubType end
abstract type SubTypeA <: SubType end
abstract type SubTypeB <: SubType end

struct MyType{T} <: Typer where T<:SubType
    a::Int
end

function MyType{T}(a::Int, b::Int) where T<:SubType
    return MyType{T}(a)
end

a = MyType{SubTypeA}(1, 2)
b = MyType{SubTypeB}(1)

function asdf(b::MyType{SubTypeA})
    println("This is an A")
end

function asdf(b::MyType{SubTypeB})
    println("This is a B")
end

asdf(a)
asdf(b)
