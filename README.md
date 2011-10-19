# Locale Selector

## Description

The locale_selector.rb file is meant to be used as middleware for a rails app. 

## Setup
The following assumes you're running a rails 3 app.

Put the file in your app:

  cp locale_selector.rb RAILS_APP/lib/middleware/locale_selector.rb
  
Add the following to your application.rb somewhere inside the Application class

  require "#{config.root}/lib/middleware/locale_selector.rb"  # or if you want to require all of the things! Dir.glob("#{config.root}/lib/**/*.rb").each { |file| require file }
  config.middleware.use Middleware::LocaleSelector



With this file in place assuming the side domain is something like herp.com you will have the following:

Given valid i18n available locales of: es, de, en
With a default locale of :en

'en.herp.com' redirects to 'herp.com'   # is default locale
'do.herp.com' redirects to 'herp.com'   # no valid locale
'herp.com' sets the locale to :en       # is default locale
'de.herp.com' sets the locale to :de    # locale is available
'www.herp.com' redirects to 'herp.com'  # who uses www anyways?

If the browser has it's language set to es and es is a supported locale then:

'herp.com' redirects to 'es.herp.com'

