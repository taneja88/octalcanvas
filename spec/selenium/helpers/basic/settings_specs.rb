shared_examples_for "settings basic tests" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_admin_logged_in
  end

  context "admins tab" do

    def add_account_admin
      address = "student1@example.com"
      f(".add_users_link").click
      f("textarea.user_list").send_keys(address)
      f(".verify_syntax_button").click
      wait_for_ajax_requests
      f("#user_lists_processed_people .person").text.should == address
      f(".add_users_button").click
      wait_for_ajax_requests
      user = User.find_by_name(address)
      user.should be_present
      admin = AccountUser.find_by_user_id(user.id)
      admin.should be_present
      admin.membership_type.should == "AccountAdmin"
      f("#enrollment_#{admin.id} .email").text.should == address
      admin.id
    end

    before (:each) do
      get "/accounts/#{account.id}/settings"
      f("#tab-users-link").click
    end

    it "should add an account admin" do
      add_account_admin
    end

    it "should delete an account admin" do
      admin_id = add_account_admin
      f("#enrollment_#{admin_id} .remove_account_user_link").click
      driver.switch_to.alert.accept
      wait_for_ajax_requests
      AccountUser.find_by_id(admin_id).should be_nil
    end
  end

  context "account settings" do

    def click_submit
      submit_form("#account_settings")
      wait_for_ajax_requests
    end

    before (:each) do
      get account_settings_url
    end

    it "should change the account name " do
      new_account_name = 'new default account name'
      replace_content(f("#account_name"), new_account_name)
      click_submit
      account.reload
      account.name.should == new_account_name
      f("#account_name").should have_value(new_account_name)
    end

    it "should change the default quotas" do
      f('#tab-quotas-link').click

      # update the quotas
      course_quota = account.default_storage_quota_mb
      course_quota_input = f('[name="default_storage_quota_mb"]')
      course_quota_input.should have_value(course_quota.to_s)

      user_quota = account.default_user_storage_quota_mb
      user_quota_input = f('[name="default_user_storage_quota_mb"]')
      user_quota_input.should have_value(user_quota.to_s)

      course_quota += 25
      replace_content(course_quota_input, course_quota.to_s)
      user_quota += 15
      replace_content(user_quota_input, user_quota.to_s)

      submit_form('#default-quotas')
      wait_for_ajax_requests

      # ensure the account was updated properly
      account.reload
      account.default_storage_quota_mb.should == course_quota
      account.default_storage_quota.should == course_quota * 1048576
      account.default_user_storage_quota_mb == user_quota
      account.default_user_storage_quota.should == user_quota * 1048576

      # ensure the new value is reflected after a refresh
      get account_settings_url
      fj('[name="default_storage_quota_mb"]').should have_value(course_quota.to_s) # fj to avoid selenium caching
      fj('[name="default_user_storage_quota_mb"]').should have_value(user_quota.to_s) # fj to avoid selenium caching
    end

    it "should change the default language to spanish" do
      f("#account_default_locale option[value='es']").click
      click_submit
      account.reload
      account.default_locale.should == "es"
      f("label[for='account_name']").text.should include_text("Nombre de Cuenta")
    end
  end
end