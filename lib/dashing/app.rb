require 'sinatra'
require 'sprockets'
require 'sinatra/content_for'
require 'rufus/scheduler'
require 'coffee-script'
require 'sass' if RUBY_VERSION < "2.5.0"
require 'sassc' if RUBY_VERSION >= "2.5.0"
require 'json'
require 'yaml'
require 'thin'

SCHEDULER = Rufus::Scheduler.new

def development?
  ENV['RACK_ENV'] == 'development'
end

def production?
  ENV['RACK_ENV'] == 'production'
end

helpers Sinatra::ContentFor
helpers do
  def protected!
    # override with auth logic
  end

  def authenticated?(token)
    return true unless settings.auth_token
    token && Rack::Utils.secure_compare(settings.auth_token, token)
  end
end

set :root, Dir.pwd
set :sprockets,     Sprockets::Environment.new(settings.root)
set :assets_prefix, '/assets'
set :digest_assets, false
set :server, 'thin'
set :connections, {}
set :history_file, 'history.yml'
set :public_folder, File.join(settings.root, 'public')
set :views, File.join(settings.root, 'dashboards')
set :default_dashboard, nil
set :auth_token, nil
set :template_languages, %i[html erb]

if File.exist?(settings.history_file)
  set :history, YAML.load_file(settings.history_file, fallback: {})
else
  set :history, {}
end

%w(javascripts stylesheets fonts images).each do |path|
  settings.sprockets.append_path("assets/#{path}")
end

['widgets', File.expand_path('../../../javascripts', __FILE__)].each do |path|
  settings.sprockets.append_path(path)
end

not_found do
  send_file File.join(settings.public_folder, '404.html'), :status => 404
end

at_exit do
  File.write(settings.history_file, settings.history.to_yaml)
end

get '/' do
  protected!
  dashboard = settings.default_dashboard || first_dashboard
  raise Exception.new('There are no dashboards available') if not dashboard

  redirect "/" + dashboard
end

get '/events', :provides => 'text/event-stream' do
  protected!
  response.headers['X-Accel-Buffering'] = 'no' # Disable buffering for nginx
  ids = params[:ids] ? params[:ids].split(',').to_set : nil
  stream :keep_open do |out|
    settings.connections[out] = ids
    settings.history.each do |id, event|
      out << event if ids.nil? || ids.include?(id)
    end
    out.callback { settings.connections.delete(out) }
  end
end

get '/:dashboard' do
  protected!
  settings.template_languages.each do |language|
    file = File.join(settings.views, "#{params[:dashboard]}.#{language}")
    return render(language, params[:dashboard].to_sym) if File.exist?(file)
  end

  halt 404
end

post '/dashboards/:id' do
  request.body.rewind
  body = JSON.parse(request.body.read)
  body['dashboard'] ||= params['id']
  if authenticated?(body.delete("auth_token"))
    send_event(params['id'], body, 'dashboards')
    204 # response without entity body
  else
    status 401
    "Invalid API key\n"
  end
end

post '/widgets/:id' do
  request.body.rewind
  body = JSON.parse(request.body.read)
  if authenticated?(body.delete("auth_token"))
    send_event(params['id'], body)
    204 # response without entity body
  else
    status 401
    "Invalid API key\n"
  end
end

get '/views/:widget?.html' do
  protected!
  settings.template_languages.each do |language|
    file = File.join(settings.root, "widgets", params[:widget], "#{params[:widget]}.#{language}")
    return Tilt[language].new(file).render if File.exist?(file)
  end

  "Drats! Unable to find a widget file named: #{params[:widget]} to render."
end

Thin::Server.class_eval do
  def stop_with_connection_closing
    Sinatra::Application.settings.connections.dup.each_key(&:close)
    stop_without_connection_closing
  end

  alias_method :stop_without_connection_closing, :stop
  alias_method :stop, :stop_with_connection_closing
end

def send_event(id, body, target=nil)
  body[:id] = id
  body[:updatedAt] ||= (Time.now.to_f * 1000.0).to_i
  event = format_event(body.to_json, target)
  Sinatra::Application.settings.history[id] = event unless target == 'dashboards'
  Sinatra::Application.settings.connections.each { |out, ids|
    begin
      out << event if target == 'dashboards' || ids.nil? || ids.include?(id)
    rescue IOError => e # if the socket is closed an IOError is thrown
      Sinatra::Application.settings.connections.delete(out)
    end
  }
end

def format_event(body, name=nil)
  str = ""
  str << "event: #{name}\n" if name
  str << "data: #{body}\n\n"
end

def first_dashboard
  files = Dir[File.join(settings.views, '*')].collect { |f| File.basename(f, '.*') }
  files -= ['layout']
  files.sort.first
end

def require_glob(relative_glob)
  Dir[File.join(settings.root, relative_glob)].each do |file|
    require file
  end
end

settings_file = File.join(settings.root, 'config/settings.rb')
require settings_file if File.exist?(settings_file)

{}.to_json # Forces your json codec to initialize (in the event that it is lazily loaded). Does this before job threads start.
job_path = ENV["JOB_PATH"] || 'jobs'
require_glob(File.join('lib', '**', '*.rb'))
require_glob(File.join(job_path, '**', '*.rb'))
