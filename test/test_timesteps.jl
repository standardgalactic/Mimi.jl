using Mimi
using Base.Test

###################################
#  Test basic timestep functions  #
###################################

t = Timestep{1850, 10, 3000}(1)
@test isfirsttimestep(t)
t1 = Mimi.getnexttimestep(t)
t2 = Mimi.getnewtimestep(t1, 1860)
@test isfirsttimestep(t2)
t3 = Mimi.getnewtimestep(t2, 1840)
@test t3.t == 3

t = Timestep{2000, 1, 2050}(51)
@test isfinaltimestep(t)
t = Mimi.getnexttimestep(t)
@test_throws ErrorException Mimi.getnexttimestep(t)

#########################################################
#  Test a model with components with different offsets  #
#########################################################

# we'll have Bar run from 2000 to 2010
# and Foo from 2005 to 2010

@defcomp Foo begin
    input = Parameter()
    output = Variable(index=[time])
end

function run_timestep(c::Foo, ts::Timestep)
    c.Variables.output[ts] = c.Parameters.input + ts.t
end

@defcomp Bar begin
    input = Parameter(index=[time])
    output = Variable(index=[time])
end

function run_timestep(c::Bar, ts::Timestep)
    if Mimi.gettime(ts) < 2005
        c.Variables.output[ts] = c.Parameters.input[ts]
    else
        c.Variables.output[ts] = c.Parameters.input[ts] * ts.t
    end
end

m = Model()
setindex(m, :time, 2000:2010)
# test that you can only add components with start/final within model's time index range
@test_throws ErrorException addcomponent(m, Foo, start=1900)
@test_throws ErrorException addcomponent(m, Foo, final=2100)

foo = addcomponent(m, Foo, start=2005) #offset for foo
bar = addcomponent(m, Bar)

set_external_parameter(m, :x, 5.)
set_external_parameter(m, :y, collect(1:11))
connectparameter(m, :Foo, :input, :x)
connectparameter(m, :Bar, :input, :y)

# run(m)
