# Plugin to add environment variables to the `site` object in Liquid templates
module Jekyll
  class EnvironmentVariablesGenerator < Generator
    def generate(site)
      site.config['api'] = ENV['API'] || 'http://localhost/api/'
      # Add other environment variables to `site.config` here...
    end
  end
end
