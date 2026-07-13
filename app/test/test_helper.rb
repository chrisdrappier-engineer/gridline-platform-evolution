ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # The Docker runtime copies the app into the image, so schema files generated
    # during db:prepare are not shared between the prepare and test containers.
    # Keep tests single-process until the test container flow commits or mounts
    # a schema artifact that Rails can use for parallel database setup.
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module AuthenticationTestHelper
  def sign_in_as(user)
    post login_path, params: {
      session: {
        email: user.email,
        password: "gridline"
      }
    }
  end
end

ActionDispatch::IntegrationTest.include AuthenticationTestHelper
