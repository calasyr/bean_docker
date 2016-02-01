require "bean_docker/version"
require 'json'

module BeanDocker
  # Your code goes here...
  class Docker
    def run
      image_name = "aws_beanstalk/current-app:latest"

      container_config = JSON.parse(File.read('/opt/elasticbeanstalk/deploy/configuration/containerconfiguration'))
      raw_vars =  container_config['optionsettings']['aws:elasticbeanstalk:application:environment']

      task = ARGV[0]

      alias_line = "sudo docker run -ti -w=\"/home/webapp/saas/rails\""

      raw_vars.each do |raw_var|
        variable, value = raw_var.split('=')
        alias_line += " --env #{variable}=\"#{value}\" " if value
      end

      exec("#{alias_line} #{image_name} bash" )
    end
  end
end
