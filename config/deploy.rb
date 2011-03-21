require 'capistrano/ext/multistage'

set :stages, %w(production)
set :default_stage, "production"

require "bundler/capistrano"

default_run_options[:pty] = true

set :application, 'near_hospitals'

set :scm, :git
# set :git_enable_submodules, 1
set :git_shallow_clone, 1
set :scm_user, 'ubuntu'
set :use_sudo, false
set :repository, "git://github.com/saleiva/nearHospitals.git"
ssh_options[:forward_agent] = true
set :keep_releases, 5

set :appserver_production, '178.79.131.104'
set :user,  'ubuntu'

set(:deploy_to){
  "/home/ubuntu/www/#{application}"
}

after  "deploy:update_code", :symlinks, :set_staging_flag

desc "Restart Application"
deploy.task :restart, :roles => [:app] do
  run "touch #{current_path}/tmp/restart.txt"
end

task :symlinks, :roles => [:app] do
  run <<-CMD
    ln -s #{shared_path}/system #{release_path}/public/system;
    ln -s #{shared_path}/cache #{release_path}/public/;
    ln -nfs #{shared_path}/config/cartodb_config.yml #{release_path}/config/cartodb_config.yml;
  CMD
end

desc 'Create asset packages'
task :asset_packages, :roles => [:app] do
 run <<-CMD
   export RAILS_ENV=#{stage} &&
   cd #{release_path} &&
   rake asset:packager:build_all
 CMD
end

desc "Uploads config yml files to app server's shared config folder"
task :upload_yml_files, :roles => :app do
  run "mkdir #{deploy_to}/shared/config ; true"
  upload("config/cartodb_config.yml", "#{deploy_to}/shared/config/cartodb_config.yml")
end

namespace :near_hospitals do

  desc "Scrape hospitals from some different web sources"
  task :scrape!, :roles => :app do
    run "cd #{current_release} && RAILS_ENV=#{stage} rake near_hospitals:scrape!"
  end

end