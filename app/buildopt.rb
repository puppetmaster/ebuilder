#
# -oOo- buildopt -oOo- 
#

$menu[:Build_Options] = "/buildopt/"

get '/buildopt/' do
  @buildopts = Buildopt.all
  if @buildopts.empty?
    haml :'/buildopt/newbuildopt'
  else
    haml :'buildopt/buildopt'
  end
end

get '/buildopt/show/:id/:slave_id/:project_id' do
  if @buildopt = Buildopt.get(params[:id],params[:slave_id],params[:project_id])
    haml :'/buildopt/buildoptshow'
  else
    haml "%h1 Error loading buildopt [#{params[:id]},#{params[:slave_id]},#{params[:project_id]}"
  end
end

# Création d'un buildopt
get '/buildopt/new' do
  haml :'/buildopt/newbuild'
end

get '/buildopt/edit/:id/:slave_id/:project_id' do
  @buildopt = Buildopt.get(params[:id],params[:slave_id],params[:project_id])
  haml :'buildopt/buildoptedit'
end

post '/buildopt/update' do
  buildopt = Buildopt.get(params[:id])
  buildopt.attribute_set(:name,params[:name])
  buildopt.attribute_set(:ip,params[:ip])
  buildopt.attribute_set(:user,params[:user])
  if params[:pass] != "nochange"
    buildopt.attribute_set(:pass,params[:pass])
  end

  if buildopt.save
    status 201
    redirect '/buildopt/show/' + build.id.to_s
  else
    status 412
    redirect '/buildopt/'
  end
end

=begin
post '/buildopt/create' do 
  buildopt = Buildopt.new(:name => params[:name])
  buildopt.ip = params[:ip]
  buildopt.user = params[:user]
  buildopt.pass = params[:pass]
  if buildopt.save
    status 201
    redirect '/buildopt/show/' + build.id.to_s
  else
    status 412
    redirect '/buildopt/'
  end
end

get '/buildopt/delete/:id' do
  slv = buildopt.get(params[:id])
  if slv.destroy
    redirect '/buildopt/'
  else
    redirect '/buildopt/' #FIXME CLEAN INFORMATION
  end
end

delete '/buildopt/:id' do 
  slv = buildopt.get(params[:id])
  if slv.destroy
    redirect '/buildopt'
  else
    redirect '/buildopt' #FIXME CLEAN INFORMATION
  end
end

#
# -oOo- END - buildopt - END -oOo- 
#
=end

