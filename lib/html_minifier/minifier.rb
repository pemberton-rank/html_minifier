# encoding: UTF-8

require "execjs"
require "multi_json"

module HtmlMinifier

  class Minifier
    Error = ExecJS::Error

    SourceBasePath = File.expand_path("../../js/", __FILE__)

    def initialize(options = nil)
      if options.instance_of? Hash then
        @options = options.dup
        @log = @options.delete :log
      elsif options.nil?
        @options = nil
      else
        raise 'Unsupported option for HtmlMinifier: ' + options.to_s
      end

      js = %w{htmlminifier}.map do |i|
        File.open("#{SourceBasePath}/#{i}.js", "r:UTF-8").read
      end.join("\n")
      js = "function globe(){#{js};return this};var global = new globe();"
      @context = ExecJS.compile(js)
    end

    def minify(source)
      source = source.respond_to?(:read) ? source.read : source.to_s
      js = []
      if @options.nil? then
        js << "var min = require('html-minifier').minify(#{MultiJson.dump(source)});"
      else
        js << "var min = require('html-minifier').minify(#{MultiJson.dump(source)}, #{MultiJson.dump(@options).gsub(/\"\//, '/').gsub(/\/\"/, '/')});"
      end
      js << "return {min:min};"

      result = @context.exec js.join("\n")
      if @log.respond_to?(:info)
        result["logs"].each do |i|
          @log.info i
        end
      end
      result["min"]
    end
  end

  def self.minify(source, options = nil)
    Minifier.new(options).minify(source)
  end

end
