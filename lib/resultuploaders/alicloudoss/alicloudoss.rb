# frozen_string_literal: true

require 'aliyun/oss'
require './lib/auxiliary/json_helper'

# AutoHCK module
module AutoHCK
  # alicloudoss class
  class Alicloudoss
    CONFIG_JSON = 'lib/resultuploaders/alicloudoss/alicloudoss.json'

    include Helper

    attr_reader :url

    def initialize(project)
      @tag = project.engine_tag
      @timestamp = project.timestamp
      @logger = project.logger
      puts "@logger is  #{@logger}"
      @repo = project.config['repository']
      @config = Json.read_json(CONFIG_JSON, @logger)

      @access_key_id = ENV.fetch('AUTOHCK_ALICLOUDOSS_ACCESS_KEY_ID')
      @access_key_secret = ENV.fetch('AUTOHCK_ALICLOUDOSS_CLIENT_SECRET')

      @bucket_name = @config['bucket_name']
      @endpoint = @config['endpoint']

      @oss_client = nil
      @bucket = nil
    end

    def html_url; end

    # This method handles exceptions that may occur during the execution of the provided block.
    # Currently, it logs error messages for specific exceptions related to OSS client and server errors,
    # as well as for file not found and general standard errors. 
    # As of now, the exception handling only logs the errors without any additional recovery or fallback mechanisms.
    # Future enhancements may include more robust error handling strategies.
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def handle_exceptions(where)
      yield
    rescue Aliyun::OSS::ClientError => e
      @logger.error("OSS Error in #{where}: #{e.message}")
      false
    rescue Aliyun::OSS::ServerError => e
      @logger.error("OSS Error in #{where}: #{e.message}")
      false
    rescue Errno::ENOENT => e
      @logger.error("OSS File not found in #{where}: #{e.message}")
      false
    rescue StandardError => e
      @logger.error("OSS General error in #{where}: (#{e.class}) #{e.message}")
      false
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def ask_token; end

    def save_token(token); end

    def load_token; end

    def connect 
      handle_exceptions(__method__) do
        @oss_client = Aliyun::OSS::Client.new(
          access_key_id: @access_key_id,
          access_key_secret: @access_key_secret,
          endpoint: @endpoint
        )
        @bucket = @oss_client.get_bucket(@bucket_name)
        @logger.info("OSS bucket connected: #{@bucket_name}")
        true
      end
    end

    def create_project_folder
      handle_exceptions(__method__) do
        @path = "#{@repo}/CI/#{@tag}-#{@timestamp}"
        @bucket.put_object("#{@path}/")
        @logger.info("OSS project folder created: #{@path}")
        true
      end
    end

    # Note: The maximum file size for upload is 5GB. Future optimizations may be needed to handle larger files.
    def upload_file(l_path, r_name) 
      handle_exceptions(__method__) do
        remote_path = "#{@path}/#{r_name}"
        @bucket.put_object(remote_path, :file => l_path)  
        @logger.info("OSS file uploaded: #{remote_path}")
        true
      end
    end

    def update_file_content(content, r_name)
      handle_exceptions(__method__) do
        remote_path = "#{@path}/#{r_name}"
        @bucket.put_object(remote_path) do |content_io|
          content_io << content
        end
        @logger.info("OSS file content updated: #{remote_path}")
        true
      end
    end

    def delete_file(r_name)
      handle_exceptions(__method__) do
        r_path = "#{@path}/#{r_name}"
        @bucket.delete_object(r_path)  
        @logger.info("OSS file deleted: #{r_path}")
        true
      end
    end

    def close; end
  end
end
