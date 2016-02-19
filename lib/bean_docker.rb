require "bean_docker/version"
require 'shellwords'
require 'json'


module BeanDocker
  # Your code goes here...
  class Docker
    def run mode=''
      image_name = "aws_beanstalk/current-app:latest"
      envvar_file_name = '/opt/elasticbeanstalk/deploy/configuration/containerconfiguration'

      begin
        container_config = JSON.parse(File.read(envvar_file_name))
      rescue => exception
        puts "Exception: #{exception}"
        puts "Enable access to this file with:\n"
        puts "  sudo chmod 664 #{envvar_file_name}"
      else
        begin
          raw_vars =  container_config['optionsettings']['aws:elasticbeanstalk:application:environment']

          command = "sudo docker run -ti -w=\"/usr/src/app\""

          raw_vars.each do |raw_var|
            variable, value = raw_var.split('=')
            if value # && !value.include?('`')
              command += " --env #{variable}=\"#{value.shellescape}\" "
            end
          end

          command = "#{command} #{image_name} bash"

          if mode == 'show'
            puts "Command for launching a new container:\n"
            puts command
          else
            puts "Launching a new container.  To protect the environment variables file again after you exit this container, use:\n"
            puts "  sudo chmod 660 #{envvar_file_name}"

            exec( command )
          end
        rescue => exception
          puts "Exception: #{exception}"
        end
      end
    end
  end
end
