require "bean_docker/version"
require 'shellwords'
require 'json'


module BeanDocker
  # Your code goes here...
  class Docker
    def run
      image_name = "aws_beanstalk/current-app:latest"

      container_config = JSON.parse(File.read('/opt/elasticbeanstalk/deploy/configuration/containerconfiguration'))
      raw_vars =  container_config['optionsettings']['aws:elasticbeanstalk:application:environment']

      alias_line = "sudo docker run -ti -w=\"/usr/src/app\""

      raw_vars.each do |raw_var|
        variable, value = raw_var.split('=')
        if value # && !value.include?('`')
          alias_line += " --env #{variable}=\"#{value.shellescape}\" "
        end
      end

      exec("#{alias_line} #{image_name} bash" )
    end
  end
end
