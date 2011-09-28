# coding: utf-8
require "rubygems"
require 'bundler'
Bundler.setup(:rakefile)

begin
  require 'vlad'
  require 'vlad/core'
  require 'vlad/git'
  
  # Deploy config
  set :repository, 'git://github.com/linjekoll/socket-server.git'
  set :revision,   'origin/master'
  set :deploy_to,  '/opt/apps/socket-server'
  set :domain,     'webmaster@burken'
  set :mkdirs,     ['.']
  set :shared_paths, {'vendor' => 'vendor'}
  set :bundle_cmd, "/usr/local/rvm/bin/webmaster_bundle"
  set :god_cmd, "sudo /usr/bin/god"
  
  namespace :vlad do
    desc "Deploys a new revision of webbhallon and reloads it using God"
    task :deploy => ['update', 'bundle', 'god:reload', 'god:restart', 'cleanup']
    
    remote_task :bundle do
      run "cd #{current_release} && #{bundle_cmd} install --without=development,test --deployment"
    end
    
    namespace :god do
      remote_task :reload do
        run "#{god_cmd} load #{current_release}/monitor.god"
      end
      
      remote_task :restart do
        run "#{god_cmd} restart monitor"
      end
    end
  end
rescue LoadError => e
  warn "Some gems are missing, run `bundle install`"
  warn e.inspect
end