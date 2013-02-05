require "bundler/capistrano"

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

set :whenever_command, "bundle exec whenever"
set :whenever_identifier, defer { "#{application}_#{stage}" }
require "whenever/capistrano"

set :application, "apphakker"
set :repository,  "git@github.com:michiels/apphakker.git"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, "beta.apphakker.nl"                          # Your HTTP server, Apache/etc
role :app, "beta.apphakker.nl"                          # This may be the same as your `Web` server
role :db,  "beta.apphakker.nl", :primary => true # This is where Rails migrations will run
# role :db,  "your slave db-server here"

set :user, "deploy"
set :use_sudo, false

set :deploy_to, defer { "/u/apps/#{application}" }

before "deploy:finalize_update" do
  run "rm -f #{release_path}/config/database.yml; ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  run "rm -f #{release_path}/config/config.yml; ln -nfs #{shared_path}/config/config.yml #{release_path}/config/config.yml"
  run "rm -f #{release_path}/config/s3.yml; ln -nfs #{shared_path}/config/s3.yml #{release_path}/config/s3.yml"
  run "ln -nfs #{shared_path}/sockets #{release_path}/tmp/sockets"

  # Uncomment this if you are using sphinx with thinking_sphinx
  # run "rm -rf #{release_path}/db/sphinx; ln -nfs #{shared_path}/sphinx #{release_path}/db/sphinx"
end

namespace :deploy do
  task :start do
    run "sudo bluepill load /etc/bluepill/#{application}.pill"
  end
  task :stop do
    run "sudo bluepill #{application} stop"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "sudo bluepill #{application} restart"
  end
  task :status do
    run "sudo bluepill #{application} status"
  end
end

namespace :backup do
  task :perform do
    run "backup perform --trigger #{application}"
  end
end