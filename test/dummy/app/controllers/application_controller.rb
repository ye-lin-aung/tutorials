class ApplicationController < ActionController::Base
  # The dummy app stubs current_user so engine controllers can be tested in isolation.
  # Tests set the current user via sign_in_as helper in test_helper.rb.
  def current_user
    @current_user ||= Thread.current[:tutorials_test_user]
  end
end
