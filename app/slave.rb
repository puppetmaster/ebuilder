#
# -oOo- SLAVE -oOo- 
#

$menu[:Slaves] = "/slave/"

get '/slave/' do
  @slaves = Slave.all
  if @slaves.empty?
    haml :'/slave/newslave'
  else
    haml :'slave/slave'
  end
end

get '/slave/show/:id' do
  @slave = Slave.get(params[:id])
  haml :'/slave/slaveshow'
end

# Création d'un Slave
get '/slave/new' do
  haml :'/slave/newslave'
end

get '/slave/edit/:id' do
  @slave = Slave.get(params[:id])
  haml :'slave/slaveedit'
end

post '/slave/update' do
  slave = Slave.get(params[:id])
  slave.attribute_set(:name,params[:name])
  slave.attribute_set(:ip,params[:ip])
  slave.attribute_set(:user,params[:user])
  if params[:pass] != "nochange"
    slave.attribute_set(:pass,params[:pass])
  end

  if slave.save
    status 201
    redirect '/slave/show/' + slave.id.to_s
  else
    status 412
    redirect '/slave/'
  end
end

post '/slave/create' do 
  slave = Slave.new(:name => params[:name])
  slave.ip = params[:ip]
  slave.user = params[:user]
  slave.pass = params[:pass]
  if slave.save
    status 201
    redirect '/slave/show/' + slave.id.to_s
  else
    status 412
    redirect '/slave/'
  end
end

get '/slave/delete/:id' do
  slv = Slave.get(params[:id])
  if slv.destroy
    redirect '/slave/'
  else
    redirect '/slave/' #FIXME CLEAN INFORMATION
  end
end

delete '/slave/:id' do 
  slv = Slave.get(params[:id])
  if slv.destroy
    redirect '/slave'
  else
    redirect '/slave' #FIXME CLEAN INFORMATION
  end
end

#
# -oOo- END - SLAVE - END -oOo- 
#
