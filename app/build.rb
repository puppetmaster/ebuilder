#
# -oOo- build -oOo- 
#

$menu[:Builds] = "/build/"

get '/build/' do
  @builds = Build.all
  if @builds.empty?
    haml :'/build/newbuild'
  else
    haml :'build/build'
  end
end

get '/build/show/:id/:slave_id/:project_id' do
  if @build = Build.get(params[:id],params[:slave_id],params[:project_id])
    haml :'/build/buildshow'
  else
    haml "%h1 Error loading Build [#{params[:id]},#{params[:slave_id]},#{params[:project_id]}"
  end
end

# Création d'un build
get '/build/new' do
  haml :'/build/newbuild'
end

get '/build/edit/:id/:slave_id/:project_id' do
  @build = Build.get(params[:id],params[:slave_id],params[:project_id])
  haml :'build/buildedit'
end

post '/build/update' do
  build = Build.get(params[:id])
  build.attribute_set(:name,params[:name])
  build.attribute_set(:ip,params[:ip])
  build.attribute_set(:user,params[:user])
  if params[:pass] != "nochange"
    build.attribute_set(:pass,params[:pass])
  end

  if build.save
    status 201
    redirect '/build/show/' + build.id.to_s
  else
    status 412
    redirect '/build/'
  end
end

=begin
post '/build/create' do 
  build = Build.new(:name => params[:name])
  build.ip = params[:ip]
  build.user = params[:user]
  build.pass = params[:pass]
  if build.save
    status 201
    redirect '/build/show/' + build.id.to_s
  else
    status 412
    redirect '/build/'
  end
end

get '/build/delete/:id' do
  slv = build.get(params[:id])
  if slv.destroy
    redirect '/build/'
  else
    redirect '/build/' #FIXME CLEAN INFORMATION
  end
end

delete '/build/:id' do 
  slv = build.get(params[:id])
  if slv.destroy
    redirect '/build'
  else
    redirect '/build' #FIXME CLEAN INFORMATION
  end
end

#
# -oOo- END - build - END -oOo- 
#
=end

