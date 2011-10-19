require File.dirname(__FILE__) + '/../spec_helper'

class AppMock
  def call(something)
    'no redirection, rails stack is called'
  end
end

environment_mock = {
  'SERVER_NAME'           => 'austin.com',
  'HTTP_ACCEPT_LANGUAGE'  => "es-US,\nen;q=0.8,\nfr;q=0.6",
  'rack.url_scheme'       => 'https',
  'SERVER_PORT'           => '80',
  'REQUEST_PATH'          => '/derp'
}
describe Middleware::LocaleSelector do
  include Middleware
  
  before(:each) do
    @environment = environment_mock.clone
    @app = AppMock.new
    @ls = LocaleSelector.new(@app)
  end
  
  describe "#protocol" do
  
    it "should return the http protocol" do
      @ls.instance_variable_set("@env", @environment)
      @ls.send(:protocol).should == @environment['rack.url_scheme'] + "://"
    end
  end
  
  describe "#subdomain" do
    it "should return the subdomain if one exists" do
      @environment['SERVER_NAME'] = 'bo.austin.com'
      @ls.instance_variable_set("@env", @environment)
      
      @ls.send(:subdomain).should == 'bo'
    end
  
    it "should return a blank string if there is no subdomain" do
      @ls.instance_variable_set("@env", @environment)
      
      @ls.send(:subdomain).should == ''
    end
    
    it "should return a blank string if the subdomain is www" do
      @environment['SERVER_NAME'] = 'www.austin.com'
      @ls.instance_variable_set("@env", @environment)
      @ls.send(:subdomain).should == ''
    end
  end
  
  describe "#set_locale" do
    before(:each) do
      @environment = environment_mock.clone
      I18n.stubs(:available_locales).returns([:es,:en])
    end
  
    it "should set the locale to the subdomain if it is included in the available locales" do
      @environment['SERVER_NAME'] = 'es.austin.com'
      @ls.instance_variable_set("@env", @environment)
      @ls.send(:set_locale)
      @ls.instance_variable_get("@locale").should == "es"
    end
    
    it "should set the locale to en if the subdomain if it is not included in available locales" do
      @environment['SERVER_NAME'] = 'it.austin.com'
      @ls.instance_variable_set("@env", @environment)
      @ls.send(:set_locale)
      @ls.instance_variable_get("@locale").should == "en"
    end
    
    it "should set the subdomain to the browser's first language choice if there is no subdomain" do
      @ls.instance_variable_set("@env", @environment)
      @ls.send(:set_locale)
      @ls.instance_variable_get("@locale").should == "es"
    end
    
    it "should set the subdomain to english if no subdomain and first browser language choice not available" do
      @environment['HTTP_ACCEPT_LANGUAGE'] = "bo-US,\nen;q=0.8,\nfr;q=0.6"
      @ls.instance_variable_set("@env", @environment)
      @ls.send(:set_locale)
      @ls.instance_variable_get("@locale").should == "en"
    end
    
    it "should set the locale to english if there is no subdomain and the browser doesn't have a usable field" do
      @environment['HTTP_ACCEPT_LANGUAGE'] = nil
      @ls.instance_variable_set("@env", @environment)
      @ls.send(:set_locale)
      @ls.instance_variable_get("@locale").should == "en"
    end
  end
  
  describe "#call" do
    before(:each) do
      @environment = environment_mock.clone
      I18n.stubs(:available_locales).returns([:es,:en])
    end
    
    it "should return a redirection array if the subdomain is en" do
      @environment['SERVER_NAME'] = 'en.austin.com'
      response = @ls.call(@environment)
      response.shift.should == 301
      response.shift.should == {"Location" => "https://austin.com/derp"}
    end
    
    it "should return a redirection array if the subdomain is missing and there is an acceptable locale in the browser" do
      response = @ls.call(@environment)
      response.shift.should == 301
      response.shift.should == {"Location" => "https://es.austin.com/derp"}
    end
    
    it "should make a call to the app and have a locale set if the correct subdomain is set" do
      @environment['SERVER_NAME'] = 'es.austin.com'
      @app.expects(:call).once
      response = @ls.call(@environment)
    end
    
    it "should maintain the port and path information in the redirection url" do
      @environment['SERVER_NAME'] = 'austin.com'
      @environment['SERVER_PORT'] = '3456'
      response = @ls.call(@environment)
      response[1]['Location'].should == "https://es.austin.com:3456/derp"
    end
    
  end

end
