require 'rubygems'
require 'i18n'
module Middleware
  class LocaleSelector
    
    def initialize(app)
      @app = app
    end

    def call(env)
      @env = env
      set_locale
      return [301, {'Location' => protocol + domain + port + path }, ''] if subdomain == default_locale


      if @language_from_browser and @locale != default_locale
        [301, {'Location' => protocol + @locale + "." + domain + port + path }, '']
      else
        @app.call(@env)
      end
    end

    private

    def default_locale; 'en' end
    def path; @env['REQUEST_PATH'] end
    def port; @env['SERVER_PORT'] == "80" ? "" : ":#{@env['SERVER_PORT']}" end
    
    def domain
      @env['SERVER_NAME'].split('.')[-2..-1].join('.')
    end
    

    def subdomain
      @subdomain = if @env['SERVER_NAME'].split('.').count > 2
        @env['SERVER_NAME'].split('.').first
      else
        ''
      end
      @subdomain == "www" ? '' : @subdomain
    end

    def protocol
      @env['rack.url_scheme'] + "://"
    end

    def set_locale
      locale = if subdomain.present?
        @language_from_browser = nil
        subdomain
      else
        if @env['HTTP_ACCEPT_LANGUAGE'].nil?
          default_locale
        else
          @language_from_browser = true
          @env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
        end
      end
      @locale = I18n.available_locales.include?(locale.to_sym) ? locale : default_locale

      I18n.locale = @env['rack.locale'] = @locale.to_sym
    end

  end
end