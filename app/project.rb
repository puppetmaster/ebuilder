#
# -oOo- PROJECT -oOo-
#
get '/project/' do
  @projects = Project.all
  if @projects.empty?
    haml :'project/newproject'
  else
    haml :'project/project'
  end
end

get '/project/show/:id' do
  @project = Project.get(params[:id])
  haml :'project/projectshow'
end


get '/project/edit/:id' do
  @project = Project.get(params[:id])
  haml :'project/projectedit'
end

# Création d'un project
get '/project/new' do
  haml :'project/newproject'
end

get '/project/delete/:id' do
  slv = Project.get(params[:id])
  if slv.destroy
    redirect '/project/'
  else
    redirect '/project/' #FIXME CLEAN INFORMATION
  end
end

delete '/project/:id' do 
  slv = Project.get(params[:id])
  if slv.destroy
    redirect '/project/'
  else
    redirect '/project/' #FIXME CLEAN INFORMATION
  end
end

post '/project/update' do
  project = Project.get(params[:id])
  project.attribute_set(:url,params[:url])
  project.attribute_set(:period,params[:period])
  if project.save
    status 201
    redirect '/project/show/' + project.id.to_s
  else
    status 412
    redirect '/project/'
  end
end

post '/project/create' do 
  project = Project.new(:name => params[:name])
  project.url = params[:url]
  project.period = params[:period]
  if project.save
    status 201
    redirect '/project/show/' + project.id.to_s
  else
    status 412
    redirect '/project/'
  end
end

#
# -oOo- END - PROJECT - END -oOo- 
#
