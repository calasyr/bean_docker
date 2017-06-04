require "bean_docker/version"
require 'shellwords'
require 'json'

DOCKER_IMAGE = "aws_beanstalk/current-app:latest"
CONFIG_PATH = '/opt/elasticbeanstalk/deploy/configuration/containerconfiguration'

module BeanDocker
  class Docker
    def run(args)
      @args = args[0]

      puts help_text && return if help?

      if Docker.mac_os?
        puts "This command can only run on an AWS Elastic Beanstalk instance."
        return
      end

      puts "This command has only been tested on Amazon Linux." unless Docker.linux_gnu?


      begin
        container_config = JSON.parse(File.read(envvar_file_name))
      rescue => exception
        puts "The environment variables needed to launch a new Docker container are protected"
        puts "You need to use bdrun as root"
        puts "  sudo /usr/local/bin/bdrun"
      else
        begin
          raw_vars =  container_config['optionsettings']['aws:elasticbeanstalk:application:environment']

          command = "sudo docker run -ti -w=\"/usr/src/app\""

          raw_vars.each do |raw_var|
            variable, value = raw_var.split('=')
            if value
              command += " --env #{variable}=\"#{value.shellescape}\" "
            end
          end

          command = "#{command} #{DOCKER_IMAGE} bash"

          if show?
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

    def help?
      return false if @args.empty?
      
      %w[-h --help help].include? @args[0]
    end

    def show?
      return false if @args.empty?
      
      %w[-s --show show].include? @args[0]
    end

    def self.mac_os?
      RbConfig::CONFIG['host_os'].starts_with?('darwin')
    end

    def self.linux_gnu?
      RbConfig::CONFIG['host_os'].starts_with?('linux-gnu')
    end

    def aws_client
      @aws_client ||= Docker.get_aws_client
    end

    def self.get_aws_client
      aws_settings = {
          :access_key_id => ENV['AWS_ACCESS_KEY'],
          :secret_access_key => ENV['AWS_SECRET_KEY'],
          :region => 'us-west-2'
      }

      Aws::ElasticBeanstalk::Client.new (AWS_SETTINGS)
    end

    def self.aws_credentials?
      have_credentials = ENV['AWS_ACCESS_KEY'] && ENV['AWS_SECRET_KEY']
      puts "You must set AWS_ACCESS_KEY and AWS_SECRET_KEY to connect to AWS." unless have_credentials
      have_credentials
    end

    #
    # get_env_vars
    #
    # Finds env vars for a Beanstalk environment, whether on an instance or on 
    # your local using the AWS Ruby gem connect to that environment
    def get_env_vars environment
      var_hash = {}

      if on_beanstalk_instance?
        container_config = JSON.parse(File.read(CONFIG_PATH))
        raw_vars =  container_config['optionsettings']['aws:elasticbeanstalk:application:environment']
        var_hash[:variable], var_hash[:value] = raw_var.split('=')
      elsif aws_credentials?
        response = aws_client.describe_environments(:environment_names => [environment_name])
        application_name = response.environments[0].application_name
        environment_id = response.environments[0].environment_id

        response = aws_client.describe_configuration_settings({:application_name => application_name, :environment_name => environment_name})


        option_settings = response.configuration_settings[0].option_settings
        rails_env_setting = option_settings.select {|setting| setting.option_name == 'RAILS_ENV'}

        if rails_env_setting.first
          rails_env = rails_env_setting.first.value

          # Before adding a variable to the hash the very first time, ask the user
          # This means you check the config file to see if the env var is accepted or rejected

          saved_variables = {}

          test_app_dir = '/Users/abrown/apps/platform-respondent-nurture-service'

          # First find the file
          settings_file = File("#{test_app_dir}/tmp/bd_config", 'r')

          if settings_file
            settings_file.each_line do |line|
              # Ignore comments
              unless line.lstrip[0] == '#'
                value_found = line.index('=')
                if value_found
                  variable = line.slice(0...value_found)
                  value = line.slice(value_found + 1..-1)

                  if value.length == 0
                    saved_variables[variable] = value
                  else
                    saved_variables[variable] = value
                  end
                end
              end
            end
          end

          # Append to the file
          config = File('tmp/bd_config', 'a')

          # Prompt the user regarding the new variables

          # Load each line into a hash key whose value is either blank or a quoted string
          # If it's blank, ignore this variable
          # If it's set, use this value
          # If it's missing, prompt the user to accept or override


          # If the user wants you to always ask, don't record the variable
          # Use the existing settings as you go to build the


          envvars = option_settings.select do |setting|
            setting[:namespace] == "aws:elasticbeanstalk:application:environment" &&
                !ignore_settings.include?(setting.option_name)
          end

          envvar_string = envvars.map{|envvar| "#{envvar.option_name}=#{envvar.value}"}.join(' ')


          # var_hash[:variable], var_hash[:value] = raw_var.split('=')


        end

      else
        puts "Must be on a Beanstalk instance.  Or have AWS_ACCESS_KEY and AWS_SECRET_KEY set."
      end

    end

    def self.help_text
      puts <<-END.gsub(/^\s+\|/, '')
      |
      |  Launch a new Docker container using same image and env vars Elastic Beanstalk uses
      |
      |  Usage:
      |    bdrun
      |    bdrun -h | --help
      |    bdrun -s | --show
      |
      |  Options:
      |     -h --help     Show this screen.
      |     -s --show     Show the Docker run command but don't execute it
      |
      END
    end
  end
end
