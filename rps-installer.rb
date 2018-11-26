require 'open-uri'
require 'sentry-raven'
require 'config'

Config.load_and_set_settings(Config.setting_files("config", "development"))
version = Settings.version
installer = Settings.installer % { :version => version }
uri = Settings.uri % { :installer => installer }
dsn = Settings.dsn
log_prefix = Settings.log_prefix % { :version => version }


def download(file_name, uri)
  open(file_name, 'wb') do |file|
    file << open(uri).read
  end
end 

def success?(code_exit)
  code_exit_leave_before_install = 1602
  code_exit_sucessfull_install = 3203
  
  code_exit.success? || [code_exit_leave_before_install, 
    code_exit_sucessfull_install].include?(code_exit.exitstatus)
end

def log_files(time)
  basedir = ENV['TEMP'] || "./"
  log_prefix = Settings.log_prefix 
  first_log_file = "#{basedir}/#{log_prefix}#{time}.log"

  Dir["#{basedir}/#{log_prefix}*.log"].select{ |file| file >= first_log_file }
end

download(installer, uri)

time = DateTime.now.strftime("%Y%d%m%H%M%S")
time = "20181123145015"

#return if system(installer) || success?($?)

Raven.configure do |config|
  config.dsn = dsn
end

log_files(time).each do |file| 
  File.readlines(file).each do |line|
    Raven.breadcrumbs.record do |crumb|
      crumb.category = File.basename(file, '*.log')
      crumb.timestamp = Time.now.to_i
      crumb.message = line
    end  
  end
end

Raven.capture_message("RPS Test")

puts "Done!"